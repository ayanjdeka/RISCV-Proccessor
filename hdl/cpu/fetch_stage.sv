module fetch_stage
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
    input rv32i_word alu_out__mangled,
    input logic imem_resp,
    input rv32i_word imem_rdata,
    input ex_mem_reg_t ex_mem_reg,
    input mem_wb_reg_t mem_wb_reg,
    input id_ex_reg_t id_ex_reg,
    input logic stall,
    input logic mult_stall,
    input logic div_stall,
    input logic flush,
    input logic br_en__mangled,
    input logic alu_recover1,
    input logic alu_recover2,
    input logic pcplus4_recover,
    input pcmux_sel_t pcmux_sel,
    output logic imem_read,
    output rv32i_word imem_address,
    output if_id_reg_t if_id_reg_next,
    output logic load_if_id_reg
);

logic load_pc;
rv32i_word pc_out;
rv32i_word pcmux_out;
//pcmux_sel_t pcmux_sel;

//assign load_pc = ~stall;

logic prediction;
logic BTB_hit;
logic [1:0] BTB_hit_idx;
logic [31:0] predicted_address;


pc PC(
    .clk(clk),
    .rst(rst),
    .load(load_pc),
    .in(pcmux_out),
    .data_out(pc_out)
);

BTB BTB
(
    .clk(clk),
    .rst(rst),
    .pc_fetch(pc_out), 
    .pc_branch(id_ex_reg.pc_out), 
    .prediction(prediction), 
    .alu_recover1(alu_recover1),
    .alu_recover2(alu_recover2),
    .pcplus4_recover(pcplus4_recover),
    .id_ex_reg(id_ex_reg),
    .BTB_kill_idx(id_ex_reg.BTB_hit_idx), 
    .target_address(alu_out__mangled), 
    .BTB_hit(BTB_hit),
    .predicted_address(predicted_address),
    .BTB_hit_idx(BTB_hit_idx)
);

global_predictor BRANCH_PREDICTOR
(
    .clk(clk),
    .rst(rst),
    .opcode(id_ex_reg.ctrl_word.opcode),
    .br_en(br_en__mangled),
    .prediction(prediction)
);

assign imem_address = pc_out;
assign imem_read = '1;

always_comb begin: set_if_id

    if(imem_resp && ~stall && ~mult_stall && ~div_stall) begin
        load_if_id_reg = '1;
        load_pc = '1;
    end
    else if(flush && ~stall && ~mult_stall && ~div_stall) begin
        load_if_id_reg = '1;
        load_pc = '1;
    end
    else begin
        load_if_id_reg = '0;
        load_pc = '0;
    end

//   if(imem_resp) begin
        if_id_reg_next.instruction = imem_rdata; //might need to check comb vs ff timing for this
        if_id_reg_next.pc_plus4 = pc_out + 4;
        if_id_reg_next.pc_out = pc_out;
        if_id_reg_next.pcmux_sel = pcmux_sel;
        if_id_reg_next.pcmux_out = pcmux_out;
        if_id_reg_next.load_pc = load_pc;
        if_id_reg_next.prediction = prediction;
        if_id_reg_next.BTB_hit = BTB_hit;
        if_id_reg_next.BTB_hit_idx = BTB_hit_idx;
//   end
end



always_comb begin: MUXES
    unique case(pcmux_sel)
        pcmux::pc_plus4: begin
            if(BTB_hit && prediction)
                pcmux_out = predicted_address;
            else
                pcmux_out = pc_out + 4;
        end
        pcmux::alu_out: begin
            if(alu_recover1 || alu_recover2)
                pcmux_out = alu_out__mangled;
            else if(pcplus4_recover)
                pcmux_out = id_ex_reg.pc_plus4;
            else
                pcmux_out = pc_out + 4;
        end
        pcmux::alu_mod2: pcmux_out = {alu_out__mangled[31:1], 1'b0};
        pcmux::alu_out_jal: pcmux_out = alu_out__mangled;
        default: pcmux_out = pc_out + 4;
    endcase
end


endmodule: fetch_stage 