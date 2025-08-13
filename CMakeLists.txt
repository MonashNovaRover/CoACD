cmake_minimum_required(VERSION 3.24)
project(CoACD LANGUAGES C CXX)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

option(WITH_3RD_PARTY_LIBS "Build with OpenVDB, spdlog, etc." ON)

find_package(ZLIB REQUIRED)
find_package(Boost REQUIRED COMPONENTS system filesystem thread iostreams)
find_package(spdlog REQUIRED)
find_package(PkgConfig REQUIRED)
pkg_check_modules(OPENVDB REQUIRED openvdb)
target_include_directories(coacd PRIVATE ${OPENVDB_INCLUDE_DIRS})
target_link_libraries(coacd PRIVATE ${OPENVDB_LIBRARIES})
if(NOT TARGET OpenVDB::openvdb)
    # Try to locate manually
    find_path(OPENVDB_INCLUDE_DIR openvdb/openvdb.h
        HINTS ${CMAKE_PREFIX_PATH}
        PATH_SUFFIXES include)

    find_library(OPENVDB_LIBRARY NAMES openvdb
        HINTS ${CMAKE_PREFIX_PATH}
        PATH_SUFFIXES lib)

    if(NOT OPENVDB_INCLUDE_DIR OR NOT OPENVDB_LIBRARY)
        message(FATAL_ERROR "Could not find OpenVDB headers or library")
    endif()

    add_library(OpenVDB::openvdb UNKNOWN IMPORTED)
    set_target_properties(OpenVDB::openvdb PROPERTIES
        IMPORTED_LOCATION ${OPENVDB_LIBRARY}
        INTERFACE_INCLUDE_DIRECTORIES ${OPENVDB_INCLUDE_DIR}
    )
endif()
pkg_check_modules(TBB REQUIRED tbb)
target_include_directories(coacd PRIVATE ${TBB_INCLUDE_DIRS})
target_link_libraries(coacd PRIVATE ${TBB_LIBRARIES})


file(GLOB_RECURSE COACD_SRC "src/*.cc" "src/*.cpp")
if(NOT WITH_3RD_PARTY_LIBS)
    list(FILTER COACD_SRC EXCLUDE REGEX ".*preprocess.*")
endif()

add_library(coacd STATIC ${COACD_SRC})
target_include_directories(coacd PUBLIC public)
target_include_directories(coacd PRIVATE 3rd/cdt/CDT)

if(WITH_3RD_PARTY_LIBS)
    target_link_libraries(coacd PRIVATE
        OpenVDB::openvdb
        spdlog::spdlog
        ${TBB_LIBRARIES}
        ZLIB::ZLIB
        Boost::system Boost::filesystem Boost::thread Boost::iostreams
    )
endif()

find_package(OpenMP)
if(OpenMP_CXX_FOUND)
    target_link_libraries(coacd PUBLIC OpenMP::OpenMP_CXX)
endif()

find_package(Threads)
target_link_libraries(coacd PRIVATE Threads::Threads)
set_target_properties(coacd PROPERTIES POSITION_INDEPENDENT_CODE TRUE)

add_library(_coacd SHARED "public/coacd.cpp")
if(WITH_3RD_PARTY_LIBS)
    target_link_libraries(_coacd PRIVATE coacd spdlog::spdlog OpenVDB::openvdb)
else()
    target_link_libraries(_coacd PRIVATE coacd)
endif()

add_executable(main main.cpp)
if(WITH_3RD_PARTY_LIBS)
    target_link_libraries(main PRIVATE coacd spdlog::spdlog OpenVDB::openvdb)
else()
    target_link_libraries(main PRIVATE coacd)
endif()
