	.data

invalid_content_str:	.asciiz	"NaN "
invalid_length_str:		.asciiz	"Large String "
comma:					.asciiz	" "
input_str:				.space	1001
curr_str:				.space	1001


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
	
	slti $t1, $t9, 9				#Check if current substring is longer than 8 characters
	beq $t1, $zero, length_error	#Throw length_error and skip to next comma
	
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
	beq $s0, '\t', space_loop
	beq $s0, $zero, print_strings	#Check if at end of input
	beq $s0, '\n', print_strings	#Check if at end of input
	beq $s0, ',', process_curr		#Process chars at the end of the current substring
	
	j is_valid						#Check if this is a valid char after reading spaces
	

is_valid:
	bne $t8, $zero, main_error		#If previous valid char has been read then NaN
	sb $s0, 0($s1)					#First valid char encountered so save in curr_str
	li $t8, 1						#Set seen valid character flag
	or $s3, $zero, $s1				#Update current string head pointer
	addi $s1, $s1, 1				#Go to next empty place in curr_str
	addi $s2, $s2, 1				#Go to next character from input
	addi $t9, $t9, 1				#Increment current substring length counter (max 8)
	
	j loop							#Back to main loop

	
process_curr:
	la $a0, ($s3)					#Load beginning of current substring into $a0 as argument
	beq $t8, $zero, main_error		#If letter has not been seen then string is not valid
	jal subprogram_2						#Go to subroutine 2
	
	addi $s2, $s2, 1				#Go to next character from input
	and $t8, $t8, $zero				#Reset seen valid character flag
	and $t9, $t9, $zero				#Reset substring counter
	or $s3, $s1, $zero				#Move head pointer of curr_str to next substring beginning
	
	j loop							#Go back to main loop
	
	
print_strings:
	la $a0, ($s3)					#Load beginning of current substring into $a0 as argument
	lb $t1, 0($s3)					#Load first character in current substring
	beq $t1, '\n', end				#Check if at end of input string
	beq $t1, $zero, end				#Check if at end of input string
	jal subprogram_2						#Go to subroutine 2
	j end
	
	
main_error:
	la $a0, invalid_content_str		#Load address of invalid_content_str
	li $v0, 4						#Print invalid_content_str
	syscall
		
	add $s1, $s1, $t9				#Move pointer for writing to current string to an empty cell
	or $s3, $zero, $s1				#Update the head of current string accordingly
	and $t8, $t8, $zero				#Reset seen valid character flag
	and $t9, $t9, $zero				#Reset substring counter
	
	j skip_loop						#Skip to next substring
	

length_error:
	la $a0, invalid_length_str		#Load address of invalid_content_str
	li $v0, 4						#Print invalid_content_str
	syscall
	
	add $s1, $s1, $t9				#Move pointer for writing to current string to an empty cell
	or $s3, $zero, $s1				#Update the head of current string accordingly
	and $t8, $t8, $zero				#Reset seen valid character flag
	and $t9, $t9, $zero				#Reset substring counter
	
	j skip_loop						#Skip to next substring
	

skip_loop:
	addi $s2, $s2, 1				#Go to next character in current string
	lb $s0, 0($s2)					#Load character into $s0
	beq $s0, ',', loop				#Check for spaces at the beginning of new substring
	beq $s0, $zero, print_strings	#Check if at end of input
	beq $s0, '\n', print_strings	#Check if at end of input
	bne $s0, ',', skip_loop			#Continue loop if space is seen
	#sb $s0, 0($s1)					#First valid char encountered so save in curr_str
	#or $s3, $s1, $zero				#If letter is seen then set head of current string accordingly
	#addi $s1, $s1, 1				#Move to next character
	#addi $s2, $s2, 1				#Move to next character
	#addi $t9, $t9, 1				#Update character counter
	
	
	j loop							#Continue loop
	
	
end:
	add $t0, $s2, -1				#Check previous character
	lb $t1, 0($t0)					#Load the character into $t1
	beq $t1, ',', print_end			#If the last character was a comma then we know this was an invalid string
	
	li $v0, 10						#End program
	syscall


print_end:
	la $a0, invalid_content_str		#Load address of invalid_content_str
	li $v0, 4						#Print error message
	syscall
	
	li $v0, 10						#End the program
	syscall
	
subprogram_1:
	sll $t2, $t2, 4					#Multiply by 16
	
	slti $t4, $t3, ':'				#Check if character is a number
	bne $t4, $zero, num_subprogram_1		#Take care of character being a number case
	
	slti $t4, $t3, 'G'				#Check if the character is uppercase
	bne $t4, $zero, upper_subprogram_1		#Take care of character being uppercase
	
	addi $t4, $t3, -87				#Subtract 87 from lowercase to get hexadecimal value
	add $t2, $t2, $t4				#Add translated character to running sum
	
	jr $ra							#Return to subprogram_2
	

num_subprogram_1:
	addi $t4, $t3, -48				#Subract 48 from number to get hexadecimal value					
	add $t2, $t2, $t4				#Add translated character to running sum
	jr $ra							#Return to subprogram_2
	

upper_subprogram_1:
	addi $t4, $t3, -55				#Subract 55 from uppercase to get hexadecimal value
	add $t2, $t2, $t4				#Add translated character to running sum
	
	jr $ra							#Return to subprogram_2
	
	

subprogram_2:
	la $t0, ($a0)					#Load current substring head from argument $a0 into $t0
	addi $sp, $sp, -12				#Make space on the stack for return addresses and return values
	sw $ra, 0($sp)					#Save return address on the stack
	and $t1, $t1, $zero				#Character counter up to value of $t9
	and $t2, $t2, $zero				#Will hold the unsigned integer to be printed
	and $t3, $t3, $zero				#Will hold the characters being read in
	
subprogram_2_loop:
	slt $t4, $t1, $t9				#Check if counter is less than substring length
	beq $t4, $zero, return_subprogram_2	#If equal or greater than, then return from subprogram_2
	lb $t3, 0($t0)					#Load next character into $t3
	
	slti $t4, $t3, '0'				#Check if current character is less than ascii value of '0'
	bne $t4, $zero, subprogram_2_error		#Substring is not a valid string
	
	slti $t4, $t3, 'A'				#Check if current character is less than ascii value of 'A'
	slti $t5, $t3, ':'				#Check if current character is less than ascii value of ':'
	bne $t4, $t5, subprogram_2_error		#If checks are not equal then character is between '9' and 'A'
	
	slti $t4, $t3, 'a'				#Check if current character is less than ascii value of 'a'
	slti $t5, $t3, 'G'				#Check if current character is less than ascii value of 'G'
	bne $t4, $t5, subprogram_2_error		#If checks are not equal then character is between 'F' and 'a'
	
	slti $t4, $t3, 'g'
	beq $t4, $zero, subprogram_2_error		#Substring is not a valid string
	
	jal subprogram_1						#Go to subprogram_1
	
	addi $t1, $t1, 1				#Increment character counter
	addi $t0, $t0, 1				#Go to the next character in the substring
	
	j subprogram_2_loop					#Continue the loop
	
	
subprogram_2_error:
	lw $ra, 0($sp)					#Restore return address from the stack
	addi $sp, $sp, 12				#Return space on the stack
	
	la $a0, invalid_content_str		#Load address of invalid_content_str
	li $v0, 4						#Print invalid_content_str
	syscall
	
	jr $ra							#Return to main/process_curr
	
	
return_subprogram_2:
	li $t4, 10000					#Load 10000 into $t4 for splitting $t2
	divu $t2, $t4					#Split unsigned number of $t2 and $t4
	
	mflo $t5						#Move upper bits into $t5
	sw $t5,  4($sp)					#Save upper bits onto stack
	mfhi $t5						#Move lower bits into $t5
	sw $t5,  8($sp)					#Save lower bits onto stack
	jal subprogram_3						#Go to subroutine 3
	
	lw $ra,	0($sp)					#Restore return address from the stack
	addi $sp, $sp, 12				#Return space on the stack
	jr $ra							#Return to main/process_curr
