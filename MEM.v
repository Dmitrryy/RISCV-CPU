

module MEM 
#(parameter N = 12, DW = 32) 
(input i_clk, 
input [31:0] /* verilator lint_off UNUSED */ addr , 
input [2:0] width, 
input we,
input [31:0] data,
output reg[31:0] out_data,
output valid);

reg	[(DW-1):0]	mem_buff 	[0:((1<<N)-1)] /*verilator public*/;

// is L*U?
wire to_extend = ~width[2:2]; 

assign valid = ~we; 

always @(posedge i_clk)
begin
    if (we) begin
        mem_buff[addr][7:0] <= data[7:0];
        if(width[0:0]) begin
            mem_buff[addr][15:8] <= data[15:8];
        end else if(width[1:1]) begin
            mem_buff[addr][31:16] <= data[31:16];
        end
    end else begin
        if(width[0:0]) begin
            // LH
            out_data <= { {16{to_extend && mem_buff[addr][15:15]}}, mem_buff[addr][15:0] };
        end else if(width[1:1]) begin
            // LW
            out_data <= mem_buff[addr];
        end else begin
            // LB
            out_data <= { {24{to_extend && mem_buff[addr][7:7]}}, mem_buff[addr][7:0] };
        end
    end
end

endmodule