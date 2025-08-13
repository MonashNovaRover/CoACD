cmake_minimum_required(VERSION 3.24)
project(CoACD LANGUAGES C CXX)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

option(WITH_3RD_PARTY_LIBS "Include 3rd party libraries" ON)

if(WITH_3RD_PARTY_LIBS)
    add_compile_definitions(WITH_3RD_PARTY_LIBS=1)
else()
    set(DISABLE_SPDLOG ON)
    add_compile_definitions(WITH_3RD_PARTY_LIBS=0)
endif()

# --- Compiler-specific flags
if(MSVC)
    # For Microsoft Visual Studio (Windows)
    add_compile_options("/bigobj")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W0 /D_USE_MATH_DEFINES")
    set(CMAKE_SHARED_LIBRARY_PREFIX "lib")
else()
    # For non-MSVC (Linux, macOS, etc.)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -fpermissive -D_USE_MATH_DEFINES")
    if(APPLE)
        # macOS: add -fPIC
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")
    elseif(UNIX)
        # Linux/Unix: add -fPIC and disable -Werror=stringop-overflow
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC -Wno-error=stringop-overflow")
    endif()
endif()

set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS}")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS} -O3")

if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -fsanitize=address")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -Wno-int-in-bool-context -Wsign-compare")
    set(CMAKE_LINKER_FLAGS_DEBUG "${CMAKE_LINKER_FLAGS_DEBUG} -fsanitize=address")
endif()

if(WITH_3RD_PARTY_LIBS)
    find_package(ZLIB REQUIRED)
    set_target_properties(ZLIB::ZLIB PROPERTIES POSITION_INDEPENDENT_CODE TRUE)
    set(ZLIB_LIBRARY ZLIB::ZLIB)
    set(ZLIB_INCLUDE_DIR ${zlib_SOURCE_DIR})
    set(ZLIB_FOUND TRUE)
    target_include_directories(ZLIB::ZLIB PUBLIC ${zlib_SOURCE_DIR} ${zlib_BINARY_DIR})
    include(zlib)

    find_package(Boost REQUIRED)
    set(BOOST_IOSTREAMS_ENABLE_ZSTD OFF CACHE BOOL "" FORCE)
    set(BOOST_IOSTREAMS_ENABLE_LZMA OFF)
    set(BOOST_IOSTREAMS_ENABLE_BZIP2 OFF)
    if(zlib_SOURCE_DIR)
        target_include_directories(boost_iostreams PRIVATE ${zlib_SOURCE_DIR} ${zlib_BINARY_DIR})
    endif()
    include(boost)

    find_package(OpenVDB REQUIRED)
    find_package(TBB REQUIRED)
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
    include(openvdb)

    find_package(spdlog REQUIRED)
    set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME spdlog)
    if(NOT spdlog_POPULATED)
        add_subdirectory(${spdlog_SOURCE_DIR} ${spdlog_BINARY_DIR} EXCLUDE_FROM_ALL)
    endif()
    set_target_properties(spdlog PROPERTIES POSITION_INDEPENDENT_CODE ON)
    include(spdlog)
endif()

file(GLOB_RECURSE COACD_SRC "src/*.cc" "src/*.cpp")
if(NOT WITH_3RD_PARTY_LIBS)
    # Exclude files that match the pattern "preprocess*"
    list(FILTER COACD_SRC EXCLUDE REGEX ".*preprocess.*")
endif()

add_library(coacd STATIC ${COACD_SRC})
target_include_directories(coacd PUBLIC public)
target_include_directories(coacd PRIVATE 3rd/cdt/CDT)

if(WITH_3RD_PARTY_LIBS)
    target_link_libraries(coacd PRIVATE openvdb_static spdlog::spdlog)
endif()

find_package(OpenMP)
if (OpenMP_CXX_FOUND)
    target_link_libraries(coacd PUBLIC OpenMP::OpenMP_CXX)
endif()

find_package(Threads)
target_link_libraries(coacd PRIVATE Threads::Threads)
set_target_properties(coacd PROPERTIES POSITION_INDEPENDENT_CODE TRUE)

add_library(_coacd SHARED "public/coacd.cpp")

if(WITH_3RD_PARTY_LIBS)
    target_link_libraries(_coacd PRIVATE coacd spdlog::spdlog openvdb_static)
else()
    target_link_libraries(_coacd PRIVATE coacd)
endif()

add_executable(main main.cpp)

if(WITH_3RD_PARTY_LIBS)
    target_link_libraries(main coacd spdlog::spdlog openvdb_static)
else()
    target_link_libraries(main coacd)
endif()