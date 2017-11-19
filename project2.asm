	.data

invalid_content_str:	.asciiz	"NaN, "
invalid_length_str:		.asciiz	"Invalid Length, "
comma:			.asciiz	", "
input_str:	.space	1001
curr_str:	.space	1001


	.text

main:
	li $v0, 8						#Read in string
	la $a0, input_str				#Store string in buffer
	li $a1, 1001					#Limit size to 1000
	syscall
	#addi $sp, $sp -4				#Make room on the stack for return address
	#sw $ra, 0($sp)					#Save main return address
	
	la $s1, curr_str				#Save address of curr_str in $s1
	la $s2, ($a0)					#Move address of input string to $s2
	la $s3, curr_str				#Copy of curr_str to know where to start printing
	and $t8, $t8, $zero				#Flag when non-terminating char/space has been read
	and $t9, $t9, $zero				#Current string length counter (8 max length)
	
loop:
	lb $s0, 0($s2)					#Load character into $s0
	
	slti $t1, $t9, 9
	beq $t1, $zero, length_error
	
	beq $s0, $zero, print_strings	#Check if at end of input
	beq $s0, '\n', print_strings	#Check if at end of input
	beq $s0, ',', process_curr		#Process chars at the end of the current substring
	beq $s0, ' ', space_loop
	
	li $t8, 1						#Set seen valid character flag
	sb $s0, 0($s1)					#Save character in current string
	addi $s2, $s2, 1				#Go to next character from input
	addi $s1, $s1, 1				#Go to next empty place in curr_str
	addi $t9, $t9, 1				#Increment current substring length counter (max 8)
	
	j loop							#Continue loop
	

space_loop:
	addi $s2, $s2, 1				#Go to next character in current string
	lb $s0, 0($s2)					#Load character into $s0
	beq $s0, ' ', space_loop		#Skip space if at the beginning or at the end
	beq $s0, $zero, print_strings	#Check if at end of input
	beq $s0, '\n', print_strings	#Check if at end of input
	beq $s0, ',', process_curr		#Process chars at the end of the current substring
	
	j is_valid						#Check if this is a valid char after reading spaces
	

is_valid:
	bne $t8, $zero, main_error		#If previous valid char has been read then NaN
	sb $s0, 0($s1)					#First valid char encountered so save in curr_str
	li $t8, 1						#Set seen valid character flag
	or $s3, $zero, $s1
	addi $s1, $s1, 1				#Go to next empty place in curr_str
	addi $s2, $s2, 1				#Go to next character from input
	addi $t9, $t9, 1				#Increment current substring length counter (max 8)
	
	j loop							#Back to main loop

	

	