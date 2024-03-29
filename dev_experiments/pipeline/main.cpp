#include "obj_dir/Vpipeline.h"
#include <verilated_vcd_c.h>

#include <array>
#include <iostream>
#include <stdlib.h>

// verilator  --build --exe --trace -cc --top-module pipeline pipeline.v main.cpp 
// ./obj_dir/Vpipeline
// gtkwave ./out.vcd

int main(int argc, char **argv) {
  // Initialize Verilators variables
  Verilated::commandArgs(argc, argv);

  Vpipeline *top_module = new Vpipeline;

  VerilatedVcdC *vcd = nullptr;
  Verilated::traceEverOn(true); // Verilator must compute traced signals
  vcd = new VerilatedVcdC;
  top_module->trace(vcd, 99); // Trace 99 levels of hierarchy
  vcd->open("out.vcd");       // Open the dump file

  // switch the clock
  vluint64_t vtime = 0;
  int clock = 0;
  top_module->clk = 0;
  top_module->StallIF = 0;
  top_module->StallID = 0;
  top_module->EnableID = 1;
  top_module->FlushE = 0;
  while (!Verilated::gotFinish()) {
    vtime += 1;
    if (vtime % 4 == 0)
      clock ^= 1;

    top_module->clk = clock;
    top_module->eval();
    vcd->dump(vtime);

    if (vtime > 100 && vtime < 140) {
      top_module->StallIF = 1;
      top_module->StallID = 1;
    } else {
      top_module->StallIF = 0;
      top_module->StallID = 0;
    }

    std::cout << "pc_out " << top_module->pc_out << std::endl;

    if (vtime > 300)
      break;
  }

  top_module->final();
  if (vcd)
    vcd->close();
  delete top_module;
  exit(EXIT_SUCCESS);
}
