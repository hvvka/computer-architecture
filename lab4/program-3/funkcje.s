#wartość zwracana w %rax dla int i w %xmm0 dla float

.data

.text

.globl funkcja
.type funkcja, @function

# funkcja (char*,   int,    int)
# %rax     %rdi,    %rsi,   %rdx

funkcja:
pushq   %rbp
movq    %rsp, %rbp

movq    %rdx, %r10
movq    $0, %r9                #licznik
movq    $0, %r8

loop:
movq    $0, %rbx
movb    (%rdi, %r9, 1), %bl

cmp     $'A', %bl
jl      czy_to_cyfra
cmp     $'Z', %bl
jg      wypisz
#kod od tego miejsca się wykona <=> duża litera w %bl
subb    $'A', %bl
addq    %r10, %rbx              #dodanie klucza
#liczenie mod26
movq    %rbx, %rax              #dzielna musi być w rax
movq    $0, %rdx
movq    $26, %r8
idiv    %r8, %rax               #wynik operacji dzielenia zapisywany jest rax, a reszta w rdx

movq    $0, %rbx
movb    %dl, %bl
add     $'A', %bl
jmp     wypisz

czy_to_cyfra:
cmp     $'0', %bl
jl      wypisz
cmp     $'9', %bl
jg      wypisz

subb    $'0', %bl
addq    %r10, %rbx
#liczenie mod10
movq    %rbx, %rax
movq    $0, %rdx
movq    $10, %r8
idiv    %r8, %rax

movq    $0, %rbx
movb    %dl, %bl
addb    $'0', %bl

wypisz:
movb    %bl, (%rdi, %r9, 1)
incq    %r9                    #przejście do następnego znaku z bufora
cmpq    %rsi, %r9
jl      loop

movq    %rbp, %rsp
popq    %rbp
ret
