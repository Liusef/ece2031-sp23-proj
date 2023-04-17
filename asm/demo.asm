;; This is the SCOMP ASM code for our final project demo
;; The application has 2 "programs". Which program gets run is determined by SW4 on reset (press KEY0).
;; When SW4 is down, we run our simple peripheral demo.
;;      This program will light different LEDs on the DE-10 board based on which threshold is exceeded in our peripheral.
;;      You can also run it in "Fixed Threshold Mode" by using switches 2, 1, 0 (high, med, low)
;;          In Fixed Threshold, all the LEDs will light up depending on which switch is enabled.
;;      The program will also display the counter on the Hex displays. Enabling SW9 will reset the counter.
;;      Enabling SW8 will run our peripheral in "Multi-Clap" mode where only claps in rapid succession will be detected.
;;          In this mode, our peripheral will light all LEDs when a snap is detected. Thresholds are not supported.
;; When SW4 is up, we run our game demo.
;;      The game demo will use the timer to generate a number to display on the hex displays
;;      The player will have to clap that many times within 10 seconds to win. The countdown is on the LEDs
;;      The primary purpose of this demo is to demonstrate our counter functionality.
;;
;; Joseph Liu, Jeffrey Zhang, Zane Peacock, Matthew Rose
;; ECE 2031 L08-3 (i think)


;; Style & Conventions
;; Labels for Program Flow:
;;      CapCamelCase for subroutine headers
;;      camelCase for other labels
;; variables:
;;      lowercase_with_underscores
;; CONSTANTS:
;;      ALLCAPS

ORG 0

;; Main is the entry point for our demo code. 
;; int main() {    // except it doesn't return an int in the asm oops
Main:
    ;; Read SW4, used to determine launch mode (which program to run)
    IN      SWITCHES
    AND     SW_4

    ;; Effectively if (AC != 0); else;
    JZERO   mainElse1
        LOAD    ZERO
        JUMP    Basic
    mainElse1: 
        LOAD    ZERO
        JUMP    Advanced
    
    ;; Kill the program if it ever reaches here
    JUMP    Halt
;; }


;; Basic runs our basic demo which just shows the core functionality of the peripheral
;; void basic() {
Basic:
    basicEventLoop:
        ;; Read user input and save
        IN      SWITCHES
        STORE   sw_in

        ;; Check what threshold to use and send to peripheral
        AND     SW_0_1
        OUT     P_THRESHSET

        ;; Check single or multi mode, then load value to send
        LOAD    sw_in
        AND     MULTI_MASK

        JZERO   basicElse1
            LOAD    MULTI_MODE
            JUMP    basicEndIf1
        basicElse1:
            LOAD    SINGL_MODE
        basicEndIf1:

        OUT     P_MULTI

        ;; Check if we need to reset the counter, then load and reset
        LOAD    sw_in
        AND     RESET_MASK

        JZERO   basicEndIf2
            LOAD    RESET_VAL
            OUT     P_RESET
        basicEndIf2:

        ;; Read peripheral output, load full or zero depending on reply
        IN      P_OUTPUT
        JZERO   basicElse3
            LOAD    FULL
            JUMP    basicEndIf3
        basicElse3:
            LOAD    ZERO
        basicEndIf3:

        OUT     LEDS    ;; Send value to LEDs

        ;; Read counter and send to hex display
        IN      P_COUNTER
        OUT     HEX0

        ;; rerun event loop
        JUMP basicEventLoop
;; }    


;; Puts a pseudorandom number into AC
;; This algorithm is complete bs it's 1:10AM and I don't know what i'm doing anymore
;; pseudo_rng() {
PseudoRng:
    LOAD    rand_val
    STORE   rand_store
    ADD     rand_store
    ADD     rand_store
    ADD     rand_store
    SHIFT   -3
    STORE   rand_store
    ADD     rand_store
    ADD     rand_store
    ADD     rand_store
    ADD     rand_store
    ADD     rand_store
    ADD     rand_store
    ADDI    1
    STORE   rand_val
    RETURN
;; }
 

;; Wait for 1 second, retains value of AC
;; wait_sec() {
WaitSec:
    STORE   swap
    OUT     TIMER
    waitSecLoopStart:
        IN      TIMER
        ADDI    -10
        JZERO   WaitSecLoopEnd
        JUMP    WaitSecLoopStart
    waitSecLoopEnd:
    LOAD    swap 
    RETURN
;; }


;; Game stuff yuh
;; adv() {
Advanced:
    LOAD    SINGL_MODE
    OUT     P_MULTI

    CALL    PseudoRng
    AND     L_S_NIBBLE
    OUT     HEX0
    STORE   adv_store

    LOAD    RESET_VAL 
    OUT     P_RESET
    LOAD    FULL 
    OUT     LEDS

    advancedLoop1Start:
        CALL    WaitSec
        SHIFT   -1
        OUT     LEDS
        JZERO   advancedLoop1End
        JUMP    advancedLoop1Start
    advancedLoop1End:

    IN      P_COUNTER
    SUB     adv_store

    JZERO   advancedElse1
        LOAD    FAIL_DISP
        OUT     HEX1
        JUMP    advancedEndIf1
    advancedElse1:
        IN      P_COUNTER
        OUT     HEX1
    advancedEndIf1:

    CALL    HALT
;; }


;; halt()
Halt:
    JUMP    Halt


;; CONSTANTS (ALL_CAPS_WITH_UNDERSCORES)
;; Addresses for I/O devices
SWITCHES:   EQU 0
LEDS:       EQU 1
TIMER:      EQU 2
HEX0:       EQU 4
HEX1:       EQU 5

;; Peripheral Output Addresses
P_OUTPUT:   EQU &H050
P_COUNTER:  EQU &H051 

;; Peripheral Input Addresses
P_THRESHSET EQU &H05D
P_RESET:    EQU &H05E
P_MULTI:    EQU &H05F

;; Other Constants
ZERO:       DW 0
FULL:       DW &H03FF   ;; Least sig 10 bits are 1

RESET_MASK: DW &H0200   ;; 10th bit set, equivalent to 9th switch
RESET_VAL:  DW 1

MULTI_MASK: DW &H0100   ;;  9th bit set, equivalent to 8th switch
SINGL_MODE: DW 0
MULTI_MODE: DW 1

SW_0_1:     DW 3        ;; 0b11, switch 0 and 1, for getting threshold

SW_4:       DW &H010
L_S_NIBBLE: DW &H0F     ;; Least Significant NIBBLE (4 bits, hex digit)

FAIL_DISP:  DW &H0FA    ;; Display this on HEX1 for failure


;; Variables (lower_with_underscores)
swap:       DW 0        ;; Swap space for saving AC when calling fns

sw_in:      DW 0        ;; Switches in, save switch input here

mode_sw:    DW 0        ;; Mode Switch

basic_store:    DW 0    ;; BASIC demo STORagE
adv_store:  DW 0        ;; ADVanced demo STORagE

rand_val:   DW 42069    ;; Last random value
rand_store: DW 0        ;; RANDom STORagE
