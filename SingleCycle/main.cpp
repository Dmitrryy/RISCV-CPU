#include "obj_dir/Vtop.h"
#include "obj_dir/Vtop_imem.h"
#include "obj_dir/Vtop_top.h"
#include <verilated_vcd_c.h>

#include <array>
#include <iostream>
#include <stdlib.h>
// verilator  -Wno-COMBDLY -Wno-IMPLICIT -Wno-WIDTH --build --exe --trace -cc top.v main.cpp
// ./obj_dir/Vtop
// gtkwave ./out.vcd

int main(int argc, char **argv) {
  // Initialize Verilators variables
  Verilated::commandArgs(argc, argv);

  Vtop *top_module = new Vtop;

  VerilatedVcdC *vcd = nullptr;
  Verilated::traceEverOn(true); // Verilator must compute traced signals
  vcd = new VerilatedVcdC;
  top_module->trace(vcd, 99); // Trace 99 levels of hierarchy
  vcd->open("out.vcd");       // Open the dump file

  // fill intr memory
  // TODO: load ELF
  std::array<uint32_t, 18> test_imem = {
      0x20020005, 0x2003000c, 0x2067fff7, 0x00e22025, 0x00642824, 0x00a42820,
      0x10a7000a, 0x0064202a, 0x10800001, 0x20050000, 0x00e2202a, 0x00853820,
      0x00e23822, 0xac670044, 0x8c020050, 0x08000011, 0x20020001, 0xac020054};

  std::copy(test_imem.begin(), test_imem.end(), top_module->top->imem->RAM);

  // switch the clock
  vluint64_t vtime = 0;
  int clock = 0;
  top_module->reset = 0;
  while (!Verilated::gotFinish()) {
    vtime += 1;
    if (vtime % 8 == 0)
      clock ^= 1;

    top_module->clk = clock;
    top_module->eval();
    vcd->dump(vtime);

    std::cout << "Writedata: " << top_module->writedata
              << ", dataadr: " << top_module->dataadr
              << ", memwrite: " << (bool)(top_module->memwrite) << std::endl;

    if (vtime > 300)
      break;
  }

  top_module->final();
  if (vcd)
    vcd->close();
  delete top_module;
  exit(EXIT_SUCCESS);
}
