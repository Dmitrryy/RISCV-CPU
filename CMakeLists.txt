cmake_minimum_required(VERSION 3.22)

project(rv32_project)

find_package(verilator HINTS $ENV{VERILATOR_ROOT})

add_executable(VRV32 main.cpp)
verilate(VRV32 SOURCES RV32.v 
VERILATOR_ARGS --trace #-Wall
)