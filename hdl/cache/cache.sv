module cache #(
            parameter       s_offset = 5,
            parameter       s_index  = 4,
            parameter       num_ways = 1
)
(
    input                   clk,
    input                   rst,

    /* CPU side signals */
    input   logic   [31:0]  mem_address,
    input   logic           mem_read,
    input   logic           mem_write,
    input   logic   [31:0]  mem_byte_enable,
    output  logic   [255:0] mem_rdata,
    input   logic   [255:0] mem_wdata,
    output  logic           mem_resp,

    /* Memory side signals */
    output  logic   [31:0]  pmem_address,
    output  logic           pmem_read,
    output  logic           pmem_write,
    input   logic   [255:0] pmem_rdata,
    output  logic   [255:0] pmem_wdata,
    input   logic           pmem_resp
);

localparam s_tag    = 32 - s_offset - s_index;
localparam s_mask   = 2**s_offset;
localparam s_line   = 8*s_mask;
localparam num_sets = 2**s_index;

logic load_tag_array[2 ** num_ways];
logic load_valid_array[2 ** num_ways];
logic load_dirty_array[2 ** num_ways];
logic load_data_array[2 ** num_ways];
logic load_lru;

logic dirty_input_array[2 ** num_ways];

logic data_bit;
logic addr_bit;
logic hit;
logic [num_ways - 1 : 0] hit_path;
logic [num_ways - 1 : 0] lru_path;
logic lru_dirty_bit;
logic lru_valid_bit;
logic [2**num_ways-2:0] lru_output;
logic [2**num_ways-2:0] lru_input;

cache_control #(s_offset, s_index, num_ways, s_tag, s_mask, s_line, num_sets) control
(
    .*
);

cache_datapath #(s_offset, s_index, num_ways, s_tag, s_mask, s_line, num_sets) datapath
(
    .*
);

endmodule : cache
