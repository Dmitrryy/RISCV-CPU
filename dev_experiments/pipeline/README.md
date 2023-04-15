# Just pipeline

![pipe](wave1.png)


## Usage

```
verilator  --build --exe --trace -cc --top-module pipeline pipeline.v main.cpp 
```
```
./obj_dir/Vpipeline
```
```
gtkwave ./out.vcd
```