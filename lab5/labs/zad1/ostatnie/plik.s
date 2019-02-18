.data
control_word:   .short 0      #2 bajty (16 bitów)
# Precision Control: bity 8 i 9 w control word
single_precision: .short 0x0000
clear_precision:  .short 0xFCFF
double_precision: .short 0x0200
double_extended:  .short 0x0300

.text
.global ustaw,   sprawdz, f_fun, g_fun
.type   ustaw,   @function
.type   sprawdz, @function
.type   f_fun, @function
.type   g_fun, @function

#   sprawdz ();
#   %rax
sprawdz:
pushq   %rbp
movq    %rsp, %rbp

movq    $0, %rax
fstcw   control_word        #zapisanie zawartości słowa kontrolnego do pamięci
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

movq    %rbp, %rsp
popq    %rbp
ret


#   f_fun (x);
#   %rax   %xmm0
f_fun:
pushq   %rbp
movq    %rsp, %rbp

subq    $8, %rsp
movsd   %xmm0, (%rsp)

fldl    (%rsp)
fmul    %st(0)
fld1
fadd    %st(1)
fsqrt

fld1
fxch    %st(1)
fsub    %st(1)

fstpl   (%rsp)
movsd   (%rsp), %xmm0
addq    $8, %rsp

movq    %rbp, %rsp
popq    %rbp
ret


#   g_fun (x);
#   %rax   %xmm0
g_fun:
pushq   %rbp
movq    %rsp, %rbp

subq    $8, %rsp
movsd   %xmm0, (%rsp)

fldl    (%rsp)
fmul    %st(0)
fld1
fadd    %st(1)
fsqrt
fld1
fadd    %st(1)

fldl    (%rsp)
fmul    %st
fdiv    %st(1)

fstpl   (%rsp)
movsd   (%rsp), %xmm0
addq    $8, %rsp

movq    %rbp, %rsp
popq    %rbp
ret

