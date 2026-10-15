`timescale 1ns / 1ps

module miniproj_tb;

    // ---- Inputs ----
    reg  [3:0]  TA;
    reg  [3:0]  TB;
    reg  [3:0]  TC;
    reg  [3:0]  KA;
    reg         SW1;
    reg         SW2;
    reg         CLK;

    // ---- Outputs ----
    wire [10:0]  LED;
    wire [7:0]  DIG1;
    wire [7:0]  DIG2;
    wire [16:0] DIG3;

    // ---- DUT ----
    miniproj dut (
        .TA(TA), .TB(TB), .TC(TC),
        .SW1(SW1), .SW2(SW2), .KA(KA),
        .CLK(CLK),
        .LED(LED), .DIG1(DIG1), .DIG2(DIG2), .DIG3(DIG3)
    );

    // ---- Clock: 10 ns period ----
    initial CLK = 0;
    always #5 CLK = ~CLK;

    // ---- VCD dump: only the signals we care about ----
    initial begin
        $dumpfile("miniproj_tb.vcd");
        $dumpvars(0,
            miniproj_tb.TA,
            miniproj_tb.TB,
            miniproj_tb.TC,
            miniproj_tb.SW1,
            miniproj_tb.LED,
            miniproj_tb.DIG1,
            miniproj_tb.DIG2,
            miniproj_tb.DIG3,
            miniproj_tb.dut.result,
            miniproj_tb.dut.overflow_borrow,
            miniproj_tb.dut.error,
            miniproj_tb.dut.display_mode
        );
        // NOT dumping sampling_counter - it toggles every 5 ns
        // and would make the VCD enormous.
    end

    // ---- One slow tick = 500001 clocks * 10 ns ~ 5.00001 ms ----
    localparam integer TICK_NS = 5000200;   // slight margin

    task wait_ticks;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) #(TICK_NS);
        end
    endtask

    // Press SW1 long enough for the slow sampler to see it,
    // then release and let the sampler settle.
    task press_sw1;
        begin
            SW1 = 1'b1;
            wait_ticks(3);
            SW1 = 1'b0;
            wait_ticks(2);
        end
    endtask

    // ---- Stimulus ----
    initial begin
        // Known initial values - must be set before anything else
        TA  = 4'd0;
        TB  = 4'd0;
        TC  = 4'b0000;
        SW1 = 1'b0;
        SW2 = 1'b0;

        #100;                // let the initial block in DUT run
        wait_ticks(2);       // let state settle

        // ------------------------------------------------
        // T1: 3 + 5 = 8  (decimal display)
        // ------------------------------------------------
        TA = 4'd3;
        wait_ticks(1);       // TA change -> result loaded with 3
        TB = 4'd5;
        TC = 4'b0000;        // 00 = add, TC[1]=0 -> decimal
        press_sw1();
        $display("[%0t] T1  3 + 5 : LED=%0d ovf=%b err=%b | D1=%0d D2=%0d D3=%0d",
                 $time, LED[7:0], LED[8], LED[9], DIG1, DIG2, DIG3);

        // ------------------------------------------------
        // T2: 10 - 3 = 7
        // ------------------------------------------------
        TA = 4'd10;
        wait_ticks(1);
        TB = 4'd3;
        TC = 4'b0100;        // 01 = sub
        press_sw1();
        $display("[%0t] T2  10 - 3: LED=%0d ovf=%b err=%b",
                 $time, LED[7:0], LED[8], LED[9]);

        // ------------------------------------------------
        // T3: 3 - 10 underflow (borrow should set)
        // ------------------------------------------------
        TA = 4'd3;
        wait_ticks(1);
        TB = 4'd10;
        TC = 4'b0100;        // sub
        press_sw1();
        $display("[%0t] T3  3 - 10: LED=%0d ovf=%b err=%b",
                 $time, LED[7:0], LED[8], LED[9]);

        // ------------------------------------------------
        // T4: 4 * 4 = 16
        // ------------------------------------------------
        TA = 4'd4;
        wait_ticks(1);
        TB = 4'd4;
        TC = 4'b1000;        // 10 = mul
        press_sw1();
        $display("[%0t] T4  4 * 4 : LED=%0d ovf=%b err=%b",
                 $time, LED[7:0], LED[8], LED[9]);

        // ------------------------------------------------
        // T5: 8 / 2 = 4
        // ------------------------------------------------
        TA = 4'd8;
        wait_ticks(1);
        TB = 4'd2;
        TC = 4'b1100;        // 11 = div
        press_sw1();
        $display("[%0t] T5  8 / 2 : LED=%0d ovf=%b err=%b",
                 $time, LED[7:0], LED[8], LED[9]);

        // ------------------------------------------------
        // T6: 12 / 0 -> error
        // TA must differ from previous TA so the reload triggers
        // ------------------------------------------------
        TA = 4'd12;
        wait_ticks(1);
        TB = 4'd0;
        TC = 4'b1100;        // div
        press_sw1();
        $display("[%0t] T6  12 / 0: LED=%0d ovf=%b err=%b",
                 $time, LED[7:0], LED[8], LED[9]);

        // ------------------------------------------------
        // T7: 3 + 5 = 8  (hex display)
        // ------------------------------------------------
        TA = 4'd3;
        wait_ticks(1);
        TB = 4'd5;
        TC = 4'b0010;        // 00 = add, TC[1]=1 -> hex
        press_sw1();
        $display("[%0t] T7  hex 3+5: LED=%0d | D1=%0d D2=%0d D3=%0d",
                 $time, LED[7:0], DIG1, DIG2, DIG3);

        wait_ticks(2);
        $display("[%0t] Simulation done.", $time);
        $finish;
    end

endmodule