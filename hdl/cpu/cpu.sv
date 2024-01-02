module cpu
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
    input rv32i_word imem_rdata,
    input logic imem_resp,
    input logic dmem_resp,
    input rv32i_word dmem_rdata,
    output logic imem_read,
    output logic dmem_read,
    output logic dmem_write,
    output rv32i_word imem_address,
    output rv32i_word dmem_wdata,
    output logic [3:0] mem_byte_enable,
    output rv32i_word dmem_address
);

//logic load_pc;
logic load_if_id_reg;
logic load_id_ex_reg;
logic load_ex_mem_reg;
logic load_mem_wb_reg;
logic mem_stall;
logic mult_stall;
logic div_stall;
logic flush;
logic br_en;
logic alu_recover1, alu_recover2, pcplus4_recover;

// logic [3:0] rmask;
// logic [3:0] wmask;

rv32i_word wbmux_out;
rv32i_word alu_out;
rv32i_word load_out;

pcmux::pcmux_sel_t pcmux_sel;

ctrl_word::ctrl_word_t ctrl_word;
IF_ID_Reg::if_id_reg_t if_id_reg;
IF_ID_Reg::if_id_reg_t if_id_reg_next;
ID_EX_Reg::id_ex_reg_t id_ex_reg;
ID_EX_Reg::id_ex_reg_t id_ex_reg_next;
EX_MEM_REG::ex_mem_reg_t ex_mem_reg;
EX_MEM_REG::ex_mem_reg_t ex_mem_reg_next;
MEM_WB_REG::mem_wb_reg_t mem_wb_reg;
MEM_WB_REG::mem_wb_reg_t mem_wb_reg_next;

fetch_stage FETCH
(
    .clk(clk),
    .rst(rst),
    .alu_out__mangled(alu_out),
    .imem_resp(imem_resp),
    .imem_rdata(imem_rdata),
    .imem_read(imem_read),
    .imem_address(imem_address),
    .ex_mem_reg(ex_mem_reg),
    .mem_wb_reg(mem_wb_reg),
    .id_ex_reg(id_ex_reg),
    .if_id_reg_next(if_id_reg_next),
    .stall(mem_stall),
    .mult_stall(mult_stall),
    .div_stall(div_stall),
    .flush(flush),
    .alu_recover1(alu_recover1),
    .alu_recover2(alu_recover2),
    .pcplus4_recover(pcplus4_recover),
    .br_en__mangled(br_en),
    .pcmux_sel(pcmux_sel),
    .load_if_id_reg(load_if_id_reg)
);

decode_stage DECODE
(
    .clk(clk),
    .rst(rst),
    .wbmux_out(wbmux_out),
    .if_id_reg(if_id_reg),
    .mem_wb_reg(mem_wb_reg),
    .id_ex_reg_next(id_ex_reg_next),
    .load_if_id_reg(load_if_id_reg),
    .load_id_ex_reg(load_id_ex_reg),
    .id_ex_reg(id_ex_reg)
    //.ex_mem_reg(ex_mem_reg)
);

execute_stage EXECUTE
(
    .clk(clk),
    .rst(rst),
    .id_ex_reg(id_ex_reg),
    .if_id_reg(if_id_reg),
    .ex_mem_reg(ex_mem_reg),
    .mem_wb_reg(mem_wb_reg),
    .wbmux_out(wbmux_out),
    .ex_mem_reg_next(ex_mem_reg_next),
    .alu_out__mangled(alu_out),
    .flush(flush),
    .mult_stall(mult_stall),
    .div_stall(div_stall),
    .alu_recover1(alu_recover1),
    .alu_recover2(alu_recover2),
    .pcplus4_recover(pcplus4_recover),
    .dmem_resp(dmem_resp),
    .load_ex_mem_reg(load_ex_mem_reg),
    .load_id_ex_reg(load_id_ex_reg),
    .br_en__mangled(br_en),
    .pcmux_sel(pcmux_sel),
    .load_out(load_out)
);

mem_stage MEM
(
    //.clk(clk),
    //.rst(rst),
    .dmem_resp(dmem_resp),
    .dmem_rdata(dmem_rdata),
    .ex_mem_reg(ex_mem_reg),
    .mem_wb_reg_next(mem_wb_reg_next),
    .load_ex_mem_reg(load_ex_mem_reg),
    .load_mem_wb_reg(load_mem_wb_reg),
    .dmem_wdata(dmem_wdata),
    .dmem_address(dmem_address),
    .dmem_read(dmem_read),
    .dmem_write(dmem_write),
    .stall(mem_stall),
    .mem_byte_enable(mem_byte_enable),
    .load_out(load_out)
);

writeback_stage WRITEBACK
(
    //.clk(clk),
    //.rst(rst),
    .mem_wb_reg(mem_wb_reg),
    .wbmux_out(wbmux_out)
);

always_ff @(posedge clk) begin
    if(rst) begin
        id_ex_reg <= '0;
        if_id_reg <= '0;
        ex_mem_reg <= '0;
        mem_wb_reg <= '0;
    end
    else begin
        if(load_if_id_reg) begin
            if_id_reg.instruction <= imem_rdata;
            if_id_reg.pc_plus4 <= if_id_reg_next.pc_plus4;
            if_id_reg.pc_out <= if_id_reg_next.pc_out; 
            if_id_reg.pcmux_sel <= if_id_reg_next.pcmux_sel;
            if_id_reg.pcmux_out <= if_id_reg_next.pcmux_out; 
            if_id_reg.load_pc <= if_id_reg_next.load_pc;
            if_id_reg.prediction <= if_id_reg_next.prediction;
            if_id_reg.BTB_hit <= if_id_reg_next.BTB_hit;
            if_id_reg.BTB_hit_idx <= if_id_reg_next.BTB_hit_idx;
        end
        if(load_id_ex_reg)
            id_ex_reg <= id_ex_reg_next;
        if(load_ex_mem_reg)
            ex_mem_reg <= ex_mem_reg_next;
        if(load_mem_wb_reg)
            mem_wb_reg <= mem_wb_reg_next;

        if(flush) begin
            id_ex_reg <= '0;
            if_id_reg <= '0;
        end 
    end
end

endmodule: cpu