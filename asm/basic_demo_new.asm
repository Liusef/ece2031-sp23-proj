; basic_demo_new.asm
; updates output when sw9 is up
; Assumes that peripheral has device ID 0x50 (&H50)
;
; ECE 2031 L08

LOAD Zero
OUT LEDs

Start:
    IN      SWITCHES      ;takes in data from switches
    AND     POLL          ;sees if sw9 is up
    JZERO   START

;--turns on the LED lights--
    IN Peripheral            ;loads full value into AC
    STORE pDATA
    AND One
    LOAD Full
    OUT LEDs
    LOAD pDATA
    SHIFT -1
    OUT Hex0
    JUMP    Start           ;jumps back to beginning


; Constants
Zero:   DW 0
One: DW 1
Full:   DW &HFFFF
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
Peripheral: EQU &H050
POLL:  DW &H0200
pData: DW 0
