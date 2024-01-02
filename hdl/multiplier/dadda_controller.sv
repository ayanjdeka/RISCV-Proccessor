module dadda_controller
import mult_funct3::*;
(
    input clk,
    input rst,
    input mult_funct3_t mult_op,
    input logic rs1_msb,
    input logic rs2_msb,
    input logic start,
    output logic compute_sign,
    //output logic flip_sign,
    output logic flip_rs1,
    output logic flip_rs2,
    output logic ld_carry,
    output logic mult_done,
    output logic mult_done_flip,
    output logic o_rdy,
    output logic mult_stall
);

enum int unsigned {IDLE, CALC_PP, MULTIPLY_LOWER, MULTIPLY_UPPER, DONE} curr_state, next_state;

always_comb begin: state_outputs
    //i_rdy = '0;
    o_rdy = '0;
    ld_carry = '0;
    //flip_sign = '0;
    mult_done = '0;
    mult_done_flip = '0;
    mult_stall = '0;
    flip_rs1 = '0;
    flip_rs2 = '0;
    compute_sign = '0;
    unique case(curr_state)
        IDLE: begin
            if(start) begin
                compute_sign = '1;
                mult_stall = '1;
                if(mult_op == mul || mult_op == mulh) begin
                    if(rs1_msb)
                        flip_rs1 = '1;
                    if(rs2_msb)
                        flip_rs2 = '1;
                end
                else if(mult_op == mulhsu) begin
                    if(rs1_msb)
                        flip_rs1 = '1;
                end
                else begin
                    flip_rs1 = '0;
                    flip_rs2 = '0;
                end
            end
        end
        // CALC_PP: begin
        //     mult_stall = '1;
        //     i_rdy = '1;
        // end
        MULTIPLY_LOWER: begin
            mult_stall = '1;
            if(mult_op == mulh || mult_op == mulhsu || mult_op == mulhu)
                ld_carry = '1;
            else begin
                if(rs1_msb ^ rs2_msb)
                    mult_done_flip = '1;
                else
                    mult_done = '1;
            end
            //mult_done = '1;
        end
        MULTIPLY_UPPER: begin
            mult_stall = '1;
            if(rs1_msb ^ rs2_msb)
                mult_done_flip = '1;
            else
                mult_done = '1;
        end
        // SIGN_CHECK: begin
        //     mult_stall = '1;
        //     flip_sign = '1;
        // end
        DONE: o_rdy = '1;
        default:; 
    endcase
end

always_comb begin: state_transitions
    unique case(curr_state)
        IDLE: begin
            if(start)
                next_state = MULTIPLY_LOWER;
            else
                next_state = IDLE;
        end
        // CALC_PP: begin
        //     next_state = MULTIPLY;
        // end
        MULTIPLY_LOWER: begin //may need to add condition if upper operation then move to multiply upper and name this multiply lower state
            if(mult_op == mulh || mult_op == mulhsu || mult_op == mulhu)
                next_state = MULTIPLY_UPPER;
            else
                next_state = DONE;
        end
        MULTIPLY_UPPER: begin
            next_state = DONE;
        end
        // SIGN_CHECK: begin
        //     next_state = DONE;
        // end
        DONE: begin
            next_state = IDLE;
        end
        default: next_state = IDLE;
    endcase
end

always_ff @(posedge clk) begin
    if(rst)
        curr_state <= IDLE;
    else
        curr_state <= next_state;
end

endmodule: dadda_controller