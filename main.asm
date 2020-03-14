;
; a3.asm
;
; Created: 2019-11-10 5:13:07 PM
; Author : Owen Jaques
;

.org 0x0000
	jmp setup

.org 0x0028
	jmp timer1_ISR

.org 0x001E
	jmp timer2_ISR

.org 0x0072

main_loop:
	ldi r16, 1
	push r16
	call updateLCD
	pop r16
	jmp main_loop

setup:
	;initialize the blinking variable to 0
	ldi ZH, high(blinking)
	ldi ZL, low(blinking)
	ldi r16, 0
	st Z, r16

	;initialize the cursor variable to 2
	ldi r16, 2
	ldi ZH, high(cursor)
	ldi ZL, low(cursor)
	st Z, r16

	; initialize the stack pointer
	ldi r16, high(RAMEND)
	out SPH, r16
	ldi r16, low(RAMEND)
	out SPL, r16

	;initialize speed to 0
	ldi ZH, high(speed)
	ldi ZL, low(speed)
	ldi r16, 0
	st Z+, r16
	st Z+, r16
	st Z, r16

	;initialize starting number to 0
	ldi ZH, high(starting_num)
	ldi ZL, low(starting_num)
	st Z+, r16
	st Z+, r16
	st Z, r16

	;initializes count and collatz
	ldi ZH, high(count)
	ldi ZL, low(count)
	st Z+, r16
	st Z+, r16
	st Z, r16
	ldi ZH, high(current_n)
	ldi ZL, low(current_n)
	st Z+, r16
	st Z+, r16
	st Z, r16

	;initialize the LCD
	call lcd_init		
	
	;clear the screen
	call lcd_clr

	;initialize the analog to digital converter
	ldi r16, 0x87
	sts ADCSRA, r16
	ldi r16, 0x40
	sts ADMUX, r16

	; initialize PORTB and PORTL for ouput
	ldi	r16, 0b10101010
	out DDRB, r16
	ldi	r16, 0b00001010
	ldi r16, 0b01010101
	sts PORTL, r16

.equ TIMER1_MAX_COUNT = 0xFFFF
.equ TIMER1_DELAY1 = 977
.equ TIMER1_DELAY2 = 1953
.equ TIMER1_DELAY3 = 3906
.equ TIMER1_DELAY4 = 7813
.equ TIMER1_DELAY5 = 15625
.equ TIMER1_DELAY6 = 23438
.equ TIMER1_DELAY7 = 31250
.equ TIMER1_DELAY8 = 39062
.equ TIMER1_DELAY9 = 46975
.equ SPEED1=TIMER1_MAX_COUNT-TIMER1_DELAY1
.equ SPEED2=TIMER1_MAX_COUNT-TIMER1_DELAY2
.equ SPEED3=TIMER1_MAX_COUNT-TIMER1_DELAY3
.equ SPEED4=TIMER1_MAX_COUNT-TIMER1_DELAY4
.equ SPEED5=TIMER1_MAX_COUNT-TIMER1_DELAY5
.equ SPEED6=TIMER1_MAX_COUNT-TIMER1_DELAY6
.equ SPEED7=TIMER1_MAX_COUNT-TIMER1_DELAY7
.equ SPEED8=TIMER1_MAX_COUNT-TIMER1_DELAY8
.equ SPEED9=TIMER1_MAX_COUNT-TIMER1_DELAY9
timer1_setup:	
	;timer mode	
	ldi r16, 0x00;normal operation
	sts TCCR1A, r16
	ldi r16, (1<<CS12)|(1<<CS10)|(1<<CS11);clock stopped
	com r16
	sts TCCR1B, r16

	; set timer counter to TIMER1_COUNTER_INIT (defined above)
	ldi r16, high(SPEED1)
	sts TCNT1H, r16 	; must WRITE high byte first 
	ldi r16, low(SPEED1)
	sts TCNT1L, r16		; low byte
	
	; allow timer to interrupt the CPU when it's counter overflows
	ldi r16, 1<<TOIE1
	sts TIMSK1, r16

timer2_setup:
	ldi r16, (1<<CS22)|(1<<CS21);clock / 1024
	sts TCCR2B, r16;sets the clock speed
	ldi r16, 0
	sts TCCR2A, r16;sets it to normal operation
	sts TCNT2, r16
	ldi r16, 1<<TOIE2;enables interupts
	sts TIMSK2, r16

	;initialize the first strings
	ldi r16, high(top_row_init << 1)
	push r16
	ldi r16, low(top_row_init << 1)
	push r16

	ldi r16, high(bottom_row_init << 1)
	push r16
	ldi r16, low(bottom_row_init << 1)
	push r16

	call initStrings
	pop r16
	pop r16
	pop r16
	pop r16
	
	;do the start up sequence
	ldi r16, 0
	push r16
	call updateLCD
	pop r16

	;change the lcd strings in memory
	ldi r16, high(top_row_2 << 1)
	push r16
	ldi r16, low(top_row_2 << 1)
	push r16

	ldi r16, high(bottom_row_2 << 1)
	push r16
	ldi r16, low(bottom_row_2 << 1)
	push r16

	call initStrings
	pop r16
	pop r16
	pop r16
	pop r16

	;enable interupts to get the timer going
	sei

	ldi r16, 0
wait_one_second:
	ldi ZH, high(blinking)
	ldi ZL, low(blinking)
	ld r17, Z
	cpi r17, 250
	brsh inc_it
	rjmp wait_one_second
inc_it:
	inc r16
	ldi r17, 255
	cpse r16, r17
	rjmp wait_one_second
	jmp main_loop

;controls the updating of collatz numbers
timer1_ISR:
	push r16
	push ZH
	push ZL
	;reset timer based on speed
	ldi ZH, high(speed)
	ldi ZL, low(speed)
	ld r16, Z
	cpi r16, 0
	brne check_speed1
	ldi r16, (1<<CS12)|(1<<CS10)|(1<<CS11);clock stopped
	com r16
	sts TCCR1B, r16
	jmp end_of_isr
check_speed1:
	cpi r16, 1
	brne check_speed2
	ldi r16, high(SPEED1)
	sts TCNT1H, r16
	ldi r16, low(SPEED1)
	sts TCNT1L, r16
check_speed2:
	cpi r16, 2
	brne check_speed3
	ldi r16, high(SPEED2)
	sts TCNT1H, r16
	ldi r16, low(SPEED2)
	sts TCNT1L, r16
check_speed3:
	cpi r16, 3
	brne check_speed4
	ldi r16, high(SPEED3)
	sts TCNT1H, r16
	ldi r16, low(SPEED3)
	sts TCNT1L, r16
check_speed4:
	cpi r16, 4
	brne check_speed5
	ldi r16, high(SPEED4)
	sts TCNT1H, r16
	ldi r16, low(SPEED4)
	sts TCNT1L, r16
check_speed5:
	cpi r16, 5
	brne check_speed6
	ldi r16, high(SPEED5)
	sts TCNT1H, r16
	ldi r16, low(SPEED5)
	sts TCNT1L, r16
check_speed6:
	cpi r16, 6
	brne check_speed7
	ldi r16, high(SPEED6)
	sts TCNT1H, r16
	ldi r16, low(SPEED6)
	sts TCNT1L, r16
check_speed7:
	cpi r16, 7
	brne check_speed8
	ldi r16, high(SPEED7)
	sts TCNT1H, r16
	ldi r16, low(SPEED7)
	sts TCNT1L, r16
check_speed8:
	cpi r16, 8
	brne check_speed9
	ldi r16, high(SPEED8)
	sts TCNT1H, r16
	ldi r16, low(SPEED8)
	sts TCNT1L, r16
check_speed9:
	cpi r16, 9
	brne end_checks
	ldi r16, high(SPEED9)
	sts TCNT1H, r16
	ldi r16, low(SPEED9)
	sts TCNT1L, r16
end_checks:
	;changes the collatz numbers
	call getNextCollatz
end_of_isr:
	pop ZL
	pop ZH
	pop r16
	reti

;controls the blinking and the button checking
timer2_ISR:
	push ZH
	push ZL
	push r16
	
	ldi ZH, high(blinking)
	ldi ZL, low(blinking)
	ld r16, Z
	inc r16
	st Z, r16

	call checkButton

	pop r16
	pop ZL
	pop ZH
	reti

;initializes strings for the bottom and top row  of the lcd from program memory to data memory
;accepts two parameters: first the top row, second the bottom row (high bytes first)
initStrings:
	push r16
	push ZL
	push ZH

	;copies the first row
	in ZH, SPH
	in ZL, SPL
	ldd r16, Z+10
	push r16
	ldd r16, Z+9
	push r16

	ldi r16, high(top_row)
	push r16
	ldi r16, low(top_row)
	push r16

	call strcpy
	pop r16
	pop r16
	pop r16
	pop r16

	;copies the second row
	ldd r16, Z+8
	push r16
	ldd r16, Z+7
	push r16

	ldi r16, high(bottom_row)
	push r16
	ldi r16, low(bottom_row)
	push r16

	call strcpy
	pop r16
	pop r16
	pop r16
	pop r16

	pop ZH
	pop ZL
	pop r16
	ret

;checks for button presses and sets things accordingly uses global variable last_button_press
checkButton:
	push r16
	push r17
	push r18
	push r19
	push r21
	push r22
	push r24
	push r25
	push r26
	push ZH
	push ZL

	ldi ZH, high(cursor)
	ldi ZL, low(cursor)
	ld r21, Z

	ldi ZH, high(last_button_press)
	ldi ZL, low(last_button_press)
	ld r22, Z

	ldi r24, 0

	;start a2d conversion
	lds	r16, ADCSRA		;get the current value of SDRA
	ori r16, 0x40		;set the ADSC bit to 1 to initiate conversion
	sts	ADCSRA, r16

	;wait for A2D conversion to complete
wait:
	lds r16, ADCSRA
	andi r16, 0x40		;see if conversion is over by checking ADSC bit
	brne wait			;ADSC will be reset to 0 is finished

	;read the value available as 10 bits in ADCH:ADCL
	lds r17, ADCL
	lds r18, ADCH

	;checks left
	ldi r19, 0x02
	cpi r17, 0x2B
	cpc r18, r19
	brsh skip
	ldi r24, 1
	;checks down
	ldi r19, 0x01
	cpi r17, 0x7C
	cpc r18, r19
	brsh skip
	ldi r24, 2
	;checks up
	ldi r19, 0x00
	cpi r17, 0xC3
	cpc r18, r19
	brsh skip
	ldi r24, 3
	;checks right
	ldi r19, 0x00
	cpi r17, 0x32
	cpc r18, r19
	brsh skip
	ldi r24, 4
skip:
	;checks if no button has been pressed or the same button is still being held
	ldi r16, 0
	cpi r24, 0
	breq mid_way_jmp
	cp r22, r24
	breq mid_way_jmp

	;checks right
	cpi r24, 4
	brne check_left
	cpi r21, 4
	breq mid_way_jmp
	inc r21
	jmp mid_way_jmp
check_left:
	cpi r24, 1
	brne check_speed
	cpi r21, 0
	breq mid_way_jmp
	dec r21
	jmp mid_way_jmp
check_speed:
	;checks the speed first
	cpi r21, 4
	brne check_starting_num
	ldi ZH, high(speed)
	ldi ZL, low(speed)
	ld r16, Z
	cpi r24, 3;checks if up
	brne check_down
	cpi r16, 9
	breq mid_way_jmp
	inc r16
	cpi r16, 1
	brne check_down
	;change the speed to 1 on the timer to get the isr going as it was previously 0 and turn it on
	ldi r17, high(SPEED1)
	sts TCNT1H, r17
	ldi r17, low(SPEED1)
	sts TCNT1L, r17
	ldi r17, (1<<CS12)|(1<<CS10);clock / 1024
	sts TCCR1B, r17
check_down:
	cpi r24, 2
	brne dont_dec
	cpi r16, 0
	breq mid_way_jmp
	dec r16
dont_dec:
	st Z, r16

	rjmp skip_this
mid_way_jmp:
	jmp end_of_buttons
skip_this:

check_starting_num:
	cpi r21, 3
	breq check_set_mid
	ldi ZH, high(starting_num)
	ldi ZL, low(starting_num)
	ld r16, Z+
	ld r17, Z
	mov r18, r16;mods the number by 10 r18 will hold the result
	mov r19, r17
	ldi r25, 0
mod_10:
	cpi r18, 10
	cpc r19, r25
	brlo end_of_mod_10
	subi r18, 10
	sbci r19, 0
	rjmp mod_10
end_of_mod_10:
	cpi r21, 2
	brne check_2nd_place
	cpi r24, 2
	breq dec_first_place_instead
add_1_to_fp:
	cpi r18, 9
	breq check_2nd_place
	ldi r18, 1;loads the temp registers for some adding
	ldi r19, 0
	add r16, r18
	adc r17, r19
	rjmp check_2nd_place
dec_first_place_instead:
	cpi r18, 0
	breq check_2nd_place
	subi r16, 1
	sbci r17, 0

rjmp end_of_this_boy
check_set_mid:
	jmp check_set
end_of_this_boy:

check_2nd_place:
	cpi r21, 1
	brne check_3rd_place
	mov r18, r16;divides the number by 10 then mods it by 10 to find the second digit
	mov r19, r17
	ldi r25, 0
	mov r26, r25
divide_by_10:
	cpi r18, 10
	cpc r19, r25
	brlo end_dividing_by_10
	inc r26
	subi r18, 10
	sbci r19, 0
	rjmp divide_by_10
end_dividing_by_10:
	mov r18, r26
mod_10_again:
	cpi r18, 10
	brlo end_of_mod_10_again
	subi r18, 10
	rjmp mod_10_again
end_of_mod_10_again:
	cpi r24, 2
	breq dec_2nd_place
	cpi r18, 9
	breq check_3rd_place
	ldi r18, 10
	add r16, r18
	adc r17, r19
	rjmp check_3rd_place
dec_2nd_place:
	cpi r18, 0
	breq check_3rd_place
	subi r16, 10
	sbci r17, 0
check_3rd_place:
	cpi r21, 0
	brne store_the_numbers_already
	ldi r25, 0
	cpi r24, 2
	breq dec_3rd_place
	mov r18, r16;checks if the third digit is 9
	mov r19, r17
	subi r18, 0x84
	sbci r19, 0x03
	brsh store_the_numbers_already
	ldi r18, 100
	add r16, r18
	adc r17, r25
	rjmp store_the_numbers_already
dec_3rd_place:
	cpi r16, 100;checks if the third digit is 0
	cpc r17, r25
	brlo store_the_numbers_already
	subi r16, 100
	sbci r17, 0
store_the_numbers_already:
	st Z, r17
	st -Z, r16
check_set:
	cpi r21, 3
	brne end_of_buttons

	;changes the starting num to the current n
	ldi ZH, high(starting_num)
	ldi ZL, low(starting_num)
	ld r16, Z+
	ld r17, Z+
	ld r18, Z
	ldi ZH, high(current_n)
	ldi ZL, low(current_n)
	st Z+, r16
	st Z+, r17
	st Z, r18

	;changes the count to 0
	ldi r16, 0
	ldi ZH, high(count)
	ldi ZL, low(count)
	st Z, r16

end_of_buttons:
	ldi ZH, high(last_button_press)
	ldi ZL, low(last_button_press)
	st Z, r24
	ldi ZH, high(cursor)
	ldi ZL, low(cursor)
	st Z, r21
	pop ZL
	pop ZH
	pop r26
	pop r25
	pop r24
	pop r22
	pop r21
	pop r19
	pop r18
	pop r17
	pop r16
	ret

;updates the lcd with the current values of stuff accepts one parameter which is a integer boolean
;0 to not update with the current values of stuff, 1 to update with the current values of stuff
updateLCD:
	push r16
	push r17
	push r18
	push r19
	push r21
	push ZH
	push ZL
	push YH
	push YL

	;gets parameter from stack and determines if it should update the values
	in YH, SPH
	in YL, SPL
	ldd r16, Y+13
	ldi r17, 1
	cpse r16, r17
	jmp skip_blink

	;resets both rows then repopulates with new data to avoid writing over stuff
	ldi r16, high(top_row_2 << 1)
	push r16
	ldi r16, low(top_row_2 << 1)
	push r16

	ldi r16, high(bottom_row_2 << 1)
	push r16
	ldi r16, low(bottom_row_2 << 1)
	push r16

	call initStrings
	pop r16
	pop r16
	pop r16
	pop r16

	;resets speed
	ldi ZH, high(speed)
	push ZH
	ldi ZL, low(speed)
	push ZL
	ldi ZH, high(top_row)
	ldi ZL, low(top_row)
	adiw Z, 14
	push ZH
	push ZL
	call intToString
	pop ZL
	pop ZH
	pop ZL
	pop ZH

	;resets top number
	ldi ZH, high(starting_num)
	ldi ZL, low(starting_num)
	push ZH
	push ZL
	ldi ZH, high(top_row)
	ldi ZL, low(top_row)
	adiw Z, 5
	push ZH
	push ZL
	call intToString
	pop ZL
	pop ZH
	pop ZL
	pop ZH

	;resets count
	ldi ZH, high(count)
	ldi ZL, low(count)
	push ZH
	push ZL
	ldi ZH, high(bottom_row)
	ldi ZL, low(bottom_row)
	adiw Z, 6
	push ZH
	push ZL
	call intToString
	pop ZL
	pop ZH
	pop ZL
	pop ZH

	;resets current collatz
	ldi ZH, high(current_n)
	ldi ZL, low(current_n)
	push ZH
	push ZL
	ldi ZH, high(bottom_row)
	ldi ZL, low(bottom_row)
	adiw Z, 15
	push ZH
	push ZL
	call intToString
	pop ZL
	pop ZH
	pop ZL
	pop ZH

	;blinks the cursor around twice a second
	ldi ZH, high(blinking)
	ldi ZL, low(blinking)
	ld r16, Z
	lsr r16
	ror r16
	ror r16
	ror r16
	ror r16
	ror r16
	ror r16
	ror r16
	brcc skip_blink
	ldi ZH, high(cursor)
	ldi ZL, low(cursor)
	ld r21, Z
	ldi ZH, high(top_row)
	ldi ZL, low(top_row)
	;finds out where the cursor is
	cpi r21, 0
	brne next1
	adiw ZH:ZL, 3
next1:
	cpi r21, 1
	brne next2
	adiw ZH:ZL, 4
next2:
	cpi r21, 2
	brne next3
	adiw ZH:ZL, 5
next3:
	cpi r21, 3
	brne next4
	adiw ZH:ZL, 6
next4:
	cpi r21, 4
	brne next5
	adiw ZH:ZL, 14
next5:
	;sets cursor to blank
	ldi r18, 0x010
	st Z, r18

skip_blink:
	;display first line
	ldi r16, 0
	push r16
	ldi r16, 0
	push r16
	call lcd_gotoxy
	pop r16
	pop r16

	ldi r16, high(top_row)
	push r16
	ldi r16, low(top_row)
	push r16
	call lcd_puts
	pop r16
	pop r16

	;display second line
	ldi r16, 1
	push r16
	ldi r16, 0
	push r16
	call lcd_gotoxy
	pop r16
	pop r16

	ldi r16, high(bottom_row)
	push r16
	ldi r16, low(bottom_row)
	push r16
	call lcd_puts
	pop r16
	pop r16
	
	pop YL
	pop YH
	pop ZL
	pop ZH
	pop r21
	pop r19
	pop r18
	pop r17
	pop r16
	ret

;this function was borrowed from Lab6, CSC 230, Fall 2019
;accepts two parameters first the source, second the destination
strcpy:
	push r30
	push r31
	push r29
	push r28
	push r26
	push r27
	push r23 ; hold each character read from program memory
	IN YH, SPH ;SP in Y
	IN YL, SPL
	ldd ZH, Y + 14 ; Z <- src address
	ldd ZL, Y + 13
	ldd XH, Y + 12 ; Y <- dest address
	ldd XL, Y + 11

next_char:
	lpm r23, Z+
	st X+, r23
	tst r23
	brne next_char
	pop r23
	pop r27
	pop r26
	pop r28
	pop r29
	pop r31
	pop r30
	ret

;generates the next collatz number 
;stores the current count and number in program memory
getNextCollatz:
	push r16
	push r17
	push r18
	push r19
	push r24
	push r25
	push r26
	push r27
	push r28
	push ZH
	push ZL
	.def countr = r16
	.def n1 = r17
	.def n2 = r18
	.def n3 = r19
	.def temp = r28
	.def temp2 = r24
	.def temp3 = r25
	.def tempCount = r26
	.def two = r27

	;loads n
	ldi ZH, high(current_n)
	ldi ZL, low(current_n)
	ld n1, Z+
	ld n2, Z+
	ld n3, Z

	;loads the count
	ldi ZH, high(count)
	ldi ZL, low(count)
	ld countr, Z

	ldi two, 2

	cpi n2, 0 ;makes sure that n = 0x0001
	brne notOne
	cpi n3, 0
	brne notOne
	cpi n1, 1
	breq end_of_func
	cpi n1, 0
	breq end_of_func
notOne:
	inc countr
	st Z, countr
midlp:
	mov temp, n1
	lsr temp
	brcs odd ;breaks odd if carry flag set
	;divides n by 2 if n is even
	lsr n3
	ror n2
	ror n1
	rjmp end_of_func
odd:
	mov temp, n1
	mov temp2, n2
	mov temp3, n3
	ldi tempCount, 0
doTwice:
	inc tempCount
	adc temp, n1 ;adds with carry to do the add one part of the algorithm
	adc temp2, n2
	adc temp3, n3
	cpse tempCount, two ;by doing this loop twice if multiplys the number by 3
	rjmp doTwice
	mov n1, temp
	mov n2, temp2
	mov n3, temp3
	rjmp end_of_func

end_of_func:
	;stores the n
	ldi ZH, high(current_n)
	ldi ZL, low(current_n)
	st Z+, n1
	st Z+, n2
	st Z, n3

	.undef countr
	.undef n1
	.undef n2
	.undef n3
	.undef temp
	.undef temp2
	.undef temp3
	.undef tempCount
	.undef two
	pop ZL
	pop ZH
	pop r28
	pop r27
	pop r26
	pop r25
	pop r24
	pop r19
	pop r18
	pop r17
	pop r16
	ret

;this function is a modified version of int_to_string from lab7, CSC 230, Fall 2019
;recieves two inputs from the stack first the location of the memory where the number is stored (3 bytes) second the location of the memory to write the string to
intToString:
	.def dividendlow=r24
	.def divisor=r1
	.def quotient=r17
	.def tempt=r16
	.def char0=r3
	.def dividendmid=r25
	.def dividendhigh=r26
	.def quotient2 = r18
	.def quotient3 = r19
	.def tempt2 = r23
	;preserve the values of the registers
	push dividendlow
	push divisor
	push quotient
	push tempt
	push char0
	push dividendmid
	push dividendhigh
	push quotient2
	push quotient3
	push ZH
	push ZL
	push YH
	push YL

	;store '0' in char0
	ldi tempt, '0'
	mov char0, tempt

	;initialize values for dividend, divisor
	in YH, SPH
	in YL, SPL
	ldd ZH, Y+20
	ldd ZL, Y+19
	ld tempt, Z+
	mov dividendlow, tempt
	ld tempt, Z+
	mov dividendmid, tempt
	ld tempt, Z
	mov dividendhigh, tempt
	ldi tempt, 10
	mov divisor, tempt

	;move Z to the location to store
	ldd ZH, Y+18
	ldd ZL, Y+17
	
	clr quotient
	clr quotient2
	clr quotient3
	digit2str:
		;make sure top of number is 0
		clr tempt
		or tempt, dividendmid
		or tempt, dividendhigh
		cpi tempt, 0
		brne division
		cp dividendlow, divisor
		brlo finish
		division:
			ldi tempt, 1
			ldi tempt2, 0
			add quotient, tempt
			adc quotient2, tempt2
			adc quotient3, tempt2
			sub dividendlow, divisor
			sbci dividendmid, 0
			sbci dividendhigh, 0
			or tempt2, dividendhigh
			or tempt2, dividendmid
			cpi tempt2, 0
			brne division
			cp dividendlow, divisor
			brsh division
		;change unsigned integer to character integer
		add dividendlow, char0
		st Z, dividendlow;store digits in reverse order
		sbiw r31:r30, 1 ;Z points to previous digit
		mov dividendlow, quotient
		mov dividendmid, quotient2
		mov dividendhigh, quotient3
		clr quotient
		clr quotient2
		clr quotient3
		jmp digit2str
	finish:
	add dividendlow, char0
	st Z, dividendlow ;store the most significant digit

	;restore the values of the registers
	pop YL
	pop YH
	pop ZL
	pop ZH
	pop quotient3
	pop quotient2
	pop dividendhigh
	pop dividendmid
	pop char0
	pop tempt
	pop quotient
	pop divisor
	pop dividendlow
	.undef dividendmid
	.undef dividendhigh
	.undef dividendlow
	.undef divisor
	.undef quotient
	.undef quotient2
	.undef quotient3
	.undef tempt
	.undef char0
	.undef tempt2
	ret

top_row_init: .db "Owen Jaques", 0	
bottom_row_init: .db "CSC230-Fall2019", 0

top_row_2: .db " n=000*   SPD:0 ", 0, 0
bottom_row_2: .db "cnt:  0 v:     0", 0, 0

.dseg
top_row: .byte 17
bottom_row: .byte 17
count: .byte 3
current_n: .byte 3
speed: .byte 3
starting_num: .byte 3
cursor: .byte 1
blinking: .byte 1
last_button_press: .byte 1

;
; Include the HD44780 LCD Driver for ATmega2560
;
; This library has it's own .cseg, .dseg, and .def
; which is why it's included last, so it would not interfere
; with the main program design.
#define LCD_LIBONLY
.include "lcd.asm"
