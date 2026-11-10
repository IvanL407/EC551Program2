// Basic functional unit blocks used by the generated datapath (hls_core.v).
// All are purely combinational, W bits wide. The generated core registers their
// outputs at the cycle boundaries, so each operation takes exactly one FSM state.

module hls_adder #(parameter W = 16) (
    input  wire [W-1:0] a,
    input  wire [W-1:0] b,
    output wire [W-1:0] y
);
    assign y = a + b;
endmodule

module hls_subtractor #(parameter W = 16) (
    input  wire [W-1:0] a,
    input  wire [W-1:0] b,
    output wire [W-1:0] y
);
    assign y = a - b;          // results are assumed non-negative (assignment spec)
endmodule

module hls_multiplier #(parameter W = 16) (
    input  wire [W-1:0] a,
    input  wire [W-1:0] b,
    output wire [W-1:0] y
);
    assign y = a * b;          // low W bits of the product
endmodule
