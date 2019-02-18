#include <stdio.h>


extern void funkcja(char*, int, int);

char input[] = "AbC123XyZ890";
int input_len = 12;

int main() {
    
    int key;
    printf("Podaj klucz: ");
    scanf("%d", &key);
    
    funkcja(&input, input_len, key);
    printf("%s\n", input);
    
    return 0;
    
}
