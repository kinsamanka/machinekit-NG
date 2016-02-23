add_subdirectory(rtapi_math)
add_subdirectory(shmdrv)

add_definitions(-DEMC2_SYSTEM_CONFIG_DIR=\"/etc/machinekit\")

set(XXAPI_COMMON_SRCS
    rtapi_common.c
    rtapi_task.c
    rtapi_shmem.c
    rtapi_time.c
    rtapi_exception.c)

add_library(rtapi_heap OBJECT rtapi_heap.c)
set_target_properties(rtapi_heap PROPERTIES COMPILE_DEFINITIONS "ULAPI")

add_library(rtapi_app OBJECT rtapi_app.cc)
set_target_properties(rtapi_app PROPERTIES COMPILE_DEFINITIONS "ULAPI")

add_library(rtapi_compat OBJECT rtapi_compat.c)
set_target_properties(rtapi_compat PROPERTIES COMPILE_DEFINITIONS "ULAPI")

add_library(rtapi_support OBJECT rtapi_support.c rtapi_hexdump.c)
set_target_properties(rtapi_support PROPERTIES COMPILE_DEFINITIONS "ULAPI")

add_library(ulapi_autoload OBJECT ulapi_autoload.c)
set_target_properties(ulapi_autoload PROPERTIES COMPILE_DEFINITIONS "ULAPI")

# GIT_BUILD_SHA
if(GIT)
    execute_process(COMMAND git rev-parse --short HEAD
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE _out
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(NOT _out)
        set(_out "non_git_repo")
    endif()
else()
    set(_out "no_git_found")
endif()

add_executable(rtapi_msgd rtapi_msgd.cc 
    $<TARGET_OBJECTS:rtapi_compat> $<TARGET_OBJECTS:rtapi_heap>)
set_target_properties(rtapi_msgd PROPERTIES
    COMPILE_DEFINITIONS
        "ULAPI;GIT_BUILD_SHA=\"${_out}\";LWS_LIBRARY_VERSION=\"${LWS_VERSION}\""
    RUNTIME_OUTPUT_DIRECTORY ${PROJECT_LIBEXEC_DIR})
target_link_libraries(rtapi_msgd mtalk mk-pb2++ mkini mkshm)
_install_exec(rtapi_msgd)

add_executable(flavor flavor.c $<TARGET_OBJECTS:rtapi_compat>)
set_target_properties(flavor PROPERTIES COMPILE_DEFINITIONS "ULAPI")
target_link_libraries(flavor mkini mkshm)
_install(flavor)

set(RTAPI_SRC ${XXAPI_COMMON_SRCS} 
    rtapi_heap.c rtapi_main.c rtapi_support.c rtapi_hexdump.c rtapi_compat.c
    $<TARGET_OBJECTS:nanopb>)

add_library(mkulapi SHARED $<TARGET_OBJECTS:ulapi_autoload>
    $<TARGET_OBJECTS:rtapi_compat> $<TARGET_OBJECTS:rtapi_support>)
set_target_properties(mkulapi PROPERTIES
    COMPILE_DEFINITIONS "ULAPI"
    BUILD_WITH_INSTALL_RPATH FALSE
    INSTALL_RPATH "${_rpath}"
    INSTALL_RPATH_USE_LINK_PATH TRUE
    VERSION ${GENERIC_LIB_VERSION})
target_link_libraries(mkulapi mk_rip mkini mkshm)
cleanup_rpath_hack(mkulapi)
_install(mkulapi)

unset(cflags)
if(WITH_USERMODE_PCI)
    set(RTAPI_SRC ${RTAPI_SRC} rtapi_pci.c)
    if(UDEV_CFLAGS)
        set(cflags "${cflags} ${UDEV_CFLAGS}")
    endif()
endif()

foreach(_flav ${BUILD_THREAD_FLAVORS})
    _flavor_helper(${_flav})
    add_library(ulapi-${_fname} SHARED ${XXAPI_COMMON_SRCS}
        ulapi_main.c ${${_FLAV}_THREADS_SOURCE}
        $<TARGET_OBJECTS:rtapi_heap> $<TARGET_OBJECTS:rtapi_support>)
    set_target_properties(ulapi-${_fname} PROPERTIES 
        COMPILE_DEFINITIONS "ULAPI;THREAD_FLAVOR_ID=${RTAPI_${_FLAV}_ID}"
        COMPILE_FLAGS "${${_FLAV}_THREADS_RTFLAGS}"
        LIBRARY_OUTPUT_DIRECTORY ${PROJECT_LIBEXEC_DIR}
        LINK_FLAGS "${${_FLAV}_THREADS_LDFLAGS}"
        PREFIX "")
    target_link_libraries(ulapi-${_fname} mkshm mkhal)
    _install_exec(ulapi-${_fname})

    set(vscript "-Wl,--version-script,rtapi_${_fname}.vers")
    add_library(rtapi_${_fname} SHARED ${RTAPI_SRC} ${${_FLAV}_THREADS_SOURCE})
    set_target_properties(rtapi_${_fname} PROPERTIES 
        COMPILE_DEFINITIONS "RTAPI;THREAD_FLAVOR_ID=${RTAPI_${_FLAV}_ID}"
        COMPILE_FLAGS "${${_FLAV}_THREADS_RTFLAGS} ${cflags}"
        LIBRARY_OUTPUT_DIRECTORY ${PROJECT_LIBEXEC_DIR}/${_fname}
        LINK_FLAGS "${${_FLAV}_THREADS_LDFLAGS} ${vscript} -Bsymbolic"
        OUTPUT_NAME "rtapi"
        PREFIX "")
    if(WITH_USERMODE_PCI)
        target_link_libraries(rtapi_${_fname} ${UDEV_LIBRARIES})
    endif()
    add_custom_command(TARGET rtapi_${_fname}
        PRE_LINK
        COMMAND pwd
        COMMAND ${CMAKE_SOURCE_DIR}/scripts/get_symbols 
            CMakeFiles/rtapi_${_fname}.dir/link.txt
            rtapi_${_fname}.vers
        COMMENT " Running PRELINK action ")
    _install_exec(rtapi_${_fname} ${_fname})

    add_executable(rtapi_app_${_fname} rtapi_app.cc rtapi_compat.c
        rtapi_hexdump.c rtapi_support.c)
    set_target_properties(rtapi_app_${_fname} PROPERTIES
        COMPILE_DEFINITIONS "ULAPI;THREAD_FLAVOR_ID=${RTAPI_${_FLAV}_ID}"
        COMPILE_FLAGS "${${_FLAV}_THREADS_RTFLAGS}"
        BUILD_WITH_INSTALL_RPATH FALSE
        INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib/machinekit/${_fname};${_rpath}"
        INSTALL_RPATH_USE_LINK_PATH TRUE
        LINK_FLAGS "${${_FLAV}_THREADS_LDFLAGS}"
        RUNTIME_OUTPUT_DIRECTORY ${PROJECT_LIBEXEC_DIR})
    target_link_libraries(rtapi_app_${_fname} mk_rip.${_fname} mkini 
        mkshm mtalk rtapi_math mk-pb2++ ${CMAKE_DL_LIBS})
    cleanup_rpath_hack(rtapi_app_${_fname})
    _install_exec_setuid(rtapi_app_${_fname})

    set(SETUID_DEPS ${SETUID_DEPS} rtapi_app_${_fname})
endforeach()

add_custom_target(setuid 
    COMMAND chown 0:0 ${SETUID_DEPS}
    COMMAND chmod 4755 ${SETUID_DEPS}
    DEPENDS ${SETUID_DEPS}
    WORKING_DIRECTORY ${PROJECT_LIBEXEC_DIR}
    VERBATIM)

install(FILES rsyslogd-machinekit.conf
    DESTINATION /etc/rsyslog.d
    RENAME machinekit.conf)
