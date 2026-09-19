module arithmetic_unit (
    input wire clk,
    input wire valid_in,

    input wire [31:0] a0,
    input wire [31:0] a1,
    input wire [31:0] a2,
    input wire [31:0] a3,

    input wire [31:0] b0,
    input wire [31:0] b1,
    input wire [31:0] b2,
    input wire [31:0] b3,

    input wire [31:0] c0,
    input wire [31:0] c1,
    input wire [31:0] c2,
    input wire [31:0] c3,

    output reg [31:0] y0,
    output reg [31:0] y1,
    output reg [31:0] y2,
    output reg [31:0] y3,

    output reg valid_out
);

    reg [31:0] sum0;
    reg [31:0] sum1;
    reg [31:0] sum2;
    reg [31:0] sum3;

    reg [31:0] c0_reg;
    reg [31:0] c1_reg;
    reg [31:0] c2_reg;
    reg [31:0] c3_reg;

    always @(posedge clk) begin
        // pipeline stage 1
        sum0 <= a0 + b0;
        sum1 <= a1 + b1;
        sum2 <= a2 + b2;
        sum3 <= a3 + b3;

        c0_reg <= c0;
        c1_reg <= c1;
        c2_reg <= c2;
        c3_reg <= c3;

        valid_out <= valid_in;

        // pipeline stage 2
        y0 <= sum0 * c0_reg;
        y1 <= sum1 * c1_reg;
        y2 <= sum2 * c2_reg;
        y3 <= sum3 * c3_reg;
    end

endmodule