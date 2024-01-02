module BTB
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
    input logic [31:0] pc_fetch, //imem_address
    input logic [31:0] pc_branch, //pc of branch instruction from exec stage
    input logic prediction, //from global predictor
    input logic alu_recover1,
    input logic alu_recover2,
    input logic pcplus4_recover,
    input id_ex_reg_t id_ex_reg,
    input logic [1:0] BTB_kill_idx, 
    input logic [31:0] target_address, //alu_out mangled
    output logic BTB_hit,
    output logic [31:0] predicted_address,//predicted PC, default predict not taken -> pcplus4
    output logic [1:0] BTB_hit_idx
    //output logic prediction
);

//most signals will come from execute stage
//need to sent BTB_hit_idx and BTB_hit signal through pipeline

logic [31:0] pc_reg[4];
logic [31:0] target_reg[4];
//logic BHT_reg[4];
logic plru_reg[3];
logic ld_plru;

logic [1:0] replacement_way;
logic pc_hit0;
logic pc_hit1;
logic pc_hit2;
logic pc_hit3;


assign pc_hit0 = (pc_reg[0] == pc_fetch);
assign pc_hit1 = (pc_reg[1] == pc_fetch);
assign pc_hit2 = (pc_reg[2] == pc_fetch);
assign pc_hit3 = (pc_reg[3] == pc_fetch);

assign BTB_hit = (pc_hit0 || pc_hit1 || pc_hit2 || pc_hit3);
assign ld_plru = alu_recover1 || BTB_hit;

always_ff @(posedge clk) begin: set_BTB_entries
    if(rst) begin
        for(int i = 0; i < 4; i++) begin
            pc_reg[i] <= '0;
            //BHT_reg[i] <= '0;
            target_reg[i] <= '0;
        end
    end
    else if(alu_recover1) begin
        unique case(replacement_way)
            2'b00: begin
                pc_reg[0] <= pc_branch;
                target_reg[0] <= target_address;
                //BHT_reg[0] <= '1;
            end
            2'b01: begin
                pc_reg[1] <= pc_branch;
                target_reg[1] <= target_address;
                //BHT_reg[1] <= '1;
            end 
            2'b10: begin
                pc_reg[2] <= pc_branch;
                target_reg[2] <= target_address;
                //BHT_reg[2] <= '1;
            end
            2'b11: begin
                pc_reg[3] <= pc_branch;
                target_reg[3] <= target_address;
                //BHT_reg[3] <= '1;
            end
        endcase
    end
    else if(alu_recover2) begin
        unique case(BTB_kill_idx)
            2'b00: begin
                pc_reg[0] <= pc_branch;
                target_reg[0] <= target_address;
                //BHT_reg[0] <= '1;
            end
            2'b01: begin
                pc_reg[1] <= pc_branch;
                target_reg[1] <= target_address;
                //BHT_reg[1] <= '1;
            end 
            2'b10: begin
                pc_reg[2] <= pc_branch;
                target_reg[2] <= target_address;
                //BHT_reg[2] <= '1;
            end
            2'b11: begin
                pc_reg[3] <= pc_branch;
                target_reg[3] <= target_address;
                //BHT_reg[3] <= '1;
            end
        endcase
    end
    else if(pcplus4_recover) begin
        unique case(BTB_kill_idx)
            2'b00: begin
                pc_reg[0] <= pc_branch;
                target_reg[0] <= target_address;
                //BHT_reg[0] <= '0;
            end
            2'b01: begin
                pc_reg[1] <= pc_branch;
                target_reg[1] <= target_address;
                //BHT_reg[1] <= '0;
            end 
            2'b10: begin
                pc_reg[2] <= pc_branch;
                target_reg[2] <= target_address;
                //BHT_reg[2] <= '0;
            end
            2'b11: begin
                pc_reg[3] <= pc_branch;
                target_reg[3] <= target_address;
                //BHT_reg[3] <= '0;
            end
        endcase
    end
end

always_comb begin : way_encoder
        if(pc_hit0)
            BTB_hit_idx = 2'b00;
        else if(pc_hit1)
            BTB_hit_idx = 2'b01;
        else if(pc_hit2)
            BTB_hit_idx = 2'b10;
        else if(pc_hit3)
            BTB_hit_idx = 2'b11;
        else
            BTB_hit_idx = 2'b00;
end

always_comb begin: predicted_address_logic
    predicted_address = pc_fetch + 4;
    if(BTB_hit) begin
        if(pc_hit0) begin
            if(prediction) begin
                predicted_address = target_reg[0];
                //prediction = BHT_reg[0];
            end
            else begin
                predicted_address = pc_fetch + 4;
            end
        end
        else if(pc_hit1) begin
            if(prediction) begin
                predicted_address = target_reg[1];
                //prediction = BHT_reg[1];
            end
            else begin
                predicted_address = pc_fetch + 4;
            end
        end
        else if(pc_hit2) begin
            if(prediction) begin
                predicted_address = target_reg[2];
                //prediction = BHT_reg[2];
            end
            else begin
                predicted_address = pc_fetch + 4;
            end
        end
        else if(pc_hit3) begin
            if(prediction) begin
                predicted_address = target_reg[3];
                //prediction = BHT_reg[3];
            end
            else begin
                predicted_address = pc_fetch + 4;
            end
        end
    end
    else begin
        predicted_address = pc_fetch + 4;
    end
end


always_ff @(posedge clk) begin : PLRU_update_logic
        if(rst) begin
            plru_reg[0] <= '0;
            plru_reg[1] <= '0;
            plru_reg[2] <= '0;
        end
        else if(ld_plru) begin
            unique case(replacement_way)
                2'b00: begin
                    plru_reg[0] <= 1'b1;
                    plru_reg[1] <= 1'b1;
                end
                2'b01: begin
                    plru_reg[0] <= 1'b1;
                    plru_reg[1] <= 1'b0;
                end
                2'b10: begin
                    plru_reg[0] <= 1'b0;
                    plru_reg[2] <= 1'b1;
                end
                2'b11: begin
                    plru_reg[0] <= 1'b0;
                    plru_reg[2] <= 1'b0;
                end
            default: begin
                plru_reg[0] <= 1'b0;
                plru_reg[1] <= 1'b0;
                plru_reg[2] <= 1'b0;
            end
            endcase
        end
    end

    always_comb begin: plru_replacement_logic
        if(plru_reg[0] == 1'b0) begin
            if(plru_reg[1] == 1'b0)
                replacement_way = 2'b00;
            else 
                replacement_way = 2'b01;
        end
        else if(plru_reg[0] == 1'b1) begin
            if(plru_reg[2] == 1'b0)
                replacement_way = 2'b10;
            else
                replacement_way = 2'b11;
        end
        else
            replacement_way = 2'b00;
    end
    
endmodule: BTB