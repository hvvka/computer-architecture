#include <stdio.h>
#include <math.h>

extern int *my_rdtsc(int *val);

int main() {
  int *adr;       // wkaznik na adres pierwszego pomiaru
  int *adr2;      // wskaznik adres drugiego pomiaru
  int licz = 0;   // licznik taktow procesora

  int a, b;       // referencje do zmiennych
  double ms;      // czas w milisekundach

  adr = &a;       // inicjalizacja wskaznikow
  adr2 = &b;

  adr = my_rdtsc(adr);

  //przykładowa operacja której czas wykonania mierzę
  printf("\n");
  // operacje na bitmapie

  adr2 = my_rdtsc(adr2);
  licz = b - a;   // roznica
  licz = abs(licz);
  ms = licz;
  ms = ms/3330000;    // liczba 3 330 000 wynika z taktowania laka, które wynosi 3,33GHz
                      // Hz = 1/s   =>    s = 1/Hz    =>  ms*10^-3 = 1/(10^9*Hz)
                      // ms = 1/Hz * 10^-9 * 10^3   =>  ms = 1/Hz * 10^-6

  printf("Operacja zajela %d taktow.\n", licz);
  printf("Czas wykonywania: %f ms\n\n", ms);

  return 0;
}
