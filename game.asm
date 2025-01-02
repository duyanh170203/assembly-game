#####################################################################
#
# CSCB58 Winter 2024 Assembly Final Project
# University of Toronto, Scarborough
#
#####################################################################
.eqv REFRESH_RATE 40
.eqv BROWN 0x964b00
.eqv WHITE 0xffffff
.eqv RED 0xff0000
.eqv YELLOW 0xffff00
.eqv BLACK 0x000000
.eqv GREEN 0x00ff00

.data
player_location:	.word	0
player_health:		.word	3
pickup_location:	.word	0
player_score:		.word	0
start_location:		.word	0
jumping_dist:		.word	0
num_jumps:		.word	0
enemy_locations:	.word	0, 0, 0, 0
enemy_direction:	.word	1
pickup_height:		.word	0
pickup_direction:	.word	1
level:			.word	1
level_three_trigger:	.word	0
platform_location:	.word	0

.text
.globl main

main:			lw $t0, level
			bne $t0, 1, level_two
			jal load_level_one
level_two:		bne $t0, 2, level_three
			jal load_level_two
level_three:		bne $t0, 3, game_over
			jal load_level_three
game_over:		bnez $t0, victory
			jal draw_game_over_screen
victory:		jal draw_victory_screen

# Loads the first level
load_level_one:		# Clears the screen
			jal clear_screen
			# Draws the starting platform
			la $t0, 7936($gp)
			li $t1, 8
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			addi $sp, $sp, -4
			sw $t1, 0($sp)
			jal draw_platform
			# Draws the middle platform
			la $t0, 8000($gp)
			la $t1, 32
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			addi $sp, $sp, -4
			sw $t1, 0($sp)
			jal draw_platform
			# Draws the exit platform
			la $t0, 8160($gp)
			li $t1, 8
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			addi $sp, $sp, -4
			sw $t1, 0($sp)
			jal draw_platform
			# Draws the player
			sw $zero, jumping_dist
			sw $zero, num_jumps
			la $t0, 6916($gp)
			sw $t0, start_location
			sw $t0, player_location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal draw_player
			# Draws the player's health bar
			li $t0, 3
			sw $t0, player_health
			jal display_health
			# Draws an enemy
			li $t0, 1
			sw $t0, enemy_direction
			la $t0, 6980($gp)
			sw $t0, enemy_locations
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal draw_enemy
			# Draws a pickup
			li $t0, 1
			sw $t0, pickup_direction
			sw $zero, pickup_height
			la $t0, 7372($gp)
			sw $t0, pickup_location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal draw_pickup
			# Resets the player's score
			sw $zero, player_score

			# Checks for keyboard input
level_one_loop:		li $t0, 0xffff0000
			lw $t1, 0($t0)
			bne $t1, 1, player_state
			lw $t2, 4($t0)
			# If key = 'w' and player has not double-jumped, jumps
			bne $t2, 119, a_entered
			lw $t0, num_jumps
			bge $t0, 2, player_state
			lw $t0, num_jumps
			addi $t0, $t0, 1
			sw $t0, num_jumps
			lw $t0, jumping_dist
			addi $t0, $t0, 10
			sw $t0, jumping_dist
			j player_state
			# If key = 'a', moves player back
a_entered:		bne $t2, 97, d_entered
			lw $t0, player_location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal move_player_back
			j player_state
			# If key = 'd', moves player forward
d_entered:		bne $t2, 100, q_entered
			lw $t0, player_location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal move_player_forward
			j player_state
			# If key = 'q', exit game
q_entered:		bne $t2, 113, r_entered
			li $v0, 10
			syscall
r_entered:		bne $t2, 114, player_state
			li $t0, 1
			sw $t0, level
			j main

			# Moves the player up if jumping
player_state:		lw $t0, jumping_dist
			blez $t0, player_falling
			lw $t0, player_location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal move_player_up
			lw $t0, jumping_dist
			addi $t0, $t0, -1
			sw $t0, jumping_dist
			j enemy_state
			# Applies gravity to player
player_falling:		lw $t0, player_location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal move_player_down
			lw $t0, player_location
			addi $t0, $t0, 0x400
			lw $t0, 0($t0)
			bne $t0, BROWN, enemy_state
			# If player lands on a platform, resets number of consecutive jumps
			li $t0, 0
			sw $t0, num_jumps

			# Updates the enemy's state
enemy_state:		lw $t0, enemy_locations
			beqz $t0, pickup_state	# Branches if no enemy exists
			# Checks whether it is at the left edge of a platform
			addi $t1, $t0, 0x3fc
			lw $t1, 0($t1)
			bne $t1, BLACK, check_right_side
			# Changes direction if at the edge
			li $t1, 1
			sw $t1, enemy_direction
			j check_below
			# Checks whether it is at the right edge of a platform
check_right_side:	addi $t1, $t0, 0x404
			lw $t1, 0($t1)
			bne $t1, BLACK, check_below
			# Changes direction if at the edge
			sw $zero, enemy_direction
			# Checks whether it is on a platform
check_below:		addi $t1, $t0, 0x400
			lw $t1, 0($t1)
			bne $t1, BLACK, move_enemy
			# If not on a platform, erases this enemy
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal erase_enemy
			sw $zero, enemy_locations
			j pickup_state
			# Loads which direction this enemy is moving in into $t1
move_enemy:		lw $t1, enemy_direction
			beqz $t1, enemy_moving_back	# If $t1 = 0, moves this enemy back
			# If $t1 = 1, moves this enemy forward
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal move_enemy_forward
			j pickup_state
enemy_moving_back:	addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal move_enemy_back

			# Updates this level's pickup state
pickup_state:		lw $t0, pickup_location
			beqz $t0, sleep			# Branches if pickup does not exist
			lw $t0, pickup_direction
			beqz $t0, pickup_moving_down	# If pickup_direction = 0, moves this pickup down
			lw $t0, pickup_height
			bge $t0, 8, max_pickup_height	# If pickup_height >= 8, changes direction and moves this pikcup down
			# If pickup_height < 8, moves this pickup up
pickup_moving_up:	jal move_pickup_up
			lw $t0, pickup_height
			addi $t0, $t0, 1
			sw $t0, pickup_height
			j sleep
max_pickup_height:	sw $zero, pickup_direction
pickup_moving_down:	lw $t0, pickup_height
			blez $t0, min_pickup_height	# If pickup_height <= 0, changes direction and moves this pickup up
			# If pickup_height >= 0, moves this pickup down
			jal move_pickup_down
			lw $t0, pickup_height
			addi $t0, $t0, -1
			sw $t0, pickup_height
			j sleep
min_pickup_height:	li $t0, 1
			sw $t0, pickup_direction
			j pickup_moving_up

			# Sleeps the game
sleep:			li $v0, 32
			li $a0, REFRESH_RATE
			syscall
			lw $t0, player_health
			bnez $t0, check_level
			sw $zero, level
			j level_one_done
check_level:		lw $t0, level
			bne $t0, 1, level_one_done
			j level_one_loop

level_one_done:		j main

# Loads level two
load_level_two:		# Clears the screen
			jal clear_screen

			# Draws the platforms
			la $t0, 0x2f00($gp)
			li $t1, 15
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			addi $sp, $sp, -4
			sw $t1, 0($sp)
			jal draw_platform

			la $t0, 0x2954($gp)
			li $t1, 3
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			addi $sp, $sp, -4
			sw $t1, 0($sp)
			jal draw_platform

			la $t0, 0x2378($gp)
			li $t1, 3
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			addi $sp, $sp, -4
			sw $t1, 0($sp)
			jal draw_platform

			la $t0, 0x1d9c($gp)
			li $t1, 3
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			addi $sp, $sp, -4
			sw $t1, 0($sp)
			jal draw_platform

			la $t0, 0x17c0($gp)
			li $t1, 3
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			addi $sp, $sp, -4
			sw $t1, 0($sp)
			jal draw_platform

			la $t0, 0x11e4($gp)
			li $t1, 7
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			addi $sp, $sp, -4
			sw $t1, 0($sp)
			jal draw_platform

			# Draws the player
			sw $zero, jumping_dist
			sw $zero, num_jumps
			la $t0, 0x2b04($gp)
			sw $t0, start_location
			sw $t0, player_location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal draw_player
			# Draws the player's health bar
			li $t0, 3
			sw $t0, player_health
			jal display_health
			# Displays the player's score
			jal display_score

			# Draws the enemies
			la $t0, 0x2558($gp)
			sw $t0, enemy_locations
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal draw_enemy

			la $t0, 0x1f7c($gp)
			sw $t0, enemy_locations + 4
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal draw_enemy

			la $t0, 0x19a0($gp)
			sw $t0, enemy_locations + 8
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal draw_enemy

			la $t0, 0x13c4($gp)
			sw $t0, enemy_locations + 12
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal draw_enemy

			# Draws a pickup
			la $t0, 0xef0($gp)
			sw $t0, pickup_location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal draw_pickup

			# Checks keyboard input
level_two_loop:		li $t0, 0xffff0000
			lw $t1, 0($t0)
			bne $t1, 1, player_state_2
			lw $t2, 4($t0)
			# If key = 'w' and player has not double-jumped, jumps
			bne $t2, 119, a_entered_2
			lw $t0, num_jumps
			bge $t0, 2, player_state_2
			lw $t0, num_jumps
			addi $t0, $t0, 1
			sw $t0, num_jumps
			lw $t0, jumping_dist
			addi $t0, $t0, 10
			sw $t0, jumping_dist
			j player_state_2
			# If key = 'a', moves player back
a_entered_2:		bne $t2, 97, d_entered_2
			lw $t0, player_location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal move_player_back
			j player_state_2
			# If key = 'd', moves player forward
d_entered_2:		bne $t2, 100, q_entered_2
			lw $t0, player_location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal move_player_forward
			j player_state_2
			# If key = 'q', exit game
q_entered_2:		bne $t2, 113, r_entered_2
			li $v0, 10
			syscall
r_entered_2:		bne $t2, 114, player_state_2
			li $t0, 1
			sw $t0, level
			j main

			# Moves the player up if jumping
player_state_2:		lw $t0, jumping_dist
			blez $t0, player_falling_2
			lw $t0, player_location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal move_player_up
			lw $t0, jumping_dist
			addi $t0, $t0, -1
			sw $t0, jumping_dist
			j sleep_2
			# Applies gravity to player
player_falling_2:	lw $t0, player_location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal move_player_down
			lw $t0, player_location
			addi $t0, $t0, 0x400
			lw $t0, 0($t0)
			bne $t0, BROWN, sleep_2
			# If player lands on a platform, resets number of consecutive jumps
			li $t0, 0
			sw $t0, num_jumps

			# Sleeps the game
sleep_2:		li $v0, 32
			li $a0, REFRESH_RATE
			syscall
			lw $t0, player_health
			bnez $t0, check_level_2
			sw $zero, level
			j level_two_done
check_level_2:		lw $t0, level
			bne $t0, 2, level_two_done
			j level_two_loop

level_two_done:		j main

# Loads the final level
			# Clears the screen
load_level_three:	jal clear_screen

			# Draws the platforms
			la $t0, 0x1f00($gp)
			li $t1, 8
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			addi $sp, $sp, -4
			sw $t1, 0($sp)
			jal draw_platform

			la $t0, 0x2720($gp)
			sw $t0, platform_location
			li $t1, 48
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			addi $sp, $sp, -4
			sw $t1, 0($sp)
			jal draw_platform

			la $t0, 0x1fe0($gp)
			li $t1, 8
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			addi $sp, $sp, -4
			sw $t1, 0($sp)
			jal draw_platform

			# Draws the player
			sw $zero, jumping_dist
			sw $zero, num_jumps
			la $t0, 0x1b04($gp)
			sw $t0, start_location
			sw $t0, player_location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal draw_player
			# Draws the player's health bar
			li $t0, 3
			sw $t0, player_health
			jal display_health
			# Displays the player's score
			jal display_score

			# Draws a pickup
			la $t0, 0x1cec($gp)
			sw $t0, pickup_location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal draw_pickup

			# Stores an enemy
			la $t0, 0x237c($gp)
			sw $t0, enemy_locations
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal draw_enemy

			sw $zero, level_three_trigger

			# Checks keyboard input
level_three_loop:	li $t0, 0xffff0000
			lw $t1, 0($t0)
			bne $t1, 1, player_state_3
			lw $t2, 4($t0)
			# If key = 'w' and player has not double-jumped, jumps
			bne $t2, 119, a_entered_3
			lw $t0, num_jumps
			bge $t0, 2, player_state_3
			lw $t0, num_jumps
			addi $t0, $t0, 1
			sw $t0, num_jumps
			lw $t0, jumping_dist
			addi $t0, $t0, 10
			sw $t0, jumping_dist
			j player_state_3
			# If key = 'a', moves player back
a_entered_3:		bne $t2, 97, d_entered_3
			lw $t0, player_location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal move_player_back
			j player_state_3
			# If key = 'd', moves player forward
d_entered_3:		bne $t2, 100, q_entered_3
			lw $t0, player_location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal move_player_forward
			j player_state_3
			# If key = 'q', exit game
q_entered_3:		bne $t2, 113, r_entered_3
			li $v0, 10
			syscall
r_entered_3:		bne $t2, 114, player_state_3
			li $t0, 1
			sw $t0, level
			j main

			# Moves the player up if jumping
player_state_3:		lw $t0, jumping_dist
			blez $t0, player_falling_3
			lw $t0, player_location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal move_player_up
			lw $t0, jumping_dist
			addi $t0, $t0, -1
			sw $t0, jumping_dist
			j level_state
			# Applies gravity to player
player_falling_3:	lw $t0, player_location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal move_player_down
			lw $t0, player_location
			addi $t1, $t0, 0x400
			lw $t2, 0($t1)
			bne $t2, BROWN, level_state
			# If player lands on a platform, resets number of consecutive jumps
			li $t2, 0
			sw $t2, num_jumps
			# If the player is on the lowest platform, changes the state of the level
			la $t2, 0x2700($gp)
			blt $t1, $t2, level_state
			li $t2, 1
			sw $t2, level_three_trigger

			# Checks the level's state
level_state:		lw $t0, level_three_trigger
			beqz $t0, sleep_3		# Branches if the player has not activated this level's trigger
			lw $t0, platform_location
			lw $t1, 0($t0)
			bne $t1, BROWN, reset_platform
			jal erase_platform
			j enemy_state_3
reset_platform:		la $t0, 0x2720($gp)
			sw $t0, platform_location
			li $t1, 48
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			addi $sp, $sp, -4
			sw $t1, 0($sp)
			jal draw_platform
			sw $zero, level_three_trigger

			# Updates the enemy's state
enemy_state_3:		lw $t0, enemy_locations
			beqz $t0, sleep_3	# Branches if no enemy exists
			# Checks whether it is on a platform
check_below_3:		addi $t1, $t0, 0x400
			lw $t1, 0($t1)
			bne $t1, BLACK, sleep_3
			# If not on a platform, erases this enemy
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal erase_enemy
			sw $zero, enemy_locations

			# Sleeps the game
sleep_3:		li $v0, 32
			li $a0, REFRESH_RATE
			syscall
			lw $t0, player_health
			bnez $t0, check_level_3
			sw $zero, level
			j level_three_done
check_level_3:		lw $t0, level
			bne $t0, 3, level_three_done
			j level_three_loop

level_three_done:	j main

# Draws a platfrom given a base address and length in units
draw_platform:		lw $t1, 0($sp)
			lw $t0, 4($sp)
			addi $sp, $sp, 8

			# Finds address of end of platform
			sll $t1, $t1, 2
			add $t1, $t0, $t1
			# Loads color brown
			li $t2, BROWN
			# Draws a 'length' * 2 platform
draw_platform_while:	bge $t0, $t1, draw_platform_end
			sw $t2, 0($t0)
			sw $t2, 0x100($t0)
			addi $t0, $t0, 4
			j draw_platform_while

draw_platform_end:	jr $ra

# Erases a piece of a platform
erase_platform:		lw $t0, platform_location
			li $t1, BLACK
			sw $t1, 0($t0)
			sw $t1, 4($t0)
			sw $t1, 0x100($t0)
			sw $t1, 0x104($t0)
			addi $t0, $t0, 8
			sw $t0, platform_location

			jr $ra

# Draws the player at the given address
draw_player:		lw $t0, 0($sp)
			addi $sp, $sp, 4

			# Draws the player
			li $t1, WHITE
			sw $t1, 0($t0)
			sw $t1, 0x100($t0)
			sw $t1, 0x200($t0)
			sw $t1, 0x300($t0)

			jr $ra

# Draws an enemy at the given address
draw_enemy:		lw $t0, 0($sp)
			addi $sp, $sp, 4

			# Draws an enemy
			li $t1, RED
			sw $t1, 0($t0)
			sw $t1, 0x100($t0)
			sw $t1, 0x200($t0)
			sw $t1, 0x300($t0)

			jr $ra

# Draws a pickup at the given address
draw_pickup:		lw $t0, 0($sp)
			addi $sp, $sp, 4

			# Draws a pickup
			li $t1, YELLOW
			sw $t1, 0($t0)
			sw $t1, 4($t0)
			sw $t1, 0x100($t0)
			sw $t1, 0x104($t0)

			jr $ra

# Erases the player at the given address
erase_player:		lw $t0, 0($sp)
			addi $sp, $sp, 4

			# Erases the player
			li $t1, BLACK
			sw $t1, 0($t0)
			sw $t1, 0x100($t0)
			sw $t1, 0x200($t0)
			sw $t1, 0x300($t0)

			jr $ra

# Moves the player back one unit from the given address
move_player_back:	lw $t0, 0($sp)
			addi $sp, $sp, 4

			# Saves return address
			addi $sp, $sp, -4
			sw $ra, 0($sp)
			# Checks for collision
			addi $t0, $t0, -4
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal check_player_collision
			# Pops returned value from stack into $t0
			lw $t0, 0($sp)
			addi $sp, $sp, 4
			beq $t0, 1, move_player_back_end	# Returns if $t0 = 1
			bne $t0, 2, enemy_collision_back
			# If $t0 = 2, resets the player to beginning of level
			lw $t0, player_health
			addi $t0, $t0, -1
			sw $t0, player_health
			jal display_health
			lw $t0, player_location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal reset_player
			j move_player_back_end
enemy_collision_back:	bne $t0, 3, pickup_collision_back
			# If $t0 = 3, deducts player's health
			lw $t0, player_health
			addi $t0, $t0, -1
			sw $t0, player_health
			jal display_health
			j erase_and_redraw_back
pickup_collision_back:	bne $t0, 4, erase_and_redraw_back
			# If $t0 = 4, collects pickup
			sw $zero, pickup_location
			lw $t0, player_score
			addi $t0, $t0, 1
			sw $t0, player_score
			# Advances the player to the next level
			lw $t0, level
			addi $t0, $t0, 1
			sw $t0, level

			# Erases the player at current address
erase_and_redraw_back:	lw $t0, player_location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal erase_player
			# Redraws the player 1 unit back and saves new location
			lw $t0, player_location
			addi $t0, $t0, -4
			sw $t0, player_location
			addi $sp, $sp, -4
			sw $t0, 0($sp)
			jal draw_player

move_player_back_end:	lw $ra, 0($sp)
			addi $sp, $sp, 4
			jr $ra

# Moves the player forward one unit from the given address
move_player_forward:		lw $t0, 0($sp)
				addi $sp, $sp, 4

				# Saves return address
				addi $sp, $sp, -4
				sw $ra, 0($sp)
				# Checks for collision
				addi $t0, $t0, 4
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal check_player_collision
				# Pops returned value from stack into $t0
				lw $t0, 0($sp)
				addi $sp, $sp, 4
				beq $t0, 1, move_player_forward_end	# Returns if $t0 = 1
				bne $t0, 2, enemy_collision_forward
				# If $t0 = 2, resets the player to beginning of level
				lw $t0, player_health
				addi $t0, $t0, -1
				sw $t0, player_health
				jal display_health
				lw $t0, player_location
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal reset_player
				j move_player_forward_end
enemy_collision_forward:	bne $t0, 3, pickup_collision_forward
				# If $t0 = 3, deducts player's health
				lw $t0, player_health
				addi $t0, $t0, -1
				sw $t0, player_health
				jal display_health
				j erase_and_redraw_forward
pickup_collision_forward:	bne $t0, 4, erase_and_redraw_forward
				# If $t0 = 4, collects pickup
				sw $zero, pickup_location
				lw $t0, player_score
				addi $t0, $t0, 1
				sw $t0, player_score
				# Advances the player to the next level
				lw $t0, level
				addi $t0, $t0, 1
				sw $t0, level

				# Erases the player at current address
erase_and_redraw_forward:	lw $t0, player_location
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal erase_player
				# Redraws player 1 unit forward and saves new location
				lw $t0, player_location
				addi $t0, $t0, 4
				sw $t0, player_location
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal draw_player

move_player_forward_end:	lw $ra, 0($sp)
				addi $sp, $sp, 4
				jr $ra

# Given an address, returns an integer indicating the type of collision, or lack thereof, with the player.
check_player_collision:	lw $t0, 0($sp)
				addi $sp, $sp, 4

				# Checks for collision with either sides of the screen
				li $t1, 0x100
				div $t0, $t1
				mfhi $t1
				bnez $t1, top_collision
				li $t1, 1
				addi $sp, $sp, -4
				sw $t1, 0($sp)
				j check_player_collision_end
				# Checks for collision with top of screen
top_collision:			bge $t0, $gp, bottom_collision
				li $t1, 1
				addi $sp, $sp, -4
				sw $t1, 0($sp)
				j check_player_collision_end
				# Checks for collision with bottom of screen
bottom_collision:		la $t1, 0x3d00($gp)
				blt $t0, $t1, no_screen_collision
				li $t1, 2
				addi $sp, $sp, -4
				sw $t1, 0($sp)
				j check_player_collision_end

				# Checks for object collision (i.e., enemies, platforms, and pickups)
no_screen_collision:		move $t1, $t0
				addi $t2, $t1, 0x400
object_collision:		bge $t1, $t2, no_collision
				lw $t3, 0($t1)
				# Checks for platform collision
				bne $t3, BROWN, enemy_collision
				li $t1, 1
				addi $sp, $sp, -4
				sw $t1, 0($sp)
				j check_player_collision_end
				# Checks for enemy collision
enemy_collision:		bne $t3, RED, pickup_collision
				# Erases enemy before returning if there is collision
				addi $sp, $sp, -4
				sw $ra, 0($sp)
				addi $sp, $sp, -4
				sw $t1, 0($sp)
				jal erase_enemy
				lw $ra, 0($sp)
				addi $sp, $sp, 4
				li $t1, 3
				addi $sp, $sp, -4
				sw $t1, 0($sp)
				j check_player_collision_end
				# Checks for pickup collision
pickup_collision:		bne $t3, YELLOW, object_collision_loop	
				addi $sp, $sp, -4
				sw $ra, 0($sp)
				jal erase_pickup
				lw $ra, 0($sp)
				addi $sp, $sp, 4
				li $t1, 4
				addi $sp, $sp, -4
				sw $t1, 0($sp)
				j check_player_collision_end
object_collision_loop:		addi $t1, $t1, 0x100
				j object_collision
				# No collision detected
no_collision:			li $t1, 0
				addi $sp, $sp, -4
				sw $t1, 0($sp)

check_player_collision_end:	jr $ra

# Moves the player down one unit from the given address
move_player_down:		lw $t0, 0($sp)
				addi $sp, $sp, 4

				# Saves return address
				addi $sp, $sp, -4
				sw $ra, 0($sp)
				# Checks for collision
				addi $t0, $t0, 0x100
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal check_player_collision
				# Pops returned value from stack into $t0
				lw $t0, 0($sp)
				addi $sp, $sp, 4
				beq $t0, 1, move_player_down_end	# Returns if $t0 = 1
				bne $t0, 2, enemy_collision_down
				# If $t0 = 2, resets the player to beginning of level
				lw $t0, player_health
				addi $t0, $t0, -1
				sw $t0, player_health
				jal display_health
				lw $t0, player_location
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal reset_player
				j move_player_down_end
enemy_collision_down:		bne $t0, 3, pickup_collision_down
				# If $t0 = 3, deducts the player's health
				lw $t0, player_health
				addi $t0, $t0, -1
				sw $t0, player_health
				jal display_health
				j erase_and_redraw_down
pickup_collision_down:		bne $t0, 4, erase_and_redraw_down
				# If $t0 = 4, collects pickup
				sw $zero, pickup_location
				lw $t0, player_score
				addi $t0, $t0, 1
				sw $t0, player_score
				# Advances the player to the next level
				lw $t0, level
				addi $t0, $t0, 1
				sw $t0, level

				# Erases the player at current address
erase_and_redraw_down:		lw $t0, player_location
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal erase_player
				# Redraws player 1 unit down and saves new location
				lw $t0, player_location
				addi $t0, $t0, 0x100
				sw $t0, player_location
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal draw_player

move_player_down_end:		lw $ra, 0($sp)
				addi $sp, $sp, 4
				jr $ra

# Resets the player at the given address back to start of level
reset_player:			lw $t0, 0($sp)
				addi $sp, $sp, 4

				# Erases the player
				addi $sp, $sp, -4
				sw $ra, 0($sp)
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal erase_player
				# Redraws the player back at the beginning
				lw $t0, start_location
				sw $t0, player_location
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal draw_player

reset_player_end:		lw $ra, 0($sp)
				addi $sp, $sp, 4
				jr $ra

# Displays the player's health
display_health:		lw $t0, player_health

			# Draws the player's health bar
			la $t1, 260($gp)
			bne $t0, 0, one_life
			li $t0, BLACK
			sw $t0, 0($t1)
			sw $t0, 256($t1)
			sw $t0, 512($t1)
			sw $t0, 4($t1)
			sw $t0, 260($t1)
			sw $t0, 516($t1)
			sw $t0, 8($t1)
			sw $t0, 264($t1)
			sw $t0, 520($t1)
			j display_health_end
			# Player has 1 life left
one_life:		bne $t0, 1, two_lives
			li $t0, RED
			sw $t0, 0($t1)
			sw $t0, 256($t1)
			sw $t0, 512($t1)
			li $t0, BLACK
			sw $t0, 4($t1)
			sw $t0, 260($t1)
			sw $t0, 516($t1)
			sw $t0, 8($t1)
			sw $t0, 264($t1)
			sw $t0, 520($t1)
			j display_health_end
two_lives:		bne $t0, 2, three_lives
			# Player has 2 lives left
			li $t0, RED
			sw $t0, 0($t1)
			sw $t0, 256($t1)
			sw $t0, 512($t1)
			li $t0, YELLOW
			sw $t0, 4($t1)
			sw $t0, 260($t1)
			sw $t0, 516($t1)
			li $t0, BLACK
			sw $t0, 8($t1)
			sw $t0, 264($t1)
			sw $t0, 520($t1)
			j display_health_end
			# Player has three (max) lives
three_lives:		li $t0, RED
			sw $t0, 0($t1)
			sw $t0, 256($t1)
			sw $t0, 512($t1)
			li $t0, YELLOW
			sw $t0, 4($t1)
			sw $t0, 260($t1)
			sw $t0, 516($t1)
			li $t0, GREEN
			sw $t0, 8($t1)
			sw $t0, 264($t1)
			sw $t0, 520($t1)

display_health_end:	jr $ra

# Erases the level's pickup
erase_pickup:		lw $t0, pickup_location
			li $t1, BLACK
			sw $t1, 0($t0)
			sw $t1, 4($t0)
			sw $t1, 256($t0)
			sw $t1, 260($t0)

			jr $ra

# Moves player up one unit
move_player_up:			lw $t0, 0($sp)
				addi $sp, $sp, 4

				# Saves return address
				addi $sp, $sp, -4
				sw $ra, 0($sp)
				# Checks for collision
				addi $t0, $t0, -256
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal check_player_collision
				# Pops returned value from stack into $t0
				lw $t0, 0($sp)
				addi $sp, $sp, 4
				beq $t0, 1, move_player_up_end		# Returns if $t0 = 1
				bne $t0, 2, enemy_collision_up
				# If $t0 = 2, resets the player to beginning of level
				lw $t0, player_health
				addi $t0, $t0, -1
				sw $t0, player_health
				jal display_health
				lw $t0, player_location
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal reset_player
				j move_player_up_end
enemy_collision_up:		bne $t0, 3, pickup_collision_up
				# If $t0 = 3, deducts the player's health
				lw $t0, player_health
				addi $t0, $t0, -1
				sw $t0, player_health
				jal display_health
				j erase_and_redraw_up
pickup_collision_up:		bne $t0, 4, erase_and_redraw_up
				# If $t0 = 4, collects pickup
				sw $zero, pickup_location
				lw $t0, player_score
				addi $t0, $t0, 1
				sw $t0, player_score
				# Advances the player to the next level
				lw $t0, level
				addi $t0, $t0, 1
				sw $t0, level

				# Erases the player at current address
erase_and_redraw_up:		lw $t0, player_location
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal erase_player
				# Redraws player 1 unit down and saves new location
				lw $t0, player_location
				addi $t0, $t0, -256
				sw $t0, player_location
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal draw_player

move_player_up_end:		lw $ra, 0($sp)
				addi $sp, $sp, 4
				jr $ra

# Erases the enemy at the given address
erase_enemy:			lw $t0, 0($sp)
				addi $sp, $sp, 4

				# Finds which enemy to delete
				la $t1, enemy_locations
				la $t2, enemy_locations + 12
find_enemy:			bgt $t1, $t2, erase_enemy_end
				lw $t3, 0($t1)
				beq $t3, $t0, found_enemy
				addi $t4, $t3, 0x100
				beq $t4, $t0, found_enemy
				addi $t4, $t3, 0x200
				beq $t4, $t0, found_enemy
				addi $t4, $t3, 0x300
				beq $t4, $t0, found_enemy
				addi $t1, $t1, 4
				j find_enemy

				# Deletes an enemy
found_enemy:			li $t1, BLACK
				sw $t1, 0($t3)
				sw $t1, 0x100($t3)
				sw $t1, 0x200($t3)
				sw $t1, 0x300($t3)

erase_enemy_end:		jr $ra

# Displays the player's score
display_score:			lw $t0, player_score
				li $t1, 0
				la $t2, 276($gp)
				# Saves return address
				addi $sp, $sp, -4
				sw $ra, 0($sp)
display_score_while:		bge $t1, $t0, display_score_end
				# Saves $t0, $t1, $t2
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				addi $sp, $sp, -4
				sw $t1, 0($sp)
				addi $sp, $sp, -4
				sw $t2, 0($sp)
				# Draws the player's score
				addi $sp, $sp, -4
				sw $t2, 0($sp)
				jal draw_pickup
				# Recovers $t0, $t1, $t2
				lw $t2, 0($sp)
				lw $t1, 4($sp)
				lw $t0, 8($sp)
				addi $sp, $sp, 12
				addi $t1, $t1, 1
				addi $t2, $t2, 12
				j display_score_while

display_score_end:		lw $ra, 0($sp)
				addi $sp, $sp, 4
				jr $ra

# Draws the game over screen
				# Clears the screen
draw_game_over_screen:		jal clear_screen

				la $t0, 0x504($gp)
				li $t1, WHITE
				sw $t1, 0($t0)
				sw $t1, 0x100($t0)
				sw $t1, 0x204($t0)
				sw $t1, 0x208($t0)
				sw $t1, 0x20c($t0)
				sw $t1, 0x10c($t0)
				sw $t1, 0x00c($t0)
				sw $t1, 0x30c($t0)
				sw $t1, 0x408($t0)
				sw $t1, 0x404($t0)
				sw $t1, 0x400($t0)

				sw $t1, 0x018($t0)
				sw $t1, 0x01c($t0)
				sw $t1, 0x020($t0)
				sw $t1, 0x124($t0)
				sw $t1, 0x224($t0)
				sw $t1, 0x324($t0)
				sw $t1, 0x420($t0)
				sw $t1, 0x41c($t0)
				sw $t1, 0x418($t0)
				sw $t1, 0x314($t0)
				sw $t1, 0x214($t0)
				sw $t1, 0x114($t0)

				sw $t1, 0x02c($t0)
				sw $t1, 0x12c($t0)
				sw $t1, 0x22c($t0)
				sw $t1, 0x32c($t0)
				sw $t1, 0x430($t0)
				sw $t1, 0x434($t0)
				sw $t1, 0x438($t0)
				sw $t1, 0x33c($t0)
				sw $t1, 0x23c($t0)
				sw $t1, 0x13c($t0)
				sw $t1, 0x03c($t0)

				sw $t1, 0x048($t0)
				sw $t1, 0x148($t0)
				sw $t1, 0x248($t0)
				sw $t1, 0x348($t0)
				sw $t1, 0x448($t0)
				sw $t1, 0x44c($t0)
				sw $t1, 0x450($t0)
				sw $t1, 0x454($t0)

				sw $t1, 0x060($t0)
				sw $t1, 0x064($t0)
				sw $t1, 0x068($t0)
				sw $t1, 0x15c($t0)
				sw $t1, 0x25c($t0)
				sw $t1, 0x35c($t0)
				sw $t1, 0x460($t0)
				sw $t1, 0x464($t0)
				sw $t1, 0x468($t0)
				sw $t1, 0x36c($t0)
				sw $t1, 0x26c($t0)
				sw $t1, 0x16c($t0)

				sw $t1, 0x084($t0)
				sw $t1, 0x080($t0)
				sw $t1, 0x07c($t0)
				sw $t1, 0x078($t0)
				sw $t1, 0x174($t0)
				sw $t1, 0x278($t0)
				sw $t1, 0x27c($t0)
				sw $t1, 0x280($t0)
				sw $t1, 0x384($t0)
				sw $t1, 0x480($t0)
				sw $t1, 0x47c($t0)
				sw $t1, 0x478($t0)
				sw $t1, 0x474($t0)

				sw $t1, 0x08c($t0)
				sw $t1, 0x090($t0)
				sw $t1, 0x094($t0)
				sw $t1, 0x098($t0)
				sw $t1, 0x09c($t0)
				sw $t1, 0x194($t0)
				sw $t1, 0x294($t0)
				sw $t1, 0x394($t0)
				sw $t1, 0x494($t0)

				# Checks keyboard input
game_over_screen_loop:		li $t0, 0xffff0000
				lw $t1, 0($t0)
				bne $t1, 1, sleep_game_over
				lw $t2, 4($t0)
				# If key = 'q', exit game
				bne $t2, 113, r_entered_game_over
				li $v0, 10
				syscall
r_entered_game_over:		bne $t2, 114, sleep_game_over
				# If key = 'r', restarts the game
				li $t0, 1
				sw $t0, level
				j main
				# Sleeps the game
sleep_game_over:		li $v0, 32
				li $a0, REFRESH_RATE
				syscall
				lw $t0, level
				bne $t0, 0, exit_game_over
				j game_over_screen_loop

exit_game_over:			j main

# Draws the victory screen
				# Clears the screen
draw_victory_screen:		jal clear_screen

				la $t0, 0x504($gp)
				li $t1, WHITE
				sw $t1, 0($t0)
				sw $t1, 0x100($t0)
				sw $t1, 0x204($t0)
				sw $t1, 0x208($t0)
				sw $t1, 0x20c($t0)
				sw $t1, 0x10c($t0)
				sw $t1, 0x00c($t0)
				sw $t1, 0x30c($t0)
				sw $t1, 0x408($t0)
				sw $t1, 0x404($t0)
				sw $t1, 0x400($t0)

				sw $t1, 0x018($t0)
				sw $t1, 0x01c($t0)
				sw $t1, 0x020($t0)
				sw $t1, 0x124($t0)
				sw $t1, 0x224($t0)
				sw $t1, 0x324($t0)
				sw $t1, 0x420($t0)
				sw $t1, 0x41c($t0)
				sw $t1, 0x418($t0)
				sw $t1, 0x314($t0)
				sw $t1, 0x214($t0)
				sw $t1, 0x114($t0)

				sw $t1, 0x02c($t0)
				sw $t1, 0x12c($t0)
				sw $t1, 0x22c($t0)
				sw $t1, 0x32c($t0)
				sw $t1, 0x430($t0)
				sw $t1, 0x434($t0)
				sw $t1, 0x438($t0)
				sw $t1, 0x33c($t0)
				sw $t1, 0x23c($t0)
				sw $t1, 0x13c($t0)
				sw $t1, 0x03c($t0)

				sw $t1, 0x048($t0)
				sw $t1, 0x148($t0)
				sw $t1, 0x248($t0)
				sw $t1, 0x348($t0)
				sw $t1, 0x44c($t0)
				sw $t1, 0x350($t0)
				sw $t1, 0x250($t0)
				sw $t1, 0x150($t0)
				sw $t1, 0x050($t0)
				sw $t1, 0x454($t0)
				sw $t1, 0x358($t0)
				sw $t1, 0x258($t0)
				sw $t1, 0x158($t0)
				sw $t1, 0x058($t0)

				sw $t1, 0x060($t0)
				sw $t1, 0x160($t0)
				sw $t1, 0x260($t0)
				sw $t1, 0x360($t0)
				sw $t1, 0x460($t0)

				sw $t1, 0x068($t0)
				sw $t1, 0x168($t0)
				sw $t1, 0x268($t0)
				sw $t1, 0x368($t0)
				sw $t1, 0x468($t0)
				sw $t1, 0x16c($t0)
				sw $t1, 0x270($t0)
				sw $t1, 0x374($t0)
				sw $t1, 0x478($t0)
				sw $t1, 0x378($t0)
				sw $t1, 0x278($t0)
				sw $t1, 0x178($t0)
				sw $t1, 0x078($t0)

				sw $t1, 0x080($t0)
				sw $t1, 0x180($t0)
				sw $t1, 0x280($t0)
				sw $t1, 0x480($t0)

				# Checks keyboard input
victory_screen_loop:		li $t0, 0xffff0000
				lw $t1, 0($t0)
				bne $t1, 1, sleep_victory
				lw $t2, 4($t0)
				# If key = 'q', exit game
				bne $t2, 113, r_entered_victory
				li $v0, 10
				syscall
r_entered_victory:		bne $t2, 114, sleep_victory
				# If key = 'r', restarts the game
				li $t0, 1
				sw $t0, level
				j main
sleep_victory:			# Sleeps the game
				li $v0, 32
				li $a0, REFRESH_RATE
				syscall
				lw $t0, level
				bne $t0, 4, exit_victory
				j victory_screen_loop

exit_victory:			j main

# Moves an enemy back one unit
move_enemy_back:		lw $t0, enemy_locations
				# Saves return address
				addi $sp, $sp, -4
				sw $ra, 0($sp)
				# Checks for collision at new location
				addi $t0, $t0, -4
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal check_object_collision
				# Erases enemy at old location
				lw $t0, enemy_locations
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal erase_enemy
				lw $t0, 0($sp)
				addi $sp, $sp, 4
				beq $t0, 1, player_collision_back	# Branches if colliding with player
				# Updates location
				lw $t0, enemy_locations
				addi $t0, $t0, -4
				sw $t0, enemy_locations
				# Draws enemy at new location
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal draw_enemy
				j move_enemy_back_end
				# Deducts player's health and erases the enemy's location
player_collision_back:		lw $t0, player_health
				addi $t0, $t0, -1
				sw $t0, player_health
				jal display_health
				sw $zero, enemy_locations

move_enemy_back_end:		lw $ra, 0($sp)
				addi $sp, $sp, 4
				jr $ra
				
# Moves an enemy forward one unit
move_enemy_forward:		lw $t0, enemy_locations
				# Saves return address
				addi $sp, $sp, -4
				sw $ra, 0($sp)
				# Checks for collision at new location
				addi $t0, $t0, 4
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal check_object_collision
				# Erases enemy at old location
				lw $t0, enemy_locations
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal erase_enemy
				lw $t0, 0($sp)
				addi $sp, $sp, 4
				beq $t0, 1, player_collision_forward	# Branches if colliding with player
				# Updates location
				lw $t0, enemy_locations
				addi $t0, $t0, 4
				sw $t0, enemy_locations
				# Draws enemy at new location
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal draw_enemy
				j move_enemy_forward_end
				# Deducts the player's health and erases the enemy's location
player_collision_forward:	lw $t0, player_health
				addi $t0, $t0, -1
				sw $t0, player_health
				jal display_health
				sw $zero, enemy_locations

move_enemy_forward_end:	lw $ra, 0($sp)
				addi $sp, $sp, 4
				jr $ra

# Checks for collision for an enemy at the given address
check_object_collision:	lw $t0, 0($sp)
				addi $sp, $sp, 4

				lw $t1, 0($t0)
				bne $t1, WHITE, object_no_collision
				# Returns 1 if colliding with the player
				li $t1, 1
				addi $sp, $sp, -4
				sw $t1, 0($sp)
				j check_object_collision_end
				# Returns 0 if no collision
object_no_collision:		addi $sp, $sp, -4
				sw $zero, 0($sp)

check_object_collision_end:	jr $ra

# Moves a level's pickup up one unit
move_pickup_up:			lw $t0, pickup_location

				# Saves return address
				addi $sp, $sp, -4
				sw $ra, 0($sp)
				# Checks for collision at new location
				addi $t0, $t0, -256
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal check_object_collision
				# Erases pickup at old location
				jal erase_pickup
				lw $t0, 0($sp)
				addi $sp, $sp, 4
				beq $t0, 1, pickup_collected_up
				# If no collision with player, updates pickup location
				lw $t0, pickup_location
				addi $t0, $t0, -256
				sw $t0, pickup_location
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal draw_pickup
				j move_pickup_up_end
				# Sets pickup's location to 0 to signal that it is collected
pickup_collected_up:		sw $zero, pickup_location
				# Increments the player's score
				lw $t0, player_score
				addi $t0, $t0, 1
				sw $t0, player_score
				# Advances the player to the next level
				lw $t0, level
				addi $t0, $t0, 1
				sw $t0, level

move_pickup_up_end:		lw $ra, 0($sp)
				addi $sp, $sp, 4
				jr $ra

# Moves a level's pickup down one unit
move_pickup_down:		lw $t0, pickup_location

				# Saves return address
				addi $sp, $sp, -4
				sw $ra, 0($sp)
				# Checks for collision at new location
				addi $t0, $t0, 0x100
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal check_object_collision
				# Erases pickup at old location
				jal erase_pickup
				lw $t0, 0($sp)
				addi $sp, $sp, 4
				beq $t0, 1, pickup_collected_down
				# If no collision with player, updates pickup location
				lw $t0, pickup_location
				addi $t0, $t0, 0x100
				sw $t0, pickup_location
				addi $sp, $sp, -4
				sw $t0, 0($sp)
				jal draw_pickup
				j move_pickup_down_end
				# Sets pickup's location to 0 to signal that it is collected
pickup_collected_down:		sw $zero, pickup_location
				# Increments the player's score
				lw $t0, player_score
				addi $t0, $t0, 1
				sw $t0, player_score
				# Advances the player to the next level
				lw $t0, level
				addi $t0, $t0, 1
				sw $t0, level

move_pickup_down_end:		lw $ra, 0($sp)
				addi $sp, $sp, 4
				jr $ra

# Clears the screen
clear_screen:			la $t0, 0($gp)
				la $t1, 0x4000($gp)
				li $t2, BLACK

clear_screen_while:		bge $t0, $t1, clear_screen_end
				sw $t2, 0($t0)
				addi $t0, $t0, 4
				j clear_screen_while

clear_screen_end:		jr $ra
