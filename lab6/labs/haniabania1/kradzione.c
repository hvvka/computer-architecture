#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern char* rozmycieAsm(int, char*, char*, int, int);
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
  long double ms = 0;    // lf

  FILE *BMPFile = fopen("2.bmp","rb");       // r - read, rb - do otwierania plików nie-tekstowych
  FILE *f;                                   // plik do ktorego bedziemy zapisywac;
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

  /* Okreslenie realnej dlugosci naglowka, maksymalnie 14+HEADER_SIZE */
  char *header = (char*) calloc (14+HEADER_SIZE, 1);
  header = (char*) calloc (14+HEADER_SIZE, 1);	// header offset

  int nread2 = fread (header, 1, 14+HEADER_SIZE,BMPFile);
  fseek(BMPFile, 14+HEADER_SIZE, 0);            // już z pominięciem offsetu

  /* Alokacja całego obrazka (bez headera) */
  unsigned char *data = (unsigned char*) calloc (IMAGE_SIZE, 1) ;

  /* Okreslenie realnej liczby wczytanych pixeli - maksymalnie IMAGE_SIZE */
  int nread = fread(data, 1, IMAGE_SIZE, BMPFile);
  printf ("\nPrzeczytano %d bajtow bitmapy.\n", nread);
  fclose(BMPFile);

  printf ("\nbiWidth: \t %i", Header.biWidth*3);
  printf ("\nPadding wynosi: \t%i",data[Header.biWidth*3]);
  int padding = 0;
  if(Header.biWidth % 4 != 0 ) {
    padding = 4 - (Header.biWidth % 4);
    printf("\nPadding: \t %d bytes", padding);
  }
  padding = (4-(Header.biWidth*3)%4)%4;
  printf("\nPadding: \t %d", padding);

  printf("\nRozmyj obraz:");
  printf("\n1. Wykorzystując funkcję w C.");
  printf("\n2. Wykorzystując funkcję w Asemblerze.\n>");
  int option = 0;
  scanf("%d",&option);
  printf("\noption: %d", option);
  /* Przygotowanie zmiennej na nowe (zamazane) dane */
  unsigned char *newdata = (unsigned char*) calloc(IMAGE_SIZE,1);
  printf("\nnewdata: %c", *newdata);
  // Padding w .bmp:
  // jest to dopełnienie biWidth bajtami (mogą być zerowe), tak
  // aby liczba bajtów w biWidth była wielokrotnością 4
  // Wikipedia: Each row in the Pixel array is padded to a multiple of 4 bytes in size

  if (option == 1) {
    f = fopen("C.bmp","wb");    // otworzenie/stworzenie nowego pliku
    p1 = my_rdtsc(p1);          // pomiar czasu dzialania
    printf("\n%d = my_rdtsc(p1);", *p1);
    printf("\n%c = rozmycieC(%d, %c, %d, %d);",Header.biWidth*3, *newdata, nread, padding);
    newdata = rozmycieC(Header.biWidth*3, data, nread, padding);
    printf("\n%d = my_rdtsc(p2);", *p2);
    // newdata = rozmycieC(Header.biWidth*3,data,nread,(4-(Header.biWidth*3)%4)%4);
    p2 = my_rdtsc(p2);
  }
  else if (option == 2) {
    f = fopen("Asm.bmp","wb");
    p1 = my_rdtsc(p1);
    newdata = rozmycieAsm(Header.biWidth*3, data, newdata, nread, padding);
    // newdata = rozmycieAsm(Header.biWidth*3, data, newdata, IMAGE_SIZE,(4-(Header.biWidth*3)%4)%4);
    p2 = my_rdtsc(p2);
  }

  // wyliczenie czasu
  licz = abs(b-a);
  printf("Liczba cykli:\t%d\n", licz);
  ms = licz/2400000;           // wyliczenie czasu
  printf("Czas operacji:\t%Lf  ms\n", ms);

  // zapis nowej bitmapy po przejsciach i zwolnienie pamieci
  fwrite(header, 1, nread2, f);
  fseek(f, 1, nread2);
  fwrite(newdata, 1, nread, f);
  fclose(f);
  free(newdata);               // zwolnienie starej pamieci z bitmapa

  return 0;
}

char *rozmycieC(unsigned int imageWidth, unsigned char* data, int imageSize, int padding)
{
  int counter = 0, i = 0, j = 0;
  unsigned char *newdata = (unsigned char*) calloc(imageSize, 1);
  unsigned short int sum = 0;

  for(i = 0; i < imageSize;)
  {
    printf("\nfor(%d = 0; %d < %d;)", i, i, imageSize);
    for(j = 0; j < imageWidth; j++)
    {
      printf("\nfor(%d = 0; %d < %d; %d++)", j, j, imageWidth, j);
      sum = 0;
      counter = 1;
      sum += data[i+j];
      /* Piksel o rzad nizej */
      /* Wykona sie dopiero kiedy rozmazujemy co najmniej 2. rzad */
      if(i >= (imageWidth+padding)) {
        counter++;
        sum += data[i+j-(imageWidth+padding)];
      }
      /* Pixel na lewo od naszego pixela */
      if((j-3) > 0) {
        counter++;
        sum += data[i+j-3];
      }
      /* Pixel na prawo od naszego pixela */
      if((j+3) < imageWidth) {
        counter++;
        sum += data[i+j+3];
      }
      /* Pixel rzad wyzej */
      if(i+j+(imageWidth+padding) < (imageSize-padding)) {
        counter++;
        sum += data[i+j+(imageWidth+padding)];
      }

      /* Pixel rzad nizej - można, nie trzeba */
      /* TODO */

      /* Wyliczanie sredniej wartosci */
      printf("\n%hu /= %d;", sum, counter);
      sum /= counter;

      printf("\nnewdata[%d+%d] = %hu;", i, j, sum);
      newdata[i+j] = sum;
    }
    /* Przesuniecie sie o rzad wyzej */
    printf("\n%d += (%d+%d);", i, imageWidth, padding);
    i += (imageWidth+padding);
  }

  /* Zwolnienie starego bufora, nikt nie lubi memory leakow */
  // free(data);
  // zrobione po wywolaniu funkcji w odpowiednim ifie
  return newdata;
}
