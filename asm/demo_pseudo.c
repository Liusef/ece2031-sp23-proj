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
#define P_basic_low (0x50)
#define P_basic_med (0x53)
#define P_basic_hi  (0x52)
#define P_counter   (0x53)

// Device inputs
#define P_resetctr  (0x5f)  // Any input to this will reset the counter
#define P_multimode (0x5e)  // Switch to multi-clap mode, can we just not do this one lmao

// Constants
const uval zero = 0;
const uval full = 0x3FF;       // LSB 10 bits
const uval reset_mask = 0x200; // Masks with the 9th switch to check to reset timer
const uval multi_mask = 0x100; // Masks with the 8th switch to switch to multiclap mode
const uval singl_mode = 0x0;   // These values are arbitrary
const uval multi_mode = 0xFFFF;// These values are arbitrary

const val mode_low = 1;
const uval low_led = 0b111; // 3 leds

const val mode_med = 2;
const uval med_led = 0b111111; // 6 leds

const val mode_hi  = 4;
const uval hi_led  = 0xFFFF; // all LEDs

const uval fourth_sw = 0x10; // 5th switch (switch no. 4)
const uval ls_nibble = 0xF; // least significant nibble (hex digit)

const val fail = 0xFA; // Display this on hex1 for failure


// Variables, if no initial value is given then just assign to whatever
val swap;
val sw_in;
val low_out;
val med_out;
val hi_out;
val modesw; // mode switch

uval adv_store;

val AC; // Simulate the accumulator


int main() {
    
    AC = IN(SWITCHES);
    AC = AC & 0x10;

    if (AC != 0) {
        AC = zero;
        basic();
    } else {
        AC = zero;
        adv();
    }

    return 0; // Just C convention dwai :)
}


void basic() {
    while (1) {
        // read user input
        sw_in = IN(SWITCHES);       // IN then STORE

        // Check if we need to reset the counter
        AC = sw_in;                 // LOAD
        AC = AC & reset_mask;       // AND
        if ((AC) > 0) {
            OUT(P_resetctr, AC);    // Shouldn't matter what the user sends
        }
    
        // read basic outputs
        low_out = IN(P_basic_low);  // IN then STORE
        med_out = IN(P_basic_med);
        hi_out  = IN(P_basic_hi);

        // read counter
        AC = IN(P_counter);         // IN
        OUT(HEX0, AC);              // OUT

        show_LEDs();

    }
}


void show_LEDs() {
    swap = AC;              // STORE

    // Check if a mode is set
    AC = sw_in;             // LOAD
    AC = AC & mode_hi;      // AND
    if (AC > 0) {
        AC = hi_out;        // LOAD
        goto show_leds_with_mode;       // JUMP
    }

    AC = sw_in;
    AC = AC & mode_med;
    if (AC > 0) {
        AC = med_out;
        goto show_leds_with_mode;
    }

    AC = sw_in;
    AC = AC & mode_low;
    if (AC > 0) {
        AC = low_out;
        goto show_leds_with_mode;
    }

    AC = hi_out;           // This is the fallthrough case       
    if (AC != 0) {
        AC = hi_led;
        goto show_leds_out;
    }

    AC = med_out;
    if (AC != 0) {
        AC = med_led;
        goto show_leds_out;
    }

    AC = low_out;
    if (AC != 0) {
        AC = low_led;
        goto show_leds_out;
    }

    AC = zero;              // LOAD

show_leds_with_mode:
    if (AC != 0) {
        AC = full;
    } else {
        AC = 0;
    }

show_leds_out:
    OUT(LEDS, AC);
    AC = swap;              // LOAD, replace original value of AC
    return;                 // RET
}

void wait_sec() {
    swap = AC;
    OUT(TIMER, AC);
    AC = IN(TIMER);
    while (AC - 10 != 0) ; // do nothing lmao
    AC = swap;  // LOAD
    return;     // RET
}

void adv() {

    AC = IN(TIMER);     
    AC = AC & ls_nibble;    // AND
    OUT(HEX0, AC);
    adv_store = AC;              // STORE

    OUT(P_resetctr, AC);    // resetting both
    AC = full;
    OUT(LEDS, AC);

    while (AC != 0) {
        wait_sec();
        AC = AC >> 1;           // SHIFT -1 (negative is right, pos is left 💃) 😔😔😔😔😔😔😔😔😔😔
        OUT(LEDS, AC);
    }

    AC = IN(P_counter);
    AC = AC - adv_store;

    if (AC != 0) {
        AC = fail;
        OUT(HEX1, AC);
    } else {
        AC = adv_store;
        OUT(HEX1, AC);
    }

    HALT();
    
}

