cmake_minimum_required(VERSION 3.22)

project(experiment_pipe)

find_package(verilator HINTS $ENV{VERILATOR_ROOT})

add_executable(Vpipeline main.cpp)
verilate(Vpipeline SOURCES pipeline.v 
TOP_MODULE pipeline
VERILATOR_ARGS --trace
)
