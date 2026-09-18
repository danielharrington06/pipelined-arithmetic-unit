module arithmetic_unit_tb;

    logic clk;
    logic [31:0] a [4];
    logic [31:0] b [4];
    logic [31:0] c [4];
    logic [31:0] y [4];

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
        a[0] = 2;
        b[0] = 3;
        c[0] = 10;

        a[1] = 4;
        b[1] = 1;
        c[1] = 7;

        a[2] = 6;
        b[2] = 2;
        c[2] = 4;

        a[3] = 5;
        b[3] = 5;
        c[3] = 3;


        @(posedge clk);
        #1;
        // first cycle should not be ready yet
        $display("Cyle 1:");
        $display("y[0] = %0d", y[0]);
        $display("y[1] = %0d", y[1]);
        $display("y[2] = %0d", y[2]);
        $display("y[3] = %0d", y[3]);

        // Results should not be ready yet
        assert(y[0] == 0)
            else $error("Cycle 1: y[0] incorrect");
        assert(y[1] == 0)
            else $error("Cycle 1: y[1] incorrect");
        assert(y[2] == 0)
            else $error("Cycle 1: y[2] incorrect");
        assert(y[3] == 0)
            else $error("Cycle 1: y[3] incorrect");

        @(posedge clk);
        #1;

        $display("Cycle 2:");
        $display("y[0] = %0d", y[0]);
        $display("y[1] = %0d", y[1]);
        $display("y[2] = %0d", y[2]);
        $display("y[3] = %0d", y[3]);

        // Results from the first input set
        assert(y[0] == 50)
            else $error("Cycle 2: y[0] incorrect");
        assert(y[1] == 35)
            else $error("Cycle 2: y[1] incorrect");
        assert(y[2] == 32)
            else $error("Cycle 2: y[2] incorrect");
        assert(y[3] == 30)
            else $error("Cycle 2: y[3] incorrect");

        $finish;
    end

endmodule