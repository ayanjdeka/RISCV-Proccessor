module divider_control
import mult_funct3::*;
(
    input  logic clk,
    input  logic rst,
    input  logic div_start,
    input  mult_funct3_t div_op,
    input  logic [31:0] dividend, //RS1
    input  logic [31:0] divisor, //RS2
    input  logic [31:0] dividend_reg,
    input  logic [31:0] divisor_reg,
    input  logic dividend_msb,
    input  logic divisor_msb,
    input  logic [31:0] R_reg,
    output logic sub_shift,
    output logic shift_signal,
    output logic div_done,
    output logic [31:0] counter,
    output logic flip_dividend,
    output logic flip_divisor,
    output logic compute_sign,
    output logic special_zero,
    output logic divide_by_zero,
    output logic overflow,
    output logic div_stall,
    output logic compute_start
);

enum logic [2:0] {
    idle_state,
    shift_state,
    sub_state,
    start_state,
    done_compute
} state, next_state;

logic [31:0] counter_next;
/*
set remainder equal to numerator
while remainder is greater than the divider
we do R = R - D and increment q
*/


always_comb begin : state_outputs
    div_done = '0;
    div_stall = '0;
    flip_dividend = '0;
    flip_divisor = '0;
    compute_sign = '0;
    compute_start = '0;
    special_zero = '0;
    divide_by_zero = '0;
    overflow = '0;
    sub_shift = '0;
    shift_signal = '0;
    counter_next = counter;
    unique case(state)
        idle_state: begin
            counter_next = 32'd31;
            if(div_start) begin
                div_stall = '1;
                compute_sign = '1;
                if(divisor == '0)
                    divide_by_zero = '1;
                else if((div_op == div || div_op == rem) && divisor == '1 && dividend == 32'h80000000)
                    overflow = '1;  
                else if((div_op == divu || div_op == remu) && (divisor > dividend))
                    special_zero = '1;    
                else if(div_op == div || div_op == rem) begin
                    if(dividend_msb)
                        flip_dividend = '1;
                    if(divisor_msb)
                        flip_divisor = '1;
                end 
            end
        end
        start_state: begin
            div_stall = '1;
            compute_start = '1;
        end
        shift_state: begin
            div_stall = '1;
            shift_signal = '1;
        end
        sub_state: begin
            div_stall = '1;
            if(divisor_reg <= R_reg) begin
                sub_shift = '1;
            end
            counter_next = counter - 32'd1;
        end
        done_compute: begin
            div_done = '1;
        end
    endcase
end

always_comb begin : next_state_logic
    unique case(state)
        idle_state: begin
            if(div_start) begin
                if(divisor == '0)
                    next_state = done_compute;
                else if((div_op == div || div_op == rem) && divisor == '1 && dividend == 32'h80000000)
                    next_state = done_compute;
                else 
                    next_state = start_state;
            end
            else
                next_state = idle_state;            
        end
        start_state: begin
            if(divisor_reg > dividend_reg)
                next_state = done_compute;
            else begin    
                next_state = shift_state;
            end
        end
        shift_state: begin
            next_state = sub_state;
        end
        sub_state: begin
            if(counter == 0) begin
                next_state = done_compute;
            end
            else begin
                next_state = shift_state;
            end
        end
        done_compute: begin
            next_state = idle_state;
        end
        default: next_state = idle_state;
    endcase
end

always_ff @(posedge clk) begin: next_state_assignment
    if (rst) begin
        state <= idle_state;
        counter <= 0;
    end
    else begin
        state <= next_state;
        counter <= counter_next;
    end
end



endmodule : divider_control