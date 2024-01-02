module pc
import rv32i_types::*;
(
    input clk,
    input rst,
    input load,
    input [31:0] in,
    output [31:0] data_out
);

logic [31:0] data;

always_ff @(posedge clk) begin
    if (rst)
    begin
        data <= 32'h40000000;
    end
    else if (load == 1)
    begin
        data <= in;
    end
    else
    begin
        data <= data;
    end
end

assign data_out = data;

endmodule: pc