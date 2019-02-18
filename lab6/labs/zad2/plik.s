.global negatyw, rozjasnienie, kontrast

.data
liczba: .byte 255,255,255,255,255,255,255,255
jasnosc: .byte 50,50,50,50,50,50,50,50


# liczba jest zawiera maksymalną wartość piksela
# negatyw (data,    IMAGE_SIZE/8)
# %rax     %rdi     %rsi
.type negatyw @function
negatyw:
pushq   %rbp
movq    %rsp, %rbp
movq    16(%rsp), %rsi
# pobranie adresu bufora
movq    24(%rsp), %rcx # pobranie rozmiaru obrazka

petla:
movq    0(%rsi), %mm0   # pobieranie wartości piksela
movq    liczba, %mm1
psubb   %mm0, %mm1      # "odwrócenie" wartości piksela
movq    %mm1, 0(%rsi)   # zapis zmienionego piksela
addq    $8, %rsi        # odwołanie wskaźnika do następnego piksela
loop    petla # pętla wykonuje się ecx razy

movq    %rbp, %rsp
popq    %rbp
ret


.type rozjasnienie, @function
rozjasnienie:
movq    8(%rsp), %rsi
movq    16(%rsp), %rcx
movq    %rsi, %rax
movq    jasnosc, %mm1 # pobranie wartości rozjaśnienia

petla:
movq    0(%rsi), %mm0
paddusb %mm1, %mm0 # odjęcie powoduje rozjaśnienie
movq    %mm0, 0(%rsi)
addq    $8, %rsi
loop    petla
movq    %rbx, %rcx
ret

.type kontrast, @function
kontrast:
movq    8(%rsp), %rsi

movq    16(%rsp), %rcx
pushq   %rsi
movq    $127, %rax
petla:
movb    0(%rsi), %bl
shr     $2, %bl
shr     $2, %bl
# przesunięcie bitowe, żeby podzielić wartość
# przez 4
addq    %rax, %rbx
movb    %bl, 0(%rsi)
movb    1(%rsi), %bl
addq    %rax, %rbx
movb    %bl, 1(%rsi)
movb    2(%rsi), %bl
shr     $2, %bl
addq    %rax, %rbx
movb    %bl, 2(%rsi)
addq    $3, %rsi # przesunięcie wskaźnika na następne 3 kolory
loop    petla
popq    %rax
ret
