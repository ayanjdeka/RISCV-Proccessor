module cache_datapath #(
            parameter       s_offset = 5,
            parameter       s_index  = 4,
            parameter       num_ways = 1,
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
    output logic [num_ways - 1:0] hit_path,
    output logic lru_dirty_bit,
    output logic lru_valid_bit,
    output logic [num_ways - 1:0] lru_path,
    input logic [2 ** num_ways - 2:0] lru_input,
    output logic [2 ** num_ways - 2:0] lru_output,
    input logic load_lru,

    input logic load_tag_array[2 ** num_ways],
    input logic load_valid_array[2 ** num_ways],
    input logic load_data_array[2 ** num_ways],
    input logic load_dirty_array[2 ** num_ways],
    input logic dirty_input_array[2 ** num_ways],

    input logic addr_bit,
    input logic data_bit
);

localparam way_number = 2 ** num_ways; 

logic [255:0] data_d [way_number];
logic [255:0] data_input;

logic [s_tag-1:0] tag;
assign tag = mem_address[31 -: s_tag];
logic[s_index - 1 : 0] set_index_data;
assign set_index_data = mem_address[s_index + s_offset - 1: s_offset];

logic [31:0] data_write_enabled[way_number];
logic valid_output[way_number];
logic dirty_output[way_number];
logic [s_tag - 1 : 0] tag_array_output[way_number];

genvar i;
generate for (i = 0; i < way_number; i++) begin : arrays
    //get all the different arrays
    cache_data_array #(s_offset, s_index) data_array  (
        .clk        (clk),
        .rst        (rst),
        .write_en     (data_write_enabled[i]),
        .index      (set_index_data),
        .datain       (data_input),
        .dataout      (data_d[i])
    );

    cache_regular_array #(s_index, s_tag) tag_arr (
        .clk(clk),
        .rst(rst),
        .load(load_tag_array[i]),
        .index(set_index_data),
        .datain(tag),
        .dataout(tag_array_output[i])
    );

    cache_regular_array #(s_index, 1) valid_array (
        .clk       (clk),
        .rst       (rst),
        .load       (load_valid_array[i]),
        .index(set_index_data),
        .datain       (1'b1),
        .dataout      (valid_output[i]) 
    );

    cache_regular_array #(s_index, 1) dirty_array (
        .clk       (clk),
        .rst       (rst),
        .load       (load_dirty_array[i]),
        .index(set_index_data),
        .datain      (dirty_input_array[i]),
        .dataout      (dirty_output[i]) 
    );
end endgenerate
cache_regular_array #(s_index, 2 ** num_ways - 1) lru_array (
    .clk       (clk),
    .rst       (rst),
    .load      (load_lru),
    .index(set_index_data),
    .datain      (lru_input),
    .dataout      (lru_output)
);

generate
    if (num_ways == 1) begin
        assign lru_path = lru_output;
    end else if (num_ways == 2) begin
        //make sure to update lru path based off tree in 4 way cache
        always_comb begin : update_lru_path_taken
            //set the middle bit (1) equal to the output of the lru cache
            lru_path[1] = lru_output[0];
            //traversing down to the left of the tree if the middle bit is 0
            if (lru_path[1] == 1'b0) begin
                lru_path[0] = lru_output[1];
            end else begin
                // otherwise go to the right of the tree
                lru_path[0] = lru_output[2];
            end
        end 
    end else if (num_ways == 3) begin
        always_comb begin 
            lru_path[2] = lru_output[0];
            if (lru_path[2] == 1'b0) begin
                lru_path[1] = lru_output[1];
            end else begin
                lru_path[1] = lru_output[2];
            end
            if (lru_path[2:1] == 2'b00) begin
                lru_path[0] = lru_output[3];
            end else if (lru_path[2:1] == 2'b01) begin
                lru_path[0] = lru_output[4];
            end else if (lru_path[2:1] == 2'b10) begin
                lru_path[0] = lru_output[5];
            end else begin
                lru_path[0] = lru_output[6];
            end
        end
    end
endgenerate


//make sure to update the data_write_enabled logic for wmask in data
generate
    always_comb begin : update_data_write_enabled
        for (int i = 0; i < way_number; ++i) begin
            if (load_data_array[i] == 1'b1) begin
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
    for (int i = 0; i < way_number; ++i) begin
        if (tag == tag_array_output[i] && valid_output[i]) begin
            hit = 1'b1;
            //make sure to update the hit path by converting to two bit
            //logical array
            hit_path = i[num_ways-1:0];
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

endmodule : cache_datapath
