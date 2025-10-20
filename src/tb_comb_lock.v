`timescale 1ns/1ps

module tb_comb_lock_simple;

  reg clk;
  reg rst;
  reg enter_button;
  reg [3:0] ip_pass;
  wire grant, deny, lock;

  localparam CLK_PERIOD_NS = 10;

  // Instantiate DUT
  comb_lock dut (
    .clk(clk),
    .rst(rst),
    .enter_button(enter_button),
    .ip_pass(ip_pass),
    .grant(grant),
    .deny(deny),
    .lock(lock)
  );

  // Clock generation
  initial clk = 0;
  always #(CLK_PERIOD_NS/2) clk = ~clk;

  // Test sequence
  initial begin
    // Reset
    rst = 1;
    enter_button = 0;
    ip_pass = 0;
    #20;
    rst = 0;
    #20;

    // Correct code: 1, 5, 3, 7 (should grant)
    enter_button = 1; #10; enter_button = 0;
    ip_pass = 1; #10;
    ip_pass = 5; #10;
    ip_pass = 3; #10;
    ip_pass = 7; #10;
    #10;

    // 1st wrong attempt: 2, 0, 0, 0
    enter_button = 1; #10; enter_button = 0;
    ip_pass = 2; #10;
    ip_pass = 0; #10;
    ip_pass = 0; #10;
    ip_pass = 0; #10;
    #10;

    // 2nd wrong attempt: 1, 1, 1, 1
    enter_button = 1; #10; enter_button = 0;
    ip_pass = 1; #10;
    ip_pass = 1; #10;
    ip_pass = 1; #10;
    ip_pass = 1; #10;
    #10;

    // 3rd wrong attempt: 0, 0, 0, 0 (should lock)
    enter_button = 1; #10; enter_button = 0;
    ip_pass = 0; #10;
    ip_pass = 0; #10;
    ip_pass = 0; #10;
    ip_pass = 0; #10;
    #10;

    // Wait for lock timeout (simulate 220 ns)
    #220;

    // Try correct code again: 1, 5, 3, 7 (should grant after unlock)
    enter_button = 1; #10; enter_button = 0;
    ip_pass = 1; #10;
    ip_pass = 5; #10;
    ip_pass = 3; #10;
    ip_pass = 7; #10;
    #10;

    $finish;
  end

endmodule
