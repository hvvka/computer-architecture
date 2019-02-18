.data
minus:  .double -1.0
#silnia: .double  1.0

.text
# Zadeklarowana tutaj funkcja będzie możliwa do wykorzystania
# w języku C po zlinkowaniu plików wynikowych kompilacji obu kodów
.global taylor
.type taylor, @function


# double taylor(double kat_rad, int EPS)
# {
#   double wyraz = kat_rad, kwadrat = kat_rad*kat_rad, suma = kat_rad;
#   int n = 1;
#
#   while(fabs(wyraz) > EPS)
#   {
#      wyraz *= -kwadrat/(2*n * (2*n + 1));
#      n++;
#      suma += wyraz;
#   }
#   return suma;
# }

# sin(x) = ∑ [(-1)^n * x*(2n-1)] / (2n+1)! = x - x^3/3! + x^5/5! - x^7/7! + ...

# taylor (kat_rad, liczba_wyrazow)
# rax     xmm0     rdi
taylor:
pushq   %rbp
movq    %rsp, %rbp

# Załadowanie wartości z rejestru xmm0
# do rejestrów ST(0), ST(1) i ST(2) przez stos
subq    $8, %rsp        #64b rezerwy
movsd   %xmm0, (%rsp)   #usadzenie 128b na stosie
fld1
fld1                    #1.0 na stosie FPU
fld1
fldl    (%rsp)          # ST(0) = kat_rad;
fld     %st             # ST(1) = ST(0) = kat_rad
fld     %st             # ST(2) = ST(1) = ST(0) = kat_rad

# przeznaczenie rejestrów FPU:
# ST(5) - $1.0
# ST(4) - mnożnik silni
# ST(3) - obecna silnia (mianownik)
# ST(2) - kat_rad (kąt podany przez użytkownika)
# ST(1) - suma  (suma wszystkich wyrazów i wynik do przesłania)
# ST(0) - wyraz (aktualny wyraz ciagu)

movq    $0, %rsi        #licznik
fwait                   # Oczekiwanie na zakończenie wykonywanych przez
                        # FPU obliczeń

petla:
# Wyskok z pętli po obliczeniu wszystkich wyrazów
cmpq    %rdi, %rsi
jge     koniec          #gdy licznik (rsi) >= liczba_wyrazow (rdi)
incq    %rsi

# wyraz *= -x^2/(2n*(2n-1))
fmull   minus           # Aktualny wyraz ciągu (ST(0)) * (-1)
fmul    %st(2), %st     # Aktualny wyraz ciągu (ST(0)) *= x
fmul    %st(2), %st     # Aktualny wyraz ciągu (ST(0)) *= x

# Po wykonaniu tych instrukcji uzyskamy:
# Aktualny wyraz ciągu = poprzedni wyraz ciągu * (-x^2)

###
### Obliczanie mianownika - silni
###
#fld1    # ST(0) -> ST(1)...; ST(0) = 1.0
#fld1    # ST(0) -> ST(1)...; ST(0) = 1.0
#fldl    silnia # ST(0) -> ST(1)...;
# ST(0) = zawartość komórki pamięci - silnia




# Aktualne rejestry:
# ST(0) - numer wyrazu silni (z "silnia")
# ST(1) - wynik silni (bez uwzględnienia
#         wcześniejszych części), początkowo 1.0
# ST(2) - 1.0

# Obliczenie kolejnych dwóch wyrazów silni:
# Jeśli początkowa wartość ze zmiennej "silnia" była równa
# Y, to w tej części obliczane są "wyrazy" (Y+1)*(Y+2).
# Przez obliczoną wartość dzielny jest poprzedni wyraz
# ciągu, po uprzednim pomnożeniu przez -x^2.
# Po tym etapie, obecny wyraz ciągu jest równy:
# (poprzedni wyraz ciągu * -x^2) / (Y+1)*(Y+2)
fxch    %st(4)
fadd    %st(5), %st
fmul    %st, %st(3)
fadd    %st(5), %st
fmul    %st, %st(3)
fxch    %st(4)

#fstpl   silnia # Zapisanie numery ostatniego wyrazu
# silni do zmiennej i ściągnięcie go
# ze "stosu" FPU

# Usunięcie niepotrzebnych wartości
#fxch    %st(1) # Zamiana miejscami ST(0) i ST(1)
#fstp    %st    # Ściągnięcie ze "stosu" FPU ostatniej
# wartości

# Aktualne rejestry:
# ST(0) - silnia (obecny dzielnik)
# ST(1) - wartość do podzielenia (aktualny wyraz ciągu)
# ST(2) - aktualna suma ciągu
# ST(3) - przesłany kąt (x)

fdiv   %st(3), %st # Dzielenie obecnego wyrazu przez
# dzielnik (silnie) - wynik trafi
# do ST(0)

#fstp    %st # Usunięcie obecnego dzielnika ze "stosu" FPU
# Zawartość rejestrów jak na początku pętli

fadd    %st, %st(1) # Dodanie wartości obecnego wyrazu
# do wyniku globalnego

jmp petla # Powrót na początek pętli

# Przeniesienie wyniku z rejestru ST(0) (sumy ciągu)
# do rejestru XMM0 przez stos i zakończenie funkcji
koniec:
fstp    %st
fstpl   (%rsp)
movsd   (%rsp), %xmm0

movq    %rbp, %rsp
popq    %rbp
ret
