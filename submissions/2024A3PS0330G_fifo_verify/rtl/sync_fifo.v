module sync_fifo#(
parameter integer DATA_WIDTH = 8,
parameter integer DEPTH= 16,
parameter integer ADDR_WIDTH=4
)(
input wire clk,
input wire rst_n,
input wire wr_en,
input wire [DATA_WIDTH-1:0] wr_data,
input wire rd_en,
output reg [DATA_WIDTH-1:0] rd_data,
output wire wr_full,
output wire rd_empty,
output wire [ADDR_WIDTH:0] count 
);

reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];         //declaring memory

reg [ADDR_WIDTH-1:0] wr_ptr;                  //declaring write pointer

reg [ADDR_WIDTH-1:0]rd_ptr;                   //declaring read pointer
                                             
reg [ADDR_WIDTH:0] oc;                      

integer i;

always@(posedge clk)begin

if(!rst_n) begin                              //synchronous active-low reset
for (i = 0; i < DEPTH; i = i + 1) begin
mem[i] <= {DATA_WIDTH{1'b0}};                //resetting memory
end

wr_ptr<='0; 
rd_ptr<='0;
oc<='0;
rd_data<='0;
end

//if both are enabled
else if(wr_en==1'b1 && rd_en==1'b1)begin
if(!(wr_full) && !(rd_empty))begin
mem[wr_ptr]<=wr_data;
rd_data<=mem[rd_ptr];
wr_ptr <= wr_ptr + 1'b1;                     //incrementing write pointer
rd_ptr <= rd_ptr + 1'b1;                     //incrementing read pointer
oc<=oc;                                      //oc latch
end                                   
end

//write operation
else if(wr_en)begin
if(!(wr_full))begin        
mem[wr_ptr]<=wr_data;                        //storing data in memory at correct address
oc<=oc+1'b1;                                 //updating count
wr_ptr <= wr_ptr + 1'b1;                     //incrementing write pointer
end
end

//read operation
else if(rd_en) begin
if(!(rd_empty))begin
rd_data<=mem[rd_ptr];       //retreiving data from memory at correct address
oc<=oc-1'b1;                //updating count
rd_ptr <= rd_ptr + 1'b1;    //incrementing read pointer         
end
end
end

assign count=oc;
assign rd_empty=(oc==0);
assign wr_full=(oc==DEPTH);

endmodule
