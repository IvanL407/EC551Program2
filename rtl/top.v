`timescale 1ns/1ps
// Top level for the Nexys4 DDR. Wraps the generated hls_core (datapath + FSM).
//
//   BTNC        : STEP  - one press = one FSM state (this is the "button clock")
//   BTNU        : LOAD  - while IDLE, write SW[7:0] into the input chosen by SW[11:8]
//   CPU_RESETN  : reset - FSM back to IDLE, inputs back to their demo defaults
//   SW[15:12]   : which functional unit (adder/subtractor/multiplier) to show
//   SW[11:8]    : which variable register to show (also the LOAD target)
//   SW[7:0]     : value to load
//   7-seg left  4 digits : selected variable register (hex)
//   7-seg right 4 digits : selected functional unit output (hex)
//   LED[4:0]    : FSM state (0 = IDLE, 1..L = schedule cycle, L+1 = DONE)
//   LED[14]     : IDLE (inputs can be loaded)      LED[15] : DONE
//   LED[11:8]   : copy of SW[11:8] (shows which variable the board thinks you picked)
//   LED[13]     : flips ON/OFF every time a LOAD is accepted (so you can see BTNU worked)
//
// The exact meaning of each SW[15:12] / SW[11:8] code is printed by hls.py and
// saved in gen/switch_map.txt, because it depends on the equations.
module top #(
    parameter W               = 16,          // must match --width given to hls.py
    parameter DEBOUNCE_CYCLES = 1_000_000,   // 10 ms at 100 MHz (testbench makes this tiny)
    parameter REFRESH_BITS    = 17
) (
    input  wire        CLK100MHZ,
    input  wire        CPU_RESETN,
    input  wire        BTNC,
    input  wire        BTNU,
    input  wire [15:0] SW,
    output wire [15:0] LED,
    output wire        CA, CB, CC, CD, CE, CF, CG, DP,
    output wire [7:0]  AN
);
    wire clk = CLK100MHZ;

    // synchronize the (active low) reset button
    reg [1:0] rst_sync = 2'b11;
    always @(posedge clk) rst_sync <= {rst_sync[0], ~CPU_RESETN};
    wire rst = rst_sync[1];

    // buttons -> clean one-cycle pulses
    wire step, load;
    debounce #(.CYCLES(DEBOUNCE_CYCLES)) u_db_step (.clk(clk), .btn(BTNC), .level(), .pulse(step));
    debounce #(.CYCLES(DEBOUNCE_CYCLES)) u_db_load (.clk(clk), .btn(BTNU), .level(), .pulse(load));

    // switches are asynchronous too, so register them twice
    reg [15:0] sw_a = 16'd0, sw = 16'd0;
    always @(posedge clk) begin sw_a <= SW; sw <= sw_a; end

    wire [W-1:0] load_val = sw[7:0];           // zero-extended (or cut) to W bits
    wire [4:0]   state;
    wire         done;
    wire [W-1:0] fu_out, var_out;

    hls_core #(.W(W)) u_core (
        .clk(clk), .rst(rst),
        .step(step),
        .load(load), .load_idx(sw[11:8]), .load_val(load_val),
        .fu_sel(sw[15:12]), .var_sel(sw[11:8]),
        .state_out(state), .done(done),
        .fu_out(fu_out), .var_out(var_out)
    );

    // display: 4 hex digits each (low 16 bits if W is bigger, zero padded if smaller)
    wire [15:0] var16 = var_out;
    wire [15:0] fu16  = fu_out;
    wire [6:0]  seg;
    seg7_hex8 #(.REFRESH_BITS(REFRESH_BITS)) u_disp (
        .clk(clk), .value({var16, fu16}),
        .dp_on(8'b0001_0000),                  // dot between the two numbers
        .seg(seg), .dp(DP), .an(AN)
    );
    assign {CG, CF, CE, CD, CC, CB, CA} = seg;

    // debug: flips every time a load is accepted (load only works in IDLE)
    reg load_seen = 1'b0;
    always @(posedge clk)
        if (rst)                         load_seen <= 1'b0;
        else if (load && state == 5'd0)  load_seen <= ~load_seen;

    assign LED[4:0]  = state;
    assign LED[7:5]  = 3'd0;
    assign LED[11:8] = sw[11:8];
    assign LED[12]   = 1'b0;
    assign LED[13]   = load_seen;
    assign LED[14]   = (state == 5'd0);
    assign LED[15]   = done;
endmodule
