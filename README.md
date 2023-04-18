# RISC-V pipelined

## Pipeline scheme (MIPS)
![](./dev_experiments/scheme.png)


## Usage

```
cmake -B build -S .
```
```
cmake --build build
```
```
./build/VRV32 -p <rv32i-ELF>
```
```
gtkwave ./out.vcd
```
