module seconds_counter(
input  wire clk,
input  wire rst_n,
input  reg enable_sc,
input  reg count_rst,
output reg [5:0] seconds,
output wire count_min
);

assign count_min=(seconds==6'd59);

always@(posedge clk,negedge rst_n)begin

if(!rst_n)
seconds<=6'd0;

else if(enable_sc)begin

if(seconds==6'd59)
seconds<=6'd0;
else
seconds<=seconds+1'b1;
end

else if(count_rst)
seconds<=6'd0;
end
endmodule
