# AT&T Professional Assembly Language s.86

.data
decimal: .asciz "%d"
float:   .asciz "%f"
nl:      .asciz "\n"

.bss
.comm number1, 8    #int
.comm number2, 8    #float

.text

.global main
main:

## WCZYTYWANIE LICZB ##

# scanf(&number1, "%d");
movq    $0, %rax            #0 parametrów zmiennoprzecinkowych
movq    $decimal, %rdi      #format zapisania liczby w buforze
movq    $number1, %rsi      #adres bufora do zapisania wyniku
call    scanf               #<stdio.h>

# scanf(&number1, "%f");
movq    $0, %rax
movq    $float, %rdi
movq    $number2, %rsi
call    scanf


## WYWOŁANIE FUNKCJI W C ##

# wywołanie funckji z funkcja.c
movq    $1, %rax                #1 parametr zmiennoprzecinkowy w %xmm0
movq    $0, %rdi                #czyszczenie rejestru przed włożeniem liczby
movq    $0, %rbx                #licznik bufora
movq    number1(,%rbx,8), %rdi  #pobranie liczby int z bufora
movq    number2, %xmm0          #single-precision floating-point
call    funkcja

cvtps2pd %xmm0, %xmm0           #konwersja wyniku na double-precision floating-point


## WYPISANIE WYNIKU ##

# printf(wynik);
movq    $1, %rax                #1 parametr - %xmm0
movq    $float, %rdi
subq    $8, %rsp                #rezerwa, żeby printf nie nadpisał wyrazu na szczycie
call    printf

addq    $8, %rsp                #powrót do poprzedniego stanu


# \n
movq    $0, %rax
movq    $nl, %rdi
call    printf

## EXIT ##
movq    $0, %rax
call    exit



