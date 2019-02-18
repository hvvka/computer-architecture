#include <stdio.h>
#include <string.h>
#include <stdbool.h>

static char txt;
int txt_len, key;

int main(void)
{
    printf("Wpisz tekst: ");
    scanf("%s", &txt);
    txt_len = strlen(&txt);
    printf("Wpisz klucz: ");
    scanf("%d", &key);
    
    //wstawka w języku Asemblera
    asm(
        "movq   $0, %%rbx \n"       //licznik
        "movq   $0, %%rax \n"       //bufor na znak
        "loop: \n"
        "movb   (%0, %%rbx, 1), %%al \n"    //pobranie znaku
        "cmpb   $'0', %%al \n"
        "jl     next \n"
        "cmpb   $'9', %%al \n"
        "jg     next \n"
        "subb   $'0', %%al \n"              //ascii -> int
        "addl   %2, %%eax \n"               //int + klucz
        "movq   $0, %%rdx \n"
        "movq   $10, %%rcx \n"
        "idiv   %%rcx, %%rax\n"
        "addq   $'0', %%rdx \n"
        "movb   %%dl, (%0, %%rbx, 1) \n"
        "next: \n"
        "incq   %%rbx\n"
        "cmpl   %1, %%ebx\n"
        "jl     loop \n"

        :
        :"r"(&txt), "r"(txt_len), "r"(key)  //%0, %1, %2
        :"%rax", "%rbx", "%rcx", "%rdx"
        
        );
    
    printf("Wynik: %s\n", &txt);
    
    return 0;
}
