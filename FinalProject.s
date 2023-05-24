.equ IO_BASE, 	 0xff200000
.equ LED,     	 0x00
.equ SWITCH,  	 0x40
.equ BUTTON,  	 0x50
.equ SEG1,    	 0x20
.equ SEG2,    	 0x30
.equ UART,    	 0x1000
.equ TOS,        0x04000000
.equ skele_room, 0x00
.equ empty_room, 0x10
.equ trap_room,  0x20
.equ boss_room,  0x30
.equ num_lines,  10

.macro push reg
	subi sp, sp, 4
	stw \reg, 0(sp)
	.endm
.macro pop reg
	ldw \reg, 0(sp)
	addi sp, sp, 4
	.endm

.global _start

_start:	
	movia sp, TOS
	movia r23, IO_BASE
	movui r2,  0b1111111111									
	stwio r2,  LED(r23)	
	call clear
	
	movia r2, dotted_line		# Introducing the game by writing to UART
	call write					#
	movia r2, new_line			#
	call write					#
	movia r2, game_logo			#
	call write					#
	movia r2, new_line			#
	call write					#
	movia r2, dotted_line		#
	call write					#
	br _stop					#

_stop: br _stop

/**********************************************************
*
*			Subroutines by Marvin Johnson
*
***********************************************************/

write: 								# r2 address of string
	push r16 						# stack	
write_char:
	ldwio r16,     UART+4(r23)		# read control register
	beq   r16, r0, write_char 		# does buffer have room ?
	ldb   r16,(r2) 					# get string character
	beq   r16, r0, _write 			# break if NULL terminator
	stwio r16,     UART(r23) 		# else write to UART
	addi  r2,  r2, 1 				# index next character
	br write_char 					# loop
_write:
	pop r16 					# unstack
	ret
	
check_button:
	ldwio r2,     BUTTON(r23) 		# read button
	andi  r2, r2, 0b01 				# bit mask for button
	bne   r2, r0, button_pressed 	# branch if button down
	br check_button
	
button_pressed:
	ldwio r2,     BUTTON(r23)	    # Loading user selection after
	andi  r2, r2, 0b01			    # button is released and then 
	beq   r2, r0, _stop    			# branching to set_selection
	
random:
	push   r16                 		# stack
	push   r17                 		#
	ldw    r16, rand_seed(r0)  		#  / fetch seed
	addi   r16, r16, 1         		# /
	movia  r17, 3141592621     		#|  make new seed
	mul    r16, r16, r17       		# \ 
 	stw    r16, rand_seed(r0)  		#  \ store new seed
 	ldw    r17, rand_max(r0)   		# generate number
 	mulxuu r16, r16, r17       		# by pulling the hi 32-bits 
 	stw    r16, rand_numb(r0)  		# random number stored in "rand"
 	pop    r17                 		# unstack 
 	pop    r16                 		# 
 	ret
/**********************************************************
*
*					My subroutines
*
***********************************************************/
	
move:
	call random						# Generate a random number to see
	ldw    r2, rand_numb(r0)		# which room the player will go into
									# Branching to a room
clear:
	movia r2, new_line				# This subroutine just 'clears' the
	call write						# UART by writing 10 new, blank lines to it
	movi  r4, 0
	addi  r4, r4, 1					
	movi  r9, 10
	bne   r4, r9, clear
	movi  r4, 0
	ret
									
/**********************************************************
*
*						DATA
*
***********************************************************/
.org 0x1000
.data
/**************************
*		PROMPTS
**************************/
new_line:		   .asciz "                                                                                                    "
dotted_line:       .asciz " +---------------+---------------+---------------+---------------+---------------+---------------+  "
game_logo:         .asciz "                               -=-   D U N G E O N   D I V E R   -=-                                "
game_start:        .asciz "You are a holy knight in search of lost relics and evil to vanquish.                                "
game_start2:       .asciz "An evil sorceror is said to be held up in a nearby dungeon.                                         "
game_start3:       .asciz "You decide to venture within to vanquish the evil.                                                  "
skele_room: 	   .asciz "You enter a room and within a raised skeleton snaps to life and moves to attack you."
empty_room: 	   .asciz "You enter a room and your footsteps echo. Completely Empty.                                         "
trap_room:  	   .asciz "You enter a room and hear a faint click. A trap is sprung and you are hurt!"
boss_room:  	   .asciz "You enter a dark room and see a thin, hooded figure. The sorcerer stands before you                 "
input_prompt: 	   .asciz "You decide to:"
attack_prompt:	   .asciz "[1] Attack"
heal_prompt:	   .asciz "[2] Heal"
dodge_prompt:	   .asciz "[3] Dodge"
forward_prompt:	   .asciz "[1] Forward"
right_prompt:	   .asciz "[2] Right"
left_prompt:	   .asciz "[3] Left"
back_prompt:       .asciz "[4] Back"

/**************************
*		MEMORY
**************************/
rand_max:  		   .word 4        # maximum number (e.g. 100 gets 0-99)
rand_seed: 		   .word 1234567  # seed for random number generator
rand_numb: 		   .word 0        # store random number here

/**********************************************************
*/
						.end
/*
***********************************************************/

