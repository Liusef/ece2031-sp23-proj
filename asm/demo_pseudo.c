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
val IN(uval device); // Equivalent to the in command


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
#define P_multimode (0x5e)  // Switch to multi-clap mode

// Constants
const uval zero = 0;
const uval full = 0xFFFF;
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


// Variables, if no initial value is given then just assign to whatever
val swap;
val sw_in;
val low_out;
val med_out;
val hi_out;
val modesw; // mode switch



val AC; // Simulate the accumulator


int main() {
    AC = zero; // This is the same as [LOAD zero]
    
    // This defines our event loop
    while (1) {
        
        // read user input
        sw_in = IN(SWITCHES);       // IN then STORE

        // Check if we need to reset the timer
        AC = sw_in;                 // LOAD
        AC = AC & reset_mask;       // AND
        if ((AC) > 0) {
            OUT(P_resetctr, AC);    // Shouldn't matter what the user sends
        }

        // Tell it what mode we're using
        AC = sw_in;
        AC = AC & multi_mask;
        if (AC != 0) {
            AC = multi_mode;
        } else {
            AC = singl_mode;
        }
    
        AC = AC - modesw;
        if (AC != 0) { // If AC isn't 0, that means there was a mode change
            if (AC == -1) AC = multi_mode; // AC will be -1 if switching from multi to single mode
            if (AC ==  1) AC = singl_mode; // AC will be  1 if switching from single to multi mode // TODO consider changing to else
            OUT(P_multimode, AC);
            modesw = AC; // STORE
        }

        // read basic outputs
        low_out = IN(P_basic_low);  // IN then STORE
        med_out = IN(P_basic_med);
        hi_out  = IN(P_basic_hi);

        // read counter
        AC = IN(P_counter);         // IN
        OUT(HEX0, AC);              // OUT

        if (modesw != 0) {
            multimode();            // CALL
        } else {
            show_LEDs();            // CALL
        }

    } // JUMP to beginning of loop

    return 0; // Just C convention dwai :)
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

void multimode() {
    // lmao i don't know what we're supposed to do with this
    return;                 // RET
}

