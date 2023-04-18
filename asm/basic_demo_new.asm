; basicdemo.asm
; Polls peripheral and lights an LED if it returns TRUE
; Assumes that peripheral has device ID 0x50 (&H50)
;
; ECE 2031 L08

Start:
	IN Switches
	AND SW9 ; checks to see if switch 9 is up
	JPOS Reset
	;if not reset, display the snap and counter on hex1 and hex0
	IN Peripheral_Snap
	OUT Hex1
	IN Peripheral_Counter
	OUT Hex0
	JUMP Start
	
	
Reset:
	LOAD Zero
	OUT Peripheral_Reset
	OUT Hex1 
	OUT Hex0
	JUMP Start


; Constants
Zero:   DW 0
Full:   DW &HFFFF
SW9: DW &H0200

Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
Peripheral_Snap: EQU &H050
Peripheral_Counter: EQU &H051
Peripheral_Reset: 	EQU &H052
