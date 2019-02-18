#include <stdio.h>
#include <stdlib.h>
#include <string.h>
 
//extern char *negatyw(char *bitmap, unsigned int rozmiar);
//extern char *rozjasnienie(char *bitmap, unsigned int rozmiar);
//extern char *kontrast(char *bitmap, unsigned int rozmiar);

char* rozmycieC(unsigned int, unsigned char*, int);
extern char* rozmycieAsm(unsigned int, unsigned char*, int);
extern int *my_rdtsc(int *val);

// przekazywany jest wskaźnik buforu obrazka oraz jego rozmiar
struct BitMap
{ 
    char Type[2];		// sygnatura (2B)
    unsigned int Size;		// rozmiar pliku BMP
    short Reserve1;		// zarezerwowane, musi być 0
    short Reserve2;		// zarezerwowane, musi być 0
    unsigned int OffBits;	// offset w bajtach do data image

// Nagłówek informacyjny
    unsigned int biSize;	// rozmiar info headera bitmapy (powinno być 40B)
    unsigned int biWidth;	// szerokość obrazka w pixelach
    unsigned int biHeight;	// wysokość obrazka w pixelach
    short biPlanes;		// zawsze 0
    short biBitCount;		// liczba bitów na pixel (domyślnie 8)
    unsigned int biCompression;	// rodzaj kompresji (0 to brak kompresji)
    unsigned int biSizeImage;	// wielkość danych o obrazie w B()
    unsigned int biXPelsPerMeter;	// zazwyczaj 0
    unsigned int biYPelsPerMeter;	// zazwyczaj 0
    unsigned int biClrUsed;	// liczba kolorów; jeśli 0, to określana na podstawie biBitCount
    unsigned int biClrImportant;	// liczba "ważnych kolorów" dla bitmapy (0 => wszystkie kolory są ważne)
} Header;

// UWAGA
// wszystkie pliki są pobierane z lokalizacji fun.c, tam też są zapisywane
int main()
{
    FILE *BMPFile = fopen("2.bmp", "rb");	// r - read, rb - do otwierania plików nie-tekstowych
    memset(&Header, 0, sizeof(Header));

    // Uzupełnienie struktury o dane (wypełnienie jej pól na podstawie otworzonego pliku)

    fread(&Header.Type, 2, 1, BMPFile);		// 2B
    fread(&Header.Size, 4, 1, BMPFile);		// 4B
    fread(&Header.Reserve1, 2, 1, BMPFile);	// 2B
    fread(&Header.Reserve2, 2, 1, BMPFile);	// 2B
    fread(&Header.OffBits, 4, 1, BMPFile);	// 4B

    // Nagłówek informacyjny
    fread(&Header.biSize, 4, 1, BMPFile);	// 4B
    int HEADER_SIZE = Header.biSize;		// zachowanie rozmiaru headera do ustawiania offsetu
    fread(&Header.biWidth, 4, 1, BMPFile);	// 4B
    fread(&Header.biHeight, 4, 1, BMPFile);	// 4B
    fread(&Header.biPlanes, 2, 1, BMPFile);	// 2B
    fread(&Header.biBitCount, 2, 1, BMPFile);	// 2B
    int SIZE = Header.biBitCount;		// zachowanie liczby bitów na pixel
    fread(&Header.biCompression, 4, 1, BMPFile); // 4B
    fread(&Header.biSizeImage, 4, 1, BMPFile);	// 4B
    int IMAGE_SIZE = Header.biSizeImage;	// zachowanie wielkości danych o obrazie (dla nieskompresowanych 0)
    fread(&Header.biXPelsPerMeter, 4, 1, BMPFile);	// 4B
    fread(&Header.biYPelsPerMeter, 4, 1, BMPFile);	// 4B
    fread(&Header.biClrUsed, 4, 1, BMPFile); 		// 4B
    fread(&Header.biClrImportant, 4, 1, BMPFile);	// 4B
    
    fseek(BMPFile,0,0);		// ustawia indykator pozycji pliku z danym offsetem

    char *header;
    header = (char*) calloc (14+HEADER_SIZE, 1);	// header offset

    int nread2 = fread(header, 1, 14+HEADER_SIZE, BMPFile);
    fseek(BMPFile, 14+HEADER_SIZE, 0);	// już z pominięciem offsetu

    char *data;
    data = (char*) calloc (IMAGE_SIZE, 1) ;

    int nread = fread(data, 1, IMAGE_SIZE, BMPFile);	// pobranie rozmiaru data image
    printf ("\nPrzeczytano %d bajtow bitmapy.\n", nread);
    fclose(BMPFile);		// zamknięcie pliku, z którego było czytanie

    printf("\nRozmyj obraz:");
    printf("\n1. Wykorzystując funkcję w C.");
    printf("\n2. Wykorzystując funkcję w Asemblerze.\n>");
    int wybor;
    scanf("%d",&wybor);
 
    FILE *newFileC;	// plik do zapisu wyniku operacji w C
    FILE *newFileAsm;   // do operacji w Asemblerze

    if (wybor == 1) {
		//pomiar czasu - 1
		int *adr;       // wkaznik na adres pierwszego pomiaru
  		int *adr2;      // wskaznik adres drugiego pomiaru
 		int licz = 0;   // licznik taktow procesora
  		int a, b;       // referencje do zmiennych
  		double ms;      // czas w milisekundach
  		adr = &a;       // inicjalizacja wskaznikow
  		adr2 = &b;
  		adr = my_rdtsc(adr);
		//end - 1

        newFileC = fopen("C.bmp", "wb");	// otworzenie/stworzenie nowego pliku
        char *dataC = rozmycieC(Header.biWidth*3, data, IMAGE_SIZE);	// przetworzenie obrazu
        fwrite(header, 1, nread2, newFileC);	// zapis headera do C.bmp
        fseek(newFileC, 1, nread2);		// ustawienie pozycji do zapisu
        fwrite(dataC, 1, nread, newFileC);	// zapis obrazu do C.bmp
        fclose(newFileC);			// zamknięcie pliku

		adr2 = my_rdtsc(adr2);
 		licz = b - a;   // roznica
  		licz = abs(licz);	// wynik może być ujemny
  		ms = licz;
 		// taktowanie komputera z labów: 3.70 GHz
 		// sprawdzenie w terminalu komendą np. cat proc/cpuinfo (wyświetlenie zawartości pliku)
  		ms = ms/3700000;
  		printf("Operacja zajela %d taktow.\n", licz);
  		printf("Czas wykonywania: %f ms\n\n", ms);
    }

    else if (wybor==2) {
        // TO DO
        newFileAsm = fopen("Asm.bmp", "wb");	// otworzenie/stworzenie nowego pliku
        char *dataAsm = rozmycieAsm(Header.biWidth*3, data, IMAGE_SIZE/8);	// przetworzenie obrazu
        fwrite(header, 1, nread2, newFileAsm);	// zapis headera do Asm.bmp
        fseek(newFileAsm, 1, nread2);		// ustawienie pozycji do zapisu
        fwrite(dataAsm, 1, nread, newFileAsm);	// zapis obrazu do Asm.bmp
        fclose(newFileAsm);			// zamknięcie pliku
    }

    return 0;
}



char* rozmycieC(unsigned int imageWidth, unsigned char* data, int imageSize)
{
    int counter = 0, i = 0;
    unsigned char* newData = (unsigned char*) calloc (imageSize, 1);
    int sum = 0;	// zmienna pomocnicza do sumowania wartości dwóch pixeli
    // jeden bajt to nasycenie jednej barwy pixela (zapis 24bitowy)
    // sumowanie pixeli (odpowiednich barw ze sobą)
    for(i = 0; i < imageSize; i++) {
        sum = 0;
        counter = 1;
        sum += data[i];	// pobranie pixela (jednego bajta)

        // lewy sąsiad
        if((i-3) > 0) {
            counter++;
            sum += data[i-3];
        }
		// prawy sąsiad
        if((i+3) < imageSize) {
            counter++;
            sum += data[i+3];
        }
	
		// dostęp do pixela nad i pod (przesunięcie się o całą linijkę)
        if((i+imageWidth + 1) < imageSize) {
            counter++;
            sum += data[i+imageWidth+1];
        }

        sum /= counter;		// obliczenie średniej
        newData[i] = sum;	// zapisanie uśrednionej wartości dwóch pixeli
    }

    return newData;
}
