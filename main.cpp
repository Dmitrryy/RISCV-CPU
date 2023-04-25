#include "VRV32.h"
#include "VRV32_MEM__N11.h"
#include "VRV32_RGF.h"
#include "VRV32_RV32.h"
#include "VRV32_RegPC.h"
#include <verilated_vcd_c.h>

#include <CLI/CLI.hpp>
#include <elfio/elfio.hpp>

#include <array>
#include <iostream>

// Source: https://github.com/106-inc/sim2022
void RegfileStr(const uint32_t *registers) {
  std::cout << std::setfill('0');
  constexpr std::size_t lineNum = 8;

  for (std::size_t i = 0; i < lineNum; ++i) {
    for (std::size_t j = 0; j < 32 / lineNum; ++j) {
      auto regIdx = j * lineNum + i;
      auto &reg = registers[regIdx];
      std::cout << "  [" << std::dec << std::setw(2) << regIdx << "] ";
      std::cout << "0x" << std::hex << std::setw(sizeof(reg) * 2) << reg;
    }
    std::cout << std::endl;
  }
}

int main(int argc, char **argv) {
  // Initialize Verilators variables
  Verilated::commandArgs(argc, argv);

  // parse cmd line
  CLI::App cli_app("RISC-V 2023");
  std::string path_to_exec{};
  int is_trace = 0;
  cli_app.add_option("-p,--path", path_to_exec, "Path to executable file")
      ->required();
  cli_app.add_option("--trace", is_trace, "Path for trace dump");
  CLI11_PARSE(cli_app, argc, argv);

  auto top_module = std::make_unique<VRV32>();

  Verilated::traceEverOn(true);
  auto vcd = std::make_unique<VerilatedVcdC>();
  top_module->trace(vcd.get(), 10); // Trace 10 levels of hierarchy
  vcd->open("out.vcd");             // Open the dump file

  // load instructions from ELF
  ELFIO::elfio m_reader{};
  if (!m_reader.load(path_to_exec))
    throw std::invalid_argument("Bad ELF filename : " + path_to_exec);
  if (m_reader.get_class() != ELFIO::ELFCLASS32) {
    throw std::runtime_error("Wrong ELF file class.");
  }
  // Check for little-endian
  if (m_reader.get_encoding() != ELFIO::ELFDATA2LSB) {
    throw std::runtime_error("Wrong ELF encoding.");
  }
  ELFIO::Elf_Half seg_num = m_reader.segments.size();
  //
  for (size_t seg_i = 0; seg_i < seg_num; ++seg_i) {
    const ELFIO::segment *segment = m_reader.segments[seg_i];
    if (segment->get_type() != ELFIO::PT_LOAD) {
      continue;
    }
    uint32_t address = segment->get_virtual_address();
    // FIXME: cause by separeting instr and data memory
    if (address >> 17) {
      throw std::runtime_error("Try load ELF to data mem! " +
                               std::to_string(address));
    }
    size_t filesz = static_cast<size_t>(segment->get_file_size());
    size_t memsz = static_cast<size_t>(segment->get_memory_size());
    if (filesz) {
      const auto *begin =
          reinterpret_cast<const uint8_t *>(segment->get_data());
      uint8_t *dst =
          reinterpret_cast<uint8_t *>(top_module->RV32->imem->mem_buff);
      std::copy(begin, begin + filesz, dst + address);
    }
  }

  // init pc
  top_module->RV32->pc_module->pc = m_reader.get_entry();

  // std::ofstream trace_out(path_to_trace);

  vluint64_t vtime = 0;
  int clock = 0;
  top_module->clk = 0;
  int inst_counter = 0;
  int tackt = 0;
  while (!Verilated::gotFinish()) {
    vtime += 1;
    if (vtime % 8 == 0) {
      // switch the clock
      if (!clock && top_module->valid_out) {
        if (is_trace == 1) {
          std::cout
              << "*********************************************************"
                 "**********************"
              << std::endl;
          std::cout << std::hex << "0x" << (unsigned)top_module->pc_out << ": "
                    << "CMD" << std::dec << " rd = " << (int)top_module->rdn_out
                    << ", rs1 = " << (int)top_module->rs1n_out
                    << ", rs2 = " << (int)top_module->rs2n_out << std::hex
                    << ", imm = 0x" << top_module->imm_out << std::dec
                    << std::endl;

          RegfileStr(top_module->RV32->reg_file->registers);
        } else if (is_trace == 2) {
          std::cout << "***********************************\n";
          std::cout << "TAKT: " << std::dec << tackt << std::endl;
          std::cout << "NUM: " << std::dec << inst_counter++ << std::endl;
          std::cout << "PC : "
                    << "0x" << std::hex << (unsigned)top_module->pc_out
                    << std::endl;
          if (top_module->RegWrite_out && top_module->rdn_out != 0) {
            std::cout
                << "X" << std::dec << (int)top_module->rdn_out << " = 0x"
                << std::hex
                << top_module->RV32->reg_file->registers[top_module->rdn_out]
                << std::endl;
          }
        }
      }
      if (top_module->Exception & (top_module->clk == 0)) {
        std::cout << "Simulation end! Registers:" << std::endl;
        RegfileStr(top_module->RV32->reg_file->registers);
        break;
      }
      clock ^= 1;
      tackt += clock;
    }

    top_module->clk = clock;
    top_module->eval();
    vcd->dump(vtime);
  }

  top_module->final();
  vcd->close();

  return 0;
}
