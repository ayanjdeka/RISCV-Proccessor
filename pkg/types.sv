package rv32i_types;
typedef logic [31:0] rv32i_word;
typedef logic [4:0] rv32i_reg;
typedef logic [3:0] rv32i_mem_wmask;
endpackage

package pcmux;
typedef enum logic [1:0] {
    pc_plus4  = 2'b00
    ,alu_out  = 2'b01
    ,alu_mod2 = 2'b10
    ,alu_out_jal = 2'b11
} pcmux_sel_t;
endpackage

package cmpmux;
typedef enum logic {
    rs2_out = 1'b0
    ,i_imm = 1'b1
} cmpmux_sel_t;
endpackage

package alumux;
typedef enum logic {
    rs1_out = 1'b0
    ,pc_out = 1'b1
} alumux1_sel_t;

typedef enum logic [2:0] {
    i_imm    = 3'b000
    ,u_imm   = 3'b001
    ,b_imm   = 3'b010
    ,s_imm   = 3'b011
    ,j_imm   = 3'b100
    ,rs2_out = 3'b101
} alumux2_sel_t;
endpackage

package wbmux;
typedef enum logic [3:0] {
    pc_plus4 = 4'b0000,
    alu_out = 4'b0001,
    cmp_out = 4'b0010,
    u_imm = 4'b0011,
    lh_out = 4'b0100,
    lhu_out = 4'b0101,
    lb_out = 4'b0110,
    lbu_out = 4'b0111,
    lw_out = 4'b1000,
    br_en = 4'b1001,
    mul_lower = 4'b1010,
    mul_upper = 4'b1011,
    quotient_out = 4'b1100,
    rem_out = 4'b1101
} wbmux_sel_t;
endpackage

package dmux;
typedef enum logic [1:0] {
    sb_out = 2'b00,
    sh_out = 2'b01,
    sw_out = 2'b10
}dmux_sel_t;
endpackage

package rv32i_opcode;
typedef enum logic [6:0] {
    op_lui   = 7'b0110111, //load upper immediate (U type)
    op_auipc = 7'b0010111, //add upper immediate PC (U type)
    op_jal   = 7'b1101111, //jump and link (J type)
    op_jalr  = 7'b1100111, //jump and link register (I type)
    op_br    = 7'b1100011, //branch (B type)
    op_load  = 7'b0000011, //load (I type)
    op_store = 7'b0100011, //store (S type)
    op_imm   = 7'b0010011, //arith ops with register/immediate operands (I type)
    op_reg   = 7'b0110011, //arith ops with register operands (R type)
    op_csr   = 7'b1110011  //control and status register (I type)
} rv32i_opcode_t;
endpackage

package branch_funct3;
typedef enum logic [2:0] {
    beq  = 3'b000,
    bne  = 3'b001,
    blt  = 3'b100,
    bge  = 3'b101,
    bltu = 3'b110,
    bgeu = 3'b111
} branch_funct3_t;
endpackage

package load_funct3;
typedef enum logic [2:0] {
    lb  = 3'b000,
    lh  = 3'b001,
    lw  = 3'b010,
    lbu = 3'b100,
    lhu = 3'b101
} load_funct3_t;
endpackage

package store_funct3;
typedef enum logic [2:0] {
    sb = 3'b000,
    sh = 3'b001,
    sw = 3'b010
} store_funct3_t;
endpackage

package arith_funct3;
typedef enum logic [2:0] {
    add  = 3'b000, //check bit30 for sub if op_reg opcode
    sll  = 3'b001,
    slt  = 3'b010,
    sltu = 3'b011,
    axor = 3'b100,
    sr   = 3'b101, //check bit30 for logical/arithmetic
    aor  = 3'b110,
    aand = 3'b111
} arith_funct3_t;
endpackage

package mult_funct3;
typedef enum logic [2:0]{
    mul    = 3'b000,
    mulh   = 3'b001,
    mulhsu = 3'b010,
    mulhu  = 3'b011,
    div    = 3'b100,
    divu   = 3'b101,
    rem    = 3'b110,
    remu   = 3'b111
} mult_funct3_t;
endpackage

package alu_ops;
typedef enum logic [2:0] {
    alu_add = 3'b000,
    alu_sll = 3'b001,
    alu_sra = 3'b010,
    alu_sub = 3'b011,
    alu_xor = 3'b100,
    alu_srl = 3'b101,
    alu_or  = 3'b110,
    alu_and = 3'b111
} alu_ops_t;
endpackage
    

package ctrl_word;
import branch_funct3::*;
typedef struct packed{
    pcmux::pcmux_sel_t pcmux_sel;
    alumux::alumux1_sel_t alumux1_sel;
    alumux::alumux2_sel_t alumux2_sel;
    cmpmux::cmpmux_sel_t cmpmux_sel;
    wbmux::wbmux_sel_t wbmux_sel;
    dmux::dmux_sel_t dmux_sel;
    logic [31:0] instruction;
    logic [2:0] funct3;
    logic [6:0] funct7;
    rv32i_opcode::rv32i_opcode_t opcode;
    logic [31:0] i_imm;
    logic [31:0] s_imm;
    logic [31:0] b_imm;
    logic [31:0] u_imm;
    logic [31:0] j_imm;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
    logic [31:0] rs1_out;
    logic [31:0] rs2_out;
    rv32i_types::rv32i_word pcmux_out;
    rv32i_types::rv32i_word pc_out;
    load_funct3::load_funct3_t load_funct3;
    branch_funct3_t branch_funct3;
    arith_funct3::arith_funct3_t arith_funct3;
    mult_funct3::mult_funct3_t mult_funct3;
    store_funct3::store_funct3_t store_funct3;
    branch_funct3_t cmpop;
    alu_ops::alu_ops_t aluop;
    logic load_pc;
    logic start_mul;
    logic start_div;
    logic dmem_read;
    logic dmem_write;
    logic [3:0] mem_byte_enable;
    logic ld_regfile;
} ctrl_word_t;
endpackage

package IF_ID_Reg;
typedef struct packed {
    pcmux::pcmux_sel_t pcmux_sel;
    rv32i_types::rv32i_word pc_plus4;
    rv32i_types::rv32i_word pc_out;
    rv32i_types::rv32i_word instruction;
    rv32i_types::rv32i_word pcmux_out;
    logic load_pc;
    logic BTB_hit;
    logic [1:0] BTB_hit_idx;
    logic prediction;
    //logic ld_id;
} if_id_reg_t;
endpackage

package ID_EX_Reg;
typedef struct packed {
    rv32i_types::rv32i_word pc_plus4;
    rv32i_types::rv32i_word pc_out;
    rv32i_types::rv32i_word rs1_out;
    rv32i_types::rv32i_word rs2_out;
    ctrl_word::ctrl_word_t ctrl_word;
    logic BTB_hit;
    logic [1:0] BTB_hit_idx;
    logic prediction;
    //logic ld_ex;
} id_ex_reg_t;
endpackage

package EX_MEM_REG;
typedef struct packed {
    rv32i_types::rv32i_word pc_plus4;
    rv32i_types::rv32i_word alu_out;
    rv32i_types::rv32i_word mul_upper;
    rv32i_types::rv32i_word mul_lower;
    rv32i_types::rv32i_word quotient_out;
    rv32i_types::rv32i_word rem_out;
    rv32i_types::rv32i_word rs2_out;
    rv32i_types::rv32i_word cmp_out;
    rv32i_types::rv32i_word dmem_address;
    rv32i_types::rv32i_word dmem_wdata;
    logic [3:0] wmask;
    logic [1:0] mar_low;
    logic br_en;
    logic pcplus4_recover;
    ctrl_word::ctrl_word_t ctrl_word;
    //logic ld_mem;
} ex_mem_reg_t;
endpackage

package MEM_WB_REG;
typedef struct packed {
    rv32i_types::rv32i_word pc_plus4;
    rv32i_types::rv32i_word alu_out;
    rv32i_types::rv32i_word mul_upper;
    rv32i_types::rv32i_word mul_lower;
    rv32i_types::rv32i_word quotient_out;
    rv32i_types::rv32i_word rem_out;
    rv32i_types::rv32i_word cmp_out;
    rv32i_types::rv32i_word lh_out;
    rv32i_types::rv32i_word lhu_out;
    rv32i_types::rv32i_word lb_out;
    rv32i_types::rv32i_word lbu_out;
    rv32i_types::rv32i_word lw_out;
    rv32i_types::rv32i_word dmem_address;
    logic [3:0] rmask;
    logic [3:0] wmask;
    rv32i_types::rv32i_word dmem_rdata;
    rv32i_types::rv32i_word dmem_wdata;
    ctrl_word::ctrl_word_t ctrl_word;
    //logic ld_regfile;
} mem_wb_reg_t;

endpackage