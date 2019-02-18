.data
minus: .double -1.0
silnia: .double 0.0

.text
.global cosinus
.type cosinus, @function

cosinus:
push    %rbp
mov     %rsp, %rbp

sub     $8, %rsp
movsd   %xmm0, (%rsp)
fldl    (%rsp)  # ST(0) = przesłany kąt
fld1             # ST(1) = ST(0); ST(0) = 1.0
fld1             # -||-

# Zawartość rejestrów FPU obecnie, na początku i końcu pętli:
# ST(0) - aktualny wyraz ciągu (początkowo 1.0)
# ST(1) - aktualna suma ciągu (początkowo 1.0)
# ST(2) - przesłany kąt (x)

movq    $0, %rsi
fwait

petla:

cmp     %rdi, %rsi
je      koniec
inc     %rsi

#licznik
fmul    %st(2), %st # Aktualny wyraz ciągu (ST(0)) *= x
fmul    %st(2), %st # Aktualny wyraz ciągu (ST(0)) *= x
fmull   minus # Aktualny wyraz ciągu (ST(0)) * (-1)
# Obecny wyraz ciągu = poprzedni wyraz ciągu * (-x^2)

###
### Obliczanie mianownika - silni
###
fld1    # ST(0) -> ST(1)...; ST(0) = 1.0
fld1    # ST(0) -> ST(1)...; ST(0) = 1.0
fldl    silnia # ST(0) -> ST(1)...;
# ST(0) = zawartość komórki pamięci - silnia

# Aktualne rejestry:
# ST(0) - numer wyrazu silni (z "silnia")
# ST(1) - wynik silni (bez uwzględnienia
#         wcześniejszych części), początkowo 1.0
# ST(2) - 1.0

fadd    %st(2), %st
fmul    %st, %st(1)
fadd    %st(2), %st
fmul    %st, %st(1)

fstpl   silnia # Zapisanie numery ostatniego wyrazu silni
# do zmiennej i ściągnięcie go
# ze "stosu" FPU

# Usunięcie niepotrzebnych wartości
fxch    %st(1) # Zamiana miejscami ST(0) i ST(1)
fstp    %st    # Ściągnięcie ze "stosu" FPU
# ostatniej wartości

# Aktualne rejestry:
# ST(0) - silnia (obecny dzielnik)
# ST(1) - wartość do podzielenia (aktualny wyraz ciągu)
# ST(2) - aktualna suma ciągu
# ST(3) - przesłany kąt (x)

fdivr   %st, %st(1) # Dzielenie obecnego wyrazu przez
# dzielnik (silnie) - wynik trafi
# do ST(1)

fstp    %st # Usunięcie obecnego dzielnika ze "stosu" FPU
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

mov     %rbp, %rsp
pop     %rbp
ret
