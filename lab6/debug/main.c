#include <stdio.h>
#include <math.h>

void char* rozmycieC(unsigned int, unsigned char*, int);
extern int *my_rdtsc(int *val);

void testTimeC() {
  int *adr;       // wkaznik na adres pierwszego pomiaru
  int *adr2;      // wskaznik adres drugiego pomiaru
  int licz = 0;   // licznik taktow procesora

  int a, b;       // referencje do zmiennych
  double ms;      // czas w milisekundach

  adr = &a;       // inicjalizacja wskaznikow
  adr2 = &b;

  adr = my_rdtsc(adr);

  //przykładowa operacja której czas wykonania mierzę
//  printf("\n");

  // tu wstawić operacje na bitmapie
  

  adr2 = my_rdtsc(adr2);
  licz = b - a;   // roznica
  licz = abs(licz);	// wynik może być ujemny
  ms = licz;
//  ms = ms/3330000;    // liczba 3 330 000 wynika z taktowania laka, które wynosi 3,33GHz
                      // Hz = 1/s   =>    s = 1/Hz    =>  ms*10^-3 = 1/(10^9*Hz)
                      // ms = 1/Hz * 10^-9 * 10^3   =>  ms = 1/Hz * 10^-6
 
 // taktowanie komputera z labów: 3.70 GHz
 // sprawdzenie w terminalu komendą np. cat proc/cpuinfo (wyświetlenie zawartości pliku)
  ms = ms/3700000;

  printf("Operacja zajela %d taktow.\n", licz);
  printf("Czas wykonywania: %f ms\n\n", ms);

  return 0;
}
