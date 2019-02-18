.data
decimal: .asciz "%d"
float:   .asciz "%f"
nl:      .asciz "\n"

.bss
.comm number1, 8    #int
.comm number2, 8    #float
.comm bool, 1       #bool

.text

.global main
main:

## WCZYTYWANIE LICZB ##
# scanf("%d", &number1);
movq    $0, %rax            #0 parametrów zmiennoprzecinkowych
movq    $decimal, %rdi      #format zapisania liczby w buforze
movq    $number1, %rsi      #adres bufora do zapisania wyniku
call    scanf               #<stdio.h>

# printf(number1);
movq    $0, %rax                #0 parametrów zmnnprzcnkwch
movq    $decimal, %rdi
movq    number1, %rsi
call    printf

# printf("\n");
movq    $0, %rax
movq    $nl, %rdi
call    printf

# scanf("%f", &number2);
movq    $0, %rax
movq    $float, %rdi
movq    $number2, %rsi
call    scanf

# scanf("%d", &bool);
movq    $0, %rax            #0 parametrów zmiennoprzecinkowych
movq    $decimal, %rdi      #format zapisania liczby w buforze
movq    $bool, %rsi          #adres bufora do zapisania wyniku
call    scanf               #<stdio.h>


## WYWOŁANIE FUNKCJI W C ##
# argumenty
movq    $0, %rdi                #czyszczenie rejestru przed włożeniem liczby
movq    $0, %rbx                #licznik number1
movq    number1(,%rbx,8), %rdi  #pobranie liczby int z bufora
movq    bool, %rsi
movss   number2, %xmm0          #single-precision floating-point

# wywołanie funkcji fun z fun.c
movq    $1, %rax                #1 parametr zmiennoprzecinkowy w %xmm0
call    fun

cvtps2pd %xmm0, %xmm0           #konwersja wyniku na double-precision floating-point

## WYPISANIE WYNIKU ##
# printf(wynik);
movq    $1, %rax                #1 parametr - %xmm0
movq    $float, %rdi
subq    $8, %rsp                #rezerwa, żeby printf nie nadpisał floata na szczycie
call    printf

addq    $8, %rsp                #powrót do poprzedniego stanu

# printf("\n");
movq    $0, %rax
movq    $nl, %rdi
call    printf

## EXIT ##
movq    $0, %rax
call    exit
