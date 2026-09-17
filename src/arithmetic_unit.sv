module arithmetic_unit (
    input logic clk,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] y
);

    always_ff @(posedge clk) begin
        y <= a + b;
    end

endmodule
