
module RegPipe #(
    parameter W = 32
) (
    input clk,
    input rst,
    input en,
    input [W-1:0] NewData,

    output [W-1:0] OutData
);
reg [W-1:0] SavedData;
assign OutData = SavedData;

always @(posedge clk) begin
    if (en && !rst)
        SavedData <= NewData;
    else if (rst)
        SavedData <= 0;
end
endmodule
