`timescale 1ns/1ps
// AUTO-GENERATED self-checking testbench for the synthesized core
module tb_hls_core;
    parameter W = 16;
    reg clk = 0, rst = 1, step = 0, load = 0;
    reg [3:0] load_idx = 0, fu_sel = 0, var_sel = 0;
    reg [W-1:0] load_val = 0;
    wire [4:0] state; wire done; wire [W-1:0] fu_out, var_out;
    hls_core #(.W(W)) dut (.clk(clk), .rst(rst), .step(step), .load(load), .load_idx(load_idx),
        .load_val(load_val), .fu_sel(fu_sel), .var_sel(var_sel), .state_out(state), .done(done),
        .fu_out(fu_out), .var_out(var_out));
    always #5 clk = ~clk;
    integer errors = 0;
    task do_reset; begin rst = 1; repeat (2) @(posedge clk); #1 rst = 0; end endtask
    task do_step; begin @(negedge clk); step = 1; @(posedge clk); #1 step = 0; @(posedge clk); #1; end endtask
    task do_load(input [3:0] i, input [W-1:0] v);
        begin @(negedge clk); load_idx = i; load_val = v; load = 1; @(posedge clk); #1 load = 0; end
    endtask
    task check(input [W-1:0] got, input [W-1:0] exp, input [255:0] nm);
        begin if (got !== exp) begin errors = errors + 1;
            $display("FAIL %0s: got %0d expected %0d", nm, got, exp); end end
    endtask
    integer k;
    initial begin
        // ---- vector 0: defaults (no loading)
        do_reset;
        do_step;
        do_step;
        do_step;
        do_step;
        if (!done) begin errors = errors + 1; $display("FAIL: FSM not DONE"); end
        check(dut.r_X_1, 8, "X_1");
        check(dut.r_Y_1, 13, "Y_1");
        check(dut.r_Z_1, 5, "Z_1");
        check(dut.r_Q_1, 15, "Q_1");
        var_sel = 4'd0; #1 check(var_out, 5, "view_A");
        var_sel = 4'd1; #1 check(var_out, 3, "view_B");
        var_sel = 4'd2; #1 check(var_out, 8, "view_X_1");
        var_sel = 4'd3; #1 check(var_out, 13, "view_Y_1");
        var_sel = 4'd4; #1 check(var_out, 5, "view_Z_1");
        var_sel = 4'd5; #1 check(var_out, 15, "view_Q_1");
        do_step;   // DONE -> IDLE
        if (state !== 5'd0) begin errors = errors + 1; $display("FAIL: did not return to IDLE"); end
        // ---- vector 1: loaded from 'switches'
        do_reset;
        do_load(4'd0, 121);
        do_load(4'd1, 7);
        do_step;
        do_step;
        do_step;
        do_step;
        if (!done) begin errors = errors + 1; $display("FAIL: FSM not DONE"); end
        check(dut.r_X_1, 128, "X_1");
        check(dut.r_Y_1, 249, "Y_1");
        check(dut.r_Z_1, 121, "Z_1");
        check(dut.r_Q_1, 847, "Q_1");
        var_sel = 4'd0; #1 check(var_out, 121, "view_A");
        var_sel = 4'd1; #1 check(var_out, 7, "view_B");
        var_sel = 4'd2; #1 check(var_out, 128, "view_X_1");
        var_sel = 4'd3; #1 check(var_out, 249, "view_Y_1");
        var_sel = 4'd4; #1 check(var_out, 121, "view_Z_1");
        var_sel = 4'd5; #1 check(var_out, 847, "view_Q_1");
        do_step;   // DONE -> IDLE
        if (state !== 5'd0) begin errors = errors + 1; $display("FAIL: did not return to IDLE"); end
        // ---- vector 2: loaded from 'switches'
        do_reset;
        do_load(4'd0, 106);
        do_load(4'd1, 124);
        do_step;
        do_step;
        do_step;
        do_step;
        if (!done) begin errors = errors + 1; $display("FAIL: FSM not DONE"); end
        check(dut.r_X_1, 230, "X_1");
        check(dut.r_Y_1, 336, "Y_1");
        check(dut.r_Z_1, 106, "Z_1");
        check(dut.r_Q_1, 13144, "Q_1");
        var_sel = 4'd0; #1 check(var_out, 106, "view_A");
        var_sel = 4'd1; #1 check(var_out, 124, "view_B");
        var_sel = 4'd2; #1 check(var_out, 230, "view_X_1");
        var_sel = 4'd3; #1 check(var_out, 336, "view_Y_1");
        var_sel = 4'd4; #1 check(var_out, 106, "view_Z_1");
        var_sel = 4'd5; #1 check(var_out, 13144, "view_Q_1");
        do_step;   // DONE -> IDLE
        if (state !== 5'd0) begin errors = errors + 1; $display("FAIL: did not return to IDLE"); end
        // ---- vector 3: loaded from 'switches'
        do_reset;
        do_load(4'd0, 189);
        do_load(4'd1, 208);
        do_step;
        do_step;
        do_step;
        do_step;
        if (!done) begin errors = errors + 1; $display("FAIL: FSM not DONE"); end
        check(dut.r_X_1, 397, "X_1");
        check(dut.r_Y_1, 586, "Y_1");
        check(dut.r_Z_1, 189, "Z_1");
        check(dut.r_Q_1, 39312, "Q_1");
        var_sel = 4'd0; #1 check(var_out, 189, "view_A");
        var_sel = 4'd1; #1 check(var_out, 208, "view_B");
        var_sel = 4'd2; #1 check(var_out, 397, "view_X_1");
        var_sel = 4'd3; #1 check(var_out, 586, "view_Y_1");
        var_sel = 4'd4; #1 check(var_out, 189, "view_Z_1");
        var_sel = 4'd5; #1 check(var_out, 39312, "view_Q_1");
        do_step;   // DONE -> IDLE
        if (state !== 5'd0) begin errors = errors + 1; $display("FAIL: did not return to IDLE"); end
        if (errors == 0) $display("PASS: all %0d vectors correct", 4);
        else $display("FAILED with %0d errors", errors);
        $finish;
    end
endmodule
