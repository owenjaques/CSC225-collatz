/*
 * a4.c
 *
 * Created: 12/2/2019 1:15:42 PM
 * Author : Owen Jaques
 */ 

#include <avr/io.h>
#include "CSC230.h"
#include <string.h>

#define  ADC_BTN_RIGHT 0x032
#define  ADC_BTN_UP 0x0C3
#define  ADC_BTN_DOWN 0x17C
#define  ADC_BTN_LEFT 0x22B
#define  ADC_BTN_SELECT 0x316
#define  NO_BTN 1001
#define SPEED1 (0xFFFF - 977)
#define SPEED2 (0xFFFF - 1953)
#define SPEED3 (0xFFFF - 3906)
#define SPEED4 (0xFFFF - 7813)
#define SPEED5 (0xFFFF - 15625)
#define SPEED6 (0xFFFF - 23438)
#define SPEED7 (0xFFFF - 31250)
#define SPEED8 (0xFFFF - 39062)
#define SPEED9 (0xFFFF - 46975)

volatile char rows[34] = "Owen Jaques     CSC230-Fall2019";
volatile int blink, count, speed, input_n, current_n, cursor;

int main(void){
	blink = 0;
	count = 0;
	speed = 0;
	input_n = 0;
	current_n = 0;
	cursor = 2;
	
	//ADC Set up
	ADCSRA = 0x87;
	ADMUX = 0x40;

	lcd_init();
	lcd_puts(rows);
	
	//set up timer 1 for the blinking
	TCCR1A = 0;
	TCCR1B = (1<<CS12)|(1<<CS10);	// Prescaler of 1024
	TCNT1 = 0xFFFF - 7192;			// Initial count (1 second)
	TIMSK1 = 1<<TOIE1;
	
	//set up timer 3 for the button checking
	TCCR3A = 0;
	TCCR3B = (1<<CS32)|(1<<CS30);
	TCNT3 = 0xFFFF - 781;
	TIMSK3 = 1<<TOIE3;
	
	//set up timer 5 for the speed
	TCCR5A = 0;
	TCCR5B = 0;//stops the clock
	TIMSK5 = 1<<TOIE5;
	
	sei();
	
	//waits a second
	_delay_ms(1000);

	//updates the screen
    while(1){
		strcpy(rows, " n=000*   SPD:0 cnt:  0 v:     0");
		intToString(input_n, 5);
		intToString(speed, 14);
		intToString(count, 22);
		intToString(current_n, 31);
		if(blink){
			switch(cursor){
				case 0:
					rows[3] = ' ';
					break;
				case 1:
					rows[4] = ' ';
					break;
				case 2:
					rows[5] = ' ';
					break;
				case 3:
					rows[6] = ' ';
					break;
				case 4:
					rows[14] = ' ';
					break;
			}
		}
		lcd_xy(0, 0);
		lcd_puts(rows);
    }
}

ISR(TIMER1_OVF_vect){
	//changes the blink variable
	//blinks twice a second
	blink ^= 1;
	TCNT1 = 0xFFFF - 7192;
}

ISR(TIMER3_OVF_vect){
	//gets the button presses at approximately 20Hz
	TCNT3 = 0xFFFF - 781;
	static int last_button = 0;
	static int old_speed = 0;
	int temp;
	int button = poll_adc();
	if(last_button == button)
		return;
	switch(button){
		case ADC_BTN_RIGHT:
			if(cursor != 4)
				cursor++;
			break;
		case ADC_BTN_DOWN:
			switch(cursor){
				case 4:
					if(speed != 0)
						speed--;
					break;
				case 3:
					current_n = input_n;
					count = 0;
					break;
				case 2:
					if(input_n % 10 != 0)
						input_n--;
					break;
				case 1:
					if((input_n / 10) % 10 != 0)
						input_n -= 10;
					break;
				case 0:
					if(input_n >= 100)
						input_n -= 100;
					break;
			}
			break;
		case ADC_BTN_UP:
			switch(cursor){
				case 4:
					if(speed != 9)
						speed++;
					//turns on timer if speed was just turned to 1
					if(speed == 1){
						TCCR5B = (1<<CS52)|(1<<CS50);
						TCNT5 = SPEED1;
					}
					break;
				case 3:
					current_n = input_n;
					count = 0;
					break;
				case 2:
					if(input_n % 10 != 9)
						input_n++;
					break;
				case 1:
					if((input_n / 10) % 10 != 9)
						input_n += 10;
					break;
				case 0:
					if(input_n < 900)
						input_n += 100;
					break;
			}
			break;
		case ADC_BTN_LEFT:
			if(cursor != 0)
				cursor--;
			break;
		case ADC_BTN_SELECT:
			temp = old_speed;
			old_speed = speed;
			speed = temp;
			//turns timer back on
			TCCR5B = (1<<CS52)|(1<<CS50);
			TCNT5 = SPEED5;
			break;
	}
	last_button = button;
	
}

ISR(TIMER5_OVF_vect){
	//changes the speed
	switch(speed){
		//turns off timer
		case 0:
			TCCR5B = 0;//stops the clock
			return;
			break;
		case 1:
			TCNT5 = SPEED1;
			break;
		case 2:
			TCNT5 = SPEED2;
			break;
		case 3:
			TCNT5 = SPEED3;
			break;
		case 4:
			TCNT5 = SPEED4;
			break;
		case 5:
			TCNT5 = SPEED5;
			break;
		case 6:
			TCNT5 = SPEED6;
			break;
		case 7:
			TCNT5 = SPEED7;
			break;
		case 8:
			TCNT5 = SPEED8;
			break;
		case 9:
			TCNT5 = SPEED9;
			break;
	}
	//gets the next collatz thing
	if(current_n == 1 || current_n == 0)
		return;
	count++;
	if(current_n % 2 == 0)
		current_n /= 2;
	else
		current_n = 3*current_n + 1;
}

//changes the specified number to a string and writes it to the rows string at the specified row index
void intToString(int the_int, int row_index){
	while(1){
		rows[row_index--] = the_int % 10 + '0';
		the_int /= 10;
		if(the_int <= 0)
			break;
	}
}

//this function is a modified version of a function taken from lab9, CSC230, Fall 2019
//A short is 16 bits wide, so the entire ADC result can be stored
//in an unsigned short.
//returns -1 if no button is pressed
int poll_adc(){
	unsigned short adc_result = 0; //16 bits
	
	ADCSRA |= 0x40;
	while((ADCSRA & 0x40) == 0x40); //Busy-wait
	
	unsigned short result_low = ADCL;
	unsigned short result_high = ADCH;
	
	adc_result = (result_high<<8)|result_low;
	
	if(adc_result <= ADC_BTN_RIGHT) return ADC_BTN_RIGHT;
	if(adc_result <= ADC_BTN_UP) return ADC_BTN_UP;
	if(adc_result <= ADC_BTN_DOWN) return ADC_BTN_DOWN;
	if(adc_result <= ADC_BTN_LEFT) return ADC_BTN_LEFT;
	if(adc_result <= ADC_BTN_SELECT) return ADC_BTN_SELECT;
	return NO_BTN;
}
