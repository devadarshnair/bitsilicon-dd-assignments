#include <iostream>
#include <iomanip>
#include "Vstopwatch_top.h"
#include "verilated.h"

// Current simulation time
vluint64_t main_time = 0;

// Helper function to toggle the clock
void tick(Vstopwatch_top* top) {
    top->clk = 0;
    top->eval();
    top->clk = 1;
    top->eval();
    main_time++;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vstopwatch_top* top = new Vstopwatch_top;

    // --- INITIALIZATION ---
    top->clk = 0;
    top->rst_n = 0; // Hardware Reset Active
    top->start = 0;
    top->stop = 0;
    top->reset = 0;

    // Step 1: Release Hardware Reset
    // Assignment requires rst_n for system initialization
    for(int i=0; i<5; i++) tick(top);
    top->rst_n = 1; 
    tick(top);
    printf("[%ld] System Initialized (Status: %d)\n", main_time, top->status);

    // Step 2: START the Stopwatch
    // Pulse the 'start' signal so the FSM moves to RUNNING
    top->start = 1;
    tick(top);
    top->start = 0; 
    printf("[%ld] START Button Pulsed\n", main_time);

    // Step 3: Observe Counting (RUNNING)
    // We let it run for a while to see the seconds increment
    printf("\nTime\t MM : SS\t Status\n");
    printf("-------------------------------\n");
    for (int i = 0; i < 5000; i++) {
        tick(top);
        if (i % 1000 == 0) {
            // Human-readable format MM:SS as required
            printf("[%ld]\t %02d : %02d \t %d\n", main_time, top->minutes, top->seconds, top->status);
        }
    }

    // Step 4: STOP (Pause) the Stopwatch
    // Pulse the 'stop' signal
    top->stop = 1;
    tick(top);
    top->stop = 0;
    printf("[%ld] STOP Button Pulsed (Paused at %02d:%02d)\n", main_time, top->minutes, top->seconds);

    // Wait a few cycles to prove it stays paused
    for(int i=0; i<10; i++) tick(top);
    printf("[%ld] After pause: %02d:%02d\n", main_time, top->minutes, top->seconds);

    // --- Step 5: RESUME and Watch Rollover ---
    top->start = 1;
    tick(top);
    top->start = 0;
    printf("[%ld] RESUME (Start Button Pulsed)\n", main_time);

    // Run enough cycles to pass 100 minutes (6000 seconds)
    // We start at 83:21 (approx 5000 seconds), so we need ~1000 more to hit 99
    for (int i = 0; i < 2000; i++) {
        tick(top);

        // ONLY print if we are about to roll over (Minutes = 99)
        if (top->minutes == 99 && top->seconds > 55) {
             printf("[%ld]\t %02d : %02d \t (WATCH CLOSELY!)\n", main_time, top->minutes, top->seconds);
        }
        
        // Also print the moment it hits 00 again
        if (top->minutes == 0 && top->seconds < 5) {
             printf("[%ld]\t %02d : %02d \t (ROLLOVER CONFIRMED)\n", main_time, top->minutes, top->seconds);
        }
    }

    // Let it run for a long simulation to check roll-over
    for (int i = 0; i < 2000; i++) {
        tick(top);
    }
    printf("[%ld] Final count before reset: %02d:%02d\n", main_time, top->minutes, top->seconds);

    // Step 6: RESET (Clear)
    // Pulse the 'reset' control input to return to IDLE/00:00
    top->reset = 1;
    tick(top);
    top->reset = 0;
    tick(top);
    printf("[%ld] RESET Pulsed. Final Time: %02d:%02d (Status: %d)\n", 
            main_time, top->minutes, top->seconds, top->status);

    // Clean up
    top->final();
    delete top;
    return 0;
}
