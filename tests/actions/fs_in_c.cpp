#include <cstdio>
int main(int argc, const char **argv) {
  FILE *f;
  const char *m = "rw";
  f = fopen("efwmc.txt", m);
  if (f == NULL) {
    printf("Error: Could not open file.\n");
    return 1; // Exit program or handle error
  }

  char ch;
  while ((ch = fgetc(f)) != EOF) {
    printf("%c", ch);
  }

  fclose(f);
  return 0;
}
