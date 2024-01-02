module mem_stage
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
    input logic dmem_resp,
    input rv32i_word dmem_rdata,
    input ex_mem_reg_t ex_mem_reg,
    input logic load_ex_mem_reg,
    output mem_wb_reg_t mem_wb_reg_next,
    output logic load_mem_wb_reg,
    output rv32i_word dmem_wdata,
    output rv32i_word dmem_address,
    output logic dmem_write,
    output logic dmem_read,
    output logic stall,
    output logic [3:0] mem_byte_enable,
    output rv32i_word load_out
);

rv32i_word lb_out;
rv32i_word lbu_out;
rv32i_word lh_out;
rv32i_word lhu_out;
rv32i_word lw_out;

logic [3:0] rmask, wmask;

assign dmem_wdata = ex_mem_reg.dmem_wdata;
assign dmem_read = ex_mem_reg.ctrl_word.dmem_read;
assign dmem_write = ex_mem_reg.ctrl_word.dmem_write;
assign dmem_address = ex_mem_reg.dmem_address;

always_comb begin: set_mem_wb
    mem_wb_reg_next.pc_plus4 = ex_mem_reg.pc_plus4;
    mem_wb_reg_next.alu_out = ex_mem_reg.alu_out;
    mem_wb_reg_next.cmp_out = ex_mem_reg.cmp_out;
    mem_wb_reg_next.lh_out = lh_out;
    mem_wb_reg_next.lhu_out = lhu_out;
    mem_wb_reg_next.lb_out = lb_out;
    mem_wb_reg_next.lbu_out = lbu_out;
    mem_wb_reg_next.lw_out = lw_out;
    mem_wb_reg_next.dmem_address = ex_mem_reg.dmem_address;
    mem_wb_reg_next.dmem_rdata = dmem_rdata;
    mem_wb_reg_next.dmem_wdata = ex_mem_reg.dmem_wdata;
    mem_wb_reg_next.rmask = rmask;
    mem_wb_reg_next.wmask = wmask;
    mem_wb_reg_next.ctrl_word = ex_mem_reg.ctrl_word;
    mem_wb_reg_next.mul_lower = ex_mem_reg.mul_lower;
    mem_wb_reg_next.mul_upper = ex_mem_reg.mul_upper;
    mem_wb_reg_next.quotient_out = ex_mem_reg.quotient_out;
    mem_wb_reg_next.rem_out = ex_mem_reg.rem_out;
    if(load_ex_mem_reg)
        load_mem_wb_reg = '1;
    else   
        load_mem_wb_reg = '0;
    if(ex_mem_reg.pcplus4_recover)
        mem_wb_reg_next.ctrl_word.pcmux_out = ex_mem_reg.pc_plus4;    
    else if(ex_mem_reg.ctrl_word.opcode == op_br && ex_mem_reg.br_en)
        mem_wb_reg_next.ctrl_word.pcmux_out = ex_mem_reg.alu_out;
    else if(ex_mem_reg.ctrl_word.opcode == op_jal)
        mem_wb_reg_next.ctrl_word.pcmux_out = ex_mem_reg.alu_out;
    else if(ex_mem_reg.ctrl_word.opcode == op_jalr)
        mem_wb_reg_next.ctrl_word.pcmux_out = {ex_mem_reg.alu_out[31:1], 1'b0};

end

always_comb begin: data_hazard_detection
    if(dmem_resp)
        stall = '0;
    else if(dmem_read) //&& (id_ex_reg.ctrl_word.rd == if_id_reg.instruction[24:20] || id_ex_reg.ctrl_word.rd == if_id_reg.instruction[19:15]))    
        stall = '1;
    else if(dmem_write)
        stall = '1;
    else      
        stall = '0; 
end

always_comb begin: MUXES
    rmask = '0;
    wmask = '0;
    lw_out = '0;
    lhu_out = '0;
    lh_out = '0;
    lb_out = '0;
    lbu_out = '0;
    load_out = '0;
    mem_byte_enable = '0;
    if(ex_mem_reg.ctrl_word.dmem_read) begin
        unique case(ex_mem_reg.ctrl_word.load_funct3)
            lb: begin
                unique case(ex_mem_reg.mar_low)
                    2'b00: begin
                        rmask = 4'b0001;
                    if(dmem_resp)
                        lb_out = {{24{dmem_rdata[7]}},dmem_rdata[7:0]};
                    end
                    2'b01: begin
                        rmask = 4'b0010;
                    if(dmem_resp)
                        lb_out = {{24{dmem_rdata[15]}},dmem_rdata[15:8]};
                    end
                    2'b10: begin
                        rmask = 4'b0100;
                    if(dmem_resp)
                        lb_out = {{24{dmem_rdata[23]}},dmem_rdata[23:16]};
                    end
                    2'b11: begin
                        rmask = 4'b1000;
                    if(dmem_resp)
                        lb_out = {{24{dmem_rdata[31]}},dmem_rdata[31:24]};
                    end
                    default: begin
                        rmask = '0;
                        lb_out = '0;
                    end
                endcase
                load_out = lb_out;
            end

            lbu: begin
                unique case(ex_mem_reg.mar_low)
                    2'b00: begin
                        rmask = 4'b0001;
                    if(dmem_resp)
                        lbu_out = {{24{1'b0}},dmem_rdata[7:0]};
                    end
                    2'b01: begin
                        rmask = 4'b0010;
                    if(dmem_resp)
                        lbu_out = {{24{1'b0}},dmem_rdata[15:8]};
                    end
                    2'b10: begin
                        rmask = 4'b0100;
                    if(dmem_resp)
                        lbu_out = {{24{1'b0}},dmem_rdata[23:16]};
                    end
                    2'b11: begin
                        rmask = 4'b1000;
                    if(dmem_resp)
                        lbu_out = {{24{1'b0}},dmem_rdata[31:24]};
                    end
                    default: begin
                        rmask = '0;
                        lbu_out = '0;
                    end
                endcase
                load_out = lbu_out;
            end

            lh: begin
                if(~ex_mem_reg.mar_low[1]) begin
                    rmask = 4'b0011;
                if(dmem_resp)
                    lh_out = {{16{dmem_rdata[15]}},dmem_rdata[15:0]};
                end
                else if(ex_mem_reg.mar_low[1]) begin
                    rmask = 4'b1100;
                if(dmem_resp)
                    lh_out = {{16{dmem_rdata[31]}},dmem_rdata[31:16]};
                end
                load_out = lh_out;
            end

            lhu: begin
                if(~ex_mem_reg.mar_low[1]) begin
                    rmask = 4'b0011;
                if(dmem_resp)
                    lhu_out = {{16{1'b0}},dmem_rdata[15:0]};
                end
                else if(ex_mem_reg.mar_low[1]) begin
                    rmask = 4'b1100;
                if(dmem_resp)
                    lhu_out = {{16{1'b0}},dmem_rdata[31:16]};
                end
                load_out = lhu_out;
            end

            lw: begin
            rmask = 4'b1111;
            if(dmem_resp)
                lw_out = dmem_rdata;
            load_out = lw_out;    
            end
            default: ;
        endcase
    end
    else if(ex_mem_reg.ctrl_word.dmem_write) begin
        unique case(ex_mem_reg.ctrl_word.store_funct3)
            sb: begin
                unique case(ex_mem_reg.mar_low)
                    2'b00: begin
                        wmask = 4'b0001;
                        mem_byte_enable = 4'b0001;
                    end
                    2'b01: begin
                        wmask = 4'b0010;
                        mem_byte_enable = 4'b0010;
                    end
                    2'b10: begin
                        wmask = 4'b0100;
                        mem_byte_enable = 4'b0100;
                    end
                    2'b11: begin
                        wmask = 4'b1000;
                        mem_byte_enable = 4'b1000;
                    end
                    default: begin
                        wmask = '0;
                        mem_byte_enable = '0;
                    end
                endcase
            end

            sh: begin
                if(~ex_mem_reg.mar_low[1]) begin
                    wmask = 4'b0011;
                    mem_byte_enable = 4'b0011;
                end
                else if(ex_mem_reg.mar_low[1]) begin
                    wmask = 4'b1100;
                    mem_byte_enable = 4'b1100;
                end
            end

            sw: begin
                wmask = 4'b1111;
                mem_byte_enable = 4'b1111;
            end

            default: ;
        endcase
    end
end
endmodule: mem_stage