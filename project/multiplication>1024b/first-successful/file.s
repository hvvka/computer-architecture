.data
EXIT = 60
EXIT_SUCCESS = 0

# mnożna
# multiplicand:	.quad 0x8888888887654321, 0xAAAABBBBAAAABBBB, 0xCCCCDDDDCCCCDDDD, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0x8888888887654321, 0xAAAABBBBAAAABBBB, 0xCCCCDDDDCCCCDDDD, 0x8888888887654321, 0xAAAABBBBAAAABBBB, 0xCCCCDDDDCCCCDDDD, 0xFFFFFFFFFFFFFFFF, 0x7777777776543210, 0x7777777776543210, 0x7777777776543210, 0x7777777776543210, 0x8888888887654321, 0xAAAABBBBAAAABBBB, 0xCCCCDDDDCCCCDDDD, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0x8888888887654321, 0xAAAABBBBAAAABBBB, 0xCCCCDDDDCCCCDDDD, 0x8888888887654321, 0xAAAABBBBAAAABBBB, 0xCCCCDDDDCCCCDDDD, 0xFFFFFFFFFFFFFFFF, 0x7777777776543210, 0x7777777776543210, 0x7777777776543210, 0x7777777776543210
multiplicand:	.quad 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF

# długość w bajtach
mnozna_len = .-multiplicand

# mnożnik
# multiplier:     .quad 0x7777777776543210, 0xB
multiplier:     .quad 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA, 0xAAAAAAAAAAAAAAAA

mnoznik_len = .-multiplier

first:    .fill 256       # mnożna
second:   .fill 256       # mnożnik
partial:  .fill 512       # suma cząstkowa

# --------------------------------------
# ---------------- MAIN ----------------
# --------------------------------------
.text
.global main
main:

# przepisanie
leaq    multiplicand, %rbx
leaq    multiplier, %r8
call    iloczyn

check:
movq    $EXIT, %rax
movq    $EXIT_SUCCESS, %rdi
syscall

# --------------------------------------
# -------------- DODAWANIE -------------
# --------------------------------------
.type dodawanie, @function
dodawanie:
pushq   %rbp
movq    %rsp, %rbp
addq    %rbx, %rsi          # suma liczników obu pętli (wew i zew)


continue:
# wynik mnożenia w: rdx | rax
addq    (%r10,%rsi,8), %rax
movq    %rax, (%r10,%rsi,8)
incq    %rsi
adcq    (%r10,%rsi,8), %rdx
movq    %rdx, (%r10,%rsi,8) # CF?
jnc     end

flag_loop:
movq    $0, %rax
incq    %rsi
adcq    (%r10,%rsi,8), %rax
movq    %rax, (%r10,%rsi,8)
jc      flag_loop

end:
movq    %rbp, %rsp
popq    %rbp
ret

# --------------------------------------
# -------------- ILOCZYN ---------------
# --------------------------------------
.type iloczyn, @function
iloczyn:
pushq   %rbp
movq    %rsp, %rbp

# zaokrąglanie mnoznej
xorq    %rdx, %rdx
movq    $mnozna_len, %rax
movq    $8, %rcx
idiv    %rcx
movq    %rax, %r9

leaq    first, %rdi
movq    %rbx, %rsi
movq    %rax, %rcx
rep     movsq

# zaokrąglanie mnoznika
xorq    %rdx, %rdx
movq    $mnoznik_len, %rax
movq    $8, %rcx
idiv    %rcx
movq    %rax, %r10

leaq    second, %rdi
movq    %r8, %rsi
movq    %rax, %rcx
rep 	  movsq

# --------------------------------------
# mnożenie: rax * rdx = rdx | rax
movq    %r9, %rcx         # maksymalny indeks FIRST
movq    %r10, %rdi        # maksymalny indeks SECOND
leaq    first, %r8
leaq    second, %r9
leaq    partial, %r10
xorq    %rsi, %rsi        # licznik pętli wewnętrznej
xorq    %rbx, %rbx        # licznik pętli zewnętrznej

outer_loop:
movq    (%r9,%rbx,8), %r13      # D

inner_loop:
# D x A
movq	  %r13, %rdx
movq    (%r8,%rsi,8), %rax      # A
mulq    %rdx
# rdx | rax
pushq   %rsi
pushq   %rbx
call    dodawanie
popq    %rbx
popq    %rsi
incq    %rsi
cmpq    %rdi, %rsi
jle     inner_loop

xorq    %rsi, %rsi
incq    %rbx
cmpq    %rcx, %rbx
jle     outer_loop

movq    %rbp, %rsp
popq    %rbp
ret
