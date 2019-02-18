 #include <stdio.h>
 #include <stdlib.h>
#include <string.h>
 
extern char *negatyw(char *bitmap, unsigned int rozmiar);
extern char *rozjasnienie(char *bitmap, unsigned int rozmiar);
extern char *kontrast(char *bitmap, unsigned int rozmiar);
// przekazywany jest wskaźnik buforu obrazka oraz jego rozmiar
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
  int main( void )
{
  FILE *BMPFile = fopen ("2.bmp", "rb");
memset(&Header, 0, sizeof(Header));
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
 char *header;
 header = (char*) calloc (14+HEADER_SIZE, 1);
 int nread2 = fread (header, 1, 14+HEADER_SIZE,BMPFile);
  fseek(BMPFile, 14+HEADER_SIZE, 0);
 char *data;
 data = (char*) calloc (IMAGE_SIZE, 1) ;
 int nread = fread (data, 1, IMAGE_SIZE,BMPFile);
 printf ("Przeczytano %d bajtow bitmapy.\n", nread);
 printf("\n1. Negatyw");
 printf("\n2. Rozjasnienie");
 printf("\n3. Kontrast");
  int wybor;
 scanf("%d",&wybor);
  if (wybor==1)
 {
FILE *f = fopen ("negatyw.bmp", "wb");`
// otworzenie/stworzenie pliku BMP
char *data2;
data2 = negatyw(data,IMAGE_SIZE/8);
// podzielone przez 8, ponieważ iteracja jest esi += 8
fwrite(header,1,nread2,f);
fseek(f,14+HEADER_SIZE,0);
fwrite(data2,1,nread,f);
fclose(f);
 }
 if (wybor==2)
 {
 FILE *f = fopen ("rozjasnienie.bmp", "wb");
 char *data2;
 data2 = rozjasnienie(data,IMAGE_SIZE/8);
 fwrite(header,1,nread2,f);
fseek(f,14+HEADER_SIZE,0);
 fwrite(data2,1,nread,f);
 fclose(f);
 }
 if (wybor==3)
 {
 FILE *f = fopen ("kontrast.bmp", "wb");
 char *data2;
 data2 = kontrast(data,IMAGE_SIZE/3);
 fwrite(header,1,nread2,f);
fseek(f,14+HEADER_SIZE,0);
 fwrite(data2,1,nread,f);
 fclose(f);
}
}
