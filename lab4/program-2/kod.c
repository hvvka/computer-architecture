#include <stdio.h>

char ak2[] = "BK";                              //zmienne   %0
int love = 1;                                   //zmienne   %1
int kc_len = 3;                                 //zmienne   %2
int out;

const int ak2_len = 2;                          //stałe
const int number = 2;                           //stałe
const char kc[] = "I <";                        //stałe

int main(void)
{
    printf("I h8\nSRK%d\n\n", number);
    
    //wstawka w języku Asemblera
    asm(
        "movq   $0, %%rbx \n"
        "movb   (%1, %%rbx, 1), %%al \n"
        "subb   $1, %%al \n"
        "movb   %%al, (%1, %%rbx, 1) \n"
        "movq   $0, %%rbx \n"
        "movl   %2, %%ebx \n"
        "addl   $2, %%ebx \n"
        "movl   %%ebx, %0 \n"

        :"=r"(out)
        :"r"(ak2), "r"(love)
        :"%rax", "%rbx"
        
        );
    
    printf("%s%d\n%s%d\n", kc, out, ak2, number);
    
    return 0;
}

//
//#include <stdio.h>
//
//char str[] = "bcdefgh";
//const int len = 8;
//
//int main(void)
//{
//    //
//    // Wstawka Asemblerowa
//    //
//    asm(
//        "movq $0, %%rbx \n"
//        "petla: \n"
//        "movb (%0, %%rbx, 1), %%al \n"
//        "subb $1, %%al \n"
//        "movb %%al, (%0, %%rbx, 1) \n"
//    
//        "incq %%rbx \n"
//        "cmpq $7, %%rbx \n"
//        "jl petla \n"
//        
//        :
//        :"r"(&str)
//        :"%rax", "%rbx"
//        );
//    
//    //
//    // Wyświetlenie wyniku
//    //
//    printf("Wynik: %s\n", str);
//    
//    //
//    // Zwrot wartości EXIT_SUCCESS
//    //
//    return 0;
//}
