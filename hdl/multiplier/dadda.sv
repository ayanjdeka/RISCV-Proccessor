module dadda
import mult_funct3::*;

(
    input clk,
    input rst,
    input logic start,
    input mult_funct3_t mult_op,
    input logic  [31:0] A,
    input logic  [31:0] B,
    output logic [63:0] C,
    output logic o_rdy,
    output logic mult_stall
);

logic rs1_msb, rs2_msb;
logic flip_rs1, flip_rs2;
logic mult_done;
logic mult_done_flip;
logic compute_sign;
logic ld_carry;
//logic flip_sign;
//logic i_rdy;

dadda_32x32 dadda_datapath
(
    .clk(clk),
    .rst(rst),
    .mult_op(mult_op),
    .compute_sign(compute_sign),
    .ld_carry(ld_carry),
    //.flip_sign(flip_sign),
    //.i_rdy(i_rdy),
    .mult_done(mult_done),
    .mult_done_flip(mult_done_flip),
    .flip_rs1(flip_rs1),
    .flip_rs2(flip_rs2),
    .A(A),
    .B(B),
    .C(C),
    .rs1_msb(rs1_msb),
    .rs2_msb(rs2_msb)
);

dadda_controller dadda_controller
(
    .clk(clk),
    .rst(rst),
    .mult_op(mult_op),
    .rs1_msb(rs1_msb),
    .rs2_msb(rs2_msb),
    .start(start),
    .compute_sign(compute_sign),
    .ld_carry(ld_carry),
    //.flip_sign(flip_sign),
    //.i_rdy(i_rdy),
    .o_rdy(o_rdy),
    .flip_rs1(flip_rs1),
    .flip_rs2(flip_rs2),
    .mult_done(mult_done),
    .mult_done_flip(mult_done_flip),
    .mult_stall(mult_stall)
);


endmodule: dadda