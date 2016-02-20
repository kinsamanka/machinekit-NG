set(HALLIBSRCS
    hal_alias.c
    hal_comp.c
    hal_funct.c
    hal_group.c
    hal_instance.c
    hal_lib.c
    hal_memory.c
    hal_misc.c
    hal_param.c
    hal_pin.c
    hal_procfs.c
    hal_rcomp.c
    hal_ring.c
    hal_signal.c
    hal_thread.c
    hal_vtable.c)

foreach(_flav ${BUILD_THREAD_FLAVORS})
    _flavor_helper(${_flav})
    add_library(hal_lib_${_fname} SHARED ${HALLIBSRCS})
    set_target_properties(hal_lib_${_fname} PROPERTIES 
        COMPILE_DEFINITIONS "RTAPI;THREAD_FLAVOR_ID=${RTAPI_${_FLAV}_ID}"
        COMPILE_FLAGS "${${_FLAV}_THREADS_RTFLAGS} -UULAPI"
        LIBRARY_OUTPUT_DIRECTORY ${PROJECT_LIBEXEC_DIR}/${_fname}
        OUTPUT_NAME "hal_lib"
        PREFIX "")
    _install_exec(hal_lib_${_fname} ${_fname})
endforeach()

add_library(mkhal SHARED ${HALLIBSRCS} hal_iter.c halpb.cc
    $<TARGET_OBJECTS:inifile> $<TARGET_OBJECTS:shmdrvapi>
    $<TARGET_OBJECTS:ulapi_autoload> $<TARGET_OBJECTS:rtapi_compat>
    $<TARGET_OBJECTS:rtapi_support> $<TARGET_OBJECTS:rtapi_heap>)
target_link_libraries(mkhal mk-pb2++ ${CMAKE_DL_LIBS} rt)
set_target_properties(mkhal PROPERTIES VERSION ${GENERIC_LIB_VERSION})
_install(mkhal)

set(halpy_dir ${PROJECT_PYTHON_DIR}/hal)
set(halpy ${halpy_dir}/__init__.py)
add_custom_command(OUTPUT ${halpy}
    COMMAND ${CMAKE_COMMAND} -E copy hal.py ${halpy}
    DEPENDS hal.py
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
add_custom_target(halpy DEPENDS ${halpy})
    
add_library(_hal SHARED halmodule.cc)
set_property(TARGET _hal APPEND PROPERTY 
    INCLUDE_DIRECTORIES ${PYTHON_INCLUDE_DIRS})
set_target_properties(_hal PROPERTIES 
    BUILD_WITH_INSTALL_RPATH FALSE
    INSTALL_RPATH "${_rpath}"
    INSTALL_RPATH_USE_LINK_PATH TRUE
    LIBRARY_OUTPUT_DIRECTORY ${halpy_dir}
    PREFIX "")
target_link_libraries(_hal mk_rip mkhal ${PYTHON_LIBRARIES})
add_dependencies(_hal halpy)
cleanup_rpath_hack(_hal)

_install_py(hal _hal)
