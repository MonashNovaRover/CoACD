find_package(spdlog REQUIRED)

set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME spdlog)
if(NOT spdlog_POPULATED)
  FetchContent_Populate(spdlog)
  add_subdirectory(${spdlog_SOURCE_DIR} ${spdlog_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()

set_target_properties(spdlog PROPERTIES POSITION_INDEPENDENT_CODE ON)
