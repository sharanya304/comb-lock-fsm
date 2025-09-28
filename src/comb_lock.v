module comb_lock(
    input clk, rst, enter_button,
    input [3:0] ip_pass,        // user input: 4-bit digit (BCD 0–9)
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

    
    always @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
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
            DENY:  next_state = IDLE;
            LOCK:  next_state = IDLE;

            default: next_state = IDLE;
        endcase
    end

  

endmodule
