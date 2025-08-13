if(TARGET OpenVDB::openvdb)
    return()
endif()

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER "12")
        message(WARNING "GCC VERSION < 12 is supported. Current version: ${CMAKE_CXX_COMPILER_VERSION}")
    endif()
endif()

set(BUILD_SHARED_LIBS OFF CACHE STRING "" FORCE)
set(USE_STATIC_DEPENDENCIES ON CACHE BOOL "" FORCE)
set(OPENVDB_ENABLE_UNINSTALL OFF CACHE BOOL "" FORCE)
set(OPENVDB_FUTURE_DEPRECATION OFF CACHE BOOL "" FORCE)
set(USE_BLOSC OFF CACHE STRING "" FORCE)
set(USE_ZLIB OFF CACHE STRING "" FORCE)

find_package(OpenVDB REQUIRED)

find_package(TBB REQUIRED)

set(CMAKE_CXX_FLAGS_OLD ${CMAKE_CXX_FLAGS})
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DTBB_ALLOCATOR_TRAITS_BROKEN")
set(CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS_OLD})

if (WIN32)
    set(OPENVDB_DISABLE_BOOST_IMPLICIT_LINKING OFF CACHE BOOL "" FORCE)
endif()

set(CMAKE_CXX_STANDARD 17)
set(OPENVDB_ENABLE_UNINSTALL OFF CACHE BOOL "" FORCE)
set_target_properties(OpenVDB::openvdb PROPERTIES POSITION_INDEPENDENT_CODE ON)

target_include_directories(OpenVDB::openvdb PUBLIC
    ${boost_SOURCE_DIR}/libs/numeric/conversion/include
    ${boost_SOURCE_DIR}/libs/any/include
    ${boost_SOURCE_DIR}/libs/algorithm/include
    ${boost_SOURCE_DIR}/libs/uuid/include
    ${boost_SOURCE_DIR}/libs/foreach/include
    ${boost_SOURCE_DIR}/libs/interprocess/include
    ${boost_SOURCE_DIR}/libs/intrusive/include
    ${boost_SOURCE_DIR}/libs/tti/include
)

add_library(Boost::disable_autolinking INTERFACE IMPORTED)
set(CMAKE_CXX_STANDARD 20)
