.global rozmycieAsm

.data

.bss

# rozmycieAsm (imageWidth,  *data, *newData,  imageSize,  padding)
# %rax         %rdi         %rsi   %rdx       %r8         %r10
.type rozmycieAsm @function
rozmycieAsm:
pushq   %rbp
movq    %rsp, %rbp

movq  %r8, %rcx     # pobranie warunku licznika pętli (imageSize)
movq  %rdx, %r15    # *newData
xorq  %r11, %r11    # i = 0
xorq  %rax, %rax    # *newData2 - albo już nie

loop1:
cmpq  %rcx, %r11    # if(i < imageSize)
jge   end
xorq  %r12, %r12    # j = 0

loop2:
cmpq  %rdi, %r12    # if(j < imageWidth)
jge   loop1

movq  $0, %r9       # sum = 0;
movq  $0, %r8       # counter = 1;

# pobranie pixela
movq  %r11, %r13    # i
addq  %r12, %r13    # i+j
addb  (%rsi,%r13,1), %r9b  # sum += data[i+j];

# if(i >= (imageWidth+padding))
movq  %rdi, %r14    # imageWidth
addq  %r10, %r14    # imageWidth+padding
cmpq  %r14, %r11    # if(i >= (imageWidth+padding))
jl    else_if_0
# if (true) {}
incq  %r8           # couter++
subq  %r14, %r13    # i+j-(imageWidth+padding
addb  (%rsi,%r13,1), %r9b # sum += data[i+j-(imageWidth+padding)];

else_if_0:



subq  $3, %r13      # i+j - 3

# if((i-3) > 0)
subq  $3, %r11      # i-3
cmpq  $0, %r11      # if((i-3) > 0)
jl    else_if_1
# if (true) {}
incq  %r8           # counter++;
addb  (%rsi,%r11,1), %r9b   # sum += data[i-3]

else_if_1:
addq  $6, %r11       # i+3

# if((i+3) < imageSize)
cmpq  %rcx, %r11
jg    else_if_2
# if (true) {}
incq  %r8           # counter++;
addb  (%rsi,%r11,1), %r9b   # sum += data[i+3]

else_if_2:
subq  $2, %r11      # i+1

# if((i+imageWidth + 1) < imageSize)
addq  %rdi, %r11    # i+imageWidth+1
cmpq  %rcx, %r11
jg    else_if_3
# if (true) {}
incq  %r8           # counter++;
addb  (%rsi,%r11,1), %r9b   # sum += data[i+imageWidth+1]

else_if_3:
subq  %rdi, %r11    # i+1
subq  $1, %r11      # i
xorq  %rdx, %rdx
movq  %r9, %rax     # sum
idivq %r8           # sum /= counter
# wynik w %rax
movb  %al, (%r15,%r11,1)    # newdata[i] = sum

# zakonczenie petli loop2
incq  %r12          # j+1
jmp   loop2

# zakonczenie petli loop1
addq  %rdi, %r11    # i + imageWidth
addq  %r10, %r11    # i+imageWidth + padding
jmp   loop1

end:
movq  %r15, %rax    # return newdata

movq	%rbp, %rsp
popq  %rbp
ret
# zwrócenie wartości z %rax
