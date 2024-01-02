module dividerold_datapath
import mult_funct3::*;
(
    input clk,
    input rst,
    input  logic div_start,
    input  logic [31:0] dividend, //RS1
    input  logic [31:0] divisor, //RS2
    input logic sub_shift,
    input mult_funct3_t div_op,
    input  logic shift_signal,
    input  logic div_done,
    input  logic flip_dividend,
    input  logic flip_divisor,
    input  logic compute_sign,
    input  logic special_zero,
    input  logic divide_by_zero,
    input  logic overflow,
    input  logic dividend_reg_bit,
    input  logic compute_start,
    output logic [31:0] quotient, //result for DIV and DIVU
    output logic [31:0] remainder, //result for REM and REMU
    output logic dividend_msb,
    output logic divisor_msb,
    output logic [31:0] dividend_reg,
    output logic [31:0] divisor_reg,
    output logic [31:0] R_reg
); 

logic [31:0] Q_reg;
assign dividend_msb = dividend[31];
assign divisor_msb = divisor[31];

always_ff @(posedge clk) begin : set_inputs
    if(rst) begin
        dividend_reg <= '0;
        divisor_reg <= '0;
    end
    else if(compute_sign) begin
        if(flip_dividend && flip_divisor) begin
            dividend_reg <= ~(dividend) + 1;
            divisor_reg <= ~(divisor) + 1;
        end
        else if(flip_dividend) begin
            dividend_reg <= ~(dividend) + 1;
            divisor_reg <= divisor;
        end
        else if(flip_divisor) begin
            dividend_reg <= dividend;
            divisor_reg <= ~(divisor) + 1;
        end
        else begin
            dividend_reg <= dividend;
            divisor_reg <= divisor;
        end
    end
end : set_inputs

always_ff @(posedge clk) begin 
    if(rst) begin
        Q_reg <= '0;
        R_reg <= '0;
    end
    else if(special_zero) begin
        Q_reg <= '0;
        R_reg <= dividend_reg;
    end
    else if(divide_by_zero)begin
        Q_reg <= '1;
        R_reg <= dividend;
    end
    else if(overflow) begin
        Q_reg <= dividend;
        R_reg <= '0;
    end
    else if(compute_start) begin
        Q_reg <= '0;
        R_reg <= dividend_reg;
    end
    else if(sub_shift) begin
        Q_reg <= Q_reg + 32'd1;
        R_reg <= R_reg - divisor_reg;
    end
   /*  else if(shift_signal) begin
        R_reg <= R_reg[30:0];
    end */
end

always_comb begin
    if(div_op == div || div_op == rem) begin
        if(dividend_msb) begin
            if(~divisor_msb) begin
                quotient = ~(Q_reg) + 1;
                remainder = ~(R_reg) + 1;
            end
            else begin
                quotient = Q_reg;
                remainder = ~(R_reg) + 1;
            end
        end
        else begin
            if(divisor_msb) begin
                quotient = ~(Q_reg) + 1;
                remainder = R_reg;
            end
            else begin
                quotient = Q_reg;
                remainder = R_reg;
            end
        end    
    end
    else begin
        quotient = Q_reg;
        remainder = R_reg;
    end
end





endmodule: dividerold_datapath