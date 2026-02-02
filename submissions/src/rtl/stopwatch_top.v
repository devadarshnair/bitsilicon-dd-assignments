module stopwatch_top (
input  wire clk,
input  wire rst_n,
input  wire start,
input  wire stop,
input  wire reset,
output wire [7:0] minutes,  
output wire [5:0] seconds,  
output wire [1:0] status    
);

wire en_count;
wire count_reset;
wire min_count;

control_fsm fsm(
.clk(clk),
.rst_n(rst_n),
.start(start),
.stop(stop),
.reset(reset),
.count_en(en_count),
.count_rst(count_reset),
.status(status)
);

seconds_counter sc(
.clk(clk),
.rst_n(rst_n),
.enable_sc(en_count),
.count_rst(count_reset),
.seconds(seconds),
.count_min(min_count)
);

minutes_counter mc(
.clk(clk),
.rst_n(rst_n),
.enable_mc(en_count & min_count),
.count_rst(count_reset),
.minutes(minutes)
);
endmodule

