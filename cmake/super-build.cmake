cmake_minimum_required(VERSION 3.5.1)

include(ExternalProject)

if(MSVC)
  add_definitions(-D_WIN32_WINNT=0x600)
endif()

# Builds c-ares project from the git submodule.
# Note: For all external projects, instead of using checked-out code, one could
# specify GIT_REPOSITORY and GIT_TAG to have cmake download the dependency directly,
# without needing to add a submodule to your project.
ExternalProject_Add(c-ares
  PREFIX c-ares
  SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/grpc/third_party/cares/cares"
  CMAKE_CACHE_ARGS
        -DCARES_SHARED:BOOL=OFF
        -DCARES_STATIC:BOOL=ON
		-DCARES_MSVC_STATIC_RUNTIME:BOOL=ON
        -DCARES_STATIC_PIC:BOOL=ON
		-CARES_BUILD_TOOLS:BOOL=OFF
        -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_CURRENT_BINARY_DIR}/c-ares
)

# Builds protobuf project from the git submodule.
ExternalProject_Add(protobuf
  PREFIX protobuf
  SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/grpc/third_party/protobuf/cmake"
  CMAKE_CACHE_ARGS
        -Dprotobuf_BUILD_TESTS:BOOL=OFF
        -Dprotobuf_WITH_ZLIB:BOOL=OFF
        -Dprotobuf_MSVC_STATIC_RUNTIME:BOOL=ON
        -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_CURRENT_BINARY_DIR}/protobuf
)

# Builds zlib project from the git submodule.
#ExternalProject_Add(zlib
#  PREFIX zlib
#  SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/grpc/third_party/zlib"
#  CMAKE_CACHE_ARGS
#        -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_CURRENT_BINARY_DIR}/zlib
#)

# Builds OpenCV from git submodule
ExternalProject_Add(OpenCV
  PREFIX opencv
  SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/opencv"
  CMAKE_CACHE_ARGS
		-DBUILD_ZLIB:BOOL=ON
        -DBUILD_TESTS:BOOL=OFF
		-DBUILD_SHARED_LIBS:BOOL=OFF
		-DBUILD_PERF_TESTS:BOOL=OFF
        -DBUILD_WITH_STATIC_CRT:BOOL=ON
		-DBUILD_opencv_apps:BOOL=OFF
        -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_CURRENT_BINARY_DIR}/opencv
)

# the location where protobuf-config.cmake will be installed varies by platform
if (WIN32)
  set(_FINDPACKAGE_PROTOBUF_CONFIG_DIR "${CMAKE_CURRENT_BINARY_DIR}/protobuf/cmake")
else()
  set(_FINDPACKAGE_PROTOBUF_CONFIG_DIR "${CMAKE_CURRENT_BINARY_DIR}/protobuf/lib/cmake/protobuf")
endif()

# if OPENSSL_ROOT_DIR is set, propagate that hint path to the external projects with OpenSSL dependency.
set(_CMAKE_ARGS_OPENSSL_ROOT_DIR "")
if (OPENSSL_ROOT_DIR)
   message("OPENSSL_ROOT_DIR is set:" ${OPENSSL_ROOT_DIR})
  set(_CMAKE_ARGS_OPENSSL_ROOT_DIR "-DOPENSSL_ROOT_DIR:PATH=${OPENSSL_ROOT_DIR}")
endif()

# Builds gRPC from git submodule
ExternalProject_Add(grpc
  PREFIX grpc
  SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/grpc"
  CMAKE_CACHE_ARGS
        -DgRPC_INSTALL:BOOL=ON
        -DgRPC_BUILD_TESTS:BOOL=OFF
		-DgRPC_MSVC_STATIC_RUNTIME:BOOL=ON
        -DgRPC_PROTOBUF_PROVIDER:STRING=package
        -DgRPC_PROTOBUF_PACKAGE_TYPE:STRING=CONFIG
		-DgRPC_BUILD_CSHARP_EXT:BOOL=OFF
        -DProtobuf_DIR:PATH=${_FINDPACKAGE_PROTOBUF_CONFIG_DIR}
        -DgRPC_ZLIB_PROVIDER:STRING=module
#        -DZLIB_ROOT:STRING=${CMAKE_CURRENT_BINARY_DIR}/zlib
        -DgRPC_CARES_PROVIDER:STRING=package
        -Dc-ares_DIR:PATH=${CMAKE_CURRENT_BINARY_DIR}/c-ares/lib/cmake/c-ares
        -DgRPC_SSL_PROVIDER:STRING=package
		${_CMAKE_ARGS_OPENSSL_ROOT_DIR}
        -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_CURRENT_BINARY_DIR}/grpc
  DEPENDS c-ares protobuf 
)

# Build Boost
#if(CMAKE_BUILD_TYPE STREQUAL "Debug")
#  set(BOOST_BUILD_TYPE "debug")
#else()
#  set(BOOST_BUILD_TYPE "release")
#endif()
#message(STATUS "Boost build type: ${BOOST_BUILD_TYPE}")
#
#ExternalProject_Add(boost
#  PREFIX boost
#  SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/boost"
#  CONFIGURE_COMMAND ./bootstrap
#  BUILD_COMMAND ./b2 -q --prefix=${CMAKE_CURRENT_BINARY_DIR}/boost --build-dir=${CMAKE_CURRENT_BINARY_DIR}/boost-build --build-type=minimal link=static address-model=64 variant=${BOOST_BUILD_TYPE} install 
##  BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/boost
#  BUILD_IN_SOURCE 1
#  INSTALL_COMMAND ""
#)

ExternalProject_Add(dminer
  PREFIX dminer
  SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}"
  BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/dminer"
  INSTALL_COMMAND ""
  CMAKE_CACHE_ARGS
		-DUSE_SUPERBUILD:BOOL=OFF
        -DProtobuf_DIR:PATH=${_FINDPACKAGE_PROTOBUF_CONFIG_DIR}
        -Dc-ares_DIR:PATH=${CMAKE_CURRENT_BINARY_DIR}/c-ares/lib/cmake/c-ares
        -DZLIB_ROOT:STRING=${CMAKE_CURRENT_BINARY_DIR}/zlib
        ${_CMAKE_ARGS_OPENSSL_ROOT_DIR}
        -DgRPC_DIR:PATH=${CMAKE_CURRENT_BINARY_DIR}/grpc/lib/cmake/grpc
		-DOpenCV_DIR:PATH=${CMAKE_CURRENT_BINARY_DIR}/opencv
  DEPENDS protobuf grpc OpenCV
)