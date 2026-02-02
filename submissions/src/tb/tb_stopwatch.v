 `timescale 1ps/1ps
module tb_stopwatch;
reg clk, rst_n, start, stop, reset;
wire [7:0] minutes;  
wire [5:0] seconds;  
wire [1:0] status;

stopwatch_top SW(
.clk(clk),
.rst_n(rst_n),
.start(start),
.stop(stop),
.reset(reset),
.minutes(minutes),
.seconds(seconds),
.status(status)
);

initial
begin
clk=1'b1;
forever #10 clk=~clk;
end

initial
begin
start=1'b0;
stop=1'b0;
reset=1'b0;
rst_n=1'b0;

#20 rst_n=1'b1;
#20 start=1'b1;
#20 stop=1'b1; start=1'b0;
#20 start=1'b1; stop=1'b0;
#150000 stop=1'b1; start=1'b0;
#200 reset=1'b1;
end

initial
begin
$monitor("time=$d, minutes=%d, seconds=%d, status=%b, start=%b, stop=%b, reset=%b", $time, minutes, seconds, status, start, stop, reset);
#160000
$finish;
end
endmodule


