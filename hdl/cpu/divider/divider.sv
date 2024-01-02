module divider
import mult_funct3::*;
(
    input clk,
    input rst,
    input  logic div_start,
    input mult_funct3_t div_op,
    input  logic [31:0] dividend, //RS1
    input  logic [31:0] divisor, //RS2
    output logic [31:0] quotient, //result for DIV and DIVU
    output logic [31:0] remainder, //result for REM and REMU
    output logic div_stall,
    output logic div_done
);

    logic sub_shift;
    logic shift_signal;
    logic flip_dividend;
    logic flip_divisor;
    logic compute_sign;
    logic special_zero;
    logic divide_by_zero;
    logic overflow;
    logic dividend_reg_bit;
    logic dividend_msb;
    logic divisor_msb;
    logic [31:0] dividend_reg;
    logic [31:0] divisor_reg;
    logic [31:0] R_reg;
    logic [31:0] counter;
    logic compute_start;

divider_control DIVIDER_CONTROL(
    .clk(clk),
    .rst(rst),
    .div_start(div_start),
    .div_op(div_op),
    .dividend(dividend), 
    .divisor(divisor),
    .dividend_reg(dividend_reg),
    .divisor_reg(divisor_reg),
    .dividend_msb(dividend_msb),
    .divisor_msb(divisor_msb),
    .R_reg(R_reg),
    .sub_shift(sub_shift),
    .shift_signal(shift_signal),
    .div_done(div_done),
    .flip_dividend(flip_dividend),
    .flip_divisor(flip_divisor),
    .compute_sign(compute_sign),
    .special_zero(special_zero),
    .divide_by_zero(divide_by_zero),
    .overflow(overflow),
    .counter(counter),
    .div_stall(div_stall),
    .compute_start(compute_start)
);

divider_datapath divider_datapath(
    .clk(clk),
    .rst(rst),
    .dividend(dividend), 
    .divisor(divisor),
    .dividend_reg(dividend_reg),
    .divisor_reg(divisor_reg),
    .dividend_msb(dividend_msb),
    .divisor_msb(divisor_msb),
    .div_op(div_op),
    .R_reg(R_reg),
    .sub_shift(sub_shift),
    .shift_signal(shift_signal),
    .flip_dividend(flip_dividend),
    .flip_divisor(flip_divisor),
    .compute_sign(compute_sign),
    .special_zero(special_zero),
    .divide_by_zero(divide_by_zero),
    .overflow(overflow),
    .counter(counter),
    .quotient(quotient),
    .remainder(remainder),
    .compute_start(compute_start)
);

endmodule  :  divider

