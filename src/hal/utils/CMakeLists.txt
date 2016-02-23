set(HALCMD_SRCS 
    halcmd.c
    halcmd_commands.c
    halcmd_main.c
    halcmd_rtapiapp.cc 
    halcmd_completion.c)

add_library(halcmd_rtapiapp OBJECT halcmd_rtapiapp.cc)

add_executable(halcmd ${HALCMD_SRCS})
target_link_libraries(halcmd mk_rip mkini mkhal mk-pb2++ mtalk rtapi_math readline)
set_target_properties(halcmd PROPERTIES
    BUILD_WITH_INSTALL_RPATH FALSE
    COMPILE_DEFINITIONS "ULAPI"
    INSTALL_RPATH "${_rpath}"
    INSTALL_RPATH_USE_LINK_PATH TRUE)
cleanup_rpath_hack(halcmd)
_install(halcmd)

add_executable(pci_write pci_write.c upci.c)
_install(pci_write)

add_executable(pci_read pci_read.c upci.c)
_install(pci_read)

foreach(util comp instcomp)
    set(src ${CMAKE_CURRENT_SOURCE_DIR}/${util}.g)
    add_custom_command( 
        OUTPUT ${util}.py
        COMMAND ${YAPPS} ${src} ${util}.py
        DEPENDS ${src}
        COMMENT "Creating ${util}.py")
    add_python_target(${util} ${PROJECT_BIN_DIR} "" 
        ${CMAKE_CURRENT_BINARY_DIR} ${util})
endforeach()

add_executable(halmeter meter.c miscgtk.c)
set_target_properties(halmeter PROPERTIES COMPILE_DEFINITIONS "ULAPI")
set_property(TARGET halmeter APPEND PROPERTY 
    INCLUDE_DIRECTORIES "${GTK2_INCLUDE_DIRS}")
target_link_libraries(halmeter mkhal ${GTK2_LIBRARIES})
_install(halmeter)

set(HALSCOPE_SRCS
    scope.c
    scope_horiz.c
    scope_vert.c
    scope_trig.c
    scope_disp.c
    scope_files.c
    miscgtk.c)

add_executable(halscope ${HALSCOPE_SRCS})
set_target_properties(halscope PROPERTIES COMPILE_DEFINITIONS "ULAPI")
set_property(TARGET halscope APPEND PROPERTY
    INCLUDE_DIRECTORIES "${GTK2_INCLUDE_DIRS}")
target_link_libraries(halscope mkhal rtapi_math ${GTK2_LIBRARIES})
_install(halscope)

_to_rtlib(scope_rt scope_rt.c)

# fixme
# set_property(GLOBAL APPEND PROPERTY target-dev pyhal_utils)
