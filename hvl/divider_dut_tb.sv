module divider_dut_tb
import mult_funct3::*;
();

timeunit 1ns;
timeprecision 1ns;

bit clk;
initial clk = 1'b1;
always #1 clk = ~clk;

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, "+all");
end

/* logic [31:0] A, B;
logic [7:0] C;
logic div_start; */

logic div_start;

mult_funct3_t div_op;

logic div_stall;

logic signed [31:0] dividend, divisor, quotient, remainder;

logic div_done;
logic data_ready;



bit rst;

task do_reset();
    rst <= '1;
    repeat (2) @ (posedge clk);
    rst <= '0;
    repeat (2) @ (posedge clk);
endtask: do_reset

task divide_by_zero_div();
    for(int i = 0; i < 32'h0000ffff; i++) begin
        dividend <= i;
        divisor <= '0;
        div_op <= div;
        div_start <= '1;
        @(posedge clk);
        div_start <= '0;
        @(posedge clk iff div_done);
        //$display("dividend = %0d, divisor = %0d", dividend, divisor);
        assert (quotient == '1)
        else begin
            $error("quotient = %0d", quotient);
        end
    end

endtask: divide_by_zero_div

task divide_by_zero_divu();
    for(int i = 0; i < 32'h0000ffff; i++) begin
        dividend <= i;
        divisor <= '0;
        div_op <= divu;
        div_start <= '1;
        @(posedge clk);
        div_start <= '0;
        @(posedge clk iff div_done);
        //$display("dividend = %0d, divisor = %0d", dividend, divisor);
        assert (quotient == '1)
        else begin
            $error("quotient = %0d", quotient);
        end
    end

endtask: divide_by_zero_divu

task divide_by_zero_rem();
    for(int i = 0; i < 32'h0000ffff; i++) begin
        dividend <= i;
        divisor <= '0;
        div_op <= rem;
        div_start <= '1;
        @(posedge clk);
        div_start <= '0;
        @(posedge clk iff div_done);
        //$display("dividend = %0d, divisor = %0d", dividend, divisor);
        assert (remainder == i)
        else begin
            $error("remainder = %0d", remainder);
        end
    end

endtask: divide_by_zero_rem

task divide_by_zero_remu();
    for(int i = 0; i < 32'h0000ffff; i++) begin
        dividend <= i;
        divisor <= '0;
        div_op <= remu;
        div_start <= '1;
        @(posedge clk);
        div_start <= '0;
        @(posedge clk iff div_done);
        //$display("dividend = %0d, divisor = %0d", dividend, divisor);
        assert (remainder == i)
        else begin
            $error("remainder = %0d", remainder);
        end
    end

endtask: divide_by_zero_remu

task overflow_div();
    dividend <= 32'h80000000;
    divisor <= '1;
    div_op <= div;
    div_start <= '1;
    @(posedge clk);
    div_start <= '0;
    @(posedge clk iff div_done);
    assert (quotient == dividend)
    else begin
        $error("quotient = %0d", quotient);
    end
endtask

task overflow_rem();
    dividend <= 32'h80000000;
    divisor <= '1;
    div_op <= rem;
    div_start <= '1;
    @(posedge clk);
    div_start <= '0;
    @(posedge clk iff div_done);
    assert (remainder == '0)
    else begin
        $error("remainder = %0d", remainder);
    end
endtask

task divide();
    for(int i = 32'h8fffffff; i <= 32'hffffffff; i++) begin
        for(int k = 1; k <= 32'hffffffff; k++) begin
            dividend <= i;
            divisor <= k;
            div_op <= div;
            div_start <= '1;
            @(posedge clk);
            div_start <= '0;
            @(posedge clk iff div_done);
            $display("dividend = %0d, divisor = %0d", dividend, divisor);
            assert (dividend / divisor == quotient)
            else begin
                $error("quotient = %0d", quotient);
            end
        end
    end
endtask: divide 

task divide_signed();
    for(int i = 32'h0fffffff; i <= 32'hffffffff; i++) begin
        for(int k = 32'h81111111; k <= 32'hffffffff; k++) begin
            dividend <= i;
            divisor <= k;
            div_op <= div;
            div_start <= '1;
            @(posedge clk);
            div_start <= '0;
            @(posedge clk iff div_done);
            $display("dividend = %0d, divisor = %0d", dividend, divisor);
            assert (dividend / divisor == quotient)
            else begin
                $error("quotient = %0d", quotient);
            end
        end
    end
endtask: divide_signed


task remainder_operation();
    for(int i = 0; i < 4'hf; i++) begin
        for(int k = 1; k < 4'hf; k++) begin
            dividend <= i;
            divisor <= k;
            div_op <= remu;
            div_start <= '1;
            @(posedge clk);
            div_start <= '0;
            @(posedge clk iff div_done);
            $display("dividend = %0d, divisor = %0d", dividend, divisor);
            assert (dividend % divisor == remainder)
            else begin
                $error("remainder = %0d", remainder);
            end
        end
    end
endtask: remainder_operation 

task remainder_signed();
    for(int i = 32'h8fffffff; i < 32'hffffffff; i++) begin
        for(int k = 32'h01111111; k < 32'hffffffff; k++) begin
            dividend <= i;
            divisor <= k;
            div_op <= rem;
            div_start <= '1;
            @(posedge clk);
            div_start <= '0;
            @(posedge clk iff div_done);
            $display("dividend = %0d, divisor = %0d", dividend, divisor);
            assert (dividend % divisor == remainder)
            else begin
                $error("remainder = %0d", remainder);
            end
        end
    end
endtask: remainder_signed

task remainder_signed_test();
        dividend <= -18;
        divisor <= 7;
        div_op <= rem;
        div_start <= '1;
        @(posedge clk);
        div_start <= '0;
        @(posedge clk iff div_done);
        $display("dividend = %0d, divisor = %0d", dividend, divisor);
        assert (dividend % divisor == remainder)
        else begin
            $error("remainder = %0d", remainder);
        end
endtask

task divide_test();
    //for(int i = 32'h0fffffff; i <= 32'hffffffff; i++) begin
        //for(int k = 32'h81111111; k <= 32'hffffffff; k++) begin
            dividend <= 32'h0000000f;
            divisor <= 32'h00000004;
            div_op <= div;
            div_start <= '1;
            @(posedge clk);
            $display("dividend = %0d, divisor = %0d", dividend, divisor);
            div_start <= '0;
            @(posedge clk iff div_done);
            $display("dividend = %0d, divisor = %0d", dividend, divisor);
            assert (dividend / divisor == quotient)
            else begin
                $error("quotient = %0d", quotient);
            end
        //end
    //end
endtask


/* dadda_4x4 dut(
    .clk(clk),
    .rst(rst),
    .start(start),
    .A(A),
    .B(B),
    .C(C)
); */

divider dut(
    .clk(clk),
    .rst(rst),
    .div_start(div_start),
    .div_op(div_op),
    .dividend(dividend),
    .divisor(divisor),
    .quotient(quotient),
    .remainder(remainder),
    .div_done(div_done),
    .div_stall(div_stall)
);

initial begin
    do_reset();
   /*  divide_by_zero_div();
    divide_by_zero_divu();
    divide_by_zero_rem();
    divide_by_zero_remu(); */
    
    /* overflow_div();
    overflow_rem(); */
    divide();
    /* divide_test();
    divide_signed();
    remainder_signed();
    remainder_operation(); */
    $display("Done test!");
    $finish;
end

endmodule