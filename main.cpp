#include "obj_dir/Vrv32.h"
#include "obj_dir/Vrv32_MEM.h"
#include "obj_dir/Vrv32_rv32.h"
#include <stdlib.h>
#include <verilated_vcd_c.h>

int main(int argc, char **argv) {
  // Initialize Verilators variables
  Verilated::commandArgs(argc, argv);

  Vrv32 *top_module = new Vrv32;

  VerilatedVcdC *vcd = nullptr;
  Verilated::traceEverOn(true); // Verilator must compute traced signals
  vcd = new VerilatedVcdC;
  top_module->trace(vcd, 99); // Trace 99 levels of hierarchy
  vcd->open("out.vcd");       // Open the dump file

  // fill intr memory
  // TODO: load ELF
  top_module->rv32->instr_mem->mem_buff[0] = 0xFF;
  top_module->rv32->instr_mem->mem_buff[0xF] = 0xF;

  // switch the clock
  vluint64_t vtime = 0;
  int clock = 0;
  top_module->pc = 0x0;
  top_module->we = 0x0;
  top_module->w = 0b010;

  // top_module->b = 0x2;
  // top_module->ALUop = 0b0000;
  while (!Verilated::gotFinish()) {
    vtime += 1;
    if (vtime % 8 == 0)
      clock ^= 1;

    if (vtime > 50)
      top_module->pc = 0xF;

    top_module->clk = clock;
    top_module->eval();
    vcd->dump(vtime);
    printf("%d %02X\n", clock, top_module->c);

    if (vtime > 500)
      break;
  }

  top_module->final();
  if (vcd)
    vcd->close();
  delete top_module;
  exit(EXIT_SUCCESS);
}
