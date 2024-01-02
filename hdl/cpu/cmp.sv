module cmp
import rv32i_types::*;
import branch_funct3::*;
(
    input [31:0] in_1,
    input [31:0] in_2,
    input branch_funct3_t cmpop,
    output logic br_en
);

always_comb 
begin
    case(cmpop)
        beq: if(in_1 == in_2) begin
                br_en = 1'b1;
             end
             else begin
                br_en = 1'b0;
             end
        bne: if(in_1 != in_2)begin
                br_en = 1'b1;
             end
             else begin
                br_en = 1'b0;
             end
        blt: if($signed(in_1) < $signed(in_2))begin
                br_en = 1'b1;
             end
             else begin
                br_en = 1'b0;
             end
        bge: if($signed(in_1) >= $signed(in_2))begin
                br_en = 1'b1;
             end
             else begin
                br_en = 1'b0;
             end
        bltu: if(in_1 < in_2)begin
                br_en = 1'b1;
             end
             else begin
                br_en = 1'b0;
             end
        bgeu: if(in_1 >= in_2)begin
                br_en = 1'b1;
             end
             else begin
                br_en = 1'b0;
             end
        default: br_en = 1'b0;
    endcase
end

endmodule: cmp