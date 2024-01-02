module dadda_4x4
import mult_funct3::*;
(
    input clk,
    input rst,
    input mult_funct3_t mult_op,
    input logic start,
    input logic compute_sign,
    //input logic ld_carry,
    input logic i_rdy,
    input logic o_rdy,
    input logic mult_done,
    input logic flip_rs1,
    input logic flip_rs2,
    input logic [3:0] A,
    input logic [3:0] B,
    output logic [7:0] C,
    output logic rs1_msb,
    output logic rs2_msb
);

logic [3:0] pp [4];
logic [1:0] c0, s0;
logic [3:0] c1, s1;
logic [5:0] c2;

logic [3:0] A_reg, B_reg;
logic [7:0] C_reg;
logic [7:0] O;
//logic upper_carry;

assign rs1_msb = A[3];
assign rs2_msb = B[3];

always_ff @(posedge clk) begin: calculate_inputs
    if(rst) begin
        A_reg <= '0;
        B_reg <= '0;
    end
    else if(compute_sign) begin
        if(flip_rs1 && flip_rs2) begin
            A_reg <= ~A + 1;
            B_reg <= ~B + 1;
        end
        else if(flip_rs1) begin
            A_reg <= ~A + 1;
            B_reg <= B;
        end
        else if(flip_rs2) begin
            A_reg <= A;
            B_reg <= ~B + 1;
        end
        else begin
            A_reg <= A;
            B_reg <= B;
        end 
    end
end

always_ff @ (posedge clk) begin: initialize_ppmatrix
    if(rst) begin
        pp[0] <= '0;
        pp[1] <= '0;
        pp[2] <= '0;
        pp[3] <= '0;
    end
    else if(i_rdy) begin
        for(int i = 0; i < 4; i++) begin
            for(int j = 0; j < 4; j++) begin
                pp[i][j] <= A_reg[j] & B_reg[i];
            end
        end 
    end
end

//stage 1
HA ha0( .a(pp[0][3]), .b(pp[1][2]), .sum(s0[0]), .cout(c0[0]) );
HA ha1( .a(pp[1][3]), .b(pp[2][2]), .sum(s0[1]), .cout(c0[1]) );

//stage 2
HA ha2( .a(pp[0][2]), .b(pp[1][1]), .sum(s1[0]), .cout(c1[0]) );
FA fa0( .a(s0[0]), .b(pp[2][1]), .cin(pp[3][0]), .sum(s1[1]), .cout(c1[1]) );
FA fa1( .a(s0[1]), .b(pp[3][1]), .cin(c0[0]), .sum(s1[2]), .cout(c1[2]) );
FA fa2( .a(pp[2][3]), .b(pp[3][2]), .cin(c0[1]), .sum(s1[3]), .cout(c1[3]) );

//addition stage

HA ha3( .a(pp[0][1]), .b(pp[1][0]), .sum(O[1]), .cout(c2[0]) );
FA fa3( .a(s1[0]), .b(pp[2][0]), .cin(c2[0]), .sum(O[2]), .cout(c2[1]) );
FA fa4( .a(s1[1]), .b(c1[0]), .cin(c2[1]), .sum(O[3]), .cout(c2[2]) );
FA fa5( .a(s1[2]), .b(c1[1]), .cin(c2[2]), .sum(O[4]), .cout(c2[3]) );
FA fa6( .a(s1[3]), .b(c1[2]), .cin(c2[3]), .sum(O[5]), .cout(c2[4]) );
FA fa7( .a(pp[3][3]), .b(c1[3]), .cin(c2[4]), .sum(O[6]), .cout(c2[5]) );

// always_ff @ (posedge clk) begin: compute_upper
//     if(rst)
//         upper_carry <= '0;
//     else if(ld_carry)
//         upper_carry <= c2[2];
// end


always_ff @ (posedge clk) begin: latch_mult_out
    if(rst) begin
        C_reg <= '0;
    end
    else if(mult_done) begin
        C_reg[0] <= pp[0][0];
        C_reg[7] <= c2[5];
        C_reg[6:1] <= O[6:1];
    end
end

always_comb begin
    if(mult_op == mul || mult_op == mulh) begin
        if((rs1_msb && ~rs2_msb) || (~rs1_msb && rs2_msb))
            C = ~C_reg + 1;
        else
            C = C_reg;
    end
    else if(mult_op == mulhsu) begin
        C = ~C_reg + 1;
    end
    else
        C = C_reg;
end

endmodule: dadda_4x4