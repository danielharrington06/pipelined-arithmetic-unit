module arithmetic_unit (
    input logic clk, // clock
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [31:0] c,
    output logic [31:0] y
);

    logic [31:0] sum_reg;
    logic [31:0] c_reg;

    always_ff @(posedge clk) begin // on every rising clock signal, store a+b in y
        sum_reg <= a+b;
        c_reg <= c;
        y <= sum_reg * c_reg;
    end

endmodule
