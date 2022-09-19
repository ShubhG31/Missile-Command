
# mp1.S - missile-command version
# Good luck, and have fun!

.data
	
    # Constants for accessing the fields of a struct missile, 
    # struct missile is defined in rtc.h and mp1.h

	NEXT 	  = 0
	X	  = 4
	Y	  = 8
	VX	  = 12
	VY	  = 16
	DEST_X	  = 20
	DEST_Y	  = 24
	EXPLODED  = 28
	C	  = 32

    # Character to draw for an explosion - '@'

	EXPLOSION = 64


# Data shared between this file and rtc.c helper functions

# This '.globl' directive makes these symbols visible externally
.globl mp1_missile_list, base_alive, mp1_score

mp1_missile_list:	.long 0x0	# Head of list pointer
base_alive:		.long 0x0	# Array of 3 bytes, plus a padding byte
mp1_score:		.long 0x0	# Player's current score


prev_missile_ptr: .long 0x0		# the ptr of the previous missile
base_counter_max: .long 0x00000002
get_status_ptr: .long 0x0	# holds the value needed in get status 

# base_start: .long 0x00000F74,0x00000F4C,0x00000F24
base_start: .long 0x00000F24,0x00000F4C,0x00000F74
missile_struct_size: .long 0x24 		# 0x24 in decimal is 36 
# Data private to this  file

base_pic:     	    .string "/^^^\\"	# Picture of a live base
dead_base_pic: 	    .string "xxxxx"	# Picture of a dead base
crosshairs_x:		.long 0x0	# X-position of the crosshairs
crosshairs_y:		.long 0x0	# Y-position of the crosshairs

.text

# void mp1_poke(void);
# You can use this function to write to video memory.
#
# Interface: Register-based arguments (not C-style)
#    Inputs: %cl  - The byte you wish to write
#            %eax - Offset from the start of video memory that you wish
#                   to write to
#   Outputs: Text-mode video screen is written to at location %eax with
#            the byte in %cl
# Registers: Clobbers EDX
.align 4
mp1_poke:
		movl    vmem_base_addr(,1),%edx
		movb    %cl,(%edx,%eax,1)
		ret

#   ----------------- Exported functions ---------------------

# void mp1_rtc_tasklet(unsigned long garbage);
# Performs three tasks:
#	(1) updates the list of missiles (implement this in update_missiles,
#           below, and call it from here).
#	(2) Redraw the bases - they may have been overwritten with missiles
#	(3) Redraw the crosshairs - it may have been overwritten with missiles
# Inputs   : none
# Outputs  : none
# Registers: Standard C calling convention

	


.globl mp1_rtc_tasklet
mp1_rtc_tasklet:
		pushl %ebp 
		movl %esp, %ebp 
		pushl %esi
		pushl %ebx
		pushl %edi
		
		call update_missiles # updates the missiles struct linked list 
		#redraw bases 
		jmp drawbase
	Bases_complete:
		jmp redraw_crosshairs
	Crosshairs_complete:
		popl %edi 
		popl %ebx
		popl %esi
		leave
		ret
drawbase:
	xorl %eax, %eax
	xorl %ebx, %ebx		# counter for printing base 3 times 
	xorl %ecx, %ecx 	# used for mp1_poke
	xorl %edx, %edx 	# used for 

	movl base_alive, %edx 

	movl $0, %ebx
	base:		
		# cmpl count_base, %ebx 
		cmpl base_counter_max, %ebx 
		jg drewBases
		pushl %edx
		cmpb $0, %dl
		jle	baseDEAD

	baseAlive:
		movl base_start(,%ebx,4),%eax	# EAX = base_start[countbase]
		movb $47, %cl
		call mp1_poke

		addl $2, %eax 

		movb $94, %cl
		call mp1_poke

		addl $2, %eax 

		movb $94, %cl
		call mp1_poke

		addl $2, %eax 

		movb $94, %cl
		call mp1_poke

		addl $2, %eax 

		movb $92, %cl
		call mp1_poke

		addl $1, %ebx
		popl %edx
		shr $8, %edx
		jmp base
		
	baseDEAD:
		# pushl %edx
		movl base_start(,%ebx,4),%eax	# EAX = base_start[countbase]
		movb $120, %cl
		call mp1_poke

		addl $2, %eax 

		movb $120, %cl
		call mp1_poke

		addl $2, %eax 

		movb $120, %cl
		call mp1_poke

		addl $2, %eax 

		movb $120, %cl
		call mp1_poke

		addl $2, %eax 

		movb $120, %cl
		call mp1_poke

		addl $2, %eax

		addl $1, %ebx
		popl %edx
		shr $8, %edx
		jmp base

	drewBases:
		jmp Bases_complete

redraw_crosshairs:
		movl crosshairs_y,%ecx 	# ecx stores the y value of the crosshair 
		movl $160, %eax		   	# EAX = 80columns*2bytes 
		mull %ecx			   	# EAX = 80*2*crosshair_y
		movl %eax, %ebx			# EBX <- EAX
		movl crosshairs_x, %eax	# EAX = crosshair_x
		movl $2,%edx			
		mull %edx				# EAX = crosshair_y*2
		addl %ebx,%eax	# EAX = 80*2*crosshair_x + 2*crosshair_x
		movb $43, %cl
		call mp1_poke
		# leave
		# ret
		jmp Crosshairs_complete


# mp1_missile_remove:
# 	this function removes the missile from the list
#	mp1_missle_remove(missile* prev, missile* remove_Missile)
#	
#	takes 2 arguments to remove the missile:
#		the pointer of the missile before the removed Missile
# 		the pointer of the missile that needs to be removed  
# |____________________|
# |______old_EBP_______| <-ESP, EBP
# |______return_Addr___|
# |_______prev_________|
# |______remove________|
mp1_missile_remove:
	pushl %ebp 
	movl %esp, %ebp 

	pushl %ebx
	pushl %esi
	pushl %edi	
	
	xorl %ebx, %ebx 	# clear ebx to store the previous missile 
	movl 8(%ebp), %ebx	# ebx <- prev missile pointer

	xorl %esi, %esi 	# clear the esi store the previous missile
	movl 12(%ebp), %esi	# esi <- remove_Missile Pointer 

	xorl %edi, %edi 
	movl 0(%esi), %edi	# remove->next pointer saved in edi 
	movl %edi, (%ebx)	# store remove->next in previous->next
	pushl %eax
	pushl %ecx
	pushl %edx
	pushl 12(%ebp)		# push in the pointer of the remove missile 

	call mp1_free		# free the remove missile 

	addl $4, %esp
	popl %edx	
	popl %ecx
	popl %eax

	popl %edi
	popl %esi
	popl %ebx
	
	leave 
	ret



# int mp1_ioctl(unsigned long arg, unsigned int cmd)
# The dispatch function for the MP1 ioctls - should use the cmd argument
# and a jumptable to execute one of the specsific ioctls implemented below.
# Inputs   : unsigned long arg - parameter to the mp1_ioctl_....
#          : unsigned int cmd  - specsifies which mp1_ioctl_... function 
#          :                     to execute
# Outputs  : Returns an integer - depends on which ioctl() function is called
# Registers: Standard C calling convention

.globl mp1_ioctl
mp1_ioctl:
	pushl %ebp
	movl %esp, %ebp
	movl 12(%ebp), %edx	#stores the cmd offset edx
	cmpl $5, %edx 		# compare sif cmd is larger than the allowed of 5 -> its 1 indexed
	jge  Done			
	cmpl $0, %edx 		#compare sif cmd is less than or equal to 0 
	jl Done			# sif less or equal to, Done
	jmp *table(,%edx,4)	# jmp in the table offset by edx * 4 from the base pointer of table 
	table:
		.long mp1_ioctl_startgame, mp1_ioctl_addmissile, mp1_ioctl_movexhairs, mp1_ioctl_getstatus, mp1_ioctl_endgame


# ----------------- Functions private to this file -------------------
#  (1)go through the missile linked list 
#	 (1)check sif the missile is currently exploding or not -- use missile_explode 
#	 (2)sif missile has moved outside of the screen -- x range: 0-79, y range: 0:23
#		 (1)missile should be erased from the screen -- print " " in old place
#		 (2)remove missile from the linked list 
#		 (3)free the memory for that missile -- use mp1_remove_missile
#	 (3)sif missile has reached destination or currently exploding
#		 (1)check if missile has reached its destination -- compare the X,Y to Dest_x, Dest_y
#		 (2)check if missile is currently exploding by other missiles or any cities -- call missile_explode, 
#			return non-zero value sif true, else returns 0 
#		 (3)after calling missile_explode decrement the Explosion Value for the current missile 
#			
# |________________|
# |________________|
# |________________|
# |_____old_ebp____| <- ebp, esp 
# |___return_Addr__|
# |_____old_ebp____|
# |___return_Addr__|
# |_______arg______|

update_missiles:
		pushl %ebp 
		movl %esp, %ebp 

		# callee saving registers
		pushl %ebx
		pushl %esi
		pushl %edi

		# setting local variables to 0 
		xorl %ebx, %ebx		 
		xorl %esi, %esi		# points to the missiles 
		xorl %edi, %edi		

		xorl %edx, %edx		
		movl mp1_missile_list, %esi # move pointer in edx
		movl $mp1_missile_list, %edx	# points to the previous missile
		movl %edx, prev_missile_ptr

	List_loop:	
		cmpl $0, %esi 	# check sif pointer is 0 or not while(root!=0)
		je update_done	# sssif pointer is 0, then leave 

		

		cmpl $0, EXPLODED(%esi)
		jne Explo

		xorl %ebx, %ebx
		movl Y(%esi),%ecx 	# ecx stores the y value of the missile  	# ecx stores the y value of the crosshair 
		# subl VY(%esi), %ecx
		shrl $16, %ecx
		movl $160, %eax		   	# EAX = 80columns*2bytes 
		imull %ecx, %eax			   	# EAX = 80*2*crosshair_y
		movl %eax, %ebx			# EBX <- EAX
		movl X(%esi),%eax	# EAX = crosshair_x
		# subl VX(%esi), %eax
		shrl $16, %eax

		movl $2,%edx			
		imull %edx, %eax		# EAX = crosshair_x*2
		addl %ebx,%eax			# EAX = 80*2*crosshair_y + 2*crosshair_x

		movb $32, %cl			# load CL <- " " -- Space is 32 in decimal

		call mp1_poke			# print space on screen

	# check if missile reached destination
		movl X(%esi), %ebx				# x value of the current missile is stored in ebx 
		shrl $16, %ebx					# shift the ebx value to the right by 16 bits
		cmpl DEST_X(%esi), %ebx			# compare the X of missile to the DEST_X of missile 
		jne  Move_Missile				# if not equal then go to not exploded 

		movl Y(%esi), %ebx				# y value of the current missile is stored in ebx
		shrl $16, %ebx					# shift the ebx value to the right by 16 bits
		cmpl DEST_Y(%esi), %ebx			# compare the Y of the missile to the DEST_Y of missile
		je Explo						# if equal then go to EXPLO for explosion

	 Move_Missile:
		# pushl X(%esi)
		# pushl Y(%esi)
		movl VX(%esi), %edi
		addl %edi,X(%esi)

		movl VY(%esi),%edi
		addl %edi, Y(%esi)



	 	not_exploded:
		xorl %ebx, %ebx
		movl Y(%esi),%ecx 	# ecx stores the y value of the missile 
		shrl $16, %ecx
		movl $160, %eax		   	# EAX = 80columns*2bytes 
		imull %ecx, %eax			   	# EAX = 80*2*crosshair_y
		movl %eax, %ebx			# EBX <- EAX
		movl X(%esi), %eax	# EAX = x
		shrl $16, %eax
			
		imull $2, %eax		# EAX = x*2
		addl %ebx,%eax			# EAX = 80*2*y + 2*x

		movb C(%esi), %cl			# load CL <- " " -- Space is 32 in decimal

		call mp1_poke			# print space on screen


	# changes the x and y values of the missile 
	# Move_Missile:
	# 	movl VX(%esi), %edi
	# 	addl %edi,X(%esi)

	# 	movl VY(%esi),%edi
	# 	addl %edi, Y(%esi)

		#go to next missile 
	remove_prev_missile:
		# xorl %ebx, %ebx
		# popl %ecx 	# ecx stores the y value of the crosshair 
		# # subl VY(%esi), %ecx
		# shrl $16, %ecx
		# movl $160, %eax		   	# EAX = 80columns*2bytes 
		# imull %ecx, %eax			   	# EAX = 80*2*crosshair_y
		# movl %eax, %ebx			# EBX <- EAX
		# popl %eax	# EAX = crosshair_x
		# # subl VX(%esi), %eax
		# shrl $16, %eax

		# movl $2,%edx			
		# imull %edx, %eax		# EAX = crosshair_x*2
		# addl %ebx,%eax			# EAX = 80*2*crosshair_y + 2*crosshair_x

		# movb $32, %cl			# load CL <- " " -- Space is 32 in decimal

		# call mp1_poke			# print space on screen

	Next_missile:
		movl %esi, prev_missile_ptr
		cmpl $0, %esi 
		je List_loop
		movl 0(%esi),%esi		#(root=root->next)
		jmp List_loop
		
	# 	# check i
	Explo:
		pushl %esi
		call missile_explode
		popl %esi

		call mp1_notify_user
		# movl 28(%esi), %edx
		addl $-1, EXPLODED(%esi) # decrements the exploding parameter in the missile struct
		# movl %edx, 28(%esi) 

		movl EXPLODED(%esi), %edx
		cmpl $0,%edx
		je explosion_done
		# stores the explosion symbol "@" in the missile 
		movl $64, C(%esi)
		


	print_Explosion:
		xorl %ebx, %ebx
		movl Y(%esi),%ecx 		# ecx stores the y value of the missile
		shrl $16, %ecx
		movl $160, %eax		   	# EAX = 80columns*2bytes 
		imull %ecx, %eax			   	# EAX = 80*2*cy
		movl %eax, %ebx			# EBX <- EAX
		movl X(%esi), %eax		# EAX = x
		shrl $16, %eax

		movl $2,%edx			
		imull %edx, %eax		# EAX = crosshair_x*2
		addl %ebx,%eax			# EAX = 80*2*y + 2*x

		movb C(%esi), %cl		# load CL <- "@" -- 64 in decimal

		call mp1_poke			# print space on screen
		
		jmp Next_missile

	explosion_done:	
		# clear out the symbol
		xorl %ebx, %ebx
		movl Y(%esi),%ecx 		# ecx stores the y value of the missile
		shrl $16, %ecx
		movl $160, %eax		   	# EAX = 80columns*2bytes 
		imull %ecx, %eax			   	# EAX = 80*2*cy
		movl %eax, %ebx			# EBX <- EAX
		movl X(%esi), %eax		# EAX = x
		shrl $16, %eax

		movl $2,%edx			
		imull %edx, %eax		# EAX = crosshair_x*2
		addl %ebx,%eax			# EAX = 80*2*y + 2*x

		movb $32, %cl			# load CL <- " " -- 32 in decimal

		call mp1_poke			# print space on screen

		# cmpl $0, prev_missile_ptr  # check the prev pointer to see if its is NULL 
		# jne prev_exists			   # if prev ptr exists then go to prev_exists

		# movl 0(%esi), %edx
		# movl %edx, prev_missile_ptr

		# pushl %esi 
		# call mp1_free
		# addl $4, %esp 
		# movl prev_missile_ptr, %esi 
		# movl %esi, mp1_missile_list
		# jmp List_loop
	prev_exists:
		pushl %esi					# push in remove missile pointer
		pushl prev_missile_ptr		# push in previous missile pointer
		call mp1_missile_remove
		popl prev_missile_ptr	# pop the previous missile pointer
		addl $4, %esp	# pop the removed missile pointer
		
		movl prev_missile_ptr,%esi
		movl 0(%esi), %esi	# go to the next missile
		jmp List_loop

	 update_done:
		popl %edi
		popl %esi
		popl %ebx
		leave
		ret
	

mp1_ioctl_startgame:
	#intialize the cross hair values
		# pushl %ebp 
		# movl %esp, %ebp

		movl $40, crosshairs_x	# sets the crosshair y value to 40 
		movl $12, crosshairs_y	# sets the crosshair x value of 12 
		movl $0x00010101, base_alive 	# sets the base alive to 1111
		movl $0, mp1_score 

		leave
		ret

# |________________|
# |________________|
# |________________|
# |_____old_ebp____| <- ebp, esp 
# |___return_Addr__|
# |_____usr_ptr____
mp1_ioctl_addmissile:
		pushl %ebx						# callee save ebx 

		movl 8(%ebp), %ebx 				# save the usr_ptr in ebx 

		# create a kernel heap memory inorder to copy struct from user missile struct
		pushl missile_struct_size		# push arg for malloc for allocation of memory for struct 
		call mp1_malloc					# stores the pointer to struct in eax
		addl $4, %esp					# pop off arg pointer for malloc
		cmpl $0, %eax
		je 	Malloc_fails

		# no need to caller save any registers as none are being used in this function

		# store args for memcpy from user to kernel
		# calling convention in C-- unsigned long mp1_copy_from_user (void *to, const void *from, unsigned long n);
		pushl missile_struct_size	# size of struct 
		pushl %ebx					# user pointer 
		pushl %eax					# kernel struct pointer

		call mp1_copy_from_user 

		popl %ebx				# new kernel struct pointer 
		addl $4, %esp			# pop off user pointer
		addl $4, %esp 			# pop off size of struct 
		

		cmpl $0, %eax			# compare the return value of copy from cpy_from_user to 0 to check
		jne copy_fails

		# copy head pointer of linked list
		movl mp1_missile_list, %edx		# store old head of list in edx
		movl %ebx, mp1_missile_list 	# stores the new head of list
		movl %edx, 0(%ebx)				# moves the old head pointer to the next of the new head
		

		popl %ebx 
		leave
		ret
	 Malloc_fails:
		movl $-1, %eax
		popl %ebx 
		leave 
		ret
	 copy_fails:
		pushl %ebx		# push in kernel struct pointer
		call mp1_free	# free the kernel struct pointer
		addl $4, %esp	# pop the kernel struct pointer
		popl %ebx
		leave 
		ret


mp1_ioctl_movexhairs:

		# pushl %ebp
		# movl %esp, %ebp

		pushl %ebx	#callee save ebx 

		#delete the old crosshair 

		movl crosshairs_y,%ecx 	# ecx stores the y value of the crosshair 
		movl $160, %eax		   	# EAX = 80columns*2bytes 
		mull %ecx			   	# EAX = 80*2*crosshair_y
		movl %eax, %ebx			# EBX <- EAX
		movl crosshairs_x, %eax	# EAX = crosshair_x
		movl $2,%edx			
		mull %edx				# EAX = crosshair_x*2
		addl %ebx,%eax			# EAX = 80*2*crosshair_y + 2*crosshair_x
		movb $32, %cl			# load CL <- " " -- Space is 32 in decimal
		call mp1_poke			# print space on screen

	#start of the changing the xhairs to new values and checking boundaries
	start:	
		xorl %eax, %eax
		xorl %ebx, %ebx
		xorl %ecx, %ecx 
		xorl %edx, %edx 

		movl 8(%ebp), %edx
		movw %dx, %bx				# stores the x value in bx (lower value of xhair_delta_packed)
		addw %bx, crosshairs_x 		# calculates the new x value in ebx
		shr $16, %edx				# right shssift the edx register to load dx with y value offset
		movw %dx, %cx				# stores the y value in cx
		addw %cx, crosshairs_y		# ecx = crosshairs_y + ecx

	x_check:
		xorl %ebx, %ebx
		movl crosshairs_x, %ebx
		cmpw $0, %bx 				# compare crosshair_x<0 
		jle set_x_low				# ssif bx is less than 0 go set the x to 0 
		cmpw $80, %bx				# compare bx>=80 -> upper bounds work 
		jge set_x_max				# sif bx is larger than 24 go set x to 24
		jmp y_check					# go to check the y value 
	y_check: 
		xorl %ecx, %ecx				# clear the ecx register
		movl crosshairs_y, %ecx 	#
		cmpw $0, %cx				#
		jle set_y_low				#
		cmpw $25, %cx 				#
		jge set_y_max				#
		jmp crosshair_values_set	#

	set_x_max:
		movw $79, crosshairs_x		#
		jmp y_check					#

	set_x_low:
		movw $0, crosshairs_x		#
		jmp y_check					#

	set_y_max:
		movw $24, crosshairs_y		#
		jmp crosshair_values_set	#

	set_y_low:
		movw $0, crosshairs_y		#
		jmp crosshair_values_set	#
	crosshair_values_set:  
		popl %ebx	
		leave
		ret




 

# passed in arguement that holds the pointer in the User space 
# mp1 copy from user (void *to, const void *from, unsigned long n);
# |________________|
# |________________|
# |________________|
# |_____old_ebp____| <- ebp, esp 
# |___return_Addr__|
# |_____usr_ptr____

mp1_ioctl_getstatus:

		pushl %edx

		xorl %edx, %edx 
		xorl %edi, %edi

		movl base_alive, %edi

		cmpw $1, %di
		jne next_base_status_2
		addl $1, %edx 


	next_base_status_2:

		shr $8, %edi # shift the base alive number by 
		sal $1, %edx # shift the user return value by 1 bit 

		cmpw $1, %di
		jne next_base_status_3
		addl $1, %edx 

	next_base_status_3:

		shr $8, %edi # shift the base alive number by 
		sal $1, %edx # shift the user return value by 1 bit 

		cmpw $1, %di
		jne base_3_dead
		addl $1, %edx 
	base_3_dead:

		xorl %edi, %edi
		movl %edx, %edi 
		sal $16, %edi
		movw mp1_score, %di
		
		movl %edi, get_status_ptr



		pushl $4
		pushl $get_status_ptr
		pushl 8(%ebp)
		call mp1_copy_to_user 
		
		popl %edx

		leave
		ret

mp1_ioctl_endgame:

		pushl %ebx
		pushl %esi
		pushl %edi
		
		# setting local variables to 0 
		xorl %ebx, %ebx		 
		xorl %esi, %esi		# next missile 
		xorl %edi, %edi		

		movl mp1_missile_list, %esi 
		movl %esi, prev_missile_ptr
		# movl 0(%esi), %edi
	
	free_loop:
		cmpl $0, %esi 			# check sif pointer is 0 or not while(root!=0)
		je endgame_done			# if pointer is 0, then leave 

		movl 0(%esi), %edi		# stores the next 
		movl %edi, mp1_missile_list

		pushl %esi
		call mp1_free
		popl %esi

		movl %edi, %esi
		jmp free_loop

	endgame_done:
		popl %edi 
		popl %esi
		popl %ebx

		leave
		ret
Done:
	leave 
	ret
