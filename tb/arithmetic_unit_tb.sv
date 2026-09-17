module arithmetic_unit_tb;

    logic [31:0] a;
    logic [31:0] b;
    logic [31:0] y;

    arithmetic_unit dut (
        .a(a),
        .b(b),
        .y(y)
    );

    initial begin
        a = 10;
        b = 20;

        #1;

        $display("a = %0d, b = %0d, y = %0d", a, b, y);

        assert(y == 30)
            else $error("Incorrect result");

        $finish;
    end

endmodule