cmake_minimum_required(VERSION 3.5.1)

option (USE_SUPERBUILD "Whether or not a superbuild should be invoked" ON)
if (USE_SUPERBUILD)
	project(super-build)
	include(cmake/super-build.cmake)
	return()
endif()


project(dminer C CXX)

if(MSVC)
  add_definitions(-D_WIN32_WINNT=0x600)
endif()

set(OpenCV_STATIC TRUE)
find_package(OpenCV CONFIG REQUIRED)

#find_package(zlib CONFIG REQUIRED)

set(ZLIB_ROOT ${CMAKE_CURRENT_BINARY_DIR}/zlib)
#set(ZLIB_LIBRARY "${CMAKE_CURRENT_BINARY_DIR}/zlib")
#set(ZLIB_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/zlib/include")


set(protobuf_MODULE_COMPATIBLE TRUE)
find_package(Protobuf CONFIG REQUIRED)
message(STATUS "Using protobuf ${protobuf_VERSION}")

set(_PROTOBUF_LIBPROTOBUF protobuf::libprotobuf)
set(_PROTOBUF_PROTOC $<TARGET_FILE:protobuf::protoc>)

find_package(gRPC CONFIG REQUIRED)
message(STATUS "Using gRPC ${gRPC_VERSION}")

add_library (dum STATIC cmake/zlib-stub.c)
add_library (ZLIB::ZLIB ALIAS dum )
set(_GRPC_ZLIB_LIBRARIES )
set(_GRPC_GRPCPP_UNSECURE gRPC::grpc++_unsecure)
set(_GRPC_CPP_PLUGIN_EXECUTABLE $<TARGET_FILE:gRPC::grpc_cpp_plugin>)

# Proto file
get_filename_component(hw_proto "${CMAKE_CURRENT_SOURCE_DIR}/protos/main.proto" ABSOLUTE)
get_filename_component(hw_proto_path "${hw_proto}" PATH)


# Generated sources
set(hw_proto_srcs "${CMAKE_CURRENT_BINARY_DIR}/main.pb.cc")
set(hw_proto_hdrs "${CMAKE_CURRENT_BINARY_DIR}/main.pb.h")
set(hw_grpc_srcs "${CMAKE_CURRENT_BINARY_DIR}/main.grpc.pb.cc")
set(hw_grpc_hdrs "${CMAKE_CURRENT_BINARY_DIR}/main.grpc.pb.h")

add_custom_command(
      OUTPUT "${hw_proto_srcs}" "${hw_proto_hdrs}" "${hw_grpc_srcs}" "${hw_grpc_hdrs}"
      COMMAND ${_PROTOBUF_PROTOC}
      ARGS --grpc_out "${CMAKE_CURRENT_BINARY_DIR}"
        --cpp_out "${CMAKE_CURRENT_BINARY_DIR}"
        -I "${hw_proto_path}"
        --plugin=protoc-gen-grpc="${_GRPC_CPP_PLUGIN_EXECUTABLE}"
        "${hw_proto}"
      DEPENDS "${hw_proto}")

# Include generated *.pb.h files
include_directories("${CMAKE_CURRENT_BINARY_DIR}" ${OpenCV_INCLUDE_DIRS})
message(STATUS "OpenCV Includes: ${OpenCV_INCLUDE_DIRS}")
message(STATUS "OpenCV Libs: ${OpenCV_LIBS}")
message(STATUS "gRPC Libs: ${_GRPC_GRPCPP_UNSECURE}")
message(STATUS "protobuf Libs: ${_PROTOBUF_LIBPROTOBUF}")

foreach(flag_var
    CMAKE_C_FLAGS CMAKE_C_FLAGS_DEBUG CMAKE_C_FLAGS_RELEASE
    CMAKE_C_FLAGS_MINSIZEREL CMAKE_C_FLAGS_RELWITHDEBINFO
    CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE
    CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_RELWITHDEBINFO)

    if(${flag_var} MATCHES "/MD")
    string(REGEX REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
    endif(${flag_var} MATCHES "/MD")
  endforeach(flag_var)

add_executable(dminer "src/main.cpp" ${hw_proto_srcs} ${hw_grpc_srcs})
target_link_libraries(dminer ${_GRPC_GRPCPP_UNSECURE} ${_PROTOBUF_LIBPROTOBUF} ${OpenCV_LIBS})
 
#
