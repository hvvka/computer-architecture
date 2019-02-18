.data
minus:  .double -1.0

.text
.global cosinus
.type cosinus, @function

# double cosinus(double x, int liczba_wyrazow) //x = kat_rad
# {
#   double wyraz = 1, kwadrat = x*x, suma = 1;
#   int n = 1;
#
#   while(n < liczba_wyrazow)
#   {
#      wyraz *= -kwadrat/((2*n - 1) * 2*n);
#      n++;
#      suma += wyraz;
#   }
#   return suma;
# }

# cos(x) = ∑ [(-1)^n * x*(2n)] / (2n)! = 1 - x^2/2! + x^4/4! - x^6/6! + ...
# każdy następny wyraz jest wynikiem mnożenia poprzedniego przez -x^2/[(2n-1)*2n]

# cosinus (kat_rad, liczba_wyrazow)
# %rax    %xmm0     %rdi
cosinus:
pushq   %rbp
movq    %rsp, %rbp

subq    $8, %rsp        #64b rezerwy
movsd   %xmm0, (%rsp)   #usadzenie 128b na stosie
                        #Move scalar double-precision floating-point value
fld1                    # 1.0 na stosie FPU
fld1                    # 1.0
fldz                    # 0.0
fldl    (%rsp)          # ST(0) = kat_rad;
fld1                    # ST(1) = ST(0) = 1.0
fld1                    # ST(2) = ST(1) = ST(0) = 1.0

# Przeznaczenie rejestrów FPU:
# ST(5) - $1.0
# ST(4) - wynik silni
# ST(3) - obecna silnia jako nr wyrazu (mianownik)
# ST(2) - kat_rad (kąt podany przez użytkownika)
# ST(1) - suma  (suma wszystkich wyrazów i wynik do przesłania)
# ST(0) - wyraz (aktualny wyraz ciagu)

movq    $0, %rsi        #licznik
fwait

loop:
cmpq    %rdi, %rsi
jge     end             #gdy licznik (rsi) >= liczba_wyrazow (rdi)
incq    %rsi

# Obliczanie następnego wyrazu ciągu
# wyraz *= -x^2/(2n*(2n-1))

# Licznik
# wyraz *= -x^2
fmull   minus           # wyraz *= (-1)
fmul    %st(2), %st     # wyraz *= x
fmul    %st(2), %st     # wyraz *= x

# Mianownik
# (2n-2)! *= (2n-1) * 2n
#fld1
fxch    %st(3)          #podmiana zawartości rejestrów ST(0) i ST(3)
fadd    %st(5), %st     # (2n-2) + 1 = 2n-1
fmul    %st, %st(4)     # (2n-1) * (2n-2)! = (2n-1)!
fadd    %st(5), %st     # (2n-1) + 1 = 2n
fmul    %st, %st(4)     # 2n * (2n-1) = 2n!
fxch    %st(3)
#zmiana na ST(0) i ST(3); powrót do poprzedniego stanu na stosie FPU

fldz
fadd    %st(1), %st
fdiv    %st(5), %st     # wyraz /= (2n)!
fadd    %st, %st(2)     # suma += wyraz
fstp    %st
jmp     loop

end:
fstp    %st             #zdjęcie ze stosu FPU ST(0) i przesunięcie wszystkich zawartości w górę stosu
fstpl   (%rsp)          #zdjęcie wartości ze szczytu stosu FPU i załadowanie do na stos
movsd   (%rsp), %xmm0   #podanie sumy przez stos

movq    %rbp, %rsp      # standardowe operacje kończące funkcję
popq    %rbp
ret
