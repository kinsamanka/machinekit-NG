set(with_protobuf "define")
set(with_boost "define")
set(with_czmq "define")
set(with_avahi "define")
set(with_jansson "define")
set(with_lws "define")
set(with_ssl "define")
set(with_uriparser "define")
set(with_uuid "define")

if(WITH_USERMODE_PCI)
    pkg_check_modules(UDEV REQUIRED libudev)
    set(with_usermode_pci "define")
else()
    set(with_usermode_pci "undef")
endif()

set(RTAPI_POSIX_ID 0)
set(RTAPI_POSIX_NAME "posix")
set(POSIX_THREADS_SOURCE "rt-preempt.c")
set(POSIX_THREADS_RTFLAGS "-pthread")
set(POSIX_THREADS_LDFLAGS "-lpthread -lrt")
set(RTAPI_RT_PREEMPT_ID 1)
set(RTAPI_RT_PREEMPT_NAME "rt-preempt")
set(RT_PREEMPT_THREADS_SOURCE "rt-preempt.c")
set(RT_PREEMPT_THREADS_RTFLAGS "-pthread")
set(RT_PREEMPT_THREADS_LDFLAGS "-lpthread -lrt")
set(RTAPI_XENOMAI_ID 2)
set(RTAPI_XENOMAI_NAME "xenomai")
set(XENOMAI_THREADS_SOURCE xenomai.c)
set(XENOMAI_THREADS_RTFLAGS ${XENO_CFLAGS})
set(XENOMAI_THREADS_LDFLAGS ${XENO_LDFLAGS})

include(RpathHack)

include_directories(${INCLUDE_DIR})
include_directories(${INCLUDE_DIR}/proto)

set(CMAKE_C_FLAGS 
    "${CMAKE_C_FLAGS} -fPIC -fwrapv -fno-strict-overflow -std=gnu99 -fgnu89-inline")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")

# enable runtime comparison of GIT_CONFIG_SHA (config.h) and GIT_BUILD_SHA
find_program(GIT git)
if(GIT)
    execute_process(COMMAND git rev-parse --short HEAD
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE _out
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(NOT _out)
        set(_out "non_git_repo")
        set(GIT_CONFIG_SHA "." PARENT_SCOPE)
    else()
        set(GIT_CONFIG_SHA ".${_out}" PARENT_SCOPE)
        execute_process(COMMAND git rev-parse --abbrev-ref HEAD
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            OUTPUT_VARIABLE _branch
            ERROR_QUIET
            OUTPUT_STRIP_TRAILING_WHITESPACE)
    endif()
else()
    set(_out "no_git_found")
    set(GIT_CONFIG_SHA "." PARENT_SCOPE)
endif()
if(NOT _branch)
    set(_branch "none")
endif()

set(PACKAGE_VERSION "${MK_VERSION_MAJOR}.${MK_VERSION_MINOR}")
set(GIT_VERSION "v${PACKAGE_VERSION}~${_branch}~${_out}")
set(GIT_CONFIG_SHA "${_out}")
set(GENERIC_LIB_VERSION "${PACKAGE_VERSION}")

# export vars
set(PACKAGE_VERSION ${PACKAGE_VERSION} PARENT_SCOPE)
set(GIT_BRANCH ${_branch} PARENT_SCOPE)

set(NPB_DEFINITIONS PB_FIELD_32BIT PB_SYSTEM_HEADER=<pb-machinekit.h>)

add_subdirectory(machinetalk)
add_subdirectory(libnml)
add_subdirectory(rtapi)
add_subdirectory(hal)
add_subdirectory(emc)

add_dependencies(rtapi_app pb_gen_files)
foreach(_flav ${BUILD_THREAD_FLAVORS})
    _flavor_helper(${_flav})
    add_dependencies(pbring.${_fname} npb_gen_files)
    add_dependencies(pbmsgs.${_fname} npb_gen_files)
    add_dependencies(ringload.${_fname} npb_gen_files)
    add_dependencies(hal_lib_${_fname} pb_gen_files)
endforeach()

# create needed directories
file(MAKE_DIRECTORY ${PROJECT_MAN_DIR}/man1)
file(MAKE_DIRECTORY ${PROJECT_MAN_DIR}/man3)
file(MAKE_DIRECTORY ${PROJECT_MAN_DIR}/man9)
file(MAKE_DIRECTORY ${PROJECT_SYSCONF_DIR})

# create config.h
configure_file(
    "${PROJECT_SOURCE_DIR}/src/config.h.in"
    "${PROJECT_BINARY_DIR}/include/config.h"
    @ONLY)
