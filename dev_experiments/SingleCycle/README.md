# Single-Cycle MIPS Processor

Source: Digital Design and Computer Architecture - chapter 7.6.1

## Usage

```
verilator  -Wno-COMBDLY -Wno-IMPLICIT -Wno-WIDTH --build --exe --trace -cc top.v main.cpp
```
```
./obj_dir/Vtop
```
```
gtkwave ./out.vcd
```