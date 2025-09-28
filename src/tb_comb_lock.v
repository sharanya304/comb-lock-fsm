`timescale 1ns/1ps

module tb_comb_lock;

  reg        clk;
  reg        rst;
  reg        enter_button;
  reg  [3:0] ip_pass;

  wire grant, deny, lock;

  // Simulation parameters
  localparam integer CLK_PERIOD_NS = 10;  // 100 MHz clock
  // Make the LOCK timeout short for simulation (counts in clock cycles)
  localparam integer SIM_TIMEOUT_CYCLES = 20;

  // Instantiate DUT 
  comb_lock #(
    .TIMEOUT(SIM_TIMEOUT_CYCLES)
  ) dut (
    .clk(clk),
    .rst(rst),
    .enter_button(enter_button),
    .ip_pass(ip_pass),
    .grant(grant),
    .deny(deny),
    .lock(lock)
  );

  // Clock generation
  initial clk = 1'b0;
  always #(CLK_PERIOD_NS/2) clk = ~clk;

  // Simple helpers
  integer errors;
  initial errors = 0;

  task wait_clks;
    input integer n;
    integer i;
    begin
      for (i = 0; i < n; i = i + 1) @(posedge clk);
    end
  endtask

  task do_reset;
    begin
      rst = 1'b1;
      enter_button = 1'b0;
      ip_pass = 4'd0;
      wait_clks(3);
      rst = 1'b0;
      wait_clks(2);
    end
  endtask

  // Pulse enter_button to leave IDLE and start a code attempt
  task press_enter;
    begin
      enter_button = 1'b1;
      @(posedge clk);
      enter_button = 1'b0;
      @(posedge clk); // FSM moves to CHECK_1
    end
  endtask

  // Present one digit for one clock so the FSM can sample it in CHECK_n
  task put_digit;
    input [3:0] d;
    begin
      ip_pass = d;
      @(posedge clk);
    end
  endtask

  // Enter a 4-digit code: press enter, then give 4 digits,
  // and wait one extra clock for GRANT/DENY to update
  task enter_code;
    input [3:0] d1, d2, d3, d4;
    begin
      press_enter();
      put_digit(d1);
      put_digit(d2);
      put_digit(d3);
      put_digit(d4);
      @(posedge clk); // allow outputs to update (GRANT/DENY)
    end
  endtask

  task expect_high;
    input sig;
    input [127:0] name;
    begin
      if (sig !== 1'b1) begin
        $display("[%0t] ERROR: Expected %s=1, got %b", $time, name, sig);
        errors = errors + 1;
      end
    end
  endtask

  task expect_low;
    input sig;
    input [127:0] name;
    begin
      if (sig !== 1'b0) begin
        $display("[%0t] ERROR: Expected %s=0, got %b", $time, name, sig);
        errors = errors + 1;
      end
    end
  endtask
 
  // Test sequence 
  initial begin
    $timeformat(-9, 1, " ns", 10);
    $display("=== comb_lock Vivado Simulation Start ===");

    // Defaults
    rst = 1'b0; enter_button = 1'b0; ip_pass = 4'd0;

    // 1) Reset
    do_reset();

    // 2) Correct code -> expect GRANT
    $display("[%0t] T1: Correct code 1-5-3-7 -> GRANT", $time);
    enter_code(4'd1, 4'd5, 4'd3, 4'd7);
    expect_high(grant, "grant");
    expect_low(deny,  "deny");
    expect_low(lock,  "lock");
    wait_clks(2);

    // 3) Wrong attempt #1 (wrong first digit) -> DENY
    $display("[%0t] T2: Wrong attempt #1 -> DENY", $time);
    enter_code(4'd2, 4'd0, 4'd0, 4'd0);
    expect_low(grant, "grant");
    expect_high(deny,  "deny");
    expect_low(lock,  "lock");
    wait_clks(2);

    // 4) Wrong attempt #2 (wrong third digit) -> DENY
    $display("[%0t] T3: Wrong attempt #2 -> DENY", $time);
    enter_code(4'd1, 4'd5, 4'd9, 4'd7);
    expect_low(grant, "grant");
    expect_high(deny,  "deny");
    expect_low(lock,  "lock");
    wait_clks(2);

    // 5) Wrong attempt #3 (wrong last digit) -> LOCK
    $display("[%0t] T4: Wrong attempt #3 -> LOCK", $time);
    enter_code(4'd1, 4'd5, 4'd3, 4'd0);
    wait_clks(1); // FSM moves DENY -> LOCK
    expect_low(grant, "grant");
    expect_low(deny,  "deny");
    expect_high(lock, "lock");

    // 6) Hold in LOCK for ~TIMEOUT cycles, then it auto-unlocks
    $display("[%0t] T5: Wait through LOCK timeout", $time);
    wait_clks(SIM_TIMEOUT_CYCLES);
    wait_clks(2); // transition back to IDLE
    expect_low(lock, "lock");

    // 7) Correct code after unlock -> GRANT again
    $display("[%0t] T6: Correct code after unlock -> GRANT", $time);
    enter_code(4'd1, 4'd5, 4'd3, 4'd7);
    expect_high(grant, "grant");
    expect_low(deny,  "deny");
    expect_low(lock,  "lock");

    if (errors == 0) $display("=== TEST PASS: No errors detected ===");
    else             $display("=== TEST FAIL: %0d error(s) detected ===", errors);

    $finish;
  end

  // Optional live monitor for console
  initial begin
    $display("   time | rst en ip | grant deny lock");
    $monitor("%7t |  %b   %b %2d |    %b     %b    %b",
             $time, rst, enter_button, ip_pass, grant, deny, lock);
  end

endmodule

