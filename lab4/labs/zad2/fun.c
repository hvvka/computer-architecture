#include <stdio.h>
#include <string.h>

extern int fun(char*, int);

char txt;
int txt_len, output;

int main() {
    
    printf("Wpisz tekst: ");
    scanf("%s", &txt);
    txt_len = strlen(&txt);
    
    output = fun(&txt, txt_len);
    printf("%d\n", output);
    
    return 0;
    
}
