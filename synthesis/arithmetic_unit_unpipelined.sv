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

    always @(posedge clk) begin
        // single combinational arithmetic stage
        y0 <= (a0 + b0) * c0;
        y1 <= (a1 + b1) * c1;
        y2 <= (a2 + b2) * c2;
        y3 <= (a3 + b3) * c3;

        valid_out <= valid_in;
    end

endmodule