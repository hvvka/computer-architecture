#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern char* rozmycieAsm(unsigned int, unsigned char*, unsigned char*, int, int);
extern int* my_rdtsc(int*);
char* rozmycieC(unsigned int, unsigned char*, int, int);

// przekazywany jest wskaźnik buforu obrazka oraz jego rozmiar
struct BitMap
{
  char Type[2];		              // sygnatura (2B)
  unsigned int Size;		        // rozmiar pliku BMP
  short Reserve1;		            // zarezerwowane, musi być 0
  short Reserve2;		            // zarezerwowane, musi być 0
  unsigned int OffBits;	        // offset w bajtach do data image

  // Nagłówek informacyjny
  unsigned int biSize;	        // rozmiar info headera bitmapy (powinno być 40B)
  unsigned int biWidth;      	  // szerokość obrazka w pixelach
  unsigned int biHeight;	      // wysokość obrazka w pixelach
  short biPlanes;		            // zawsze 0
  short biBitCount;		          // liczba bitów na pixel (domyślnie 8)
  unsigned int biCompression;   // rodzaj kompresji (0 to brak kompresji)
  unsigned int biSizeImage;	    // wielkość danych o obrazie w B()
  unsigned int biXPelsPerMeter;	// zazwyczaj 0
  unsigned int biYPelsPerMeter;	// zazwyczaj 0
  unsigned int biClrUsed;	      // liczba kolorów; jeśli 0, to określana na podstawie biBitCount
  unsigned int biClrImportant;  // liczba "ważnych kolorów" dla bitmapy (0 => wszystkie kolory są ważne)
} Header;


// UWAGA
// wszystkie pliki są pobierane z lokalizacji fun.c, tam też są zapisywane
int main(void)
{
  int a = 0, b = 0, *p1, *p2;
  p1 = &a;
  p2 = &b;
  int licz = 0;
  long double ms = 0;

  FILE *BMPFile = fopen("2.bmp","rb");       // r - read, rb - do otwierania plików nie-tekstowych
  memset(&Header, 0, sizeof(Header));

  // Uzupełnienie struktury o dane (wypełnienie jej pól na podstawie otworzonego pliku)
  fread(&Header.Type, 2, 1, BMPFile);
  fread(&Header.Size, 4, 1, BMPFile);
  fread(&Header.Reserve1, 2, 1, BMPFile);
  fread(&Header.Reserve2, 2, 1, BMPFile);
  fread(&Header.OffBits, 4, 1, BMPFile);

  // Nagłówek informacyjny
  fread(&Header.biSize, 4, 1, BMPFile);
  int HEADER_SIZE = Header.biSize;           // zachowanie rozmiaru headera do ustawiania offsetu
  fread(&Header.biWidth, 4, 1, BMPFile);
  fread(&Header.biHeight, 4, 1, BMPFile);
  fread(&Header.biPlanes, 2, 1, BMPFile);
  fread(&Header.biBitCount, 2, 1, BMPFile);
  fread(&Header.biCompression, 4, 1, BMPFile);
  int SIZE = Header.biBitCount;              // zachowanie liczby bitów na pixel
  fread(&Header.biSizeImage, 4, 1, BMPFile);
  int IMAGE_SIZE = Header.biSizeImage;       // zachowanie wielkości danych o obrazie (dla nieskompresowanych 0)
  fread(&Header.biXPelsPerMeter, 4, 1, BMPFile);
  fread(&Header.biYPelsPerMeter, 4, 1, BMPFile);
  fread(&Header.biClrUsed, 4, 1, BMPFile);
  fread(&Header.biClrImportant, 4, 1, BMPFile);

  fseek(BMPFile,0,0);		// ustawia indykator pozycji pliku z danym offsetem

  char *header = (char*) calloc (14+HEADER_SIZE, 1);  // długość nagłówka
  header = (char*) calloc (14+HEADER_SIZE, 1);	      // header offset

  int nread2 = fread (header, 1, 14+HEADER_SIZE,BMPFile);
  fseek(BMPFile, 14+HEADER_SIZE, 0);            // już z pominięciem offsetu

  // alkowoanie pamięci na całye obrazek bez headera
  unsigned char *data = (unsigned char*) calloc (IMAGE_SIZE, 1);

  // liczba wczytanych pixeli
  int nread = fread(data, 1, IMAGE_SIZE, BMPFile);
  printf ("\nBitmap: \t%d bytes", nread);
  fclose(BMPFile);

  printf ("\nbiWidth:\t%i bytes", Header.biWidth*3);
  int padding = (4-(Header.biWidth*3)%4)%4;
  printf("\nPadding:\t%d byte(s)\n", padding);

  printf("\nRozmyj obraz:");
  printf("\n1. Wykorzystując funkcję w C.");
  printf("\n2. Wykorzystując funkcję w Asemblerze.\n>");
  int option = 0;
  scanf("%d",&option);

  if (option == 1) {
    //pomiar czasu - 1
    int *adr, *adr2;// wskazniki adresy pomiarów
    int licz = 0;   // licznik taktow procesora
    int a, b;       // referencje do zmiennych
    double ms;      // czas w milisekundach
    adr = &a;       // inicjalizacja wskaznikow
    adr2 = &b;
    //end - 1

    FILE *fileC = fopen("C.bmp","wb");
    adr = my_rdtsc(adr);
    char* dataC = rozmycieC(Header.biWidth*3, data, nread, padding);
    adr2 = my_rdtsc(adr2);

    //pomiar czasu - 2
    licz = b - a;     // roznica
    licz = abs(licz);	// wynik może być ujemny
    ms = licz;
    // taktowanie komputera z labów: 3.70 GHz
    // sprawdzenie w terminalu komendą np. cat proc/cpuinfo (wyświetlenie zawartości pliku)
    ms /= 3700000;
    printf("\nLiczba taktow:\t%d", licz);
    printf("\nCzas wykonania:\t%f ms\n\n", ms);
    //end - 2

    fwrite(header, 1, nread2, fileC);
    fseek(fileC, 1, nread2);
    fwrite(dataC, 1, nread, fileC);
    fclose(fileC);
    free(dataC);
  }

  else if (option == 2) {
    //pomiar czasu - 1
    int *adr, *adr2;// wskazniki adresy pomiarów
    int licz = 0;   // licznik taktow procesora
    int a, b;       // referencje do zmiennych
    double ms;      // czas w milisekundach
    adr = &a;       // inicjalizacja wskaznikow
    adr2 = &b;
    //end - 1

    FILE *fileAsm = fopen("Asm.bmp","wb");
    unsigned char *space = (unsigned char*) calloc(IMAGE_SIZE,1);

    adr = my_rdtsc(adr);
    char *dataAsm = rozmycieAsm(Header.biWidth*3, data, space, padding, nread);
    adr2 = my_rdtsc(adr2);

    //pomiar czasu - 2
    licz = b - a;   // roznica
    licz = abs(licz);	// wynik może być ujemny
    ms = licz;
    ms /= 3700000;
    printf("\nLiczba taktow:\t%d", licz);
    printf("\nCzas wykonania:\t%f ms\n\n", ms);
    //end - 2

    fwrite(header, 1, nread2, fileAsm);
    fseek(fileAsm, 1, nread2);
    fwrite(dataAsm, 1, nread, fileAsm);
    fclose(fileAsm);
    free(dataAsm);
  }

  return 0;
}

char *rozmycieC(unsigned int imageWidth, unsigned char* data, int imageSize, int padding)
{
  int counter = 0, i = 0, j = 0, sum = 0;
  unsigned char *newdata = (unsigned char*) calloc(imageSize, 1);
  // poruszanie się w górę/w dół obrazka
  for(i = 0; i < imageSize; i += (imageWidth+padding))
  {
    // przejście po bitach w obrębie jednego rzędu - poruszanie się w boki
    for(j = 0; j < imageWidth; j++)
    {
      sum = 0;
      counter = 1;
      sum += data[i+j];
      // dolny pixel
      if(i >= (imageWidth+padding)) {
        counter++;
        sum += data[i+j-(imageWidth+padding)];
      }
      // lewy sąsiad
      if((j-3) > 0) {
        counter++;
        sum += data[i+j-3];
      }
      // prawy sąsiad
      if((j+3) < imageWidth) {
        counter++;
        sum += data[i+j+3];
      }
      // górny sąsiad
      if(i+j+(imageWidth+padding) < (imageSize-padding)) {
        counter++;
        sum += data[i+j+(imageWidth+padding)];
      }

      sum /= counter;       // średnia
      newdata[i+j] = sum;
    }
  }
  free(data);
  return newdata;
}
