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

    int NUM_TESTS = 1000;
    int errors = 0;

    transaction t = new();

    // functional coverage counters

    int zero_coverage [4];
    int boundary_coverage [4];
    int addition_overflow_coverage [4];
    int multiplication_overflow_coverage [4];


    // reference model

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


    // coverage trakcing

    task automatic record_coverage(
        input int lane,
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [31:0] c
    );

        logic [32:0] full_sum;
        logic [63:0] full_product;

        begin
            // check for zero inputs
            if (a == 32'h00000000 || b == 32'h00000000 || c == 32'h00000000) begin
                zero_coverage[lane]++;
            end

            // check for boundary values
            if (a >= 32'hFFFFFF00 || b >= 32'hFFFFFF00 || c >= 32'hFFFFFF00) begin
                boundary_coverage[lane]++;
            end

            // check for addition overflow
            full_sum = {1'b0, a} + {1'b0, b};

            if (full_sum[32]) begin
                addition_overflow_coverage[lane]++;
            end

            // check for multiplication overflow
            full_product = full_sum[31:0] * c;

            if (|full_product[63:32]) begin
                multiplication_overflow_coverage[lane]++;
            end
        end

    endtask


    // DUT

    arithmetic_unit dut (
        .clk(clk),
        .a(a),
        .b(b),
        .c(c),
        .y(y)
    );

    // clock

    always #5 clk = ~clk;


    // testbench

    initial begin
        clk = 0;

        // Initialise coverage counters
        for (int i = 0; i < 4; i++) begin
            zero_coverage[i] = 0;
            boundary_coverage[i] = 0;
            addition_overflow_coverage[i] = 0;
            multiplication_overflow_coverage[i] = 0;
        end



        // constrained-random tests

        // generate the first input batch
        for (int i = 0; i < 4; i++) begin

            if (t.randomize() == 0) begin
                $fatal("Randomization failed");
            end

            a[i] = t.a;
            b[i] = t.b;
            c[i] = t.c;

            expected[i] = calculate_expected(a[i], b[i], c[i]);

            record_coverage(i, a[i], b[i], c[i]);
        end


        // process all constrained-random test batches
        for (int test = 0; test < NUM_TESTS; test++) begin

            @(posedge clk);
            #1;

            // check the previous batch's results
            if (test > 0) begin
                for (int i = 0; i < 4; i++) begin

                    if (y[i] !== previous_expected[i]) begin
                        $error(
                            "Random test %0d: y[%0d] incorrect, expected %0d, got %0d",
                            test,
                            i,
                            previous_expected[i],
                            y[i]
                        );

                        errors++;
                    end

                end
            end


            // save expected results for the current batch
            for (int i = 0; i < 4; i++) begin
                previous_expected[i] = expected[i];
            end


            // generate the next constrained-random input batch
            for (int i = 0; i < 4; i++) begin

                if (t.randomize() == 0) begin
                    $fatal("Randomization failed");
                end

                a[i] = t.a;
                b[i] = t.b;
                c[i] = t.c;

                expected[i] = calculate_expected(a[i], b[i], c[i]);

                record_coverage(i, a[i], b[i], c[i]);
            end

        end


        // Check the final random batch
        @(posedge clk);
        #1;

        for (int i = 0; i < 4; i++) begin

            if (y[i] !== previous_expected[i]) begin
                $error(
                    "Final random test: y[%0d] incorrect, expected %0d, got %0d",
                    i,
                    previous_expected[i],
                    y[i]
                );

                errors++;
            end

        end

        $display("%0d constrained-random tests completed.", NUM_TESTS);


        // edge-case tests

        // edge case 1:
        // 0 + 0 = 0, 0 * 0 = 0
        a[0] = 32'h00000000;
        b[0] = 32'h00000000;
        c[0] = 32'h00000000;

        // edge case 2:
        // 0 + 1 = 1, 1 * 1 = 1
        a[1] = 32'h00000000;
        b[1] = 32'h00000001;
        c[1] = 32'h00000001;

        // edge case 3:
        // FFFFFFFF + 1 = 0 (32-bit overflow)
        a[2] = 32'hFFFFFFFF;
        b[2] = 32'h00000001;
        c[2] = 32'h00000001;

        // edge case 4:
        // FFFFFFFF * 2 = 1FFFFFFFE -> FFFFFFFE (32-bit overflow)
        a[3] = 32'hFFFFFFFF;
        b[3] = 32'h00000000;
        c[3] = 32'h00000002;


        // calculate expected results
        for (int i = 0; i < 4; i++) begin
            expected[i] = calculate_expected(a[i], b[i], c[i]);
        end


        // record edge-case coverage
        for (int i = 0; i < 4; i++) begin
            record_coverage(i, a[i], b[i], c[i]);
        end


        // the edge-case batch enters the pipeline
        @(posedge clk);
        #1;

        // results are not ready yet, so we do not check y here.


        // wait for the edge-case results
        @(posedge clk);
        #1;

        for (int i = 0; i < 4; i++) begin

            if (y[i] !== expected[i]) begin
                $error(
                    "Edge case: y[%0d] incorrect, expected %0d, got %0d",
                    i,
                    expected[i],
                    y[i]
                );

                errors++;
            end

        end

        $display("Edge-case tests completed.");


        // coverage report

        $display("");
        $display("============================================================");
        $display("Functional Coverage");
        $display("============================================================");

        for (int i = 0; i < 4; i++) begin

            $display("Lane %0d:", i);

            $display(
                "  Zero input:              %0d",
                zero_coverage[i]
            );

            $display(
                "  Boundary input:         %0d",
                boundary_coverage[i]
            );

            $display(
                "  Addition overflow:      %0d",
                addition_overflow_coverage[i]
            );

            $display(
                "  Multiplication overflow: %0d",
                multiplication_overflow_coverage[i]
            );

        end

        $display("============================================================");

        // final result

        if (errors == 0) begin
            $display("All tests passed.");
        end
        else begin
            $display("TEST FAILED: %0d errors detected.", errors);
        end

        $finish;
    end

endmodule