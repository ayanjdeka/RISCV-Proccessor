module cache_datapath_two_cycle #(
            parameter       s_offset = 5,
            parameter       s_index  = 4,
            parameter       s_tag    = 32 - s_offset - s_index,
            parameter       s_mask   = 2**s_offset,
            parameter       s_line   = 8*s_mask,
            parameter       num_sets = 2**s_index
)(

    input clk,
    input rst,

    input logic [31:0]  mem_address,
    input logic [31:0]  mem_byte_enable,
    output logic [255:0] mem_rdata,
    input logic [255:0] mem_wdata,

    input logic [255:0] pmem_rdata,
    output logic [255:0] pmem_wdata,
    output logic [31:0]  pmem_address,

    output logic hit,
    output logic [0:0] hit_path,
    output logic lru_dirty_bit,
    output logic lru_valid_bit,
    output logic [0:0] lru_path,
    input logic [0:0] lru_input,
    output logic [0:0] lru_output,
    input logic load_lru,

    input logic load_tag_array[2],
    input logic load_valid_array[2],
    input logic load_data_array[2],
    input logic load_dirty_array[2],
    input logic dirty_input_array[2],

    input logic addr_bit,
    input logic data_bit
);

logic [255:0] data_d [2];
logic [255:0] data_input;

logic [s_tag-1:0] tag;
assign tag = mem_address[31 -: s_tag];
logic[s_index - 1 : 0] set_index_data;
assign set_index_data = mem_address[s_index + s_offset - 1: s_offset];

logic [31:0] data_write_enabled[2];
logic valid_output[2];
logic dirty_output[2];
logic [s_tag - 1 : 0] tag_array_output[2];

genvar i;
generate for (i = 0; i < 2; i++) begin : arrays
    //get all the different arrays
    mp4_data_array data_array  (
        .clk0       (clk),
        .csb0       (1'b0),
        .web0       (load_data_array[i]),
        .wmask0     (data_write_enabled[i]),
        .addr0      (set_index_data),
        .din0       (data_input),
        .dout0      (data_d[i])
    );

    mp4_tag_array tag_arr (
        .clk0       (clk),
        .csb0       (1'b0),
        .web0       (load_tag_array[i]),
        .addr0      (set_index_data),
        .din0       (tag),
        .dout0      (tag_array_output[i])    
    );

    ff_array valid_array (
        .clk0       (clk),
        .rst0       (rst),
        .csb0       (1'b0),
        .web0       (load_valid_array[i]),
        .addr0      (set_index_data),
        .din0       (1'b1),
        .dout0      (valid_output[i]) 
    );
    ff_array dirty_array (
        .clk0       (clk),
        .rst0       (rst),
        .csb0       (1'b0),
        .web0       (load_dirty_array[i]),
        .addr0      (set_index_data),
        .din0       (dirty_input_array[i]),
        .dout0      (dirty_output[i]) 
    );
end endgenerate

plru_array lru (
    .clk0       (clk),
    .rst0       (rst),
    .csb0       (1'b0),
    .web0       (load_lru),
    .addr0      (set_index_data),
    .din0       (lru_input),
    .dout0      (lru_output) ,
    .plru_way   (lru_path)
);


//make sure to update the data_write_enabled logic for wmask in data
generate
    always_comb begin : update_data_write_enabled
        for (int i = 0; i < 2; ++i) begin
            if (load_data_array[i] == 1'b0) begin
                unique case (data_bit)
                    1'b0: data_write_enabled[i] = mem_byte_enable;
                    1'b1: data_write_enabled[i] = {32{1'b1}};
                    default: data_write_enabled[i] = {32{1'b0}};
                endcase
            end else begin
                data_write_enabled[i] = {32{1'b0}};
            end
        end
    end 
endgenerate


//make sure to update both dirty and valid bits by
//getting the proper location from the lru path
assign lru_dirty_bit = dirty_output[lru_path];
assign lru_valid_bit = valid_output[lru_path];

//hit logic from my design
always_comb begin : update_hit_path
    hit = '0;
    hit_path = '0;
    for (int i = 0; i < 2; ++i) begin
        if (tag == tag_array_output[i] && valid_output[i]) begin
            hit = 1'b1;
            //make sure to update the hit path by converting to two bit
            //logical array
            hit_path = i[0:0];
        end
    end
end : update_hit_path

//assigne read of memory and cacheline from respective paths
assign mem_rdata = data_d[hit_path];
assign pmem_wdata = data_d[lru_path];

//data output based on mux from design
always_comb begin : data_muxes
    unique case (data_bit)
        1'b0: data_input = mem_wdata;
        1'b1: data_input = pmem_rdata;
        default: data_input = {256{1'bX}};
    endcase
end : data_muxes

//address muxes from design
always_comb begin : addr_muxes
    unique case (addr_bit)
        1'b0: pmem_address = {mem_address[31:s_offset], 5'b00000};
        1'b1: pmem_address = {tag_array_output[lru_path], set_index_data, 5'b00000};
        default: pmem_address = {32'bX};
    endcase
end

endmodule : cache_datapath_two_cycle
