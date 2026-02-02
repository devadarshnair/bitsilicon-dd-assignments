module minutes_counter (
input  wire clk,
input  wire rst_n,
input  wire enable_mc,
input  wire count_rst,
output reg [7:0] minutes
);

always@(posedge clk,negedge rst_n)begin

if(!rst_n)
minutes<=8'd0;

else if(count_rst)
minutes<=8'd0;

else if(enable_mc)begin

if(minutes==8'd99)
minutes<=8'd0;
else
minutes<=minutes+1'b1;
end

end
endmodule  

