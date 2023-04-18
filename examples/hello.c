
int main() {
  int b = 666;
  int a = 220;
  if (a == b) {
    a = 448;
  }

  asm("ecall");
  return a;
}
