module execute_stage
import rv32i_types::*;
import pcmux::*;
import cmpmux::*;
import alumux::*;
import wbmux::*;
import dmux::*;
import rv32i_opcode::*;
import branch_funct3::*;
import load_funct3::*;
import store_funct3::*;
import arith_funct3::*;
import alu_ops::*;
import ctrl_word::*;
import IF_ID_Reg::*;
import ID_EX_Reg::*;
import EX_MEM_REG::*;
import MEM_WB_REG::*;
(
    input clk,
    input rst,
    input id_ex_reg_t id_ex_reg,
    input if_id_reg_t if_id_reg,
    input ex_mem_reg_t ex_mem_reg,
    input mem_wb_reg_t mem_wb_reg,
    input rv32i_word wbmux_out,
    input logic load_id_ex_reg,
    input rv32i_word load_out,
    input logic dmem_resp,
    output ex_mem_reg_t ex_mem_reg_next,
    output rv32i_word alu_out__mangled,
    output logic flush,
    output logic alu_recover1,
    output logic alu_recover2,
    output logic pcplus4_recover,
    output logic mult_stall,
    output logic div_stall,
    output logic load_ex_mem_reg,
    output logic br_en__mangled,
    output pcmux_sel_t pcmux_sel
);

rv32i_word alumux1_out; 
rv32i_word alumux2_out;
rv32i_word cmpmux_out;

logic [63:0] mult_out;
logic mult_done;

logic [31:0] quotient, remainder;
logic div_done;

logic [1:0] forward_out1;
logic [1:0] forward_out2;

logic [31:0] forward_rs1;
logic [31:0] forward_rs2;

logic branch_flush;

assign alu_recover1 = (id_ex_reg.ctrl_word.opcode == op_br) && (id_ex_reg.BTB_hit && ~id_ex_reg.prediction && br_en__mangled);
assign alu_recover2 = (id_ex_reg.ctrl_word.opcode == op_br) && (~id_ex_reg.BTB_hit && br_en__mangled);
assign pcplus4_recover = (id_ex_reg.ctrl_word.opcode == op_br) && (id_ex_reg.BTB_hit && id_ex_reg.prediction && ~br_en__mangled);

alu ALU (
    .aluop(id_ex_reg.ctrl_word.aluop),
    .a(alumux1_out), 
    .b(alumux2_out),
    .f(alu_out__mangled)
);

dadda MULTIPLIER(
    .clk(clk),
    .rst(rst),
    .start(id_ex_reg.ctrl_word.start_mul),
    .mult_op(id_ex_reg.ctrl_word.mult_funct3),
    .A(forward_rs1),
    .B(forward_rs2),
    .C(mult_out),
    .o_rdy(mult_done),
    .mult_stall(mult_stall)
);

divider DIVIDER
(
    .clk(clk),
    .rst(rst),
    .div_start(id_ex_reg.ctrl_word.start_div),
    .div_op(id_ex_reg.ctrl_word.mult_funct3),
    .dividend(forward_rs1), 
    .divisor(forward_rs2), 
    .quotient(quotient), 
    .remainder(remainder), 
    .div_stall(div_stall),
    .div_done(div_done)
);


// add_shift_multiplier MULTIPLIER(
//     .clk(),
//     .reset_n_i(),
//     .multiplicand_i(),
//     .multiplier_i(),
//     .start_i(),
//     .ready_o(),
//     .product_o(),
//     .done_o()
// );

cmp CMP(
    .in_1(forward_rs1),
    .in_2(cmpmux_out),
    .cmpop(id_ex_reg.ctrl_word.cmpop),
    .br_en(br_en__mangled)
);


forwarding_unit forwarding_unit(
    .id_ex_reg(id_ex_reg),
    .ex_mem_reg(ex_mem_reg),
    .mem_wb_reg(mem_wb_reg),
    .forward_out1(forward_out1),
    .forward_out2(forward_out2)
);


//assign dmem_wdata = id_ex_reg.ctrl_word.rs2_out << (alu_out[1:0] * 8);
//assign dmem_address = {alu_out[31:2], 2'b00};
//assign dmem_read = id_ex_reg.ctrl_word.dmem_read;
//assign dmem_write = id_ex_reg.ctrl_word.dmem_write;

always_comb begin: set_ex_mem
    ex_mem_reg_next.pc_plus4 = id_ex_reg.pc_plus4;
    ex_mem_reg_next.alu_out = alu_out__mangled;
    //add mul_out next logic
    ex_mem_reg_next.rs2_out = id_ex_reg.rs2_out;
    ex_mem_reg_next.br_en = br_en__mangled;
    ex_mem_reg_next.pcplus4_recover = pcplus4_recover;
    ex_mem_reg_next.cmp_out = {31'b0, br_en__mangled};
    ex_mem_reg_next.dmem_address = {alu_out__mangled[31:2], 2'b00};
    ex_mem_reg_next.mar_low = alu_out__mangled[1:0];
    ex_mem_reg_next.dmem_wdata = forward_rs2 << (alu_out__mangled[1:0] * 8);
    ex_mem_reg_next.mul_lower = mult_out[31:0];
    ex_mem_reg_next.mul_upper = mult_out[63:32];
    ex_mem_reg_next.quotient_out = quotient;
    ex_mem_reg_next.rem_out = remainder;
    if(load_id_ex_reg)
        load_ex_mem_reg = '1;
    else   
        load_ex_mem_reg = '0;
    flush = '0;
    branch_flush = '0;
    if((ex_mem_reg.ctrl_word.opcode == op_store || ex_mem_reg.ctrl_word.opcode == op_load) && (alu_recover1 || alu_recover2 || pcplus4_recover)) begin
        flush = dmem_resp;
        branch_flush = '1;
    end
    else if((id_ex_reg.ctrl_word.opcode == op_jalr || id_ex_reg.ctrl_word.opcode == op_jal) && (ex_mem_reg.ctrl_word.opcode == op_store || ex_mem_reg.ctrl_word.opcode == op_load))
        flush = dmem_resp;
    else if(alu_recover1 || alu_recover2 || pcplus4_recover) begin
        flush = '1;    
        branch_flush = '1;
    end
    else if((id_ex_reg.ctrl_word.opcode == op_jal || id_ex_reg.ctrl_word.opcode == op_jalr))
        flush = '1;
    else begin
        flush = '0;    
        branch_flush = '0; 
    end
end

always_comb begin: pcmuxselect
    if((alu_recover1 || alu_recover2 || pcplus4_recover))
        pcmux_sel = pcmux::alu_out;
    else if(id_ex_reg.ctrl_word.opcode == op_jalr)
        pcmux_sel = pcmux::alu_mod2;
    else if(id_ex_reg.ctrl_word.opcode == op_jal)    
        pcmux_sel = pcmux::alu_out_jal;
    else
        pcmux_sel = pcmux::pc_plus4;    
end

always_comb begin: FORWARDING
    ex_mem_reg_next.ctrl_word = id_ex_reg.ctrl_word;
    unique case(forward_out1)
        2'b00: begin
            forward_rs1 = id_ex_reg.ctrl_word.rs1_out;
            ex_mem_reg_next.ctrl_word.rs1_out = id_ex_reg.ctrl_word.rs1_out;
        end
        2'b01: begin
        unique case(ex_mem_reg.ctrl_word.wbmux_sel)
            wbmux::pc_plus4: begin
                forward_rs1 = ex_mem_reg.pc_plus4;
                ex_mem_reg_next.ctrl_word.rs1_out = ex_mem_reg.pc_plus4;
            end
            wbmux::alu_out: begin
                forward_rs1 = ex_mem_reg.alu_out;
                ex_mem_reg_next.ctrl_word.rs1_out = ex_mem_reg.alu_out;
            end
            wbmux::mul_lower: begin
                forward_rs1 = ex_mem_reg.mul_lower;
                ex_mem_reg_next.ctrl_word.rs1_out = ex_mem_reg.mul_lower;
            end
            wbmux::mul_upper: begin
                forward_rs1 = ex_mem_reg.mul_upper;
                ex_mem_reg_next.ctrl_word.rs1_out = ex_mem_reg.mul_upper;
            end
            wbmux::quotient_out: begin
                forward_rs1 = ex_mem_reg.quotient_out;
                ex_mem_reg_next.ctrl_word.rs1_out = ex_mem_reg.quotient_out;
            end
            wbmux::rem_out: begin
                forward_rs1 = ex_mem_reg.rem_out;
                ex_mem_reg_next.ctrl_word.rs1_out = ex_mem_reg.rem_out; 
            end
            wbmux::cmp_out: begin
                 forward_rs1 = {31'b0, ex_mem_reg.br_en};
                 ex_mem_reg_next.ctrl_word.rs1_out = {31'b0, ex_mem_reg.br_en};
            end
            wbmux::u_imm: begin
                forward_rs1 = ex_mem_reg.ctrl_word.u_imm;
                ex_mem_reg_next.ctrl_word.rs1_out = ex_mem_reg.ctrl_word.u_imm;
            end
            wbmux::lh_out: begin
                forward_rs1 = load_out;
                ex_mem_reg_next.ctrl_word.rs1_out = load_out;
            end
            wbmux::lhu_out: begin
                forward_rs1 = load_out;
                ex_mem_reg_next.ctrl_word.rs1_out = load_out;
            end 
            wbmux::lb_out: begin
                forward_rs1 = load_out;
                ex_mem_reg_next.ctrl_word.rs1_out = load_out;
            end
            wbmux::lbu_out: begin
                forward_rs1 = load_out;
                ex_mem_reg_next.ctrl_word.rs1_out = load_out;
            end
            wbmux::lw_out: begin
                forward_rs1 = load_out;
                ex_mem_reg_next.ctrl_word.rs1_out = load_out;
            end
            wbmux::br_en: begin
                 forward_rs1 = {31'b0, ex_mem_reg.br_en};
                 ex_mem_reg_next.ctrl_word.rs1_out = {31'b0, ex_mem_reg.br_en};
            end
        default: begin
            forward_rs1 = ex_mem_reg.alu_out;
            ex_mem_reg_next.ctrl_word.rs1_out = ex_mem_reg.alu_out;
        end
        endcase
        end
        2'b10: begin
            forward_rs1 = wbmux_out;
            ex_mem_reg_next.ctrl_word.rs1_out = wbmux_out;
        end
        default: begin
            forward_rs1 = id_ex_reg.ctrl_word.rs1_out;
            ex_mem_reg_next.ctrl_word.rs1_out = id_ex_reg.ctrl_word.rs1_out;            
        end
    endcase

    unique case(forward_out2)
        2'b00: begin
            forward_rs2 = id_ex_reg.ctrl_word.rs2_out;
            ex_mem_reg_next.ctrl_word.rs2_out = id_ex_reg.ctrl_word.rs2_out;
        end
        2'b01: begin 
        unique case(ex_mem_reg.ctrl_word.wbmux_sel)
            wbmux::pc_plus4: begin
                forward_rs2 = ex_mem_reg.pc_plus4;
                ex_mem_reg_next.ctrl_word.rs2_out = ex_mem_reg.pc_plus4;
            end
            wbmux::alu_out: begin
                forward_rs2 = ex_mem_reg.alu_out;
                ex_mem_reg_next.ctrl_word.rs2_out = ex_mem_reg.alu_out;
            end
            wbmux::mul_lower: begin
                forward_rs2 = ex_mem_reg.mul_lower;
                ex_mem_reg_next.ctrl_word.rs2_out = ex_mem_reg.mul_lower;
            end
            wbmux::mul_upper: begin
                forward_rs2 = ex_mem_reg.mul_upper;
                ex_mem_reg_next.ctrl_word.rs2_out = ex_mem_reg.mul_upper;
            end
            wbmux::quotient_out: begin
                forward_rs2 = ex_mem_reg.quotient_out;
                ex_mem_reg_next.ctrl_word.rs2_out = ex_mem_reg.quotient_out;
            end
            wbmux::rem_out: begin
                forward_rs2 = ex_mem_reg.rem_out;
                ex_mem_reg_next.ctrl_word.rs2_out = ex_mem_reg.rem_out; 
            end
            wbmux::cmp_out: begin
                 forward_rs2 = {31'b0, ex_mem_reg.br_en};
                 ex_mem_reg_next.ctrl_word.rs2_out = {31'b0, ex_mem_reg.br_en};
            end
            wbmux::u_imm: begin
                forward_rs2 = ex_mem_reg.ctrl_word.u_imm;
                ex_mem_reg_next.ctrl_word.rs2_out = ex_mem_reg.ctrl_word.u_imm;
            end
            wbmux::lh_out: begin
                forward_rs2 = load_out;
                ex_mem_reg_next.ctrl_word.rs2_out = load_out;
            end
            wbmux::lhu_out: begin
                forward_rs2 = load_out;
                ex_mem_reg_next.ctrl_word.rs2_out = load_out;
            end 
            wbmux::lb_out: begin
                forward_rs2 = load_out;
                ex_mem_reg_next.ctrl_word.rs2_out = load_out;
            end
            wbmux::lbu_out: begin
                forward_rs2 = load_out;
                ex_mem_reg_next.ctrl_word.rs2_out = load_out;
            end
            wbmux::lw_out: begin
                forward_rs2 = load_out;
                ex_mem_reg_next.ctrl_word.rs2_out = load_out;
            end
            wbmux::br_en: begin
                 forward_rs2 = {31'b0, ex_mem_reg.br_en};
                 ex_mem_reg_next.ctrl_word.rs2_out = {31'b0, ex_mem_reg.br_en};
            end
        default: begin
            forward_rs2 = ex_mem_reg.alu_out;
            ex_mem_reg_next.ctrl_word.rs2_out = ex_mem_reg.alu_out;
        end
        endcase
        end
        2'b10: begin
            forward_rs2 = wbmux_out;
            ex_mem_reg_next.ctrl_word.rs2_out = wbmux_out;
        end
        default: begin
            forward_rs2 = id_ex_reg.ctrl_word.rs2_out;
            ex_mem_reg_next.ctrl_word.rs2_out = id_ex_reg.ctrl_word.rs2_out;
        end
    endcase
end

always_comb begin: MUXES
    unique case(id_ex_reg.ctrl_word.alumux1_sel)
        alumux::rs1_out: alumux1_out = forward_rs1;
        alumux::pc_out: alumux1_out = id_ex_reg.pc_out;
        default: alumux1_out = 32'h0000;
    endcase
    unique case(id_ex_reg.ctrl_word.alumux2_sel)
        alumux::i_imm: alumux2_out = id_ex_reg.ctrl_word.i_imm;
        alumux::u_imm: alumux2_out = id_ex_reg.ctrl_word.u_imm;
        alumux::b_imm: alumux2_out = id_ex_reg.ctrl_word.b_imm;
        alumux::s_imm: alumux2_out = id_ex_reg.ctrl_word.s_imm;
        alumux::j_imm: alumux2_out = id_ex_reg.ctrl_word.j_imm;
        alumux::rs2_out: alumux2_out = forward_rs2;
        default: alumux2_out = 32'h0000;
    endcase
    unique case(id_ex_reg.ctrl_word.cmpmux_sel)
        cmpmux::rs2_out: cmpmux_out = forward_rs2;
        cmpmux::i_imm: cmpmux_out = id_ex_reg.ctrl_word.i_imm;
        default: cmpmux_out = 32'h0000;
    endcase
end

endmodule: execute_stage