module global_predictor
import rv32i_opcode::*;
(
    input clk,
    input rst,
    input rv32i_opcode_t opcode,
    input logic br_en,
    output logic prediction
);

logic [3:0] GHR_reg;
logic [1:0] PHT_reg[16];
logic [3:0] GHR_out;


always_ff @(posedge clk) begin : GHR_update
    if(rst)
        GHR_reg <= '0;
    else if(opcode == op_br)
        GHR_reg <= {GHR_reg[2:0], br_en};
end
assign GHR_out = GHR_reg;

always_ff @(posedge clk) begin: PHT_update
    if(rst) begin
        for(int i = 0; i < 16; i++) begin
            PHT_reg[i] <= '0;
        end
    end
    else if(opcode == op_br) begin
        if(br_en) begin
            unique case(PHT_reg[GHR_out])
                // 1'b0: PHT_reg[GHR_out] <= 1'b1;
                // 1'b1: PHT_reg[GHR_out] <= 1'b1;
                2'b00: PHT_reg[GHR_out] <= 2'b01;
                2'b01: PHT_reg[GHR_out] <= 2'b10;
                2'b10: PHT_reg[GHR_out] <= 2'b11;
                2'b11: PHT_reg[GHR_out] <= 2'b11;
            default: PHT_reg[GHR_out] <= PHT_reg[GHR_out];
            endcase
        end
        else begin
            unique case(PHT_reg[GHR_out])
                // 1'b0: PHT_reg[GHR_out] <= 1'b0; 
                // 1'b1: PHT_reg[GHR_out] <= 1'b0;
                2'b00: PHT_reg[GHR_out] <= 2'b00;
                2'b01: PHT_reg[GHR_out] <= 2'b00;
                2'b10: PHT_reg[GHR_out] <= 2'b01;
                2'b11: PHT_reg[GHR_out] <= 2'b10;
            default: PHT_reg[GHR_out] <= PHT_reg[GHR_out];
            endcase
        end
    end
end
assign prediction = PHT_reg[GHR_out][1];

endmodule: global_predictor