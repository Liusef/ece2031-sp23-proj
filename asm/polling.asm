; basicdemo.asm
; Polls peripheral and lights an LED if it returns TRUE
; Assumes that peripheral has device ID 0x50 (&H50)
;
; ECE 2031 L08

Start:
    IN      Peripheral      ;takes in data from peripheral
    JZERO   Richard         ;if peripheral has not returned a positive value of 1 (snap detected), jump

;--turns on the LED lights--
    LOAD    Full            ;loads full value into AC
    OUT     LEDs            ;outputs the LED lights (should be on)
    JUMP    Start           ;jumps back to beginning

;--keeps the LED lights off--
Richard:
    LOAD    Zero            ;loads zero into AC
    OUT     LEDs            ;outputs the LED lights (should be off)
    JUMP    Start           ;jumps back to beginning



; Constants
Zero:   DW 0
Full:   DW &HFFFF
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
Peripheral: EQU &H050
