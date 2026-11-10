// Push-button conditioner: 2-FF synchronizer + debounce + rising-edge one-shot.
// "pulse" is high for exactly one clk cycle per clean button press. This is what
// lets a button act as the "clock" of the generated FSM (one press = one step).
module debounce #(parameter CYCLES = 1_000_000) (   // 1,000,000 cycles = 10 ms at 100 MHz
    input  wire clk,
    input  wire btn,       // raw, asynchronous, bouncy
    output reg  level,     // debounced level
    output reg  pulse      // one-cycle pulse on a debounced 0 -> 1
);
    reg [1:0]  sync = 2'b00;
    reg [31:0] cnt  = 32'd0;
    initial begin level = 1'b0; pulse = 1'b0; end

    always @(posedge clk) begin
        sync  <= {sync[0], btn};
        pulse <= 1'b0;
        if (sync[1] == level) begin
            cnt <= 32'd0;                       // nothing changed (or it bounced back)
        end else if (cnt == CYCLES - 1) begin   // input stayed different long enough
            level <= sync[1];
            cnt   <= 32'd0;
            if (sync[1]) pulse <= 1'b1;
        end else begin
            cnt <= cnt + 32'd1;
        end
    end
endmodule
