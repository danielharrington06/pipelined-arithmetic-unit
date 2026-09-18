module arithmetic_unit (
    input logic clk, // clock
    input logic [31:0] a [4],
    input logic [31:0] b [4],
    input logic [31:0] c [4],
    output logic [31:0] y [4]
);

    logic [31:0] sum_reg [4];
    logic [31:0] c_reg [4];

    always_ff @(posedge clk) begin // on every rising clock signal, store a+b in y
        for (int i = 0; i < 4; i++) begin // describes replicated hardware, not sequential looping
            sum_reg [i] <= a [i] + b [i];
            c_reg [i] <= c [i];
            y [i] <= sum_reg [i] * c_reg [i];

        end
    end

endmodule
