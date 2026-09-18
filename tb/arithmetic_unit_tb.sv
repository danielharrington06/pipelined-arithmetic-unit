module arithmetic_unit_tb;

    class transaction;

        rand logic [31:0] a;
        rand logic [31:0] b;
        rand logic [31:0] c;

        constraint value_ranges {
            a dist {
                32'h00000000 := 10,
                [32'h00000001:32'h000003E8] := 70,
                [32'hFFFFFF00:32'hFFFFFFFF] := 20
            };

            b dist {
                32'h00000000 := 10,
                [32'h00000001:32'h000003E8] := 70,
                [32'hFFFFFF00:32'hFFFFFFFF] := 20
            };

            c dist {
                32'h00000000 := 10,
                [32'h00000001:32'h000003E8] := 70,
                [32'hFFFFFF00:32'hFFFFFFFF] := 20
            };
        }

    endclass

    logic clk;

    logic [31:0] a [4];
    logic [31:0] b [4];
    logic [31:0] c [4];
    logic [31:0] y [4];

    logic [31:0] expected [4];
    logic [31:0] previous_expected [4];

    int NUM_TESTS = 100;
    int errors = 0;

    transaction t = new();

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

    always #5 clk = ~clk;

    initial begin
        clk = 0;


        // --- Constrained randomised tests ---


        // Generate the first input batch
        for (int i = 0; i < 4; i++) begin
            if (t.randomize() == 0) begin
                $fatal("Randomization failed");
            end

            a[i] = t.a;
            b[i] = t.b;
            c[i] = t.c;

            expected[i] = calculate_expected(a[i], b[i], c[i]);
        end

        // Process all random test batches
        for (int test = 0; test < NUM_TESTS; test++) begin

            @(posedge clk);
            #1;

            // Check the previous batch's results
            if (test > 0) begin
                for (int i = 0; i < 4; i++) begin
                    if (y[i] !== previous_expected[i]) begin
                        $error("Random test %0d: y[%0d] incorrect, expected %0d, got %0d", test, i, previous_expected[i], y[i]);
                        errors++;
                    end
                end
            end

            // Save expected results for the current batch
            for (int i = 0; i < 4; i++) begin
                previous_expected[i] = expected[i];
            end

            // Generate the next input batch
            for (int i = 0; i < 4; i++) begin
                if (t.randomize() == 0) begin
                    $fatal("Randomization failed");
                end

                a[i] = t.a;
                b[i] = t.b;
                c[i] = t.c;

                expected[i] = calculate_expected(a[i], b[i], c[i]);
            end
        end

        // Check the final random batch
        @(posedge clk);
        #1;

        for (int i = 0; i < 4; i++) begin
            if (y[i] !== previous_expected[i]) begin
                $error("Final random test: y[%0d] incorrect, expected %0d, got %0d", i, previous_expected[i], y[i]);
                errors++;
            end
        end

        $display("%0d constrained-random tests completed.", NUM_TESTS);



        // --- Edge-case tests ---

        // Edge case 1:
        // 0 + 0 = 0, 0 * 0 = 0
        a[0] = 32'h00000000;
        b[0] = 32'h00000000;
        c[0] = 32'h00000000;

        // Edge case 2:
        // 0 + 1 = 1, 1 * 1 = 1
        a[1] = 32'h00000000;
        b[1] = 32'h00000001;
        c[1] = 32'h00000001;

        // Edge case 3:
        // FFFFFFFF + 1 = 0 (32-bit overflow)
        a[2] = 32'hFFFFFFFF;
        b[2] = 32'h00000001;
        c[2] = 32'h00000001;

        // Edge case 4:
        // FFFFFFFF * 2 = 1FFFFFFFE -> FFFFFFFE (32-bit overflow)
        a[3] = 32'hFFFFFFFF;
        b[3] = 32'h00000000;
        c[3] = 32'h00000002;

        // Calculate expected results
        for (int i = 0; i < 4; i++) begin
            expected[i] = calculate_expected(a[i], b[i], c[i]);
        end

        // The edge-case batch enters the pipeline
        @(posedge clk);
        #1;

        // Results are not ready yet, so we do not check y here.

        // Wait for the edge-case results
        @(posedge clk);
        #1;

        for (int i = 0; i < 4; i++) begin
            if (y[i] !== expected[i]) begin
                $error("Edge case: y[%0d] incorrect, expected %0d, got %0d", i, expected[i], y[i]);
                errors++;
            end
        end

        $display("Edge-case tests completed.");



        // --- Final result ----


        if (errors == 0) begin
            $display("All tests passed.");
        end
        else begin
            $display("TEST FAILED: %0d errors detected.", errors);
        end

        $finish;
    end

endmodule