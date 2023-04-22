
// /home/ddrozdov/tools/bin/riscv32-embecosm-ubuntu2204-gcc12.2.0/bin/riscv32-unknown-elf-gcc -march=rv32i -e main ./examples/hello.c -o ./examples/hello.out -O0

int summ(int n) {
  int res = 1;
  for(int i = 2; i <= n; i++) {
   res = res + i;
  }
  return res;
}

int main() {
  int n = 0xFFF;
  int res = 1;
  
  res = summ(n);
  asm("ecall");
  return res;
}
