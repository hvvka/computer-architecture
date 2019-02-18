.data
EXIT = 60
EXIT_SUCCESS = 0
SYSWRITE = 1

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
BUF_LEN = 1024

.bss
.comm tmp,      1024
.comm textout,  1024

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

# przepisanie na ascii #

movq    $16, %r11               # dzielnik - można ładniej zrobić przesunięciem bitowym
movq    $0, %rdi                # wyzerowanie licznika do tmp
cmpq    $mnozna_len, $mnoznik_len
jg      wybierz_mnoznik
movq    $mnozna_len, %r8       # wybor odpowiedniego licznika
jmp     next_quad
wybierz_mnoznik:
movq    $mnoznik_len, %r8
next_quad:
shlq    $2, %r8                 # 2x więcej miejsca na wynik
cmpq    %r8, %rdi               # koniec partial
jge     end_ascii
movq    partial(%rdi,8), %rax
ascii_loop:
movq    $0, %rdx                # wyzerowanie rejestru na resztę
cmpq    $0, %rax
jle     next_quad
idiv    %r11, %rax              # wynik w rax, reszta w rdx
# reszta nie może być większa od 10, więc mieści się na 1 bajcie
cmpq    %dl, $10
jge     litera
addb    $'0', %dl               # przepisanie na ascii
jmp     move_digit
litera:
addb    $'A', %dl               # przepisanie na ascii
move_digit:
movb    %dl, tmp(,%rdi,1)       # znaki będą wpisywane od najmłodszego (na odwrót)
incq    %rdi
jmp     ascii_loop

end_ascii:
movq    $0, %rsi                # licznik do textout
decq    %rdi                    # cofnięcie ostatniej inkrementacji, by wrócić do indeksu ostatnio wpisanego znaku
tmp_to_textout_loop:            # przepisanie tmp do textout w odwrotnej kolejności
movb    tmp(,%rdi,1), %cl
movb    %cl, textout(,%rsi,1)
decq    %rdi
incq    %rsi
cmpq    $0, %rdi
jl      end_tmp_to_textout
jmp     tmp_to_textout_loop

end_tmp_to_textout:
movb    $'\n', textout(,%rsi,1)
movq    $SYSWRITE, %rax
movq    $STDOUT, %rdi
movq    $textout, %rsi
movq    $BUFLEN, %rdx
syscall

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
