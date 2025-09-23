module comb_lock(
    input clk, rst,enter_button,
    input [3:0] ip_pass,        // user input: 4-digit passcode
    output reg grant, deny, lock
);


parameter IDLE=3'd0, 
CHECK_1=3'd1, 
CHECK_2=3'd2, 
CHECK_3=3'd3, 
CHECK_4=3'd4,
GRANT=3'd5, 
DENY=3'd6, 
LOCK=3'd7;

reg [2:0] current_state, next_state;
localparam [15:0] STORED_PASS = 16'd1537;
reg [1:0] count;
wire [3:0] pass_digit1 = STORED_PASS[15:12]; // 1
wire [3:0] pass_digit2 = STORED_PASS[11:8];  // 5
wire [3:0] pass_digit3 = STORED_PASS[7:4];   // 3
wire [3:0] pass_digit4 = STORED_PASS[3:0];   // 7

always @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
    
 // Next-state logic
 always@(*)begin
 case (current_state)
    IDLE: begin
    if(enter_button) 
        next_state =CHECK_1;
    else next_state= IDLE;
    end
    CHECK_1: begin
    if (ip_pass == pass_digit1) next_state = CHECK_2;
         else next_state = DENY;
    end
    CHECK_2: begin
    if (ip_pass == pass_digit2) next_state = CHECK_3;
         else next_state = DENY;
    end
    CHECK_3: begin
    if (ip_pass == pass_digit3) next_state = CHECK_4;
         else next_state = DENY;
    end
    CHECK_4: begin
    if (ip_pass == pass_digit4) next_state = GRANT;
         else next_state = DENY;
    end
    GRANT: 
    next_state= IDLE;
    DENY:    next_state = IDLE;  
    LOCK:    next_state = IDLE;  

    default: next_state = IDLE;
        endcase
        end
        
endmodule
