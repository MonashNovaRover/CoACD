find_package(ZLIB REQUIRED)

set_target_properties(zlibstatic PROPERTIES POSITION_INDEPENDENT_CODE TRUE)
set(ZLIB_LIBRARY ZLIB::ZLIB)
set(ZLIB_INCLUDE_DIR ${zlib_SOURCE_DIR})
set(ZLIB_FOUND TRUE)
target_include_directories(ZLIB::ZLIB PUBLIC ${zlib_SOURCE_DIR} ${zlib_BINARY_DIR})
