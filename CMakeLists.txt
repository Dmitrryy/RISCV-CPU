cmake_minimum_required(VERSION 3.22)

project(rv32_project)

set(CLI11_PRECOMPILED ON)
add_subdirectory(3rd_party/CLI11)

find_package(verilator HINTS $ENV{VERILATOR_ROOT})

set(TARGET VRV32)
add_executable(${TARGET} main.cpp)
verilate(${TARGET} SOURCES RV32.v 
VERILATOR_ARGS --trace #-Wall
)

target_link_libraries(${TARGET} PRIVATE CLI11::CLI11)
target_include_directories(${TARGET} SYSTEM PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/3rd_party/CLI11/include)
target_include_directories(${TARGET} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/3rd_party/ELFIO)
