add_definitions(-DULAPI)

include_directories(${PYTHON_INCLUDE_DIRS})

set(CY_SRC hal rtapi compat shmcommon)

set(deps halfile.py launcher.py service.py nosetests)
set(stamp ${CMAKE_CURRENT_BINARY_DIR}/timestamp)
add_custom_command(OUTPUT ${stamp}
    COMMAND ${CMAKE_COMMAND} -E touch ${stamp}
    COMMAND cp -a ${deps} ${PROJECT_PYTHON_DIR}/machinekit/
    DEPENDS ${deps}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

set(init ${PROJECT_PYTHON_DIR}/machinekit/__init__.py)
add_custom_command(OUTPUT ${init}
    COMMAND ${CMAKE_COMMAND} -E touch ${init})

set(PWD ${CMAKE_CURRENT_BINARY_DIR})
foreach(file ${CY_SRC})
    add_custom_command(
        OUTPUT  ${PWD}/${file}.c
        COMMAND ${CYTHON} -o ${PWD}/${file}.c ${file}.pyx
        DEPENDS ${file}.pyx ${file}.pxd ${init} ${stamp}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Generate C files from ${file}.pyx")
    add_library(${file}_obj OBJECT ${PWD}/${file}.c)
endforeach()

configure_file("config.py.in" "${PROJECT_PYTHON_DIR}/machinekit/config.py" @ONLY)

# create files for installation
set(PROJECT_SYSCONF_DIR "${INSTALL_SYSCONF_DIR}")
set(PROJECT_LIBEXEC_DIR "${CMAKE_INSTALL_PREFIX}/lib/machinekit")
set(PROJECT_BINARY_DIR "${CMAKE_INSTALL_PREFIX}")
set(PROJECT_BIN_DIR "${CMAKE_INSTALL_PREFIX}/bin")

configure_file("config.py.in" "config.py" @ONLY)
