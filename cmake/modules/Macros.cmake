#! _mkconv : this macro creates conv_IN_OUT.comp from conv.comp.in 
#
# this calls the mkconv.sh script with the required parameters
#
# the list of generated comp files ${_gen_comp} is then updated after the macro ends
#
# \arg:NAME name of the output file
# \arg:ARGS list of arguments needed by mkconv.sh
#
macro(_mkconv NAME ARGS)
    set(_args "${ARGS}")
    set(_comp "${CMAKE_CURRENT_BINARY_DIR}/${NAME}.comp")
    add_custom_command(
        OUTPUT ${_comp}
        COMMAND bash mkconv.sh ${_args} < conv.comp.in > ${_comp}
        DEPENDS mkconv.sh conv.comp.in comp
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
    set(_gen_comp ${_gen_comp} ${_comp})
endmacro()

#! _comp_to_c : this macro generates c source files from comp file
#
# the list of generated c files ${_gen_c} is updated after the macro ends
#
# \arg:NAME comp src file without the extension
# \arg:DIR Optional, source directory
#
macro(_comp_to_c NAME)
    if(NOT ${ARGV1})
        set(_wdir ${ARGV1})
    else()
        set(_wdir  ${CMAKE_CURRENT_SOURCE_DIR})
    endif()
    set(_c "${CMAKE_CURRENT_BINARY_DIR}/${NAME}.c")
    add_custom_command(
        OUTPUT ${_c}
        COMMAND ${PROJECT_BIN_DIR}/comp 
            --require-license -o ${_c} ${NAME}.comp
        DEPENDS ${_wdir}/${NAME}.comp comp
        WORKING_DIRECTORY ${_wdir})
    set(_gen_c ${_gen_c} ${_c})
endmacro()

#! _comp_to_man : this macro generates manpages from comp file
#
# the list of generated manpages ${_gen_man} is updated after the macro ends
#
# \arg:NAME comp src file without the extension
# \arg:DIR Optional, source directory
#
macro(_comp_to_man NAME)
    if(NOT ${ARGV1})
        set(_wdir ${ARGV1})
    else()
        set(_wdir  ${CMAKE_CURRENT_SOURCE_DIR})
    endif()
    set(_man "${PROJECT_MAN_DIR}/man9/${NAME}.9comp")
    add_custom_command(
        OUTPUT ${_man}
        COMMAND ${PROJECT_BIN_DIR}/comp 
            --document -o ${_man} ${NAME}.comp
        DEPENDS ${_wdir}/${NAME}.comp comp
        WORKING_DIRECTORY ${_wdir})
    set(_gen_man ${_gen_man} ${_man})
endmacro()

#! _icomp_to_c : this macro generates c source files from icomp file
#
# the list of generated c files ${_gen_c} is updated after the macro ends
#
# \arg:NAME icomp src file without the extension
# \arg:DIR Optional, source directory
#
macro(_icomp_to_c NAME)
    if(NOT ${ARGV1})
        set(_wdir ${ARGV1})
    else()
        set(_wdir  ${CMAKE_CURRENT_SOURCE_DIR})
    endif()
    set(_c "${CMAKE_CURRENT_BINARY_DIR}/${NAME}.c")
    add_custom_command(
        OUTPUT ${_c}
        COMMAND ${PROJECT_BIN_DIR}/instcomp 
            --require-license -o ${_c} ${NAME}.icomp
        DEPENDS ${_wdir}/${NAME}.icomp instcomp
        WORKING_DIRECTORY ${_wdir})
    set(_gen_c ${_gen_c} ${_c})
endmacro()

#! _icomp_to_man : this macro generates manpages from icomp file
#
# the list of generated manpages ${_gen_man} is updated after the macro ends
#
# \arg:NAME comp src file without the extension
# \arg:DIR Optional, source directory
#
macro(_icomp_to_man NAME)
    if(NOT ${ARGV1})
        set(_wdir ${ARGV1})
    else()
        set(_wdir  ${CMAKE_CURRENT_SOURCE_DIR})
    endif()
    set(_man "${PROJECT_MAN_DIR}/man9/${NAME}.9comp")
    add_custom_command(
        OUTPUT ${_man}
        COMMAND ${PROJECT_BIN_DIR}/instcomp 
            --document -o ${_man} ${NAME}.icomp
        DEPENDS ${_wdir}/${NAME}.icomp instcomp
        WORKING_DIRECTORY ${_wdir})
    set(_gen_man ${_gen_man} ${_man})
endmacro()

#! _flavor_helper : helper macro
#
# sets FLAV to uppercase and stores in _FLAV
# _fname is the defined flavor name
#
# \arg:FLAV flavor name
#
macro(_flavor_helper FLAV)
    string(TOUPPER ${FLAV} _FLAV)
    set(_fname ${RTAPI_${_FLAV}_NAME})
endmacro()

#! _to_rtlib : this macro generates an rt library for all flavors
#
# \arg:NAME library name
# \arg:SRCS sources
#
macro(_to_rtlib NAME SRCS)
    foreach(_flav ${BUILD_THREAD_FLAVORS})
        _flavor_helper(${_flav})
        add_library(${NAME}.${_fname} SHARED ${SRCS})
        set_target_properties(${NAME}.${_fname} PROPERTIES 
            COMPILE_DEFINITIONS "RTAPI;THREAD_FLAVOR_ID=0"
            LIBRARY_OUTPUT_DIRECTORY ${PROJECT_LIBEXEC_DIR}/${_fname}
            LINK_FLAGS "-Wl,--version-script,${NAME}.${_fname}.vers -Bsymbolic"
            OUTPUT_NAME ${NAME}
            PREFIX "")
        add_custom_command(TARGET ${NAME}.${_fname}
            PRE_LINK
            COMMAND ${CMAKE_SOURCE_DIR}/scripts/get_symbols 
                CMakeFiles/${NAME}.${_fname}.dir/link.txt ${NAME}.${_fname}.vers
            COMMENT "Extract exported symbols")
        install(TARGETS ${NAME}.${_fname}
            LIBRARY DESTINATION lib/machinekit/${_fname})
    endforeach()
endmacro()

#! _install* : these are install helper macros
#
macro(_install SRC)
    install(TARGETS ${SRC} 
        DESTINATION bin
        LIBRARY DESTINATION lib)
endmacro()

macro(_install_exec SRC)
    set(_lib_dest lib/machinekit)
    if(NOT ${ARGV1})
        set(_lib_dest lib/machinekit/${ARGV1})
    endif()
    install(TARGETS ${SRC}
        DESTINATION lib/machinekit
        LIBRARY DESTINATION ${_lib_dest})
endmacro()

macro(_install_exec_flavor SRC)
    foreach(_flav ${BUILD_THREAD_FLAVORS})
        _flavor_helper(${_flav})
        set(_lib_dest lib/machinekit/${_fname})
        install(TARGETS ${SRC}_${_fname}_
            DESTINATION lib/machinekit
            LIBRARY DESTINATION ${_lib_dest})
    endforeach()
endmacro()

macro(_install_exec_setuid SRC)
    set(_lib_dest lib/machinekit)
    if(NOT ${ARGV1})
        set(_lib_dest lib/machinekit/${ARGV1})
    endif()
    install(TARGETS ${SRC}
        DESTINATION lib/machinekit
        PERMISSIONS SETUID
            OWNER_WRITE OWNER_READ OWNER_EXECUTE
            GROUP_READ GROUP_EXECUTE
            WORLD_EXECUTE WORLD_READ
        LIBRARY DESTINATION ${_lib_dest})
endmacro()

macro(_install_man SRC)
    install(FILES ${SRC} 
        DESTINATION man/man9)
endmacro()

macro(_install_script SRC)
    install(PROGRAMS ${SRC} 
        DESTINATION bin)
endmacro()

#! _install_py
#
# \arg:NAME python module name
# \arg:ARGN python targets
#
macro(_install_py NAME)
    set(_src ${PROJECT_PYTHON_DIR}/${NAME})
    set(_dst ${INSTALL_PYSHARED_DIR})
    install(DIRECTORY ${_src} DESTINATION share/pyshared
        FILES_MATCHING PATTERN "*.py"
    PATTERN "nosetests" EXCLUDE)
    install(TARGETS ${ARGN}
        DESTINATION share/pyshared/${NAME})
    set(_setup "${_src}/setup.py")
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/setup.py.in ${_setup})
    install(CODE "execute_process(COMMAND 
        ${SCRIPTS_DIR}/python_package_helper 
            ${NAME} ${_src} ${_dst} 
        ${PYTHON_EXECUTABLE} ${CMAKE_INSTALL_PREFIX} ${CPACK_PACKAGING_INSTALL_PREFIX})")
endmacro()
# *** _install ***

#! add_python_target : add python executable target/s
#
# This macro performs syntax checking on python files and copies 
# it to the destination dir. Renames the file depending on ${ext} parameter
#
# \arg:TGT python target
# \arg:DST output destination directory
# \arg:EXT output extension
# \arg:SDIR source destination directory
# \arg:ARGN python source file/s
#
macro(add_python_target TGT DST EXT SDIR)
    unset(_out_files)
    separate_arguments(_py_cmd UNIX_COMMAND
        "-c 'import sys\; compile(open(sys.argv[1]).read(), sys.argv[1], \"exec\")'")
    separate_arguments(_sed_cmd UNIX_COMMAND 
        "'1s-^#!.*-#!${PYTHON_EXECUTABLE}-'")
    foreach(_x ${ARGN})
        set(_out ${DST}/${_x}${EXT})
        list(APPEND _out_files ${_out})
        add_custom_command(OUTPUT ${_out}
            COMMAND ${PYTHON_EXECUTABLE} ${_py_cmd} ${SDIR}/${_x}.py
            COMMAND sed ${_sed_cmd} ${SDIR}/${_x}.py > ${_out}
            COMMAND chmod +x ${_out}
            DEPENDS ${SDIR}/${_x}.py
            COMMENT "Creating ${_out}"
            VERBATIM)
    endforeach()
    add_custom_target(${TGT} DEPENDS ${_out_files})
endmacro()
