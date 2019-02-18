.global rozmycieAsm

.data

# rozmycieAsm (data,    IMAGE_SIZE/8)
# %rax     %rdi     %rsi

.type rozmycieAsm @function
rozmycieAsm:
pushq   %rbp
movq    %rsp, %rbp

movq	%rbp, %rsp
popq    %rbp
ret
