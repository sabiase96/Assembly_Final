.equ IO_BASE, 0xff200000
.equ LED,     0x00
.equ SWITCH,  0x40
.equ BUTTON,  0x50
.equ UART,    0x1000
.equ TOS,     0x04000000

/**********************************************************
*
* 		MACROS
*
***********************************************************/
.macro push reg
	subi sp, sp, 4
	stw \reg, 0(sp)
	.endm
.macro pop reg
	ldw \reg, 0(sp)
	addi sp, sp, 4
	.endm

.macro type
	push ra
	call write
	pop  ra
	.endm
	
.macro clear_terminal
	push  r2
	movi  r2, 0x1b
	stwio r2, UART(r23)
	movi  r2, '['
	stwio r2, UART(r23)
	movi  r2, '2'
	stwio r2, UART(r23)
	movi  r2, 'J'
	stwio r2, UART(r23)
	pop   r2
	.endm
	
.macro move_prompt
	movia r2, new_line
	call write
	call write
	movia r2, prompt
	call write
	movia r2, new_line
	call write
	movia r2, forward_prompt
	call write
	movia r2, new_line
	call write
	movia r2, right_prompt
	call write
	movia r2, new_line
	call write
	movia r2, left_prompt
	call write
	movia r2, new_line
	call write
	movia r2, back_prompt
	call write
	movia r2, new_line
	call write
	.endm
	
.macro combat_prompt
	movia r2, new_line
	type
	type
	movia r2, prompt
	type
	movia r2, new_line
	type
	movia r2, attack_prompt
	type
	movia r2, new_line
	type
	movia r2, dodge_prompt
	type
	movia r2, new_line
	type
	movia r2, heal_prompt
	type
	movia r2, new_line
	type
	.endm
	
.macro boss_combat_prompt
	movia r2, new_line
	type
	type
	movia r2, prompt
	type
	movia r2, new_line
	type
	movia r2, attack_prompt
	type
	movia r2, new_line
	type
	movia r2, dodge_prompt
	type
	movia r2, new_line
	type
	movia r2, heal_prompt
	type
	.endm

/**********************************************************
*
* 		MAIN BRANCH
*
***********************************************************/

.global _start
_start:
	movia sp,  TOS				# use LEDs for healthbar
	movia r23, IO_BASE			#
	movui r3,  0x3ff			# 
	stwio r3,  LED(r23)			#
	
	movi  r10, 1 				# use register 10 for room location, starting in room 1
		
	clear_terminal				# clearing terminal and displaying title
	call title					# prompt user to use button 0 to begin game
	call start_button			#
	call intro					# show intro flavor text after game is started
	
main:
	move_prompt
	br move_button

_stop: br _stop

/**********************************************************
*
* 		MY SUBROUTINES
*
***********************************************************/
	
title: 					# Showing title to UART
	movia r2, new_line		#
	type				#
	movia r2, dotted_line 		#
	type 				#
	movia r2, new_line 		#
	type 				#	
	type 				#
	movia r2, game_logo 		#
	type 				#
	movia r2, new_line 		#
	type 				#
	type 				#
	movia r2, dotted_line 		#
	type 				#
	movia r2, game_start_prompt #
	type 				#
	ret 				#
	
start_button:				#
	ldwio r2, BUTTON(r23)		#
	andi  r2, r2, 0b01		#
	bne   r2, r0, start_check	#
	br start_button			#
start_check:				#
	ldwio r2, BUTTON(r23)		#
	andi  r2, r2, 0b01		#
	cmpeq r4, r2, r0		#
	beq   r4, r0, start_check	#
	ret				#
	
intro:					# Introductory flavor text
	movia r2, new_line		#
	type				#
	type				#
	type				#
	movia r2, game_intro1		#
	type				#
	movia r2, new_line		#
	type				#
	movia r2, game_intro2		#
	type				#
	movia r2, new_line		#
	type				#
	movia r2, game_intro3		#
	type				#
	ret				#


/**********************************************************
*
* 		MOVEMENT SUBROUTINES
*
***********************************************************/
	
move:					# Move subroutine that branches to
	movi r2, 1			# corresponding move subroutine 
	beq  r2, r3, move_forward	# depending on user's selection
	movi r2, 2			#
	beq  r2, r3, move_right		#
	movi r2, 4			#
	beq  r2, r3, move_left		#
	movi r2, 8			#
	beq  r2, r3, move_back		#
					# if a switch outside of 0-3 is used, 
	br wall				# br to wall subroutine
	
/**************************
* 	 FORWARD
**************************/
move_forward:   			# move sub routines that see which
	cmpeqi r5, r10, 4		# room the user is in and changes	
	bne    r5, r0,  wall		# its value based on which direction
	cmpeqi r5, r10, 6		# the player decides to go
	bne    r5, r0,  wall		#
	cmpeqi r5, r10, 8		# re-prompts user if moving to invalid area
	bne    r5, r0,  wall
	cmpeqi r5, r10, 0
	bne    r5, r0,  move_forward0
	cmpeqi r5, r10, 1
	bne    r5, r0,  move_forward1
	cmpeqi r5, r10, 2
	bne    r5, r0,  move_forward2
	cmpeqi r5, r10, 3
	bne    r5, r0,  move_forward3
	cmpeqi r5, r10, 5
	bne    r5, r10, move_forward5
move_forward0:
	movi   r10, 3
	br skeleton
move_forward1:
	movi   r10, 4
	br trap
move_forward2:
	movi   r10, 5
	br trap
move_forward3:
	movi   r10, 6
	br skeleton
move_forward5:
	movi   r10, 8
	br empty
	
/**************************
* 	RIGHT
**************************/
move_right:
	cmpeqi r5, r10, 2
	bne    r5, r0,  wall
	cmpeqi r5, r10, 5
	bne    r5, r0,  wall
	cmpeqi r5, r10, 8
	bne    r5, r0,  wall
	cmpeqi r5, r10, 0
	bne    r5, r0,  move_right0
	cmpeqi r5, r10, 1
	bne    r5, r0,  move_right1
	cmpeqi r5, r10, 3
	bne    r5, r0,  move_right3
	cmpeqi r5, r10, 4
	bne    r5, r0,  move_right4
	cmpeqi r5, r10, 6
	bne    r5, r10, move_right6
move_right0:
	movi   r10, 1
	br empty
move_right1:
	movi   r10, 2
	br skeleton
move_right3:
	movi   r10, 4
	br trap
move_right4:
	movi   r10, 5
	br trap
move_right6:
	movi   r10, 7
	br boss
	
/**************************
* 	LEFT
**************************/
move_left:
	cmpeqi r5, r10, 0
	bne    r5, r0,  wall
	cmpeqi r5, r10, 3
	bne    r5, r0,  wall
	cmpeqi r5, r10, 6
	bne    r5, r0,  wall
	cmpeqi r5, r10, 1
	bne    r5, r0,  move_left1
	cmpeqi r5, r10, 2
	bne    r5, r0,  move_left2
	cmpeqi r5, r10, 4
	bne    r5, r0,  move_left4
	cmpeqi r5, r10, 5
	bne    r5, r0,  move_left5
	cmpeqi r5, r10, 8
	bne    r5, r10, move_left8
move_left1:
	movi   r10, 0
	br empty
move_left2:
	movi   r10, 1
	br empty
move_left4:
	movi   r10, 3
	br skeleton
move_left5:
	movi   r10, 4
	br trap
move_left8:
	movi   r10, 7
	br boss
	
/**************************
* 	BACK
**************************/
move_back:
	cmpeqi r5, r10, 0
	bne    r5, r0,  wall
	cmpeqi r5, r10, 1
	bne    r5, r0,  wall
	cmpeqi r5, r10, 2
	bne    r5, r0,  wall
	cmpeqi r5, r10, 3
	bne    r5, r0,  move_back3
	cmpeqi r5, r10, 4
	bne    r5, r0,  move_back4
	cmpeqi r5, r10, 5
	bne    r5, r0,  move_back5
	cmpeqi r5, r10, 6
	bne    r5, r0,  move_back6
	cmpeqi r5, r10, 8
	bne    r5, r10, move_back8
move_back3:
	movi   r10, 0
	br empty
move_back4:
	movi   r10, 1
	br empty
move_back5:
	movi   r10, 2
	br skeleton
move_back6:
	movi   r10, 3
	br skeleton
move_back8:
	movi   r10, 5
	br trap
	
	
/**********************************************************
*
* 			ROOMS
*
***********************************************************/	
wall:
	movia r2, new_line
	type
	movia r2, wall_text
	type
	br main
	
empty:
	movia r2, new_line
	type
	movia r2, empty_room
	type
	br main
	
skeleton:
	movia r2, new_line
	type
	movia r2, skele_room
	type							# Skeletons take 2 hits to defeat, r9 used to
	movi  r9, 0						# keep track of how many hits the skeleton has taken
	movi  r8, 0						# r8 used for flag to see if user dodged before attacking
	br skele_combat_prompt			#	
	
trap:								# user takes 3 points of damage for landing
	movia  r2, new_line				# on a trap
	type							#
	movia  r2, trap_room			#
	type							#
	ldwio  r3, LED(r23)				#  
	slli   r4, r3, 3				#
	stwio  r4, LED(r23)				#
	andi   r4, r4, 0x3ff			# bit mask for health bar
	beq    r4, r0, death			#
	br main
	
boss:
	movia  r2, new_line
	type
	movia  r2, boss_room
	type
	movia  r2, new_line
	type
	movia  r2, boss_room2
	type
	movi   r20, 5					# boss health. upon reaching 0, is defeated
	br boss_abilities	
	
	
/**********************************************************
*
* 		COMBAT SUBROUTINES
*
***********************************************************/

/**************************
* 	SKELETON
**************************/
skele_combat_prompt:
	bne    r8, r0, dodge_skip			# if user dodged last attack, skeleton is stunned
	movi   r22, 0						# set heal flag to 0
	movi   r21, 0						# reset dodge flag
	movia  r2, new_line					#
	type								#
	movia  r2, skele_attacks_text		#
	type								#
dodge_skip:								#
	combat_prompt						#
	br skele_combat_button				# 
skele_combat:							# reading player input
	cmpeqi r5, r3, 1					#
	bne    r5, r0, attack_skele			#
	cmpeqi r5, r3, 2					#
	bne    r5, r0, dodge_skele			#
	cmpeqi r5, r3, 4
	bne    r5, r0, heal_roll
	br skele_combat_prompt				#
attack_skele:							# 
	bne    r8, r0, damage_skele			# did player dodge first?
	movia  r2, new_line					# then dont take damage
	type								#
	type								#
player_damaged:
	movia  r2, skele_swing_text 		# else user takes damage for not dodging
	type								#
	ldwio  r3, LED(r23)					#  
	slli   r4, r3, 2					#
	stwio  r4, LED(r23)					#
	andi   r4, r4, 0x3ff				# bit mask for health bar
	beq    r4, r0, death				#
	bne   r22, r0, skele_combat_prompt	# if player was healing, go back to prompt
	bne   r21, r0, skele_combat_prompt	# if player was dodging, go back to prompt
damage_skele:							# 
	movi   r8, 0						# reset dodge flag
	movia  r2, new_line					#
	type								#
	movia  r2, damage_skele_text		# 
	type								#
	movia  r2, new_line					#
	type								#	
	addi   r9, r9, 1					# increment hits skeleton has taken
	cmpeqi r7, r9, 2					# and see if it is two yet
	bne    r7, r0, defeat_skele			# skeleton defeated if it is
	br skele_combat_prompt				#
dodge_skele:							#
	movi   r21, 1						# dodge flag
	movia  r2, new_line					#
	type								#
	movia  r2, dodge_skele_text			#
	type								#
	call random							#
	ldw    r8, rand_numb(r0)			# 66.6% chance to dodge attack
	cmpeqi r3, r8, 0					# 
	bne    r3, r0, unsuccessful_dodge	#
	cmpeqi r3, r8, 1					#
	bne    r3, r0, successful_dodge		#
	cmpeqi r3, r8, 2					#
	bne    r3, r0, successful_dodge		#
	br skele_combat_prompt				#
	
successful_dodge:						# player succesfully exectues dodge
	movia  r2, new_line					#
	type								#
	movia  r2, successful_text			#
	type								#
	movia  r2, new_line					#
	type								#
	br skele_combat_prompt				#
	
unsuccessful_dodge:						# player unsuccesfully exectues dodge
	movia  r2, new_line					#
	type								#
	movia  r2, unsuccessful_text		#
	type								#
	movia  r2, new_line					#
	type								#
	br player_damaged					#

defeat_skele:							# display defeated skeleton text
	movia  r2, new_line					# and branch back to movement
	type								#
	movia  r2, defeated_skele_text		#
	type								#
	br main								#
heal_roll:								#
	movi   r22, 1						# heal flag
	call random
	ldw    r5, rand_numb(r0)
	cmpeqi r6, r5, 0
	bne    r6, r0, heal_cast
	cmpeqi r6, r5, 1
	bne    r6, r0, heal_cast
	cmpeqi r6, r5, 2
	bne    r6, r0, heal_miscast
	br skele_combat_prompt
heal_cast:
	movia  r2, new_line
	type
	movia  r2, player_heal_text
	type
	movia  r2, new_line
	type
	ldwio  r3, LED(r23)
	andi   r3, r3, 0x3ff				# bit mask for health bar
	srli   r4, r3, 2					# add two points of health
	addi   r4, r4, 0b1100000000			# replace two most significant bits 
	stwio  r4, LED(r23)
	beq    r8, r0, player_damaged		# if player didn't dodge first, take swing damage
	movi   r8, 0						# reset dodge flag
	br skele_combat_prompt
heal_miscast:
	movia r2, new_line
	type
	movia r2, heal_miscast_text
	type
	movia r2, new_line
	type
	ldwio  r3, LED(r23)					#  
	slli   r4, r3, 4					#
	stwio  r4, LED(r23)					#
	andi   r4, r4, 0x3ff				# bit mask for health bar
	beq    r4, r0, death				#
	beq    r8, r0, player_damaged		# if player didn't dodge first, take swing damage
	movi   r8, 0						# reset dodge flag
	br skele_combat_prompt
	
	
/**************************
* 	BOSS
**************************/	
boss_abilities:							# 
	ldwio  r3, LED(r23)					# player takes 1 health point of damage every
	slli   r4, r3, 1					# turn of combat with boss
	stwio  r4, LED(r23)					#
	andi   r4, r4, 0x3ff				# bit mask for health bar
	beq    r4, r0, death				#
	call random							# random number for boss behavior
	ldw    r11, rand_numb(r0)			# r11 used for storing which ability the boss is 
	cmpeqi r3, r11, 0					# currently doing
	bne    r3, r0, boss_spell			#
	cmpeqi r3, r11, 1					#
	bne    r3, r0, boss_heal			#
	cmpeqi r3, r11, 2					#
	bne    r3, r0, boss_barrier			#
boss_spell:								#
	movia  r2, new_line					#
	type
	type
	movia  r2, boss_spell_text
	type
	boss_combat_prompt
	br boss_combat_button
boss_barrier:
	movia  r2, new_line
	type
	type
	movia  r2, boss_barrier_text
	type
	boss_combat_prompt
	br boss_combat_button
boss_heal:
	movia  r2, new_line
	type
	type
	movia  r2, boss_heal_text
	type
	boss_combat_prompt
	br boss_combat_button
boss_combat:
	boss_combat_prompt
	br boss_combat_button
player_input:
	cmpeqi r5, r3, 1
	bne    r5, r0, player_attack
	cmpeqi r5, r3, 2
	bne    r5, r0, player_dodge
	cmpeqi r5, r3, 4
	bne    r5, r0, player_heal
	br boss_combat
player_attack:
	beq    r11, r0, trade_damage		# if player attacks for boss spell, deal damage, but also take damage
	cmpeqi r5,  r11, 1					#
	bne    r5,  r0, deal_damage			# if player attacks during boss heal, deal damage
	cmpeqi r5,  r11, 2					#
	bne    r5,  r0, take_damage			# if player attacks during boss barrier, take damage
player_dodge:							
	beq    r11, r0, avoid_damage		# if player dodges for boss spell, avoid damage
	cmpeqi r5,  r11, 1					#
	bne    r5,  r0, boss_heal_action	# if player dodges during boss heal, boss heals to full health
	cmpeqi r5,  r11, 2					#
	bne    r5,  r0, boss_abilities		# if player dodges during boss barrier, nothing happens
player_heal:
	beq    r11, r0, take_damage		 	# if player heals for boss spell, take damage
	cmpeqi r5,  r11, 1					#
	bne    r5,  r0, boss_heal_action	# if player heals during boss heal, heal, but boss also heals
	cmpeqi r5,  r11, 2					#
	bne    r5,  r0, player_heal_action	# if player heals during boss barrier, heal for 2 points of health
trade_damage:
	movia  r2, new_line
	type
	movia  r2, boss_damaged_text
	type
	movia  r2, new_line
	type
	movia  r2, boss_spell_hit
	type
	subi   r20, r20, 1					# boss takes a point of damage
	ldwio  r3, LED(r23)					# player takes 5 health point of damage
	slli   r4, r3, 5					# 
	stwio  r4, LED(r23)					#
	andi   r4, r4, 0x3ff				# bit mask for health bar
	beq    r4, r0, death
	br boss_abilities
deal_damage:
	movia  r2, new_line
	type
	type
	movia  r2, boss_damaged_text
	type
	subi  r20, r20, 1					# boss takes damage
	beq   r20, r0, win
	br boss_abilities
take_damage:
	movia  r2, new_line
	type
	type
	movia  r2, boss_spell_hit
	type
	ldwio  r3, LED(r23)					# player takes 5 health point of damage
	slli   r4, r3, 5					# 
	stwio  r4, LED(r23)					#
	andi   r4, r4, 0x3ff				# bit mask for health bar
	beq    r4, r0, death
	br boss_abilities
avoid_damage:
	movia  r2, new_line
	type
	type
	movia  r2, player_dodge_text
	type
	br boss_abilities
boss_heal_action:
	movia  r2, new_line
	type
	type
	movia  r2, boss_heal_hit
	type
	movi   r20, 5						# boss health reset to 5
	cmpeqi r5, r3, 4					#
	bne    r5, r0, player_heal_action	# if player healed, go to heal action
	br boss_abilities					#
player_heal_action:	
	movia  r2, new_line
	type
	type
	movia  r2, player_heal_text
	type
	ldwio  r3, LED(r23)
	andi   r3, r3, 0x3ff				# bit mask for health bar
	srli   r4, r3, 2					# add two points of health
	addi   r4, r4, 0b1100000000			# replace two most significant bits 
	stwio  r4, LED(r23)
	br boss_abilities
	
	
/**************************
* 	WIN & LOSE
**************************/
win:									# player win or lose text
	clear_terminal						# looping back to start
	movia r2, new_line
	type
	movia r2, win_text
	type
	movia r2, new_line
	type
	movia r2, play_again_text
	type
	br play_again_button
death:
	movia  r2, new_line
	type
	type
	movia  r2, death_text
	type
	movia  r2, new_line
	type
	movia  r2, play_again_text
	type
	br play_again_button
	
	
/**********************************************************
*
* 	SUBROUTINES BY MARVIN JOHNSON
*
***********************************************************/

write: 							# r2 address of string
	push  r16 					# stack
	push  r2
write_char:
	ldwio r16,     UART+4(r23)	# read control register
	beq   r16, r0, write_char 	# does buffer have room ?
	ldb   r16,(r2) 				# get string character
	beq   r16, r0, _write 		# break if NULL terminator	
	stwio r16,     UART(r23) 	# else write to UART
	addi  r2,  r2, 1 			# index next character
	br write_char 				# loop
_write:
	pop   r2
	pop   r16 					# unstack
	ret
	
random:
	push   r16                 # stack
	push   r17                 #
	ldw    r16, rand_seed(r0)  #  / fetch seed
	addi   r16, r16, 1         # /
	movia  r17, 3141592621     #|  make new seed
	mul    r16, r16, r17       # \ 
	stw    r16, rand_seed(r0)  #  \ store new seed
	ldw    r17, rand_max (r0)  # generate number
	mulxuu r16, r16, r17       # by pulling the hi 32-bits 
	stw    r16, rand_numb(r0)  # random number stored in "rand"
	pop    r17                 # unstack 
	pop    r16                 # 
	ret
	
	
/**********************************************************
*
* 		BUTTON SUBROUTINES
*
***********************************************************/
move_button:
	ldwio r2,     BUTTON(r23)			# read button
	andi  r2, r2, 0b01 					# bit mask for button
	bne   r2, r0, move_button_pressed 	# branch if button down
	br move_button						#
move_button_pressed:					#
	ldwio r2, BUTTON(r23)				#
	ldwio r3, SWITCH(r23)				#
	andi  r2, r2, 0b01 					#
	beq   r2, r0, move	 				#
	br move_button_pressed 				#
	
skele_combat_button:
	ldwio r2,     BUTTON(r23)					# read button
	andi  r2, r2, 0b01 							# bit mask for button
	bne   r2, r0, skele_combat_button_pressed	# branch if button down
	br skele_combat_button						#
skele_combat_button_pressed:					#
	ldwio r2, BUTTON(r23)						#
	ldwio r3, SWITCH(r23)						#
	andi  r2, r2, 0b01 							#
	beq   r2, r0, skele_combat	 				#
	br skele_combat_button_pressed 				#
												
boss_combat_button:								#
	ldwio r2, BUTTON(r23)						#
	andi  r2, r2, 0b01							#
	bne   r2, r0, boss_button_pressed			#
	br boss_combat_button						#
boss_button_pressed:							#
	ldwio r2, BUTTON(r23)						#
	ldwio r3, SWITCH(r23)						#
	andi  r2, r2, 0b01 							#
	beq   r2, r0, player_input	 				#
	br boss_button_pressed 						#
	
play_again_button:
	ldwio r2, BUTTON(r23)
	andi  r2, r2, 0b01
	bne   r2, r0, play_again_button_pressed
	br play_again_button
play_again_button_pressed:
	ldwio r2, BUTTON(r23)
	andi  r2, r2, 0b01
	cmpeq r4, r2, r0
	beq   r4, r0, _start
	br play_again_button_pressed
	
/**********************************************************
*
* 			DATA
*
***********************************************************/
.org 0x2000
.data
/**************************
* TITLE, INTRO, & NEW LINE
**************************/
new_line:   	     .byte  0x0a, 0x00
dotted_line:         .asciz " +---------------+---------------+---------------+---------------+---------------+---------------+  "
game_logo:           .asciz "                               -=-   D U N G E O N   D I V E R   -=-                                "
game_start_prompt:   .asciz "                                       Use button 0 to start                                        "
game_intro1:         .asciz "You are a holy knight in search of lost relics and evil to vanquish."
game_intro2:         .asciz "An evil sorceror is said to be held up in a nearby dungeon."
game_intro3:         .asciz "You decide to venture within to vanquish the evil."

/**************************
* MOVEMENT PROMPTS
**************************/
forward_prompt:      .asciz "[0] Move Forward"
right_prompt:        .asciz "[1] Move Right"
left_prompt:         .asciz "[2] Move Left"
back_prompt:	     .asciz "[3] Go back"
prompt:              .asciz "You decide to:"
wall_text:  	     .asciz "You go in that direction, but you find only a solid wall."
  
/**************************
* ROOM PROMPTS
**************************/
skele_room:          .asciz "You enter a room and within a raised skeleton snaps to life."
empty_room:   	     .asciz "You enter a room and your footsteps echo. Completely Empty."
trap_room:     	     .asciz "You enter a room and hear a faint click. A trap is sprung and you are hurt!"
boss_room:    	     .asciz "You enter a dark room and see a thin, hooded figure. The sorcerer stands before you."
boss_room2:		     .asciz "A strange aura envelops you. It seems to be draining your life force."

/**************************
* COMBAT PROMPTS
**************************/
attack_prompt:	  	 .asciz "[0] Attack"
dodge_prompt:	  	 .asciz "[1] Dodge"
heal_prompt:	   	 .asciz "[2] Heal"
heal_miscast_text:	 .asciz "The winds of magic are a volatile force..."
skele_attacks_text:  .asciz "The skeleton moves toward you to attack!"
skele_swing_text:	 .asciz "The skeleton swings it's sword and strikes you. You take damage!"
damage_skele_text:   .asciz "You swing your sword and strike the skeleton."
dodge_skele_text:    .asciz "You attempt to dodge the skeleton's attack!"
successful_text:	 .asciz "You dodged the attack! The skeleton is vulnerable!"
unsuccessful_text:	 .asciz "You couldn't dodge the attack!"
defeated_skele_text: .asciz "The skeleton falls to the floor and remains motionless."
boss_spell_text:	 .asciz "The sorceror begins to cast a spell at you."
boss_barrier_text:	 .asciz "The sorceror begins chanting in an alien language. An iridescent barrier forms around him."
boss_heal_text:		 .asciz "The sorceror begins channeling dark magic to mend his wounds."
boss_damaged_text:	 .asciz "You strike the sorceror with your sword!"
boss_spell_hit:		 .asciz "The sorceror's spell hits you!"
boss_heal_hit:		 .asciz "The sorceror finishes his spell, and rejuvinates himself!"
strike_barrier_text: .asciz "You attempt to strike the sorceror, but your sword bounces off his barrier and hurts you!"
player_heal_text:    .asciz "You channel the winds to mend some of your wounds."
player_dodge_text:   .asciz "You dodge the spell!"

/**************************
*  DEATH AND PLAY AGAIN
**************************/
death_text:			 .asciz "YOU DIED!"
win_text:			 .asciz "The sorceror falls to the floor, defeated. You are victorious!"
play_again_text:     .asciz "Press button 0 to play again"

/**************************
*  RANDOM NUMBER DATA
**************************/
.align 2
rand_max:  .word 3	      # maximum number (e.g. 100 gets 0-99)
rand_seed: .word 1234567  # seed for random number generator
rand_numb: .word 0        # store random number here
/**********************************************************
*/
						.end
/*
***********************************************************/

/**************************
* 	 INTRO
**************************/
Upon starting the game, you will be presented with a graphic
and a prompt to press button 0 to start the game. Once you
release button 0, the game will start.

/**************************
* 	 MOVEMENT
**************************/
You will begin in room 1, which is an empty room. You will be 
able to navigate rooms by using switches 0 - 3 for their 
corresponding directions. If there is not a room in the direction 
you have selected, the game will tell you there is a wall there 
and then prompt you to select a new direciton.


/**************************
* 	ROOMS
**************************/
There are 4 different rooms that you can encounter in this game:

	- There is the empty room, which holds nothing within it.
	
	- A skeleton room, which holds a skeleton within that you must 
		defeat before being allowed to continue.
		
	- A trap room, which deals 3 points of damage to the player's 
		health bar.
		
	- The boss room, which holds the boss that the player must 
		defeat to win the game.
		
Rooms are continuous, so if you move into a trap room, trigger
the trap, move to a different room, and back track to the trap room,
you will take another 3 points of damage because the trap is still
active. The same rule applies to skeleton rooms.


/**************************
* 	FINAL BOSS
**************************/
The final boss has three unique abilities as well as a passive aura
that surrounds the player. The aura deals 1 point of health damage 
every turn of combat. So, the player is under constant pressure to 
finish the fight before they run out of health.

The boss' three abilities are:

	- A damaging spell. The boss will begin casting a spell which
		will do heavy damage to the player if it is not avoided.
		
	- A barrier. The boss will surround himself in a barrier that
		protects him from any incoming damage. It also deals damage
		to any would be attackers.
	
	- A heal. The boss will beging casting a healing spell which
		completely restores his health to full if not interupted.
		

/**************************
* 	MAP
**************************/

+--------+		+--------+		+--------+
|        |		|        |		|        |
|Skeleton|------|  Boss  |------| Empty  |
|   6    |		|   7    |		|   8    |
+--------+		+--------+		+--------+
	|								|
	|								|
+--------+      +--------+      +--------+
|        |      |        |      |        |
|Skeleton|------|  Trap  |------|  Trap  |
|   3    |      |   4    |      |   5    |
+--------+      +------─-+      +--------+
	|				|				|
	|				|				|
+--------+      +--------+      +--------+
|        |      |        |      |        |
| Empty  |------| Start  |------|Skeleton|
|   0    |      |   1    |      |   2    |
+--------+      +--------+      +--------+	
