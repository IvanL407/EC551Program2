`timescale 1ns/1ps
// 8-digit multiplexed hex display driver for the Nexys4 DDR (segments and anodes active low).
// value[31:28] is the leftmost digit (AN[7]), value[3:0] the rightmost (AN[0]).
module seg7_hex8 #(parameter REFRESH_BITS = 17) (   // 100 MHz / 2^17 = ~763 Hz per digit
    input  wire        clk,
    input  wire [31:0] value,
    input  wire [7:0]  dp_on,     // 1 = light the decimal point of that digit
    output reg  [6:0]  seg,       // {g,f,e,d,c,b,a}, active low
    output wire        dp,        // active low
    output reg  [7:0]  an         // active low
);
    reg [REFRESH_BITS+2:0] cnt = 0;
    always @(posedge clk) cnt <= cnt + 1'b1;
    wire [2:0] digit = cnt[REFRESH_BITS+2:REFRESH_BITS];

    wire [3:0] nib = value[digit*4 +: 4];
    assign dp = ~dp_on[digit];

    always @* begin
        an = ~(8'b0000_0001 << digit);
        case (nib)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            default: seg = 7'b0001110;   // F
        endcase
    end
endmodule
