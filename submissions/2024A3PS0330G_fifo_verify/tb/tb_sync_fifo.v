`timescale 1ns/1ps
module tb_sync_fifo;

//parameters
parameter DATA_WIDTH=8;
parameter DEPTH=16;
parameter ADDR_WIDTH=$clog2(DEPTH);

//DUT inputs
reg clk;
reg rst_n;
reg wr_en;
reg [DATA_WIDTH-1:0] wr_data;
reg rd_en;
wire [DATA_WIDTH-1:0] rd_data;
wire wr_full;
wire rd_empty;
wire [ADDR_WIDTH:0] count;

//Golden Model variables
reg [DATA_WIDTH-1:0] model_mem [0:DEPTH-1];
integer model_wr_ptr;
integer model_rd_ptr;
integer model_count;
reg [DATA_WIDTH-1:0] model_rd_data;

//coverage counters
integer cov_full = 0;
integer cov_empty = 0;
integer cov_wrap = 0;
integer cov_simul = 0;
integer cov_overflow = 0;
integer cov_underflow = 0;

// Testbench tracking
integer cycle = 0;
integer i;

//DUT instantiation
sync_fifo_top #(
.DATA_WIDTH(DATA_WIDTH),
.DEPTH(DEPTH),
.ADDR_WIDTH(ADDR_WIDTH)
) DUT (
.clk(clk),
.rst_n(rst_n),
.wr_en(wr_en),
.wr_data(wr_data),
.rd_en(rd_en),
.rd_data(rd_data),
.wr_full(wr_full),
.rd_empty(rd_empty),
.count(count)
);

//generating clock of time period 10ns
initial begin
clk=1'b0;
forever #5 clk=~clk;
end

//tracks how many cycles have passed
always @(posedge clk) begin
cycle <= cycle + 1;
end

//running the golden model and updating coverage counters
always@(posedge clk)begin
if(!rst_n)begin
model_count<=0;
model_wr_ptr<=0;
model_rd_ptr<=0;
model_rd_data<=0;
end

else begin
if(model_count==(DEPTH-1))
cov_full=cov_full+1;
if(model_count==0)
cov_empty=cov_empty+1;
if(model_wr_ptr==15 && wr_en)
cov_wrap=cov_wrap+1;
if(wr_en && model_count==(DEPTH-1))
cov_overflow=cov_overflow+1;
if(rd_en && model_count==0)
cov_underflow=cov_underflow+1;

//simulatneous read and write
if(wr_en && rd_en)begin

if(model_count!=DEPTH && model_count!=0)begin
cov_simul=cov_simul+1;
model_mem[model_wr_ptr]<=wr_data;
model_rd_data<=model_mem[model_rd_ptr];
model_wr_ptr<=(model_wr_ptr+1)%DEPTH;
model_rd_ptr<=(model_rd_ptr+1)%DEPTH;
model_count<=model_count;
end
end

//write operation
else if(wr_en && model_count!=DEPTH)begin
model_mem[model_wr_ptr]<=wr_data;
model_count<=model_count+1;
model_wr_ptr<=(model_wr_ptr+1)%DEPTH;
end

//read operation
else if(rd_en && model_count!=0)begin
model_rd_data<=model_mem[model_rd_ptr];
model_rd_ptr<=(model_rd_ptr+1)%DEPTH;
model_count<=model_count-1;
end
end
end

//Scoreboard (DUT and Golden model are compared on the negedge of the clock to let the DUT outputs settle
always@(negedge clk)begin
if(rst_n)begin
if(count!=model_count)
error("Occupancy Counter Mismatch");

if(wr_full!=(model_count==DEPTH))
error("Full Flag Mismatch");

if(rd_empty!=(model_count==0))
error("Empty Flag Mismatch");

//if there is valid data to be read but the data that has been read by DUT does not match the data the testbench has read.
if (rd_en && (model_count > 0 || (wr_en && rd_en)) && (rd_data !== model_rd_data)) 
error("Read Data Mismatch");
end
end

//Custom error tasks
task error(input [255:0] reason);
        begin
            $display("\n========================================");
            $display("SCOREBOARD ERROR DETECTED!");
            $display("Reason: %s", reason);
            $display("Time: %0t | Cycle: %0d", $time, cycle);
            $display("----------------------------------------");
            $display("EXPECTED (Golden Model):");
            $display("  model_count   = %0d", model_count);
            $display("  model_rd_data = 8'h%h", model_rd_data);
            $display("  (model_empty) = %b", (model_count == 0));
            $display("  (model_full)  = %b", (model_count == DEPTH));
            $display("ACTUAL (DUT):");
            $display("  count         = %0d", count);
            $display("  rd_data       = 8'h%h", rd_data);
            $display("  rd_empty      = %b", rd_empty);
            $display("  wr_full       = %b", wr_full);
            $display("CURRENT INPUTS:");
            $display("  wr_en = %b, rd_en = %b, wr_data = 8'h%h", wr_en, rd_en, wr_data);
            $display("========================================\n");
            $finish; // Terminate simulation immediately
        end
endtask

//Stimulus Application Tasks
task do_write(input [DATA_WIDTH-1:0] d);
    begin
        @(negedge clk);
        wr_en = 1; rd_en = 0; wr_data = d;
    end
endtask

task do_read();
    begin
        @(negedge clk);
        wr_en = 0; rd_en = 1; wr_data = 0;
    end
endtask

task do_write_read(input [DATA_WIDTH-1:0] d);
    begin
        @(negedge clk);
        wr_en = 1; rd_en = 1; wr_data = d;
    end
endtask

task do_idle();
    begin
        @(negedge clk);
        wr_en = 0; rd_en = 0; wr_data = 0;
    end
endtask

//Directed Tests
initial begin
        $display("Starting FIFO Automated Verification...\n");

        // Initialize signals
        rst_n = 0; wr_en = 0; rd_en = 0; wr_data = 0;
        
        // 1. Reset Test
        #25; 
        rst_n = 1; // Release reset
        do_idle();
        $display("PASS: Reset Test");

        // 2. Single Write / Read Test
        do_write(8'hAA);
        do_idle();
        do_read();
        do_idle();
        $display("PASS: Single Write / Read Test");

        // 3. Fill Test
        for (i = 0; i < DEPTH; i = i + 1) begin
            do_write(i);
        end
        do_idle();
        $display("PASS: Fill Test (FIFO is now full)");

        // 4. Overflow Attempt Test
        do_write(8'hFF); // Attempt to write while full
        do_idle();
        $display("PASS: Overflow Attempt Test");

        // 5. Drain Test
        for (i = 0; i < DEPTH; i = i + 1) begin
            do_read();
        end
        do_idle();
        $display("PASS: Drain Test (FIFO is now empty)");

        // 6. Underflow Attempt Test
        do_read(); // Attempt to read while empty
        do_idle();
        $display("PASS: Underflow Attempt Test");

        // Prepare for simultaneous testing
        do_write(8'h11);
        do_write(8'h22);
        
        // 7. Simultaneous Read and Write Test
        do_write_read(8'h33);
        do_idle();
        $display("PASS: Simultaneous Read/Write Test");

        // 8. Pointer Wrap-Around Test
        // Write and read repeatedly to force the pointers to wrap back to 0
        for (i = 0; i < (DEPTH * 2); i = i + 1) begin
            do_write_read(i);
        end
        do_idle();
        $display("PASS: Pointer Wrap-Around Test");


        // Coverage Summary Report
        
        $display("\n========================================");
        $display("SIMULATION COMPLETE: ALL TESTS PASSED");
        $display("Coverage Summary:");
        $display("  cov_full      = %0d", cov_full);
        $display("  cov_empty     = %0d", cov_empty);
        $display("  cov_wrap      = %0d", cov_wrap);
        $display("  cov_simul     = %0d", cov_simul);
        $display("  cov_overflow  = %0d", cov_overflow);
        $display("  cov_underflow = %0d", cov_underflow);
        
        // Final assertion to ensure coverage was met
        if (cov_full > 0 && cov_empty > 0 && cov_wrap > 0 && 
            cov_simul > 0 && cov_overflow > 0 && cov_underflow > 0) begin
            $display("--> SUCCESS: 100%% Coverage Target Met!");
        end else begin
            $display("--> WARNING: Not all edge cases were covered.");
        end
        $display("========================================\n");
        
        $finish;
    end
endmodule
