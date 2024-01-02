module writeback_stage
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
    input mem_wb_reg_t mem_wb_reg,
    output rv32i_word wbmux_out
);

always_comb begin: MUXES
    unique case(mem_wb_reg.ctrl_word.wbmux_sel)
        wbmux::pc_plus4: wbmux_out = mem_wb_reg.pc_plus4;
        wbmux::alu_out: wbmux_out = mem_wb_reg.alu_out;
        wbmux::mul_lower: wbmux_out = mem_wb_reg.mul_lower;
        wbmux::mul_upper: wbmux_out = mem_wb_reg.mul_upper;
        wbmux::quotient_out: wbmux_out = mem_wb_reg.quotient_out;
        wbmux::rem_out: wbmux_out = mem_wb_reg.rem_out;
        wbmux::cmp_out: wbmux_out = mem_wb_reg.cmp_out;
        wbmux::u_imm: wbmux_out = mem_wb_reg.ctrl_word.u_imm;
        wbmux::lh_out: wbmux_out = mem_wb_reg.lh_out;
        wbmux::lhu_out: wbmux_out = mem_wb_reg.lhu_out;
        wbmux::lb_out: wbmux_out = mem_wb_reg.lb_out;
        wbmux::lbu_out: wbmux_out = mem_wb_reg.lbu_out;
        wbmux::lw_out: wbmux_out = mem_wb_reg.lw_out;
        wbmux::br_en: wbmux_out = mem_wb_reg.cmp_out;
        default: wbmux_out = '0;
    endcase
end

endmodule: writeback_stage