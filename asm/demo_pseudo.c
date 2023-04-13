/**
 * C "pseudocode" for our ASM demo for the peripheral
 * Made sure to treat accessing variables like SCOMP (bc there's only 1 register)
 * We should be able to directly translate this to SCOMP asm
 * 
 * Mostly based on our proposal, but SCOMP can't read button input.
 * Basic:       Light LEDs depending on threshold, if none light different LEDs based on levels, 
 *              if a switch is set, use that as threshold and light all LEDS
 * 
 * Count:       Show counter on Hex0, enable Sw9 to reset peripheral
 * Multi-clap:  idk lol
*/

// typedefs, just for the linter
typedef signed   short  val; // Signed value
typedef unsigned short uval; // Unsigned value

// Dummy functions
void OUT(uval device, val message); // Equivalent to the out command
val  IN(uval device); // Equivalent to the in command
void HALT(); // self explanatory


// definitions, same as the bottom of our .asm file
// other devices
#define SWITCHES    (000)
#define LEDS        (001)
#define TIMER       (002)
#define HEX0        (004)   // larger (right side) display, shows 4 hex digits
#define HEX1        (005)   // smaller (left size) display, shows 2 hex digits, reads lower byte

// Device outputs
#define P_output    (0x50)
#define P_counter   (0x51)

// Device inputs
#define P_threshset (0x5d)  // Sets the threshold, 0: low, 1: med, 2-3: high (mask with switch 0, 1)
#define P_resetctr  (0x5e)  // Sending 1 to this address will reset the counter
#define P_multimode (0x5f)  // Switch to multi-clap mode, can we just not do this one lmao

// Constants
const uval zero = 0;
const uval full = 0x3FF;       // LSB 10 bits

const uval reset_mask = 0x200; // Masks with the 9th switch to check to reset timer
const uval reset_val = 0x1;

const uval multi_mask = 0x100; // Masks with the 8th switch to switch to multiclap mode
const uval singl_mode = 0x0;   // These values are arbitrary
const uval multi_mode = 0x1;   // These values are arbitrary

const uval sw_0_1 = 0x3;

const uval sw_4 = 0x10; // 5th switch (switch no. 4)
const uval ls_nibble = 0xF; // least significant nibble (hex digit)

const val fail = 0xFA; // Display this on hex1 for failure


// Variables, if no initial value is given then just assign to whatever
val swap;
val sw_in;
val modesw; // mode switch

uval basic_store;
uval adv_store;

uval rand_val = 42069; // Since we're not flashing, this will keep going hopefully without repeating
uval rand_store;

val AC; // Simulate the accumulator 


int main() {
    
    AC = IN(SWITCHES);
    AC = AC & sw_4;

    if (AC != 0) {
        AC = zero;
        basic();
    } else {
        AC = zero;
        adv();
    }

    HALT(); // we should never reach this, the above programs either loop forever or halt on their own

    return 0; // Just C convention dwai :)
}

// This function never returns
void basic() {
    while (1) {
        // read user input and save
        AC = IN(SWITCHES);          
        sw_in = AC;                 // STORE

        // Check what threshold to use and send
        AC = AC & sw_0_1;           // AND, mask with switches to read threshold
        OUT(P_threshset, AC);       // Tell peripheral which threshold to use

        // Check single or multi mode, then load proper value and send to addr
        AC = sw_in;                 // LOAD, get value of switches
        AC = AC & multi_mask;       // AND
        
        if (AC != 0) {
            AC = multi_mode;
        } else {
            AC = singl_mode;
        }

        OUT(P_multimode, AC);

        // Check if we need to reset the counter, if so load reset_val and send to addr
        AC = sw_in;                 // LOAD
        AC = AC & reset_mask;       // AND
        if (AC != 0) {
            AC = reset_val;
            OUT(P_resetctr, AC);
        }
 
        // Read peripheral output, load full or zero depending on output, then send to addr
        AC = IN(P_output);  // IN
        if (AC != 0) {
            AC = full;
        } else {
            AC = zero;
        }
        OUT(LEDS, AC);

        // Read counter value and send to the hex display
        AC = IN(P_counter);
        OUT(HEX0, AC);
    }
}

// Loads a pseudo random generator into AC
// This algorithm is complete BS it's 12:30 am and I don't know what i'm doing
void pseudo_rng() {
    AC = rand_val;    // LOAD
    rand_store = AC;    // STORE
    AC = AC + rand_store; // * 4
    AC = AC + rand_store;
    AC = AC + rand_store;
    AC = AC >> 3;       // Shift -3
    rand_store = AC;    // STORE
    AC = AC + rand_store; // * 7
    AC = AC + rand_store;
    AC = AC + rand_store;
    AC = AC + rand_store;
    AC = AC + rand_store;
    AC = AC + rand_store;
    AC = AC + 1;        // ADDI
    rand_val = AC;      // STORE
    return;
}

void wait_sec() {
    swap = AC;
    OUT(TIMER, AC); // reset the timer
    AC = IN(TIMER);
    while (AC - 10 != 0) ; // In asm we have to in timer on every loop iteration
    AC = swap;  // LOAD
    return;     // RET
}

void adv() {
    // Force single mode for this game
    AC = singl_mode;
    OUT(P_multimode, AC);

    pseudo_rng();           // CALL, this loads a pseudorandom number into AC  
    AC = AC & ls_nibble;    // AND
    OUT(HEX0, AC);
    adv_store = AC;         // STORE

    AC = reset_val;         // resetting both
    OUT(P_resetctr, AC);    
    AC = full;
    OUT(LEDS, AC);

    while (AC != 0) {
        wait_sec();
        AC = AC >> 1;       // SHIFT -1 (negative is right, pos is left 💃) 😔😔😔😔😔😔😔😔😔😔
        OUT(LEDS, AC);
    }

    AC = IN(P_counter);
    AC = AC - adv_store;

    if (AC != 0) {
        AC = fail;
        OUT(HEX1, AC);
    } else {
        AC = IN(P_counter);
        OUT(HEX1, AC);
    }

    HALT();
    
}

