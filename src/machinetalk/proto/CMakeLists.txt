set(MK_PROTO_SRC
    canon
    config
    emcclass
    log
    message
    motcmds
    nanopb
    object
    preview
    rtapi_message
    rtapicommand
    status
    task
    test
    types
    value)

set(PB_PROTO_PATHS --proto_path=${PROTOBUF_INCLUDEDIR} --proto_path=proto)

set(PB_GEN_DIR ${CMAKE_CURRENT_BINARY_DIR})
set(PB2_GEN_DIR ${PROJECT_PYTHON_DIR})

# file(MAKE_DIRECTORY ${PB_GEN_DIR})
file(MAKE_DIRECTORY ${PB2_GEN_DIR})

unset(PROTOC CACHE)
find_program(PROTOC protoc)
if(NOT PROTOC)
    message(FATAL_ERROR "protoc not found: install protobuf-compiler")
endif()

# create proto C++
set(PB_GEN_OPTS ${PB_PROTO_PATHS} --cpp_out=${PB_GEN_DIR})

foreach(file ${MK_PROTO_SRC})
    set(out ${file}.pb.cc)
    set(PB_GEN ${PB_GEN} ${PB_GEN_DIR}/${out})
    add_custom_command(
        OUTPUT  ${PB_GEN_DIR}/${out}
        COMMAND ${PROTOC} ${PB_GEN_OPTS} proto/${file}.proto
        COMMAND ${CMAKE_COMMAND} -E remove -f ${INCLUDE_DIR}/${file}.pb.h
        COMMAND ${CMAKE_COMMAND} -E create_symlink 
            ${PB_GEN_DIR}/${file}.pb.h 
            ${INCLUDE_DIR}/${file}.pb.h
        DEPENDS proto/${file}.proto
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Generate cpp files from proto/${file}.proto")
    add_custom_target(${file}.pb.h DEPENDS ${PB_GEN_DIR}/${out})
endforeach()

add_custom_target(pb_gen_files DEPENDS ${PB_GEN})

# create python files
set(PB2_GEN_OPTS ${PB_PROTO_PATHS} --python_out=${PB2_GEN_DIR})

foreach(file ${MK_PROTO_SRC})
    set(out ${file}_pb2.py)
    set(PB2_GEN ${PB2_GEN} ${PB2_GEN_DIR}/${out})
    add_custom_command(
        OUTPUT ${PB2_GEN_DIR}/${out}
        COMMAND ${PROTOC} ${PB2_GEN_OPTS} proto/${file}.proto
        DEPENDS proto/${file}.proto
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Generate python files from proto/${file}.proto")
        add_custom_target(${out} DEPENDS ${PB2_GEN_DIR}/${out})
endforeach()

# create nanopb files
set(NPB_GEN_OPTS "${PB_PROTO_PATHS}" 
    "--plugin=protoc-gen-nanopb=${PROTOC_GEN_NANOPB}"
    "--nanopb_out=\"--options-file=${NANOPB_OPTIONS}"
    "--library-include-format='#include" "<nanopb/%s>'"
	"--extension=.npb\":${PB_GEN_DIR}")

foreach(file ${MK_PROTO_SRC})
    set(out ${file}.npb.c)
    set(NPB_GEN ${NPB_GEN} ${PB_GEN_DIR}/${out})
    add_custom_command(
        OUTPUT  ${PB_GEN_DIR}/${out}
        COMMAND ${PROTOC} ${NPB_GEN_OPTS} proto/${file}.proto
        COMMAND ${CMAKE_COMMAND} -E remove -f ${INCLUDE_DIR}/${file}.npb.h
        COMMAND ${CMAKE_COMMAND} -E create_symlink 
            ${PB_GEN_DIR}/${file}.npb.h 
            ${INCLUDE_DIR}/${file}.npb.h
        DEPENDS proto/${file}.proto protoc-gen-nanopb 
            nanopb_generator.py ${PB2_GEN}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Generate npb cpp files from proto/${file}.proto")
    add_custom_target(${file}.npb.h DEPENDS ${PB_GEN_DIR}/${out})
endforeach()

add_custom_target(npb_gen_files DEPENDS ${NPB_GEN})

add_library(mk-pb2++ SHARED ${PB_GEN})
set_target_properties(mk-pb2++ PROPERTIES COMPILE_FLAGS "${PROTOBUF_CFLAGS}")
target_link_libraries(mk-pb2++ ${PROTOBUF_LIBRARIES})
set_target_properties(mk-pb2++ PROPERTIES VERSION ${GENERIC_LIB_VERSION})
_install(mk-pb2++)
    
foreach(file ${MK_PROTO_SRC})
    if(NOT ${file} STREQUAL "nanopb")
        set(NPB_SRC ${NPB_SRC} ${PB_GEN_DIR}/${file}.npb.c)
    endif()
endforeach()

add_library(npb-obj OBJECT ${NPB_SRC})
set_target_properties(npb-obj PROPERTIES COMPILE_DEFINITIONS "${NPB_DEFINITIONS}")

add_library(mk-npb SHARED $<TARGET_OBJECTS:nanopb> $<TARGET_OBJECTS:npb-obj> 
    ${PB_GEN_DIR}/nanopb.npb.c)
set_target_properties(mk-npb PROPERTIES COMPILE_DEFINITIONS "${NPB_DEFINITIONS}")
set_target_properties(mk-npb PROPERTIES VERSION ${GENERIC_LIB_VERSION})
_install(mk-npb)

add_dependencies(mk-pb2++ mk-npb)
