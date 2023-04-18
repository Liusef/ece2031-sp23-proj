; AudioTest.asm
; Displays the value from the audio peripheral

ORG 0
Start:
In Switches
ADDI -1
JZERO Debug_Demo
IN Switches
ADDI -2
JZERO Basic_Demo
IN Switches
ADDI -4
JZERO Game_Demo
JUMP Start

Debug_Demo:

	IN Switches
	AND SW9 ; checks to see if switch 9 is up
	JPOS Reset_Debug
	;if not reset, display the snap and counter on hex1 and hex0
	IN snap
	OUT Hex1
	IN counter
	OUT Hex0
	JUMP Start
	
Reset_Debug:
	LOADi 0
	OUT resetcount
	OUT Hex1 
	OUT Hex0
	JUMP Debug_Demo



Basic_Demo:
    IN Count
    OUT Hex1
    IN Switches
    JZERO Basic_Demo
 
 	CALL wait
    LOADI 0
    OUT Hex1
    LOAD FULL
    OUT LEDs
    
    OUT resetCount
    
    CLAP_DETECTION:
    IN Switches
    JPOS CLAP_DETECTION
            
    IN Count
    OUT HEX0
    LOADI 0
    OUT LEDs
    OUT ResetCount
   	Call Wait
    Call Wait
    Call Wait
    Call Wait
    Jump Basic_Demo
	

	;Start of the program
Game_Demo:	
    
    ;Run n cycle for delay at start
	LOAD Counter
Reset:
	ADDI -1
    OUT ResetCount
    JPOS Reset
    LOADI 0
    
Advanced:
    LOADI 0
    OUT HEX1
    
    ;Generates a random number between 0 and 16 to play game
    CALL PseudoRng
    AND L_S_NIBBLE
    OUT HEX0
    STORE goal

	;Start Count Time
    LOAD FULL 
    OUT LEDs
    
    ;Resets the clap counter
    OUT ResetCount

	;Lower Count Down until we reach 0. Take around 5 seconds
    advancedLoop1Start:
        CALL    Wait
        SHIFT   -1
        OUT     LEDs
        JZERO   advancedLoop1End
        JUMP    advancedLoop1Start
    advancedLoop1End:

	;Takes Count Value from peripheral
    IN Counter
    OUT HEX1
    SUB goal

	; Checks if number of count match goal
    JZERO advancedElse1
		LoadI 0
        OUT LEDS
        JUMP    advancedEndIf1
    advancedElse1:
        LOAD    Score
        Addi    1 
        OUT     LEDs
        Store Score
    advancedEndIf1:

	;Wait for switches to reset

Next:
	IN Switches
    JZERO Next
    Call Wait
    Call Wait
Next2:
	IN Switches
    JZERO END
    JUMP Next2
    
END:
    Call Wait
    JUMP Advanced
    

Wait:
    STORE   swap
    OUT     TIMER
    waitLoopStart:
        IN      TIMER
        ADDI    -5
        JZERO   WaitLoopEnd
        JUMP    WaitLoopStart
    waitLoopEnd:
    LOAD    swap 
    RETURN

PseudoRng:
    LOADI 10
PseudoRng_Loop:
    JZERO END_PseudoRng
    CALL Collatz
    ADDI -1
    
END_PseudoRng:
    LOAD rng
    JZERO Increment
    RETURN

Increment:
    Addi 1
    Return

 

;; Method to generate a random number using collatz conjecture. Number should be sufficiently random for demo
Collatz:
    Store swap
    Load rng
    AND One
    JZERO EVEN_Collatz
    JUMP ODD_Collatz
           
    ODD_Collatz:
        Load rng
        ADD rng
        ADD rng
        ADDi 1
        JUMP END_Collatz
    EVEN_Collatz:
        Load rng
        Shift -1
        Store rng
    END_Collatz:
        Store rng
        load swap
        Return
    
; IO address constants
Switches:   EQU 000
LEDs:       EQU 001
Timer:      EQU 002
Hex0:       EQU 004
Hex1:       EQU 005
Snap:       EQU &H50
Count:      EQU &H51
ResetCount: EQU &H52


; Constants
L_S_NIBBLE: DW &H0F
One: DW 1
Full: DW &H03FF
SW9: DW &H0200


; Variables
swap:      DW 0 
score:     DW 0
goal:      DW 0
rng:       DW 100
Counter: DW &H7FFF
