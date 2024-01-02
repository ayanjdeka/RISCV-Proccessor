module forwarding_unit
import ctrl_word::*;
import IF_ID_Reg::*;
import ID_EX_Reg::*;
import EX_MEM_REG::*;
import MEM_WB_REG::*;
import rv32i_opcode::*;

(
    input id_ex_reg_t id_ex_reg,
    input ex_mem_reg_t ex_mem_reg,
    input mem_wb_reg_t mem_wb_reg,
    output logic [1:0] forward_out1,
    output logic [1:0] forward_out2
);

//1. add x4, x3, x3 //when 1. in mem stage, 2. will be in exec stage
//2. sub x2, x4, x6 //forward 1. from mem to 2. in exec
//3. add x3, x4, x4 //forward 1. from wb to 3. in exec.

//1. add x4, x3, x3 //when 1. in mem stage, 2. will be in exec stage
//2. sub x4, x4, x6 //forward 1. from mem to 2. in exec.
//3. add x3, x4, x4 //forward 2. from mem to 3. in exec.


//alumux1 handles rs1_out, alumux2 handles rs2_out
always_comb begin : set_wbmuxout_forwarding
    forward_out1 = 2'b00;
    forward_out2 = 2'b00;
    // if((ex_mem_reg.ctrl_word.opcode == op_store && id_ex_reg.ctrl_word.opcode == op_jalr) && (ex_mem_reg.ctrl_word.rs2 == id_ex_reg.ctrl_word.rs1)) begin
    //     forward_out1 = 2'b01;
    // end
    if((~(ex_mem_reg.ctrl_word.rd == '0)) && (ex_mem_reg.ctrl_word.rd == id_ex_reg.ctrl_word.rs1 && ex_mem_reg.ctrl_word.rd == id_ex_reg.ctrl_word.rs2)) begin
        forward_out1 = 2'b01; //forward alu_out from ex_mem into alumux1
        forward_out2 = 2'b01; //forward alu_out from ex_mem into alumux2
    end
    else if((~(ex_mem_reg.ctrl_word.rd == '0)) && (~(mem_wb_reg.ctrl_word.rd == '0)) && (ex_mem_reg.ctrl_word.rd == id_ex_reg.ctrl_word.rs1 && mem_wb_reg.ctrl_word.rd == id_ex_reg.ctrl_word.rs2)) begin
        forward_out1 = 2'b01;
        forward_out2 = 2'b10;
    end
    else if((~(ex_mem_reg.ctrl_word.rd == '0)) && (~(mem_wb_reg.ctrl_word.rd == '0)) && (ex_mem_reg.ctrl_word.rd == id_ex_reg.ctrl_word.rs2 && mem_wb_reg.ctrl_word.rd == id_ex_reg.ctrl_word.rs1)) begin
        forward_out1 = 2'b10;
        forward_out2 = 2'b01;
    end
    else if((~(ex_mem_reg.ctrl_word.rd == '0)) && (ex_mem_reg.ctrl_word.rd == id_ex_reg.ctrl_word.rs1)) begin
        forward_out1 = 2'b01;
    end
    else if((~(ex_mem_reg.ctrl_word.rd == '0)) && (ex_mem_reg.ctrl_word.rd == id_ex_reg.ctrl_word.rs2)) begin
        forward_out2 = 2'b01;
    end
    else if((~(mem_wb_reg.ctrl_word.rd == '0)) && (mem_wb_reg.ctrl_word.rd == id_ex_reg.ctrl_word.rs1 && mem_wb_reg.ctrl_word.rd == id_ex_reg.ctrl_word.rs2)) begin
        forward_out1 = 2'b10; //forward wbmux_out into alumux1
        forward_out2 = 2'b10; //forward wbmux_out into alumux2
    end 
    else if((~(mem_wb_reg.ctrl_word.rd == '0)) && (mem_wb_reg.ctrl_word.rd == id_ex_reg.ctrl_word.rs1)) begin
        forward_out1 = 2'b10;
    end
    else if((~(mem_wb_reg.ctrl_word.rd == '0)) && (mem_wb_reg.ctrl_word.rd == id_ex_reg.ctrl_word.rs2)) begin
        forward_out2 = 2'b10;
    end
end

endmodule