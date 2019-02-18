#wartość zwracana w %rax dla int i w %xmm0 dla float
.data
.text

.globl fun
.type fun, @function

# fun   (char*,   int)
# %rax   %rdi,    %rsi

fun:
pushq   %rbp
movq    %rsp, %rbp

movq    $0, %r9         #licznik
movq    $0, %rax
movq    $0, %rbx        #do pobrania znaku

loop:
imul    $16, %rax
movb    (%rdi, %r9, 1), %bl

cmpb    $'A', %bl
jl      czy_to_cyfra
cmpb    $'Z', %bl
jg      return
#kod od tego miejsca się wykona <=> duża litera w %al
subb    $55, %bl
jmp     wypisz

czy_to_cyfra:
cmpb    $'0', %bl
jl      return
cmpb    $'9', %bl
jg      return
subb    $'0', %bl

wypisz:
addq    %rbx, %rax
incq    %r9                    #przejście do następnego znaku z bufora
cmpq    %rsi, %r9
jl      loop

return:
movq    %rbp, %rsp
popq    %rbp
ret
