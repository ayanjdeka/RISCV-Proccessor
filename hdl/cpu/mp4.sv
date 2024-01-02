module mp4
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,

    // Use these for CP1 (magic memory)
    // output  logic   [31:0]  imem_address,
    // output  logic           imem_read,
    // input   logic   [31:0]  imem_rdata,
    // input   logic           imem_resp,
    // output  logic   [31:0]  dmem_address,
    // output  logic           dmem_read,
    // output  logic           dmem_write,
    // output  logic   [3:0]   dmem_wmask,
    // input   logic   [31:0]  dmem_rdata,
    // output  logic   [31:0]  dmem_wdata,
    // input   logic           dmem_resp,

    // Use these for CP2+ (with caches and burst memory)
    output  logic   [31:0]  bmem_address,
    output  logic           bmem_read,
    output  logic           bmem_write,
    input   logic   [63:0]  bmem_rdata,
    output  logic   [63:0]  bmem_wdata,
    input   logic           bmem_resp
);

logic [255:0] pmem_wdata;
logic [255:0] pmem_rdata;
logic [31:0] pmem_address;
logic pmem_write;
logic pmem_read;
logic pmem_resp;

logic[31:0] instruction_address;
logic[31:0] instruction_rdata;
logic      instruction_read;
logic      instruction_resp;
logic [255:0] instruction_rdata256;

logic instruction_arbiter_read;
logic [31:0]  instruction_arbiter_address;
logic [255:0] instruction_arbiter_rdata;
logic instruction_arbiter_resp;

logic[31:0] data_address;
logic[31:0] data_rdata;
logic[31:0] data_wdata;
logic [3:0] d_byte_enable;
logic data_read;
logic data_write;
logic data_resp;
logic data_arbiter_write;
logic data_arbiter_read;
logic [31:0]  data_arbiter_address;
logic [255:0] data_arbiter_rdata;
logic [255:0] data_arbiter_wdata;
logic data_arbiter_resp;
logic [255:0] data_wdata256;
logic [255:0] data_rdata256;
logic [31:0]  d_byte_enable256;


cpu cpu (
    .clk(clk),
    .rst(rst),
    .imem_resp(instruction_resp),
    .dmem_resp(data_resp),
    .imem_rdata(instruction_rdata),
    .dmem_rdata(data_rdata),
    .dmem_wdata(data_wdata),
    .imem_read(instruction_read),
    .dmem_read(data_read),
    .dmem_write(data_write),
    .imem_address(instruction_address),
    .dmem_address(data_address),
    .mem_byte_enable(d_byte_enable)
);



bus_adapter i_bus_adapter (
    .address(instruction_address),
    .mem_wdata('X),
    .mem_rdata(instruction_rdata),
    .mem_byte_enable(4'b1111),
    .mem_wdata256(),
    .mem_rdata256(instruction_rdata256),
    .mem_byte_enable256()
);

cache #(5, 1, 1) i_cache
(
    .clk(clk),
    .rst(rst),
    .mem_address(instruction_address),
    .mem_wdata('X),
    .mem_rdata(instruction_rdata256),
    .mem_byte_enable(32'hFFFFFFFF),
    .mem_read(instruction_read),
    .mem_write(1'b0),
    .mem_resp(instruction_resp),

    .pmem_rdata(instruction_arbiter_rdata),
    .pmem_wdata(),
    .pmem_address(instruction_arbiter_address),
    .pmem_read(instruction_arbiter_read),
    .pmem_write(),
    .pmem_resp(instruction_arbiter_resp)
);


bus_adapter d_bus_adapter (
    .address(data_address),
    .mem_wdata(data_wdata),
    .mem_rdata(data_rdata),
    .mem_byte_enable(d_byte_enable),
    .mem_wdata256(data_wdata256),
    .mem_rdata256(data_rdata256),
    .mem_byte_enable256(d_byte_enable256)
);
cache #(5, 1, 1) d_cache
(
    .clk(clk),
    .rst(rst),
    .mem_address(data_address),
    .mem_wdata(data_wdata256),
    .mem_rdata(data_rdata256),
    .mem_byte_enable(d_byte_enable256),
    .mem_read(data_read),
    .mem_write(data_write),
    .mem_resp(data_resp),

    .pmem_rdata(data_arbiter_rdata),
    .pmem_wdata(data_arbiter_wdata),
    .pmem_address(data_arbiter_address),
    .pmem_read(data_arbiter_read),
    .pmem_write(data_arbiter_write),
    .pmem_resp(data_arbiter_resp)
);

arbiter arbiter(
    .clk(clk),
    .rst(rst),
    .instruction_read(instruction_arbiter_read),
    .instruction_address(instruction_arbiter_address),
    .instruction_data(instruction_arbiter_rdata),
    .instruction_resp(instruction_arbiter_resp),
    .data_read(data_arbiter_read),
    .data_write(data_arbiter_write),
    .data_address(data_arbiter_address),
    .data_wdata(data_arbiter_wdata),
    .data_rdata(data_arbiter_rdata),
    .data_resp(data_arbiter_resp),
    .pmem_resp(pmem_resp),
    .pmem_rdata(pmem_rdata),
    .pmem_write(pmem_write),
    .pmem_read(pmem_read),
    .pmem_wdata(pmem_wdata),
    .pmem_address(pmem_address)
);

cacheline_adaptor cacheline_adaptor
(
    .clk(clk),
    .reset_n(~rst),
    .line_i(pmem_wdata),
    .line_o(pmem_rdata),
    .read_i(pmem_read),
    .write_i(pmem_write),
    .resp_o(pmem_resp),
    .address_i(pmem_address),
    .burst_i(bmem_rdata),
    .burst_o(bmem_wdata),
    .address_o(bmem_address),
    .read_o(bmem_read),
    .write_o(bmem_write),
    .resp_i(bmem_resp)
);




logic commit;

always_comb begin
    if(cpu.mem_stall || cpu.mult_stall || cpu.div_stall)
        commit = '0;
    else if(cpu.flush && ~cpu.mem_stall && ~cpu.mult_stall && ~cpu.div_stall)
        commit = cpu.mem_wb_reg.ctrl_word.load_pc; 
    else if(~instruction_resp)
        commit = '0;
    else  
        commit = cpu.mem_wb_reg.ctrl_word.load_pc;    
end

//assign commit = cpu.mem_wb_reg.ctrl_word.load_pc;

logic [31:0] order;
always_ff @(posedge clk) begin
    if(rst) begin
        order <= 0;
    end
    else if(commit)
        order <= order + 1;
    else   
        order <= order;
end

            logic           monitor_valid; //load_pc signal
            logic   [63:0]  monitor_order;
            logic   [31:0]  monitor_inst;
            logic   [4:0]   monitor_rs1_addr;
            logic   [4:0]   monitor_rs2_addr;
            logic   [31:0]  monitor_rs1_rdata;
            logic   [31:0]  monitor_rs2_rdata;
            logic   [4:0]   monitor_rd_addr;
            logic   [31:0]  monitor_rd_wdata;
            logic   [31:0]  monitor_pc_rdata;
            logic   [31:0]  monitor_pc_wdata;
            logic   [31:0]  monitor_mem_addr;
            logic   [3:0]   monitor_mem_rmask;
            logic   [3:0]   monitor_mem_wmask;
            logic   [31:0]  monitor_mem_rdata;
            logic   [31:0]  monitor_mem_wdata;


    // Fill this out
    // Only use hierarchical references here for verification
    // **DO NOT** use hierarchical references in the actual design!
    assign monitor_valid     = commit;
    assign monitor_order     = order;
    assign monitor_inst      = cpu.mem_wb_reg.ctrl_word.instruction;
    assign monitor_rs1_addr  = cpu.mem_wb_reg.ctrl_word.rs1;
    assign monitor_rs2_addr  = cpu.mem_wb_reg.ctrl_word.rs2;
    assign monitor_rs1_rdata = cpu.mem_wb_reg.ctrl_word.rs1_out;
    assign monitor_rs2_rdata = cpu.mem_wb_reg.ctrl_word.rs2_out;
    assign monitor_rd_addr   = cpu.mem_wb_reg.ctrl_word.rd;
    assign monitor_rd_wdata  = cpu.wbmux_out;
    assign monitor_pc_rdata  = cpu.mem_wb_reg.ctrl_word.pc_out;
    assign monitor_pc_wdata  = cpu.mem_wb_reg.ctrl_word.pcmux_out;
    assign monitor_mem_addr  = cpu.mem_wb_reg.dmem_address;
    assign monitor_mem_rmask = cpu.mem_wb_reg.rmask;
    assign monitor_mem_wmask = cpu.mem_wb_reg.wmask;
    assign monitor_mem_rdata = cpu.mem_wb_reg.dmem_rdata;
    assign monitor_mem_wdata = cpu.mem_wb_reg.dmem_wdata;

endmodule : mp4