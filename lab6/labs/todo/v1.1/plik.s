.global rozmycieAsm

.data

.bss

# rozmycieAsm (imageWidth,  *data, *newData,  imageSize)
# %rax         %rdi         %rsi   %rdx       %r8
.type rozmycieAsm @function
rozmycieAsm:
pushq   %rbp
movq    %rsp, %rbp

movq  %r8, %rcx     # pobranie warunku licznika pętli (imageSize)
movq  %rdx, %r15
xorq  %r10, %r10    # i = 0
xorq  %rax, %rax    # newData2

loop:
cmpq  %rcx, %r10
jge   end
movq  $0, %r9       # sum = 0;
movq  $0, %r8       # counter = 1;

# pobranie pixela
addb  (%rsi,%r10,1), %r9b  # sum += data[i];
incq  %r10

# if((i-3) > 0)
subq  $3, %r10      # i-3
cmpq  $0, %r10      # if((i-3) > 0)
jl    else_if_1
# if (true) {}
incq  %r8           # counter++;
addb  (%rsi,%r10,1), %r9b   # sum += data[i-3]

else_if_1:
addq  $6, %r10       # i+3

# if((i+3) < imageSize)
cmpq  %rcx, %r10
jg    else_if_2
# if (true) {}
incq  %r8           # counter++;
addb  (%rsi,%r10,1), %r9b   # sum += data[i+3]

else_if_2:
subq  $2, %r10      # i+1

# if((i+imageWidth + 1) < imageSize)
addq  %rdi, %r10    # i+imageWidth+1
cmpq  %rcx, %r10
jg    else_if_3
# if (true) {}
incq  %r8           # counter++;
addb  (%rsi,%r10,1), %r9b   # sum += data[i+imageWidth+1]

else_if_3:
subq  %rdi, %r10    # i+1
subq  $1, %r10      # i
xorq  %rdx, %rdx
movq  %r9, %rax     # sum
idivq %r8           # sum /= counter
# wynik w %rax
movb  %al, (%r15,%r10,1)
jmp   loop

end:
movq  %r15, %rax

movq	%rbp, %rsp
popq  %rbp
ret
# zwrócenie wartości z %rax
