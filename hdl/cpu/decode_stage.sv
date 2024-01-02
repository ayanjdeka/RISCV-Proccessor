module decode_stage
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
import mult_funct3::*;
import alu_ops::*;
import ctrl_word::*;
import IF_ID_Reg::*;
import ID_EX_Reg::*;
import EX_MEM_REG::*;
import MEM_WB_REG::*;
(
    input clk,
    input rst,
    input rv32i_word wbmux_out,
    input if_id_reg_t if_id_reg,
    input mem_wb_reg_t mem_wb_reg,
    input logic load_if_id_reg,
    input id_ex_reg_t id_ex_reg,
    output id_ex_reg_t id_ex_reg_next,
    output logic load_id_ex_reg
);

logic [31:0] rs1_out, rs2_out;
ctrl_word_t ctrl_word;
logic ld_regfile;

rv32i_word lh_out;
rv32i_word lhu_out;
rv32i_word lb_out;
rv32i_word lbu_out;
rv32i_word lw_out;
rv32i_word sb_out;
rv32i_word sh_out;
rv32i_word sw_out;

//pcmux::pcmux_sel_t pcmux_sel;

logic br_en;

regfile REGFILE(
    .clk(clk),
    .rst(rst),
    .load(ld_regfile),
    .in(wbmux_out),
    .src_a(if_id_reg.instruction[19:15]), 
    .src_b(if_id_reg.instruction[24:20]), 
    .dest(mem_wb_reg.ctrl_word.rd),
    .reg_a(rs1_out), 
    .reg_b(rs2_out)
);


assign ctrl_word.instruction = if_id_reg.instruction;
assign ctrl_word.funct3 = if_id_reg.instruction[14:12];
assign ctrl_word.funct7 = if_id_reg.instruction[31:25];
assign ctrl_word.opcode = rv32i_opcode_t'(if_id_reg.instruction[6:0]);
assign ctrl_word.i_imm = {{21{if_id_reg.instruction[31]}}, if_id_reg.instruction[30:20]};
assign ctrl_word.s_imm = {{21{if_id_reg.instruction[31]}}, if_id_reg.instruction[30:25], if_id_reg.instruction[11:7]};
assign ctrl_word.b_imm = {{20{if_id_reg.instruction[31]}}, if_id_reg.instruction[7], if_id_reg.instruction[30:25], if_id_reg.instruction[11:8], 1'b0};
assign ctrl_word.u_imm = {if_id_reg.instruction[31:12], 12'h000};
assign ctrl_word.j_imm = {{12{if_id_reg.instruction[31]}}, if_id_reg.instruction[19:12], if_id_reg.instruction[20], if_id_reg.instruction[30:21], 1'b0};
assign ctrl_word.rs1 = if_id_reg.instruction[19:15];

//assign ctrl_word.rs1_out = rs1_out;
//assign ctrl_word.rs2_out = rs2_out;
assign ctrl_word.arith_funct3 = arith_funct3_t'(ctrl_word.funct3);
assign ctrl_word.mult_funct3 = mult_funct3_t'(ctrl_word.funct3);
assign ctrl_word.branch_funct3 = branch_funct3_t'(ctrl_word.funct3);
assign ctrl_word.load_funct3 = load_funct3_t'(ctrl_word.funct3);
assign ctrl_word.store_funct3 = store_funct3_t'(ctrl_word.funct3);
assign ctrl_word.pcmux_out = if_id_reg.pcmux_out;
assign ctrl_word.pc_out = if_id_reg.pc_out;
assign ctrl_word.load_pc = if_id_reg.load_pc;

function void set_defaults();
    ctrl_word.pcmux_sel = pcmux::pc_plus4;
    ctrl_word.cmpmux_sel = cmpmux::rs2_out;
    ctrl_word.alumux1_sel = alumux::rs1_out;
    ctrl_word.alumux2_sel = alumux::i_imm;
    ctrl_word.wbmux_sel = wbmux::alu_out;
    ctrl_word.aluop = alu_ops::alu_add;
    ctrl_word.cmpop = branch_funct3::beq;
    ctrl_word.mem_byte_enable = 4'b0000;
    ctrl_word.dmem_read = '0;
    ctrl_word.dmem_write = '0;
    ctrl_word.ld_regfile = '0;
    ctrl_word.start_mul = '0;
    ctrl_word.start_div = '0;
    ctrl_word.rd = '0;
    ctrl_word.rs2 = if_id_reg.instruction[24:20];
endfunction //need to call this function in our control_word_signals block

always_comb begin: hazard_detection_decode
    ctrl_word.rs1_out = rs1_out;
    ctrl_word.rs2_out = rs2_out;
    
    if((~(mem_wb_reg.ctrl_word.rd == '0)) && mem_wb_reg.ctrl_word.rd == if_id_reg.instruction[19:15] && mem_wb_reg.ctrl_word.rd == if_id_reg.instruction[24:20]) begin
        ctrl_word.rs1_out = wbmux_out;
        ctrl_word.rs2_out = wbmux_out;
    end 
    else if((~(mem_wb_reg.ctrl_word.rd == '0)) && mem_wb_reg.ctrl_word.rd == if_id_reg.instruction[19:15]) begin
        ctrl_word.rs1_out = wbmux_out;
    end
    else if((~(mem_wb_reg.ctrl_word.rd == '0)) && mem_wb_reg.ctrl_word.rd == if_id_reg.instruction[24:20]) begin
        ctrl_word.rs2_out = wbmux_out;
    end 
    //if(ctrl_word.dmemid_ex_reg.ctrl_word.rs1 == if_id_reg.instruction[24:20] || id_ex_reg.ctrl_word.rs2 == if_id_reg.instruction[19:15])
end

always_comb begin: set_control_word
    set_defaults();
    unique case (ctrl_word.opcode) //using opcode too early need to use from control word
        op_lui: begin
           ctrl_word.ld_regfile = 1'b1;
           ctrl_word.rd = if_id_reg.instruction[11:7];
           ctrl_word.wbmux_sel = wbmux::u_imm;
           ctrl_word.pcmux_sel = pcmux::pc_plus4;
        end
        op_auipc: begin
            ctrl_word.ld_regfile = 1'b1;
            ctrl_word.rd = if_id_reg.instruction[11:7];
            ctrl_word.alumux1_sel = alumux::pc_out;
            ctrl_word.alumux2_sel = alumux::u_imm;
            ctrl_word.aluop = alu_ops::alu_add;
            ctrl_word.wbmux_sel = wbmux::alu_out;
            ctrl_word.pcmux_sel = pcmux::pc_plus4;
        end
        op_jal: begin
            ctrl_word.ld_regfile = '1;
            ctrl_word.alumux1_sel = alumux::pc_out;
            ctrl_word.rd = if_id_reg.instruction[11:7];
            ctrl_word.alumux2_sel = alumux::j_imm;
            ctrl_word.aluop = alu_ops::alu_add;
            ctrl_word.wbmux_sel = wbmux::pc_plus4;
            ctrl_word.pcmux_sel = pcmux::alu_out_jal;
         end  
         op_jalr: begin
            ctrl_word.ld_regfile = '1;
            ctrl_word.rd =if_id_reg.instruction[11:7];
            ctrl_word.alumux1_sel = alumux::rs1_out;
            ctrl_word.alumux2_sel = alumux::i_imm;
            ctrl_word.aluop = alu_ops::alu_add;
            ctrl_word.wbmux_sel = wbmux::pc_plus4;
            ctrl_word.pcmux_sel = pcmux::alu_mod2;
         end
        op_br: begin   
            unique case(ctrl_word.branch_funct3) 
                beq: begin
                    ctrl_word.cmpmux_sel = cmpmux::rs2_out;
                    ctrl_word.cmpop = branch_funct3::beq;
                    ctrl_word.alumux1_sel = alumux::pc_out;
                    ctrl_word.alumux2_sel = alumux::b_imm;
                    ctrl_word.aluop = alu_ops::alu_add;     
                end
                bne: begin
                    ctrl_word.cmpmux_sel = cmpmux::rs2_out;
                    ctrl_word.cmpop = branch_funct3::bne;
                    ctrl_word.alumux1_sel = alumux::pc_out;
                    ctrl_word.alumux2_sel = alumux::b_imm;
                    ctrl_word.aluop = alu_ops::alu_add;
                end
                blt: begin
                    ctrl_word.cmpmux_sel = cmpmux::rs2_out;
                    ctrl_word.cmpop = branch_funct3::blt;
                    ctrl_word.alumux1_sel = alumux::pc_out;
                    ctrl_word.alumux2_sel = alumux::b_imm;
                    ctrl_word.aluop = alu_ops::alu_add;
                end

                bge: begin
                    ctrl_word.cmpmux_sel = cmpmux::rs2_out;
                    ctrl_word.cmpop = branch_funct3::bge;
                    ctrl_word.alumux1_sel = alumux::pc_out;
                    ctrl_word.alumux2_sel = alumux::b_imm;
                    ctrl_word.aluop = alu_ops::alu_add;
                end
                bltu: begin
                    ctrl_word.cmpmux_sel = cmpmux::rs2_out;
                    ctrl_word.cmpop = branch_funct3::bltu;
                    ctrl_word.alumux1_sel = alumux::pc_out;
                    ctrl_word.alumux2_sel = alumux::b_imm;
                    ctrl_word.aluop = alu_add;
                end
                bgeu: begin
                    ctrl_word.cmpmux_sel = cmpmux::rs2_out;
                    ctrl_word.cmpop = branch_funct3::bgeu;
                    ctrl_word.alumux1_sel = alumux::pc_out;
                    ctrl_word.alumux2_sel = alumux::b_imm;
                    ctrl_word.aluop = alu_ops::alu_add;
                end
                default: begin
                    ctrl_word.cmpmux_sel = cmpmux::rs2_out;
                    ctrl_word.cmpop = branch_funct3::beq;
                    ctrl_word.alumux1_sel = alumux::pc_out;
                    ctrl_word.alumux2_sel = alumux::b_imm;
                    ctrl_word.aluop = alu_ops::alu_add;   
                end
            endcase
        end
        
        op_load: begin
                ctrl_word.dmem_read = '1;
                ctrl_word.ld_regfile = 1'b1;
                ctrl_word.rd = if_id_reg.instruction[11:7];
                ctrl_word.alumux1_sel = alumux::rs1_out;
                ctrl_word.alumux2_sel = alumux::i_imm;
                ctrl_word.aluop = alu_ops::alu_add;
                unique case(ctrl_word.load_funct3)
                    lb: ctrl_word.wbmux_sel = wbmux::lb_out;
                    lbu: ctrl_word.wbmux_sel = wbmux::lbu_out;
                    lh: ctrl_word.wbmux_sel = wbmux::lh_out;
                    lhu: ctrl_word.wbmux_sel = wbmux::lhu_out;
                    lw: ctrl_word.wbmux_sel = wbmux::lw_out;
                    default: ctrl_word.wbmux_sel = wbmux::lw_out;
                endcase
        end 
        op_store: begin
                ctrl_word.dmem_write = '1;
                ctrl_word.alumux1_sel = alumux::rs1_out;
                ctrl_word.alumux2_sel = alumux::s_imm;
                ctrl_word.aluop = alu_ops::alu_add;
        end
        op_imm: begin
            ctrl_word.rs2 = '0;
            unique case(ctrl_word.arith_funct3)
                add: begin
                    ctrl_word.ld_regfile = 1'b1;
                    ctrl_word.rd = if_id_reg.instruction[11:7];
                    ctrl_word.wbmux_sel = wbmux::alu_out;
                    ctrl_word.alumux1_sel = alumux::rs1_out;
                    ctrl_word.alumux2_sel = alumux::i_imm;
                    ctrl_word.aluop = alu_ops::alu_add;
                    ctrl_word.pcmux_sel = pcmux::pc_plus4;
                end

                sll: begin
                    ctrl_word.ld_regfile = 1'b1;
                    ctrl_word.rd = if_id_reg.instruction[11:7];
                    ctrl_word.wbmux_sel = wbmux::alu_out;
                    ctrl_word.alumux1_sel = alumux::rs1_out;
                    ctrl_word.alumux2_sel = alumux::i_imm;
                    ctrl_word.aluop = alu_ops::alu_sll;
                    ctrl_word.pcmux_sel = pcmux::pc_plus4;
                end

                slt: begin
                    ctrl_word.ld_regfile = 1'b1;
                    ctrl_word.rd = if_id_reg.instruction[11:7];
                    ctrl_word.wbmux_sel = wbmux::br_en;
                    ctrl_word.cmpmux_sel = cmpmux::i_imm;
                    ctrl_word.cmpop = branch_funct3::blt;
                    ctrl_word.pcmux_sel = pcmux::pc_plus4;
                end

                sltu: begin
                    ctrl_word.ld_regfile = 1'b1;
                    ctrl_word.rd = if_id_reg.instruction[11:7];
                    ctrl_word.wbmux_sel = wbmux::br_en;
                    ctrl_word.cmpmux_sel = cmpmux::i_imm;
                    ctrl_word.cmpop = branch_funct3::bltu;
                    ctrl_word.pcmux_sel = pcmux::pc_plus4;
                end

                axor: begin
                    ctrl_word.ld_regfile = 1'b1;
                    ctrl_word.rd = if_id_reg.instruction[11:7];
                    ctrl_word.wbmux_sel = wbmux::alu_out;
                    ctrl_word.alumux1_sel = alumux::rs1_out;
                    ctrl_word.alumux2_sel = alumux::i_imm;
                    ctrl_word.aluop = alu_ops::alu_xor;
                    ctrl_word.pcmux_sel = pcmux::pc_plus4;
                end

                sr: begin
                    if(ctrl_word.i_imm[10]) begin
                        ctrl_word.ld_regfile = 1'b1;
                        ctrl_word.rd = if_id_reg.instruction[11:7];
                        ctrl_word.wbmux_sel = wbmux::alu_out;
                        ctrl_word.alumux1_sel = alumux::rs1_out;
                        ctrl_word.alumux2_sel = alumux::i_imm;
                        ctrl_word.aluop = alu_ops::alu_sra;
                        ctrl_word.pcmux_sel = pcmux::pc_plus4;
                    end
                    else begin
                        ctrl_word.ld_regfile = 1'b1;
                        ctrl_word.rd = if_id_reg.instruction[11:7];
                        ctrl_word.wbmux_sel = wbmux::alu_out;
                        ctrl_word.alumux1_sel = alumux::rs1_out;
                        ctrl_word.alumux2_sel = alumux::i_imm;
                        ctrl_word.aluop = alu_ops::alu_srl;
                        ctrl_word.pcmux_sel = pcmux::pc_plus4;
                    end
                end

                aor: begin
                    ctrl_word.ld_regfile = 1'b1;
                    ctrl_word.rd = if_id_reg.instruction[11:7];
                    ctrl_word.wbmux_sel = wbmux::alu_out;
                    ctrl_word.alumux1_sel = alumux::rs1_out;
                    ctrl_word.alumux2_sel = alumux::i_imm;
                    ctrl_word.aluop = alu_ops::alu_or;
                    ctrl_word.pcmux_sel = pcmux::pc_plus4;
                end

                aand: begin
                    ctrl_word.ld_regfile = 1'b1;
                    ctrl_word.rd = if_id_reg.instruction[11:7];
                    ctrl_word.wbmux_sel = wbmux::alu_out;
                    ctrl_word.alumux1_sel = alumux::rs1_out;
                    ctrl_word.alumux2_sel = alumux::i_imm;
                    ctrl_word.aluop = alu_ops::alu_and;
                    ctrl_word.pcmux_sel = pcmux::pc_plus4;
                end
            endcase
        end
        op_reg: begin
            if(ctrl_word.funct7[0]) begin
                unique case(ctrl_word.mult_funct3)
                    mul: begin
                        ctrl_word.ld_regfile = 1'b1;
                        ctrl_word.rd = if_id_reg.instruction[11:7];
                        ctrl_word.wbmux_sel = wbmux::mul_lower;
                        ctrl_word.pcmux_sel = pcmux::pc_plus4;
                        ctrl_word.start_mul = '1;
                    end

                    mulh: begin
                        ctrl_word.ld_regfile = 1'b1;
                        ctrl_word.rd = if_id_reg.instruction[11:7];
                        ctrl_word.wbmux_sel = wbmux::mul_upper;
                        ctrl_word.pcmux_sel = pcmux::pc_plus4;
                        ctrl_word.start_mul = '1;
                    end

                    mulhsu: begin
                        ctrl_word.ld_regfile = 1'b1;
                        ctrl_word.rd = if_id_reg.instruction[11:7];
                        ctrl_word.wbmux_sel = wbmux::mul_upper;
                        ctrl_word.pcmux_sel = pcmux::pc_plus4;
                        ctrl_word.start_mul = '1;
                    end

                    mulhu: begin
                        ctrl_word.ld_regfile = 1'b1;
                        ctrl_word.rd = if_id_reg.instruction[11:7];
                        ctrl_word.wbmux_sel = wbmux::mul_upper;
                        ctrl_word.pcmux_sel = pcmux::pc_plus4;
                        ctrl_word.start_mul = '1;
                    end

                    div: begin
                        ctrl_word.ld_regfile = 1'b1;
                        ctrl_word.rd = if_id_reg.instruction[11:7];
                        ctrl_word.wbmux_sel = wbmux::quotient_out;
                        ctrl_word.pcmux_sel = pcmux::pc_plus4;
                        ctrl_word.start_div = '1;
                    end
                
                    divu: begin
                        ctrl_word.ld_regfile = 1'b1;
                        ctrl_word.rd = if_id_reg.instruction[11:7];
                        ctrl_word.wbmux_sel = wbmux::quotient_out;
                        ctrl_word.pcmux_sel = pcmux::pc_plus4;
                        ctrl_word.start_div = '1;
                    end

                    rem: begin
                        ctrl_word.ld_regfile = 1'b1;
                        ctrl_word.rd = if_id_reg.instruction[11:7];
                        ctrl_word.wbmux_sel = wbmux::rem_out;
                        ctrl_word.pcmux_sel = pcmux::pc_plus4;
                        ctrl_word.start_div = '1;
                    end

                    remu: begin
                        ctrl_word.ld_regfile = 1'b1;
                        ctrl_word.rd = if_id_reg.instruction[11:7];
                        ctrl_word.wbmux_sel = wbmux::rem_out;
                        ctrl_word.pcmux_sel = pcmux::pc_plus4;
                        ctrl_word.start_div = '1;
                    end
                endcase
            end
            else begin
                unique case(ctrl_word.arith_funct3)
                    add: begin
                        if(ctrl_word.funct7[5]) begin
                            ctrl_word.ld_regfile = 1'b1;
                            ctrl_word.rd = if_id_reg.instruction[11:7];
                            ctrl_word.alumux1_sel = alumux::rs1_out;
                            ctrl_word.alumux2_sel = alumux::rs2_out;
                            ctrl_word.aluop = alu_ops::alu_sub;
                            ctrl_word.wbmux_sel = wbmux::alu_out;
                            ctrl_word.pcmux_sel = pcmux::pc_plus4;
                        end
                        else begin
                            ctrl_word.ld_regfile = 1'b1;
                            ctrl_word.rd = if_id_reg.instruction[11:7];
                            ctrl_word.alumux1_sel = alumux::rs1_out;
                            ctrl_word.alumux2_sel = alumux::rs2_out;
                            ctrl_word.aluop = alu_ops::alu_add;
                            ctrl_word.wbmux_sel = wbmux::alu_out;
                            ctrl_word.pcmux_sel = pcmux::pc_plus4;
                        end
                    end

                    sll: begin
                            ctrl_word.ld_regfile = 1'b1;
                            ctrl_word.rd = if_id_reg.instruction[11:7];
                            ctrl_word.alumux1_sel = alumux::rs1_out;
                            ctrl_word.alumux2_sel = alumux::rs2_out;
                            ctrl_word.aluop = alu_ops::alu_sll;
                            ctrl_word.wbmux_sel = wbmux::alu_out;
                            ctrl_word.pcmux_sel = pcmux::pc_plus4;
                        end

                    slt: begin
                            ctrl_word.ld_regfile = 1'b1;
                            ctrl_word.rd = if_id_reg.instruction[11:7];
                            ctrl_word.cmpmux_sel = cmpmux::rs2_out;
                            ctrl_word.cmpop = branch_funct3::blt;
                            ctrl_word.wbmux_sel = wbmux::br_en;
                            ctrl_word.pcmux_sel = pcmux::pc_plus4;
                        end    

                    sltu: begin
                            ctrl_word.ld_regfile = 1'b1;
                            ctrl_word.rd = if_id_reg.instruction[11:7];
                            ctrl_word.cmpmux_sel = cmpmux::rs2_out;
                            ctrl_word.cmpop = branch_funct3::bltu;
                            ctrl_word.wbmux_sel = wbmux::br_en;
                            ctrl_word.pcmux_sel = pcmux::pc_plus4;
                        end      

                    axor: begin
                            ctrl_word.ld_regfile = 1'b1;
                            ctrl_word.rd = if_id_reg.instruction[11:7];
                            ctrl_word.alumux1_sel = alumux::rs1_out;
                            ctrl_word.alumux2_sel = alumux::rs2_out;
                            ctrl_word.aluop = alu_ops::alu_xor;
                            ctrl_word.wbmux_sel = wbmux::alu_out;
                            ctrl_word.pcmux_sel = pcmux::pc_plus4;
                        end    

                    sr: begin
                        if(ctrl_word.funct7[5]) begin
                            ctrl_word.ld_regfile = 1'b1;
                            ctrl_word.rd = if_id_reg.instruction[11:7];
                            ctrl_word.wbmux_sel = wbmux::alu_out;
                            ctrl_word.alumux1_sel = alumux::rs1_out;
                            ctrl_word.alumux2_sel = alumux::rs2_out;
                            ctrl_word.aluop = alu_ops::alu_sra;
                            ctrl_word.pcmux_sel = pcmux::pc_plus4;
                        end
                        else begin
                            ctrl_word.ld_regfile = 1'b1;
                            ctrl_word.rd = if_id_reg.instruction[11:7];
                            ctrl_word.wbmux_sel = wbmux::alu_out;
                            ctrl_word.alumux1_sel = alumux::rs1_out;
                            ctrl_word.alumux2_sel = alumux::rs2_out;
                            ctrl_word.aluop = alu_ops::alu_srl;
                            ctrl_word.pcmux_sel = pcmux::pc_plus4;
                        end
                end

                aor: begin
                    ctrl_word.ld_regfile = 1'b1;
                    ctrl_word.rd = if_id_reg.instruction[11:7];
                    ctrl_word.alumux1_sel = alumux::rs1_out;
                    ctrl_word.alumux2_sel = alumux::rs2_out;
                    ctrl_word.aluop = alu_ops::alu_or;
                    ctrl_word.wbmux_sel = wbmux::alu_out;
                    ctrl_word.pcmux_sel = pcmux::pc_plus4;
                end
                aand: begin
                    ctrl_word.ld_regfile = 1'b1;
                    ctrl_word.rd = if_id_reg.instruction[11:7];
                    ctrl_word.alumux1_sel = alumux::rs1_out;
                    ctrl_word.alumux2_sel = alumux::rs2_out;
                    ctrl_word.aluop = alu_ops::alu_and;
                    ctrl_word.wbmux_sel = wbmux::alu_out;
                    ctrl_word.pcmux_sel = pcmux::pc_plus4;
                end 
            endcase
            end
        end
        default: begin
                ctrl_word.ld_regfile = 1'b1;
                ctrl_word.rd = if_id_reg.instruction[11:7];
                ctrl_word.wbmux_sel = wbmux::alu_out;
                ctrl_word.alumux1_sel = alumux::rs1_out;
                ctrl_word.alumux2_sel = alumux::i_imm;
                ctrl_word.aluop = alu_ops::alu_add;
                ctrl_word.pcmux_sel = pcmux::pc_plus4;
        end
    endcase
end

always_comb begin: set_id_ex
    id_ex_reg_next.pc_plus4 = if_id_reg.pc_plus4;
    id_ex_reg_next.pc_out = if_id_reg.pc_out;
    id_ex_reg_next.rs1_out = rs1_out;
    id_ex_reg_next.rs2_out = rs2_out;
    id_ex_reg_next.prediction = if_id_reg.prediction;
    id_ex_reg_next.BTB_hit = if_id_reg.BTB_hit;
    id_ex_reg_next.BTB_hit_idx = if_id_reg.BTB_hit_idx;
    id_ex_reg_next.ctrl_word = ctrl_word;
    if(load_if_id_reg) begin
        load_id_ex_reg = '1;
        ld_regfile = mem_wb_reg.ctrl_word.ld_regfile;
    end
    else  begin
        load_id_ex_reg = '0;
        ld_regfile = '0;
    end
end

endmodule: decode_stage