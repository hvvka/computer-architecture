.global rozmycieAsm

.data
i:    	 .single 0
#counter: .single 0   R8
#sum:	    .single 0   R9
#newData: .single 0   RAX

.bss
#.comm Blue,   8
#.comm Green,  8
#.comm Red,    8
.comm newData 16

# rozmycieAsm (imageWidth,  *data,  imageSize)
# %rax         %rdi         %rsi    %rdx

.type rozmycieAsm @function
rozmycieAsm:
pushq   %rbp
movq    %rsp, %rbp


movq  %rdx, %rcx    # pobranie warunku licznika pętli (imageSize)
xorq  %r10, %r10    # i = 0
xorq  %rax, %rax    # newData

movq  $0, %r9       # sum = 0;
movq  $1, %r8       # counter = 1;

# pobranie pixela
addq  (%rsi,%r10,8), %r9  # sum += data[i];

# if((i-3) > 0)
subq  $3, %r10      # i-3
cmpq  $0, %r10      # if((i-3) > 0)
jl    else_if_1
#if (true) {}
incq  %r8           # counter++;
addq  (%rsi,%r10,8), %r9   # sum += data[i-3]

else_if_1:
addq  $6, %rcx      # i+3

# if((i+3) < imageSize)
cmpq  %rdx, %r10
jg    else_if_2
#if (true) {}
incq  %r8           # counter++;
addq  (%rsi,%r10,8), %r9   # sum += data[i+3]

else_if_2:
subq  $2, %r10      # i+1

# if((i+imageWidth + 1) < imageSize)
addq  %rdi, %r10   # i+imageWidth+1
cmpq  %rdx, %r10
jg    else_if_3
#if (true) {}
incq  %r8           # counter++;
addq  (%rsi,%r10,8), %r9   # sum += data[i+imageWidth+1]

else_if_3:
subq  %rdi, %r10    # i+1
subq  $1, %r10      # i
movq  %rdx, %r11    # tmp
xorq  %rdx, %rdx
movq  %r9, %rax     # sum
idivq %r8           # sum /= counter
# wynik w %rax

movq  %rax, newData(,%r10,1)  # newData[i] = sum

movq	%rbp, %rsp
popq  %rbp
ret
# zwrócenie wartości z %rax
