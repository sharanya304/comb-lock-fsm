`timescale 1ns/1ps
module comb_lock(
    input clk, rst, enter_button,
    input [3:0] ip_pass,        // user input: 4-bit digit (BCD 0-9)
    output reg grant, deny, lock
);

    // FSM states
    parameter IDLE   = 3'd0, 
              CHECK_1= 3'd1, 
              CHECK_2= 3'd2, 
              CHECK_3= 3'd3, 
              CHECK_4= 3'd4,
              GRANT  = 3'd5, 
              DENY   = 3'd6, 
              LOCK   = 3'd7;

    reg [2:0] current_state, next_state;

    // Stored password digits (BCD encoding)
    localparam [3:0] PASS_DIGIT1 = 4'd1;
    localparam [3:0] PASS_DIGIT2 = 4'd5;
    localparam [3:0] PASS_DIGIT3 = 4'd3;
    localparam [3:0] PASS_DIGIT4 = 4'd7;

    // Wrong attempt counter
    reg [1:0] attempt_count; // counts up to 3

    // Timer for lock state (30 seconds simulated)
    reg [31:0] timer_count;
    parameter TIMEOUT = 32'd300000000; // adjust to clk freq (30s)

    // State register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            attempt_count <= 0;
            timer_count   <= 0;
        end else begin
            current_state <= next_state;

            // Timer handling in LOCK state
            if (current_state == LOCK) begin
                if (timer_count < TIMEOUT)
                    timer_count <= timer_count + 1;
                else begin
                    timer_count   <= 0;
                    attempt_count <= 0;  // reset attempts after timeout
                end
            end else begin
                timer_count <= 0; // reset timer if not in lock state
            end
        end
    end

    // Next-state logic
    always @(*) begin
        case (current_state)
            IDLE: begin
                if (enter_button) 
                    next_state = CHECK_1;
                else 
                    next_state = IDLE;
            end

            CHECK_1: begin
                if (ip_pass == PASS_DIGIT1) next_state = CHECK_2;
                else                        next_state = DENY;
            end

            CHECK_2: begin
                if (ip_pass == PASS_DIGIT2) next_state = CHECK_3;
                else                        next_state = DENY;
            end

            CHECK_3: begin
                if (ip_pass == PASS_DIGIT3) next_state = CHECK_4;
                else                        next_state = DENY;
            end

            CHECK_4: begin
                if (ip_pass == PASS_DIGIT4) next_state = GRANT;
                else                        next_state = DENY;
            end

            GRANT: next_state = IDLE;

            DENY: begin
                if (attempt_count == 2) // already had 2 wrong → 3rd wrong
                    next_state = LOCK;
                else
                    next_state = IDLE;
            end

            LOCK: begin
                if (timer_count < TIMEOUT)
                    next_state = LOCK;
                else
                    next_state = IDLE;  // unlock after timeout
            end

            default: next_state = IDLE;
        endcase
    end

   
    // Output & attempt logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant        <= 0;
            deny         <= 0;
            lock         <= 0;
            attempt_count<= 0;
        end else begin
            case (current_state)
                GRANT: begin
                    grant <= 1;
                    deny  <= 0;
                    lock  <= 0;
                    attempt_count <= 0; // reset attempts on success
                end

                DENY: begin
                    grant <= 0;
                    deny  <= 1;
                    lock  <= 0;
                    attempt_count <= attempt_count + 1; // increment on failure
                end

                LOCK: begin
                    grant <= 0;
                    deny  <= 0;
                    lock  <= 1;
                end

                default: begin
                    grant <= 0;
                    deny  <= 0;
                    lock  <= 0;
                end
            endcase
        end
    end

endmodule
