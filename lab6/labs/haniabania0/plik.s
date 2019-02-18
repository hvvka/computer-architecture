.global rozmycieAsm
# BUFFER OVERFLOW

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

# RBX - imageSize-padding
# RCX - imageSize
# RDI - imageWidth
# RSI - *data
# R8  - counter
# R9  - sum
# R10 - padding
# R11 - i
# R12 - j
# R13 - i+j
# R14 - imageWidth+padding
# R15 - *newData

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
addq  %r12, %r13    # i + j
addb  (%rsi,%r13,1), %r9b  # sum += data[i+j];

# if(i >= (imageWidth+padding))
movq  %rdi, %r14    # imageWidth
addq  %r10, %r14    # imageWidth+padding
cmpq  %r14, %r11    # if(i >= (imageWidth+padding))
jl    else_if_0
# if (true) {}
incq  %r8           # couter++
subq  %r14, %r13    # i+j - (imageWidth+padding)
addb  (%rsi,%r13,1), %r9b # sum += data[i+j-(imageWidth+padding)];
addq  %r14, %r13    # i+j

else_if_0:
# if((j-3) > 0)
subq  $3, %r12      # j - 3
cmpq  $0, %r12      # if((j-3) > 0)
jl    else_if_1
# if (true) {}
incq  %r8           # counter++;
subq  $3, %r13      # i+j - 3
addb  (%rsi,%r13,1), %r9b   # sum += data[i+j - 3]
addq  $3, %r13      # i+j

else_if_1:
addq  $6, %r12      # j + 3

# if((j+3) < imageWidth)
cmpq  %rdi, %r12
jg    else_if_2
# if (true) {}
incq  %r8           # counter++;
addq  $3, %r13      # i+j + 3
addb  (%rsi,%r13,1), %r9b   # sum += data[i+j + 3]
subq  $3, %r13      # i+j

else_if_2:
subq  $3, %r13      # j

# if(i+j+(imageWidth+padding) < (imageSize-padding))
# if((i+imageWidth + 1) < imageSize)
addq  %r14, %r13    # i+j + (imageWidth+padding)
movq  %rcx, %rbx    # imageSize
subq  %r10, %rbx    # imageSize - padding
cmpq  %rbx, %r13    # if(i+j+(imageWidth+padding) < (imageSize-padding))
jg    else_if_3
# if (true) {}
incq  %r8           # counter++;
addb  (%rsi,%r13,1), %r9b   # sum += data[i+j+(imageWidth+padding)]

else_if_3:
subq  %r14, %r13    # i+j
xorq  %rdx, %rdx
movq  %r9, %rax     # sum
idivq %r8           # sum /= counter
# wynik w %rax
movb  %al, (%r15,%r13,1)    # newdata[i+j] = sum

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
