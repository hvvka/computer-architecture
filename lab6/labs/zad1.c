#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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
}Header;

char * rozmycie(unsigned int Width,unsigned char* data,int sizeOfData)
{
int count,i;
unsigned char *newdata =(unsigned char*) calloc(sizeOfData,1);
unsigned short int sumOfData;
for(i=0;i<sizeOfData;i++)
{
sumOfData=0;
count =1;
sumOfData+=data[i];
/*Piksel o rzad wyzej, niestety z jakiegos powodu if sie buguje*/

if((i-Width+2)>0)
{
count++;
sumOfData+=data[i-Width+2];
}
/*Pixel na lewo od naszego pixela*/
if((i-3)>0)
{
count++;
sumOfData+=data[i-3];
}
/*Pixel na prawo od naszego pixela*/
if((i+3)<sizeOfData)
{
count++;
sumOfData+=data[i+3];
}
/*Pixel rzad nizej, mocno zmienil kolor obrazka*/

if((i+Width+1)<sizeOfData)
{
count++;
sumOfData+=data[i+Width+1];
}

sumOfData= sumOfData/count;
newdata[i]=sumOfData;
}
return newdata;
}
int main(void)
{
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
char *header;
header = (char*) calloc (14+HEADER_SIZE, 1);
int nread2 = fread (header, 1, 14+HEADER_SIZE,BMPFile);
fseek(BMPFile, 14+HEADER_SIZE, 0);
unsigned char *data;
data = (unsigned char*) calloc (IMAGE_SIZE, 1) ;
int nread = fread (data, 1, IMAGE_SIZE,BMPFile);
fclose(BMPFile);
printf ("Przeczytano %d bajtow bitmapy.\n", nread);
printf ("1.Rozmycie w C\n");
printf ("2.Rozmycie w Asm\n");
printf ("Kazdy inny klawisz zakonczy prace programu\n");
int option;
scanf("%d",&option);

switch(option)
{
case 1:
f = fopen("rozmycieC.bmp","wb");
char *data2=rozmycie(Header.biWidth*3,data,IMAGE_SIZE);
fwrite(header,1,nread2,f);
fseek(f,1,nread2);
fwrite(data2,1,nread,f);
fclose(f);
break;
case 2:
printf("Working as intended\n");
break;
default:
printf("Nie ma takiej opcji,program zakonczy dzialanie\n");
break;
}
return 0;
}
