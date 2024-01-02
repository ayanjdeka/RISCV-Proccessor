module dadda_dut_tb;
timeunit 1ns;
timeprecision 1ns;

import mult_funct3::*;



bit clk;
initial clk = 1'b1;
always #1 clk = ~clk;

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, "+all");
end

logic  signed [31:0] A;
logic  signed [31:0] B;
logic  signed [63:0] C;
logic start;
logic i_rdy, o_rdy;
logic mult_stall;

mult_funct3_t mult_op;

bit rst;

task do_reset();
    rst <= '1;
    repeat (2) @ (posedge clk);
    rst <= '0;
    repeat (2) @ (posedge clk);
endtask: do_reset

task mult_unsigned();
    for(int i = 0; i < 32'hffffffff; i++) begin
        for(int k = 0; k < 32'hffffffff; k++) begin
            mult_op <= mulhu;
            A <= i;
            B <= k;
            @(posedge clk);
            start <= '1;
            @(posedge clk);
            start <= '0;
            repeat (3) @(posedge clk);
            $display("A = %0d, B = %0d", A, B);
            assert (A * B == C)
            else begin
                $error("C = %0d", C);
            end
            assert(o_rdy == '1)
            else begin
                $error("output ready = %0d", o_rdy);
            end
            @(posedge clk);
        end
    end
endtask: mult_unsigned

task mul_signed_unsigned();
    for(int i = 0; i < 4'hf; i++) begin
        for(int k = 0; k < 4'hf; k++) begin
            mult_op <= mulhsu;
            A <= i;
            B <= k;
            @(posedge clk);
            start <= '1;
            @(posedge clk);
            start <= '0;
            repeat (3) @(posedge clk);
            $display("A = %0d, B = %0d, C = %0d", A, B, C);
            $display("A*B = %0d", A * B);
            assert (A * B == C)
            else begin
                $error("C = %0d", C);
            end
            assert(o_rdy == '1)
            else begin
                $error("output ready = %0d", o_rdy);
            end
            @(posedge clk);
        end
    end
endtask: mul_signed_unsigned

task mul_signed();
    for(int i = 12; i <= 32'hffffffff; i++) begin
        for(int k = 32'hffffffff / 2 + 1; k <= 32'hffffffff; k++) begin
            mult_op <= mulh;
            A <= i;
            B <= k;
            @(posedge clk);
            start <= '1;
            @(posedge clk);
            start <= '0;
            repeat (3) @(posedge clk);
            $display("A = %0d, B = %0d, C = %0d", A, B, C);
            $display("A*B = %0d", A * B);
            assert (A * B == C)
            else begin
                $error("C = %0d", C);
            end
            assert(o_rdy == '1)
            else begin
                $error("output ready = %0d", o_rdy);
            end
            @(posedge clk);
        end
    end
endtask: mul_signed

dadda dut(
    .clk(clk),
    .rst(rst),
    .start(start),
    .mult_op(mult_op),
    .A(A),
    .B(B),
    .C(C),
    .o_rdy(o_rdy),
    .mult_stall(mult_stall)
);

initial begin
    do_reset();
    //mult_unsigned();
    //mul_signed_unsigned();
    mul_signed();
    $display("Done test!");
    $finish;
end

endmodule