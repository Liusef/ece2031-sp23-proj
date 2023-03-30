; basicdemo.asm
; Polls peripheral and lights an LED if it returns TRUE
; Assumes that peripheral has device ID 0x50 (&H50)
;
; ECE 2031 L08

Start:
    IN      Peripheral
    JZERO   Richard

LEDon:
    LOAD    Full
    OUT     LEDs
    JUMP    Start

Richard:
    LOAD    Zero
    OUT     LEDs
    JUMP    Start



; Constants
Zero:   DW 0
Full:   DW &HFFFF
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
Peripheral:EQU &H50