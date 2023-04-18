

module MEM 
#(parameter N = 12, DW = 32) 
(input i_clk, 
input [31:0] /* verilator lint_off UNUSED */ addr , 
input [2:0] width, 
input we,
input [31:0] write_data,
output [31:0] read_data
);
//assert property(addr >> N == 0);

reg	[(DW-1):0]	mem_buff 	[0:((1<<N)-1)] /*verilator public*/;

// is L*U?
wire to_extend = ~width[2:2];

wire [31:0]read_b = { {24{to_extend && mem_buff[addr][7:7]}}, mem_buff[addr][7:0] };
wire [31:0]read_h = { {16{to_extend && mem_buff[addr][15:15]}}, mem_buff[addr][15:0] };
wire [31:0]read_w = mem_buff[addr];

assign read_data = (width[0:0]) ? read_h : ((width[1:1]) ? read_w : read_b); 

always @(posedge i_clk)
begin
    if (we) begin
        mem_buff[addr][7:0] <= write_data[7:0];
        if(width[0:0]) begin
            mem_buff[addr][15:8] <= write_data[15:8];
        end else if(width[1:1]) begin
            mem_buff[addr][31:8] <= write_data[31:8];
        end
    end
end

endmodule