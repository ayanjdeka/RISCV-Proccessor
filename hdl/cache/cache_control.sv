module cache_control #(
            parameter       s_offset = 5,
            parameter       s_index  = 4,
            parameter       num_ways = 1,
            parameter       s_tag    = 32 - s_offset - s_index,
            parameter       s_mask   = 2**s_offset,
            parameter       s_line   = 8*s_mask,
            parameter       num_sets = 2**s_index
)
(
    input clk,
    input rst,
    input logic mem_read,
    input logic mem_write,
    output logic mem_resp,

    input logic pmem_resp,
    output logic pmem_read,
    output logic pmem_write,

    input logic hit,
    input logic [num_ways - 1:0] hit_path,
    input logic [num_ways - 1:0] lru_path,
    input logic lru_dirty_bit,
    input logic lru_valid_bit,
    output logic load_tag_array [2**num_ways],
    output logic load_valid_array [2**num_ways],
    output logic load_dirty_array[2**num_ways],
    output logic dirty_input_array [2**num_ways],
    input logic [2**num_ways-2:0] lru_output,
    output logic [2**num_ways-2:0] lru_input,
    output logic load_lru,
    output logic data_bit,
    output logic addr_bit,
    output logic load_data_array[2**num_ways]
);

enum logic [1:0] {
    idle_state,
    matching_state,
    writeback_state,
    load_state
} state, next_state;



generate
    //make sure to negate the input that will be used in the data path
    if (num_ways == 1) begin
        assign lru_input = ~hit_path;
        logic temp_reg;
        assign temp_reg = lru_output;
    end else if (num_ways == 2) begin
        always_comb begin
            lru_input[0] = ~hit_path[1];
            if (hit_path[1] == 1'b0) begin
                lru_input[1] = ~hit_path[0];
            end else begin
                lru_input[1] = lru_output[1];
            end
            if (hit_path[1] == 1'b1) begin
                lru_input[2] = ~hit_path[0];
            end else begin
                lru_input[2] = lru_output[2];
            end  
        end
    end else if (num_ways == 3) begin
        always_comb begin
            lru_input[0] = ~hit_path[2];
            // For lru_in[1]
            if (hit_path[2] == 1'b0) begin
                lru_input[1] = ~hit_path[1];
            end else begin
                lru_input[1] = lru_output[1];
            end

            // For lru_input[2]
            if (hit_path[2] == 1'b1) begin
                lru_input[2] = ~hit_path[1];
            end else begin
                lru_input[2] = lru_output[2];
            end
            // For lru_input[3]
            if (hit_path[2:1] == 2'b00) begin
                lru_input[3] = ~hit_path[0];
            end else begin
                lru_input[3] = lru_output[3];
            end

            // For lru_input[4]
            if (hit_path[2:1] == 2'b01) begin
                lru_input[4] = ~hit_path[0];
            end else begin
                lru_input[4] = lru_output[4];
            end 
            // For lru_input[5]
            if (hit_path[2:1] == 2'b10) begin
                lru_input[5] = ~hit_path[0];
            end else begin
                lru_input[5] = lru_output[5];
            end
            // For lru_input[6]
            if (hit_path[2:1] == 2'b11) begin
                lru_input[6] = ~hit_path[0];
            end else begin
                lru_input[6] = lru_output[6];
            end
        end
    end
endgenerate

always_comb begin : state_actions
    for (int i = 0; i < 2 ** num_ways; ++i) begin
        load_tag_array[i] = 1'b0;
        load_dirty_array[i] = 1'b0;
        load_data_array[i] = 1'b0;
        load_valid_array[i] = 1'b0;
        dirty_input_array[i] = 1'b0;
    end
    mem_resp = 1'b0;
    pmem_read = 1'b0;
    pmem_write = 1'b0;  
    load_lru = 1'b0;
    data_bit = 1'b1;
    addr_bit = 1'b0;
    unique case (state)

        matching_state: begin
            //match load_lru to hit (negate as writing is active low)
            if (hit == 1'b1) begin
                load_lru = 1'b1;
            end else begin
                load_lru = 1'b0;
            end
            //set signal mem_resp equal to hit
            mem_resp = (mem_read | mem_write) & hit;
            //set data bit to read from memory
            data_bit = 1'b0;
            //if there is a hit and I am writing, make sure to load data array
            if ((hit & mem_write) == 1'b1) begin
                load_data_array[hit_path] = 1'b1;
            end else begin
                load_data_array[hit_path] = 1'b0;
            end
            dirty_input_array[hit_path] = 1'b1;
            if ((hit & mem_write) == 1'b1) begin
                load_dirty_array[hit_path] = 1'b1;
            end else begin
                load_dirty_array[hit_path] = 1'b0;
            end

        end

        load_state: begin
            //load tag and valid array
            load_tag_array[lru_path] = 1'b1;
            load_valid_array[lru_path] = 1'b1;
            //set load data equal to cacheline adaptor response
            if (pmem_resp == 1'b1) begin
                load_data_array[lru_path] = 1'b1;
            end else begin
                load_data_array[lru_path] = 1'b0;
            end
            dirty_input_array[lru_path] = 1'b0;
            load_dirty_array[lru_path] = 1'b1;
            //set pmem_read to 1 and data bit to 1 so that I read from
            // pmem_rdata
            pmem_read = 1'b1;
            data_bit = 1'b1;
        end
        writeback_state: begin
            pmem_write = 1'b1;
            addr_bit = 1'b1;
        end
        default: ;
    endcase
end

generate
always_comb begin : next_state_logic
    unique case (state)
        matching_state: begin
            if ((mem_read | mem_write) & ~hit) begin
                if (~lru_valid_bit || ~lru_dirty_bit) begin
                    next_state = load_state;
                end else begin
                    next_state = writeback_state;
                end                         
            end else begin
                next_state = matching_state;
            end
        end
        writeback_state: begin
            if (pmem_resp) begin
                next_state = load_state;
            end else begin
                next_state = writeback_state;
            end
        end
        load_state: begin
            if (pmem_resp) begin
                next_state = matching_state;
            end else begin
                next_state = load_state;
            end
        end
        default: next_state = state;
    endcase
end

always_ff @(posedge clk) begin: next_state_assignment
    if (rst) state <= matching_state;
    else     state <= next_state;
end
endgenerate
endmodule : cache_control