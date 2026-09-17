module arithmetic_unit_tb;

    logic clk;
    logic [31:0] a;
    logic [31:0] b;
    logic [31:0] c;
    logic [31:0] y;

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

        // input set 1
        a = 2;
        b = 3;
        c = 10;


        @(posedge clk);
        #1;
        // first cycle should not be ready yet
        $display("Cycle 1: y = %0d", y);

        // Input set 2
        a = 4;
        b = 1;
        c = 7;

        @(posedge clk);
        #1;
        // Second cycle: result from input set 1
        $display("Cycle 2: y = %0d", y);
        assert(y == 50)
            else $error("Cycle 2: expected 50, got %0d", y);
        
        // Input set 3
        a = 6;
        b = 2;
        c = 4;

        @(posedge clk);
        #1;

        // Third cycle: result from input set 2
        $display("Cycle 3: y = %0d", y);
        assert(y == 35)
            else $error("Cycle 3: expected 35, got %0d", y);
        
        @(posedge clk);
        #1;

        // Fourth cycle: result from input set 3
        $display("Cycle 4: y = %0d", y);
        assert(y == 32)
            else $error("Cycle 4: expected 32, got %0d", y);

        $finish;
    end

endmodule