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
.equ SYS_WRITE, 4
.equ SYS_READ, 3
.equ SYS_CLOSE, 6
.equ SYS_EXIT, 1

.equ O_RDONLY, 0
.equ O_CREAT_WRONLY_TRUNC, 03101

#standard file descriptors
.equ STDIN, 0
.equ STDOUT, 1
.equ STDERR, 2

#system call interrupt
.equ LINUX_SYSCALL, 0x80
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
.equ BUFFER_SIZE, 500
.lcomm BUFFER_DATA, BUFFER_SIZE

.text

#STACK POSITIONS
.equ ST_SIZE_RESERVE, 8
.equ ST_FD_IN, -4
.equ ST_FD_OUT, -8
.equ ST_ARGC, 0		#Number of arguments
.equ ST_ARGV_0, 4	#Name of program
.equ ST_ARGV_1, 8	#Input file name
.equ ST_ARGV_2, 12	#Output file name

 .globl _start
_start:
###INITIALIZE PROGRAM###
#save the stack pointer
movl  %esp, %ebp
#Allocate space for our file descriptors
#on the stack
subl  $ST_SIZE_RESERVE, %esp

open_files:
open_fd_in:

###OPEN INPUT FILE###
#open syscall
movl  $SYS_OPEN, %eax			#system call number ($5)
#input filename into %ebx
movl  ST_ARGV_1(%ebp), %ebx		#the address of the first
								#character of the filename
#read-only flag
movl  $O_RDONLY, %ecx 			#read/write intensions
								#0 - for files u want to read from
								#03101 - to write to
#this doesn’t really matter for reading
movl  $0666, %edx 				#0666 - permission set
#call Linux
int   $LINUX_SYSCALL

#a file descriptor is returned in %eax
#it is a number that you use to refer to this file
#throughout your program

store_fd_in:
#save the given file descriptor
movl  %eax, ST_FD_IN(%ebp)

open_fd_out:
###OPEN OUTPUT FILE###
#open the file
movl  $SYS_OPEN, %eax
#output filename into %ebx
movl  ST_ARGV_2(%ebp), %ebx
#flags for writing to the file
movl  $O_CREAT_WRONLY_TRUNC, %ecx
#mode for new file (if it’s created)
movl  $0666, %edx
#call Linux
int   $LINUX_SYSCALL

store_fd_out:
#store the file descriptor here
movl  %eax, ST_FD_OUT(%ebp)

###BEGIN MAIN LOOP###
read_loop_begin:
###READ IN A BLOCK FROM THE INPUT FILE###
movl  $SYS_READ, %eax			#3 - system call for read
#get the input file descriptor
movl  ST_FD_IN(%ebp), %ebx		#file descriptor in %ebx
#the location to read into
movl  $BUFFER_DATA, %ecx 		#the address of a buffer for
								#storing the data
#the size of the buffer
movl  $BUFFER_SIZE, %edx
#Size of buffer read is returned in %eax
int   $LINUX_SYSCALL

#returns the number of characters read from the file
#or an error code (they are always negative numbers)

###EXIT IF WE’VE REACHED THE END###
#check for end of file marker
cmpl  $END_OF_FILE, %eax
#if found or on error, go to the end
jle   end_loop

continue_read_loop:
###CONVERT THE BLOCK TO UPPER CASE###
pushl $BUFFER_DATA			#location of buffer
pushl %eax					#size of the buffer
call  convert_to_upper
popl  %eax					#get the size back
addl $4, %esp				#restore %esp


###WRITE THE BLOCK OUT TO THE OUTPUT FILE###
#size of the buffer
movl  %eax, %edx
movl  $SYS_WRITE, %eax
#file to use
movl  ST_FD_OUT(%ebp), %ebx
#location of the buffer
movl  $BUFFER_DATA, %ecx
int   $LINUX_SYSCALL
###CONTINUE THE LOOP###
jmp   read_loop_begin
end_loop:
###CLOSE THE FILES###
#NOTE - we don’t need to do error checking
#       on these, because error conditions
#       don’t signify anything special here
movl  $SYS_CLOSE, %eax
movl  ST_FD_OUT(%ebp), %ebx
int   $LINUX_SYSCALL

movl  $SYS_CLOSE, %eax
movl  ST_FD_IN(%ebp), %ebx
int   $LINUX_SYSCALL

###EXIT###
movl  $SYS_EXIT, %eax
movl  $0, %ebx
int   $LINUX_SYSCALL



