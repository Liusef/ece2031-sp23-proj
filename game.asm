; AudioTest.asm
; Displays the value from the audio peripheral

ORG 0

	LOAD Counter
Reset:
	ADDI -1
    OUT Audio
    JPOS Reset
    LOADI 0
    
Advanced:
    
    LOADI 0
    OUT HEX1
    
    CALL PseudoRng
    AND L_S_NIBBLE
    OUT HEX0
    STORE goal

    LOAD FULL 
    OUT LEDs
    
    ;Resets the clap counter
    OUT     Audio

    advancedLoop1Start:
        CALL    Wait
        SHIFT   -1
        OUT     LEDs
        JZERO   advancedLoop1End
        JUMP    advancedLoop1Start
    advancedLoop1End:

    IN Audio
    OUT HEX1
    SUB goal

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


Next:
	IN Switches
    JZERO Next
    
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
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
Audio:     EQU &H50

; Constants
L_S_NIBBLE: DW &H0F
One: DW 1
Full: DW &H03FF


; Variables
swap:      DW 0 
score:     DW 0
goal:      DW 0
temp:      DW 0
rng:       DW 100

Counter: DW &H7FFF
