.data
control_word:   .short 0      #2 bajty (16 bitów)
# Precision Control: bity 8 i 9 w control word
single_precision: .short 0x0000
clear_precision:  .short 0xFCFF
double_precision: .short 0x0200
double_extended:  .short 0x0300


#double:  .asciz "0x%016llX"
double:  .asciz "%Lf"
nl:      .asciz "\n"
#single_small:   .double 0x00000001
#double_small:   .double 0x00000000000001
extended_small: .double 10^10
extended_srk: .double 1e-10
potezna_liczba: .tfloat 1e-21       #80-bit IEEE extended precision floating-point
                                    #suffix "t" - stands for 80-bit (ten byte) real

result: .double 2

#STDOUT  = 1
#SYSWRITE= 1

.text
.global ustaw,   sprawdz#,   wyswietl
.type   ustaw,   @function
.type   sprawdz, @function
#.type   wyswietl, @function

#   sprawdz ();
#   %rax
sprawdz:
pushq   %rbp
movq    %rsp, %rbp

movq    $0, %rax
fstcw   control_word        #zapisanie zawartości słowa kontrolnego do pamięci
                            #load x87 FPU control word
fwait                       #wait for FPU/check for and handle pending unmasked x87 FPU exceptions
                            #synchronization instruction
movw    control_word, %ax   #przeniesienie do rejestru ogólnego przeznaczenia

andw    $0x300, %ax
shrw    $8, %ax


movq    %rbp, %rsp
popq    %rbp
ret


#   ustaw (prezycja_obliczen);
#   %rax    %rdi
ustaw:
    pushq   %rbp
    movq    %rsp, %rbp      #standardowe operacje na stosie

    # if(precyzja_obliczen == 0) single
    # if(precyzja_obliczen == 2) double
    # if(precyzja_obliczen == 3) extended double

    movq    $0, %rax
    fstcw   control_word
    fwait
    movw    control_word, %ax

#Tryb pracy jednostki ustawia się za pomocą 16-bitowego słowa sterującego FPU (FPU Control Word)
#za precyzję odpowiadają bity 8 i 9, za zaokrąglanie 10 i 11 - dokładny opis w instrukcji Intela.

    andw    $0xFCFF, %ax     #w tym momencie bity precyzji to 00 (single precision)

    cmp     $2, %rdi
    jl      end
    je      set_double

    #jg
    set_extended:
    xorw    double_extended, %ax
    jmp     end

    set_double:
    xorw    double_precision, %ax

    end:
    movw    %ax, control_word
    fldcw   control_word

    fld1
    fldl    extended_small
    fdiv    %st(1), %st
#    fsqrt
    subq    $8, %rsp
    fstpl   (%rsp)                  #zdjęcie wartości ze szczytu stosu FPU i załadowanie do na stos
    movsd   (%rsp), %xmm0

    movq    $1, %rax                #1 parametr - %xmm0
    movq    $double, %rdi
    subq    $8, %rsp                #rezerwa, żeby printf nie nadpisał floata na szczycie
    call    printf
    addq    $8, %rsp

movq    $0, %rax
movq    $nl, %rdi
call    printf

#    fldl    extended_srk
#    fstpl   extended_srk

    subq    $8, %rsp
    fldl    extended_srk
    fstpl   (%rsp)                  #zdjęcie wartości ze szczytu stosu FPU i załadowanie do na stos
    movsd   (%rsp), %xmm0

    movq    %rbp, %rsp
    popq    %rbp
    ret
