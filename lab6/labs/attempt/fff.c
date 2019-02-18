#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern char* rozmycieAsm(int, char*, char*, int, int);
extern int my_rdtsc(int*);
char* rozmycieC(unsigned int, unsigned char*, int, int);

struct BitMap
{
  char Type[2];
  unsigned int Size;
  short Reserve1;
  short Reserve2;
  unsigned int OffBits;
  unsigned int biSize;
  unsigned int biWidth;
  unsigned int biHeight;
  short biPlanes;
  short biBitCount;
  unsigned int biCompression;
  unsigned int biSizeImage;
  unsigned int biXPelsPerMeter;
  unsigned int biYPelsPerMeter;
  unsigned int biClrUsed;
  unsigned int biClrImportant;
} Header;


int main(void)
{
  int a = 0, b = 0, *p1, *p2;
  p1 = &a;
  p2 = &b;
  int licz = 0;
  double ms = 0;

  FILE *BMPFile = fopen("2.bmp","rb");
  FILE *f; //Plik do ktorego bedziemy zapisywac;
  memset(&Header,0,sizeof(Header));

  fread(&Header.Type, 2, 1, BMPFile);
  fread(&Header.Size, 4, 1, BMPFile);
  fread(&Header.Reserve1, 2, 1, BMPFile);
  fread(&Header.Reserve2, 2, 1, BMPFile);
  fread(&Header.OffBits, 4, 1, BMPFile);
  fread(&Header.biSize, 4, 1, BMPFile);
  int HEADER_SIZE = Header.biSize;
  fread(&Header.biWidth, 4, 1, BMPFile);
  fread(&Header.biHeight, 4, 1, BMPFile);
  fread(&Header.biPlanes, 2, 1, BMPFile);
  fread(&Header.biBitCount, 2, 1, BMPFile);
  int SIZE = Header.biBitCount;
  fread(&Header.biCompression, 4, 1, BMPFile);
  fread(&Header.biSizeImage, 4, 1, BMPFile);
  int IMAGE_SIZE = Header.biSizeImage;
  fread(&Header.biXPelsPerMeter, 4, 1, BMPFile);
  fread(&Header.biYPelsPerMeter, 4, 1, BMPFile);
  fread(&Header.biClrUsed, 4, 1, BMPFile);
  fread(&Header.biClrImportant, 4, 1, BMPFile);
  fseek(BMPFile,0,0);
  char *header = (char*) calloc (14+HEADER_SIZE, 1);
  /* Okreslenie realnej dlugosci naglowka, maksymalnie 14+HEADER_SIZE */
  int nread2 = fread (header, 1, 14+HEADER_SIZE,BMPFile);
  fseek(BMPFile, 14+HEADER_SIZE, 0);
  /* Alokacja całego obrazka (bez headera) */
  unsigned char *data = (unsigned char*) calloc (IMAGE_SIZE, 1) ;
  /* Okreslenie realnej liczby wczytanych pixeli - maksymalnie IMAGE_SIZE */
  int nread = fread(data, 1, IMAGE_SIZE, BMPFile);
  fclose(BMPFile);

  printf ("Padding wynosi (nieczytane z data) %i\n", Header.biWidth*3);
  printf ("Padding wynosi %i\n", data[Header.biWidth*3]);
  printf ("Przeczytano %d bajtow bitmapy.\n", nread);
  printf ("1.Rozmycie w C\n");
  printf ("2.Rozmycie w Asm\n");
  printf ("Kazdy inny klawisz zakonczy prace programu\n");
  int option = 0;
  scanf("%d",&option);
  /* Przygotowanie zmiennej na nowe (zamazane) dane */
  unsigned char *newdata =(unsigned char*) calloc(sizeOfData,1);

  int padding = 0;
  if(Header.biWidth % 4 != 0 ) {
    padding = 4 - (Header.biWidth % 4);

    printf( "Padding: %d bytes\n", read );
    fread( pixel, read, 1, inFile );
  }

  // Padding w .bmp:
  // jest to dopełnienie biWidth bajtami (mogą być zerowe), tak
  // aby liczba bajtów w biWidth była wielokrotnością 4
  // Wikipedia: Each row in the Pixel array is padded to a multiple of 4 bytes in size

  if (option == 1) {
    f = fopen("C.bmp","wb");
    p1 = myrdtsc(p1);       // pomiar czasu dzialania
    newdata = rozmycieC(Header.biWidth*3,data,nread,(4-(Header.biWidth*3)%4)%4);
    p2 = myrdtsc(p2);
  }
  else if (option == 2) {
    f = fopen("Asm.bmp","wb");
    p1 = myrdtsc(p1);
    newdata = rozmycieAsm(data,IMAGE_SIZE,Header.biWidth*3,(4-(Header.biWidth*3)%4)%4);
    p2 = myrdtsc(p2);
  }

  // wyliczenie czasu
  licz = abs(b-a);
  printf("Liczba cykli:\t%d\n", licz);
  ms /= 2700000;         // wyliczenie czasu
  printf("Czas operacji:\t%lf  ms\n", ms);

  // zapis nowej bitmapy po przejsciach i zwolnienie pamieci
  fwrite(header,1,nread2,f);
  fseek(f,1,nread2);
  fwrite(newdata,1,nread,f);
  fclose(f);
  free(data);     // zwolnienie starej pamieci z bitmapa

  return 0;
}

char *rozmycieC(unsigned int Width, unsigned char* data, int sizeOfData, int padding)
{
  int counter = 0, i = 0, j = 0;
  unsigned char *newdata = (unsigned char*) calloc(sizeOfData,1);
  unsigned short int sumOfData;
  for(i = 0; i < sizeOfData; i += (Width+padding))
  {
    for(j = 0; j < Width; j++)
    {
      sumOfData = 0;
      counter = 1;
      sumOfData += data[i+j];
      /* Piksel o rzad nizej */
      /* Wykona sie dopiero kiedy rozmazujemy co najmniej 2. rzad */
      if(i >= (Width+padding)) {
        counter++;
        sumOfData += data[i+j-(Width+padding)];
      }
      /* Pixel na lewo od naszego pixela */
      if((j-3) > 0) {
        counter++;
        sumOfData += data[i+j-3];
      }
      /* Pixel na prawo od naszego pixela */
      if((j+3) < Width) {
        counter++;
        sumOfData += data[i+j+3];
      }
      /* Pixel rzad wyzej */
      if(i+j+(Width+padding) < (sizeOfData-padding)) {
        counter++;
        sumOfData += data[i+j+(Width+padding)];
      }

      /* Pixel rzad nizej */
      /* TODO */

      /* Wyliczanie sredniej wartosci */
      sumOfData /= counter;
      newdata[i+j] = sumOfData;
    }
    /* Przesuniecie sie o rzad wyzej */
  }

  /* Zwolnienie starego bufora, nikt nie lubi memory leakow */
  // free(data);
  // zrobione po wywolaniu funkcji w odpowiednim ifie
  return newdata;
}
