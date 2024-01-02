module cache_data_array #(
            parameter       s_offset = 5,
            parameter       s_index  = 4,
            parameter       s_tag    = 32 - s_offset - s_index,
            parameter       s_mask   = 2**s_offset,
            parameter       s_line   = 8*s_mask,
            parameter       num_sets = 2**s_index
)
(
    input clk,
    input rst,
    input [s_mask-1:0] write_en,
    input [s_index-1:0] index,
    input [s_line-1:0] datain,
    output logic [s_line-1:0] dataout
);

logic [s_line-1:0] internal_array [num_sets-1:0];

always_ff @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < num_sets; ++i) begin
            internal_array[i] <= '0;
        end
    end else begin
        for (int i = 0; i < s_mask; i++) begin
            if (write_en[i]) begin
                internal_array[index][8*i +: 8] <= datain[8*i +: 8];
            end else begin
                internal_array[index][8*i +: 8] <= internal_array[index][8*i +: 8];
            end
        end
    end
end

generate
    always_comb begin
        dataout = internal_array[index];
    end 
endgenerate

endmodule : cache_data_array
