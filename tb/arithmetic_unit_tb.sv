module arithmetic_unit_tb;

    logic clk;
    logic [31:0] a;
    logic [31:0] b;
    logic [31:0] y;

    arithmetic_unit dut (
        .clk(clk),
        .a(a),
        .b(b),
        .y(y)
    );

    always #5 clk = ~clk; // #5 means every 5 simulation time uints, it flips

    initial begin
        clk = 0;

        a = 10;
        b = 20;

        @(posedge clk);
        #1;
        $display("After first rising edge: y = %0d", y);

        a = 5;
        b = 7;

        #4;
        $display("Before next rising edge: y = %0d", y);

        @(posedge clk);
        #1;
        $display("After next rising edge: y = %0d", y);

        $finish;
    end

endmodule