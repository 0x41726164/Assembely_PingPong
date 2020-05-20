STACK SEGMENT PARA STACK
	DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'

	pixel_x DW 0A0h ;x_position
	pixel_y DW 64h ;y_position
	pixel_color DB 07h
	pixel_velocity_x DW 04h
	pixel_velocity_y DW 02h
	
	pixel_original_x DW 0A0h
	pixel_original_y DW 64h
	
	window_width DW 140h ;320px
	window_height DW 0C8h ;200px
	window_boundary DW 6
	
	pixel_size DW 04h ;quantity of pixels in width and height
	
	temp_time DB 0 ;current time holder (to compare and update)
	
	bar_left_x DW 0Ah
	bar_left_y DW 0Ah
	bar_right_x DW 12Ch
	bar_right_y DW 0Ah
	bar_width DW 05h
	bar_height DW 20h
	bar_velocity DW 10h

DATA ENDS

CODE SEGMENT PARA 'CODE'


	; MAIN FUNCTION --------------------------------------------------------------------------------
	MAIN PROC FAR
	
	ASSUME CS:CODE,DS:DATA,SS:STACK ;assume as code,data and stack segments the respective registers
	PUSH DS ;push to stack the DS segment
	SUB AX,AX ;clear the registers
	PUSH AX ;push AX to the stack
	MOV AX,DATA ;save on the AX register the contents of the DATA segment
	MOV DS,AX ;save on the DS segment the contents of AX
	POP AX ; release top item of stack to AX
	POP AX ; release top item of stack to AX

		CALL paint_screen
		
		check_time:
			MOV AH,2CH ;get sys time
			INT 21h    ;set (CH:hour - CL:min - DH:sec - DL:1/100secs)
			
			CMP DL,temp_time ;comparing 1/100secs to temp_time
			JE check_time ;if equal, check_time
			MOV temp_time,DL ;updating temp_time
			;INC pixel_color
			
			;PAINTING THE BACKGROUND, BLACK (INSTEAD OF CLEARING IT)
			CALL paint_screen
			
			CALL moving_pixels
			CALL generate_resized_pixel ;if not equal, then draw, yo
			
			CALL moving_bars
			CALL draw_bars
			
			JMP check_time ;looping for ever
		
		RET
	MAIN ENDP
	
	; PAINTING SCREEN ------------------------------------------------------------------------------
	paint_screen PROC NEAR
		MOV AH,00h ;video mode
		MOV AL,13h ;video mode screen type (320x200px-256colors)
		INT 10h    ;set
		
;		MOV AH,0Bh ;config
;		MOV BH,01h
;		MOV BL,13 ;background color selection
;		INT 10h    ;set
		
		RET
	paint_screen ENDP
	
	; MOVING PIXELS AND BOUNDARY DETECTION ---------------------------------------------------------
	moving_pixels PROC NEAR
		MOV AX, pixel_velocity_x
		ADD pixel_x,AX		
		MOV AX, pixel_velocity_y
		ADD pixel_y, AX
		
		;ATTENTION: you can delete all the comments, they work just fine as well
		
		;pixel_x comparison
;		MOV AX,window_boundary
;		CMP pixel_x,AX
		CMP pixel_x,03h
		JL reset_position
		
		MOV AX,139h
;		MOV AX,window_width
;		SUB AX,pixel_size
;		SUB AX,window_boundary
		CMP pixel_x,AX
		JG reset_position
		
		;pixel_y comparison
;		MOV AX,window_boundary
;		CMP pixel_y,AX
		CMP pixel_y,03h
		JL velocity_y_negation
		
		MOV AX,0C2h
;		MOV AX,window_height
;		SUB AX,pixel_size
;		SUB AX,window_boundary
		CMP pixel_y,AX
		JG velocity_y_negation
		
		;collision check with left bar --------------------
		MOV AX,pixel_x
		ADD AX,pixel_size
		CMP AX,bar_right_x
		JNG check_collision_with_left_bar
		
		MOV AX,bar_right_x
		ADD AX,bar_width
		CMP pixel_X,AX
		JNL check_collision_with_left_bar
		
		MOV AX,pixel_y
		ADD AX,pixel_size
		CMP AX,bar_right_y
		JNG check_collision_with_left_bar
		
		MOV AX,bar_right_y
		ADD AX,bar_height
		CMP pixel_y,AX
		JNL check_collision_with_left_bar
		
		NEG pixel_velocity_x
		RET
		
		;collision check with right bar -------------------
		check_collision_with_left_bar:
			MOV AX,pixel_x
			SUB AX,pixel_size
			CMP AX,bar_left_x
			JNL exit_pixels_movement_procedure
			
			MOV AX,bar_left_x
			ADD AX,bar_width
			CMP pixel_x,AX
			JNL exit_pixels_movement_procedure
			
			MOV AX,pixel_y
			ADD AX,pixel_size
			CMP AX,bar_left_y
			JNG exit_pixels_movement_procedure
			
;			MOV AX,bar_right_y
;			SUB AX,bar_height
;			CMP pixel_y,AX
;			JNL exit_pixels_movement_procedure
			
			NEG pixel_velocity_x
;			RET
		
			exit_pixels_movement_procedure:
				RET
		
		RET
		
		reset_position:
			CALL reset_pixel_position
			RET
			
		velocity_y_negation:
			NEG pixel_velocity_y
			RET
	moving_pixels ENDP
	
	; BAR CONTROLLER ------------------------------------------------------------------------------
	moving_bars PROC NEAR
		
		; see if any key is being pushed
		MOV AH,01h
		INT 16h
		JZ check_bar_movement_right ;if zero-flag is one, jump to label
		
		; see what key is being pushed (ASCII based)
		MOV AH,00h
		INT 16h
		
		CMP AL,77h ;lowercase 'w' 77
		JE move_left_bar_up
		CMP AL,57h ;capital 'W'
		JE move_left_bar_up
		
		CMP AL,73h ;lowercase 's' 73
		JE move_left_bar_down
		CMP AL,53h ;capital 'S'
		JE move_left_bar_down
		
		JMP check_bar_movement_right
		
		move_left_bar_up:
			MOV AX,bar_velocity
			SUB bar_left_y,AX
			
			CMP bar_left_y,03h ;03h and 0A0h are good disstances
			JL bar_boundary_top_left
			JMP check_bar_movement_right
			
			bar_boundary_top_left:
				MOV bar_left_y,03h
				JMP check_bar_movement_right
		
		move_left_bar_down:
			MOV AX,bar_velocity
			ADD bar_left_y,AX
			
			CMP bar_left_y,0A0h
			JG bar_boundary_bottom_left
			JMP check_bar_movement_right
			
			bar_boundary_bottom_left:
				MOV bar_left_y, 0A0h
				JMP check_bar_movement_right
			
		; RIGHT ----------------------------
		check_bar_movement_right:
			
			CMP AL,38h ;num 8
			JE move_right_bar_up
			
			CMP AL,32h ;num 2
			JE move_right_bar_down
			
			JMP exit_bar_movement
			
			move_right_bar_up:
				MOV AX,bar_velocity
				SUB bar_right_y,AX
				
				CMP bar_right_y,03h ;03h and 0A0h are good disstances
				JL bar_boundary_top_right
				JMP exit_bar_movement
				
				bar_boundary_top_right:
					MOV bar_right_y,03h
					JMP exit_bar_movement
			
			move_right_bar_down:
				MOV AX,bar_velocity
				ADD bar_right_y,AX
				
				CMP bar_right_y,0A0h
				JG bar_boundary_bottom_right
				JMP exit_bar_movement
				
				bar_boundary_bottom_right:
					MOV bar_right_y, 0A0h
					JMP exit_bar_movement
			
			exit_bar_movement:
				RET
		
	moving_bars ENDP
	
	; RESET PIXEL POSITION -------------------------------------------------------------------------
	reset_pixel_position PROC NEAR
		MOV AX,pixel_original_x
		MOV pixel_x,AX
		
		MOV AX,pixel_original_y
		MOV pixel_y,AX
	
		RET
	reset_pixel_position ENDP
	
	; GENERATING THE PIXEL -------------------------------------------------------------------------
	generate_resized_pixel PROC NEAR
	
		MOV CX,pixel_x ;initial position x
		MOV DX,pixel_y ;initial position y
		
		generate_resized_pixel_horizontal:
			MOV AH,0Ch ;pixel config
			MOV AL,pixel_color ;pixel color
			MOV BH,00h ;page number 
			INT 10h    ;set
			
			INC CX ;CX++ -> (x position) increasing by one
			
			MOV AX,CX
			SUB AX,pixel_x
			CMP AX,pixel_size
			JNG generate_resized_pixel_horizontal
			
			MOV CX,pixel_x ;CX gets the initial position x
			INC DX ;DX++ -> (y position) increasing by one
			
			MOV AX,DX
			SUB AX,pixel_y
			CMP AX,pixel_size
			JNG generate_resized_pixel_horizontal
		
		RET
	generate_resized_pixel ENDP
	
	; PRODUCE PING-PONG BARS -----------------------------------------------------------------------
	draw_bars PROC NEAR
	
		; LEFT
		MOV CX,bar_left_x ;initial position x
		MOV DX,bar_left_y ;initial position y
		
		draw_bar_left_horizontal:
			MOV AH,0Ch ;pixel config
			MOV AL,0Ch ;pixel color
			MOV BH,00h ;page number 
			INT 10h    ;set
			
			INC CX ;CX++ -> (x position) increasing by one
			
			MOV AX,CX
			SUB AX,bar_left_x
			CMP AX,bar_width
			JNG draw_bar_left_horizontal
			
			MOV CX,bar_left_x ;CX gets the initial position x
			INC DX ;DX++ -> (y position) increasing by one
			
			MOV AX,DX
			SUB AX,bar_left_y
			CMP AX,bar_height
			JNG draw_bar_left_horizontal
		
		;RIGHT
		MOV CX,bar_right_x ;initial position x
		MOV DX,bar_right_y ;initial position y
		
		draw_bar_right_horizontal:
			MOV AH,0Ch ;pixel config
			MOV AL,09h ;pixel color
			MOV BH,00h ;page number 
			INT 10h    ;set
			
			INC CX ;CX++ -> (x position) increasing by one
			
			MOV AX,CX
			SUB AX,bar_right_x
			CMP AX,bar_width
			JNG draw_bar_right_horizontal
			
			MOV CX,bar_right_x ;CX gets the initial position x
			INC DX ;DX++ -> (y position) increasing by one
			
			MOV AX,DX
			SUB AX,bar_right_y
			CMP AX,bar_height
			JNG draw_bar_right_horizontal
			
		RET
	draw_bars ENDP

CODE ENDS
END
