module arithmetic_unit_tb;

    logic clk;

    logic [31:0] a [4];
    logic [31:0] b [4];
    logic [31:0] c [4];
    logic [31:0] y [4];

    logic [31:0] expected [4];

    function automatic logic [31:0] calculate_expected(
        logic [31:0] a,
        logic [31:0] b,
        logic [31:0] c
    );

        logic [31:0] sum;

        begin
            sum = a + b;
            calculate_expected = sum * c;
        end

    endfunction

    arithmetic_unit dut (
        .clk(clk),
        .a(a),
        .b(b),
        .c(c),
        .y(y)
    );

    always #5 clk = ~clk; // #5 means every 5 simulation time uints, it flips

    initial begin
        clk = 0;

        // Generate random input set
        for (int i = 0; i < 4; i++) begin
            a[i] = $urandom;
            b[i] = $urandom;
            c[i] = $urandom;

            expected[i] = calculate_expected(a[i], b[i], c[i]);
        end

        // First cycle: pipeline is not ready
        @(posedge clk);
        #1;

        $display("Cycle 1:");

        for (int i = 0; i < 4; i++) begin
            $display("y[%0d] = %0d", i, y[i]);

            assert(y[i] == 0)
                else $error("Cycle 1: y[%0d] incorrect, got %0d", i, y[i]);
        end

        // Second cycle: results from first input set
        @(posedge clk);
        #1;

        $display("Cycle 2:");

        for (int i = 0; i < 4; i++) begin
            $display("y[%0d] = %0d, expected = %0d", i, y[i], expected[i]);

            assert(y[i] == expected[i])
                else $error("Cycle 2: y[%0d] incorrect, expected %0d, got %0d", i, expected[i], y[i]);
        end

        $display("All tests passed.");

        $finish;
    end

endmodule