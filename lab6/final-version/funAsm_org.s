.text
.globl rozmycieAsm
.type rozmycieAsm, @function


# rozmycieAsm (imageWidth,  *data, *newData,  padding,    imageSize)
# %rax         %rdi         %rsi   %rdx       %r10        %r8

rozmycieAsm:
pushq   %rbp
movq    %rsp, %rbp

movq  %r8, %rcx     # pobranie warunku licznika pętli (imageSize)
movq  %rdx, %r15    # *newData
xorq  %r11, %r11    # i = 0

movq	%rdi, %r14		
addq 	%r10, %r14		# imageWidth + padding

movq  %rcx, %rbx    
subq  %r10, %rbx    # imageSize - padding

# RAX -	pomocniczy dla R9
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

loop2:
cmpq  %rdi, %r12    # if(j < imageWidth)
jge   end_loop1

movq  $0, %r9       # sum = 0;
movq  $1, %r8       # counter = 1;
xorq	%rax, %rax
xorq  %r13, %r13    # j+i = 0

# pobranie bajtu pixela
movq  %r11, %r13    # i
addq  %r12, %r13    # i + j
xorq	%r9, %r9
movb  (%rsi,%r13,1), %r9b  # sum += data[i+j];
addq	%r9, %rax

# if(i >= (imageWidth+padding))
cmpq  %r14, %r11    # if(i >= (imageWidth+padding))
jl    else_if_0
# if (true) {}
incq  %r8           # counter++
subq  %r14, %r13    # i+j - (imageWidth+padding)
xorq	%r9, %r9
movb  (%rsi,%r13,1), %r9b # sum += data[i+j-(imageWidth+padding)];
addq	%r9, %rax
addq  %r14, %r13    # i+j

else_if_0:
# if((j-3) > 0)
subq  $3, %r12      # j - 3
cmpq  $0, %r12      # if((j-3) > 0)
jle   else_if_1
# if (true) {}
incq  %r8           # counter++;
subq  $3, %r13      # i+j - 3
xorq	%r9, %r9
movb  (%rsi,%r13,1), %r9b   # sum += data[i+j - 3]
addq	%r9, %rax
addq  $3, %r13      # i+j

else_if_1:
addq  $6, %r12      # j + 3

# if((j+3) < imageWidth)
cmpq  %rdi, %r12
jge   else_if_2
# if (true) {}
incq  %r8           # counter++;
addq  $3, %r13      # i+j + 3
xorq	%r9, %r9
movb  (%rsi,%r13,1), %r9b   # sum += data[i+j + 3]
addq	%r9, %rax
subq  $3, %r13      # i+j

else_if_2:
subq  $3, %r12      # j

# if(i+j+(imageWidth+padding) < (imageSize-padding))
addq  %r14, %r13    # i+j + (imageWidth+padding)
cmpq  %rbx, %r13    # if(i+j+(imageWidth+padding) < (imageSize-padding))
jge   else_if_3
# if (true) {}
incq  %r8           # counter++;
xorq	%r9, %r9
movb  (%rsi,%r13,1), %r9b   # sum += data[i+j+(imageWidth+padding)]
addq	%r9, %rax

else_if_3:
subq  %r14, %r13    # i+j

xorq  %rdx, %rdx
divq  %r8           # sum /= counter
# wynik w %rax
movb  %al, (%r15,%r13,1)    # newdata[i+j] = sum

# zakonczenie petli loop2
incq  %r12          # j + 1
jmp   loop2

end_loop1:
# zakonczenie petli loop1
# i += (imageWidth+padding)
addq  %r14, %r11    # i + (imageWidth+padding)
xorq  %r12, %r12    # j = 0
jmp   loop1

end:
movq  %r15, %rax    # return newdata

movq	%rbp, %rsp
popq  %rbp
ret
# zwrócenie wartości z %rax


