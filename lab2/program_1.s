#PURPOSE:    This program converts an input file
#            to an output file with all letters
#            converted to uppercase.
#
#PROCESSING: 	1) Open the input file
#				2) Open the output file
#				3) While we’re not at the end of the input file
# 				  	a) read part of file into our memory buffer
#					b) go through each byte of memory
#				        if the byte is a lower-case letter,
#				        convert it to uppercase
# 				    c) write the memory buffer to output file


.data

.equ SYS_OPEN, 5
.equ SYS_WRITE, 1
.equ SYS_READ, 0
.equ SYS_CLOSE, 6
.equ SYS_EXIT, 60

.equ O_RDONLY, 0
.equ O_CREAT_WRONLY_TRUNC, 03101


#standard file descriptors
.equ STDIN, 0
.equ STDOUT, 1
.equ STDERR, 2

.equ END_OF_FILE, 0  #This is the return value
                     #of read which means we’ve
                     #hit the end of the file

.equ NUMBER_ARGUMENTS, 2

.bss
#Buffer - this is where the data is loaded into
#         from the data file and written from
#         into the output file.  This should
#         never exceed 16,000 for various
#         reasons.
.equ BUFFER_SIZE, 512
.lcomm BUFFER_DATA, BUFFER_SIZE

.text

#STACK POSITIONS
.equ ST_SIZE_RESERVE, 16
.equ ST_FD_IN, -8
.equ ST_FD_OUT, -16
.equ ST_ARGC, 0		#Number of arguments
.equ ST_ARGV_0, 8	#Name of program
.equ ST_ARGV_1, 16	#Input file name
.equ ST_ARGV_2, 24	#Output file name

 .globl _start
_start:
###INITIALIZE PROGRAM###
#save the stack pointer
movq  %rsp, %rbp
#Allocate space for our file descriptors
#on the stack
subq  $ST_SIZE_RESERVE, %rsp

open_files:
open_fd_in:

###OPEN INPUT FILE###
#open syscall
movq  $SYS_OPEN, %rax			#system call number ($5)
#input filename into %ebx
movq  ST_ARGV_1(%rbp), %rbx		#the address of the first
								#character of the filename
#read-only flag
movq  $O_RDONLY, %rcx 			#read/write intensions
								#0 - for files u want to read from
								#03101 - to write to
#this doesn’t really matter for reading
movq  $0666, %rdx 				#0666 - permission set
#call Linux
syscall

#a file descriptor is returned in %eax
#it is a number that you use to refer to this file
#throughout your program

store_fd_in:
#save the given file descriptor
movq  %rax, ST_FD_IN(%rbp)

open_fd_out:
###OPEN OUTPUT FILE###
#open the file
movq  $SYS_OPEN, %rax
#output filename into %ebx
movq  ST_ARGV_2(%rbp), %rbx
#flags for writing to the file
movq  $O_CREAT_WRONLY_TRUNC, %rcx
#mode for new file (if it’s created)
movq  $0666, %rdx
#call Linux
syscall

store_fd_out:
#store the file descriptor here
movq  %rax, ST_FD_OUT(%rbp)

###BEGIN MAIN LOOP###
read_loop_begin:
###READ IN A BLOCK FROM THE INPUT FILE###
movq  $SYS_READ, %rax			#3 - system call for read
#get the input file descriptor
movq  ST_FD_IN(%rbp), %rbx		#file descriptor in %rbx
#the location to read into
movq  $BUFFER_DATA, %rcx 		#the address of a buffer for
								#storing the data
#the size of the buffer
movq  $BUFFER_SIZE, %rdx
#Size of buffer read is returned in %eax
syscall

#returns the number of characters read from the file
#or an error code (they are always negative numbers)

###EXIT IF WE’VE REACHED THE END###
#check for end of file marker
cmpl  $END_OF_FILE, %rax
#if found or on error, go to the end
jle   end_loop

###############




###############
###WRITE THE BLOCK OUT TO THE OUTPUT FILE###
#size of the buffer
movq  %rax, %rdx
movq  $SYS_WRITE, %rax
#file to use
movq  ST_FD_OUT(%rbp), %rbx
#location of the buffer
movq  $BUFFER_DATA, %rcx
syscall
###CONTINUE THE LOOP###
jmp   read_loop_begin
end_loop:
###CLOSE THE FILES###
#NOTE - we don’t need to do error checking
#       on these, because error conditions
#       don’t signify anything special here
movq  $SYS_CLOSE, %rax
movq  ST_FD_OUT(%rbp), %rbx
syscall

movq  $SYS_CLOSE, %rax
movq  ST_FD_IN(%rbp), %rbx
syscall

###EXIT###
movq  $SYS_EXIT, %rax
movq  $0, %rbx
syscall



