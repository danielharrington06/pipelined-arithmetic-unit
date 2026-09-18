
module arithmetic_unit (
    input logic clk,
    input logic valid_in,

    input logic [31:0] a [4],
    input logic [31:0] b [4],
    input logic [31:0] c [4],

    output logic [31:0] y [4],
    output logic valid_out
);

    logic [31:0] sum_reg [4];
    logic [31:0] c_reg [4];

    always_ff @(posedge clk) begin

        // pipeline stage 1
        for (int i = 0; i < 4; i++) begin
            sum_reg[i] <= a[i] + b[i];
            c_reg[i] <= c[i];
        end

        valid_out <= valid_in;

        // pipeline stage 2
        for (int i = 0; i < 4; i++) begin
            y[i] <= sum_reg[i] * c_reg[i];
        end
    end

endmodule
