cmake_minimum_required(VERSION 3.24)
project(CoACD LANGUAGES C CXX)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

option(WITH_3RD_PARTY_LIBS "Build with OpenVDB, spdlog, etc." ON)

find_package(ZLIB REQUIRED)
find_package(Boost REQUIRED COMPONENTS system filesystem thread iostreams)
find_package(OpenVDB REQUIRED)
find_package(TBB REQUIRED)
find_package(spdlog REQUIRED)

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
        TBB::tbb
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
