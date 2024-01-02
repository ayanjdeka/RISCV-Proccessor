module update_plru_logic(

    input logic [2:0] output_array,
    output logic [2:0] input_array,
    input logic [1:0] hit_path

);

//make sure to negate the input that will be used in the data path
always_comb begin : update_lru_pseudo_logic
    input_array[0] = ~hit_path[1];
    if (hit_path[1] == 1'b0) begin
        input_array[1] = ~hit_path[0];
    end else begin
        input_array[1] = output_array[1];
    end
    if (hit_path[1] == 1'b1) begin
        input_array[2] = ~hit_path[0];
    end else begin
        input_array[2] = output_array[2];
    end
end

endmodule : update_plru_logic