;; final asm demo 

ORG 0

;; Main is the entry point for our demo code. 
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

;; Basic runs our basic demo which just shows the core functionality of the peripheral
;; void basic() {
Basic:
    basicEventLoop:
        ;; Read user input and save
        IN      SWITCHES
        STORE   sw_in

;;      commented multi mode bc not implemented yet
;;        ;; Check single or multi mode, then load value to send
;;        LOAD    sw_in
;;        AND     MULTI_MASK

;;        JZERO   basicElse1
;;            LOAD    MULTI_MODE
;;            JUMP    basicEndIf1
 ;;       basicElse1:
;;            LOAD    SINGL_MODE
;;       basicEndIf1:

;;        OUT     P_MULTI

        ;;check if user wants the input to be read or not
        LOAD sw_in
        AND POLL_MASK
        
        JZERO        ;;

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
       

        ;; rerun event loop
        JUMP basicEventLoop



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

POLL_MASK: DW &H0100 ;; 9th bit set, equivalent to 8th switch

MULTI_MASK: DW &H0080   ;;  8th bit set, equivalent to 7th switch
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
