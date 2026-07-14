// ============================================================================
// Module Name: Lab2_FIR
// Target Device: Intel MAX 10 (DE10-Lite FPGA Board - 10M50DAF484C7G)
// Description: Real-time 3-Tap FIR Moving Average Filter with Noise Rejection.
//              Includes a 50MHz-to-1Hz Clock Scaler and Magnitude Thresholding.
// ============================================================================

module Lab2_FIR (
    input  wire       MAX10_CLK1_50, // 50MHz onboard system clock
    input  wire [0:0] SW,            // Input stimulus switch (x[n])
    output wire [9:0] LEDR,          // Visualizer LEDs (History & Output)
    output wire [7:0] HEX0           // 7-Segment Display (to be disabled)
);

    // ------------------------------------------------------------------------
    // 1. CLOCK DIVIDER ARCHITECTURE (50MHz -> 1Hz)
    // ------------------------------------------------------------------------
    reg [25:0] counter = 26'd0;
    reg        slow_clk = 1'b0;

    always @(posedge MAX10_CLK1_50) begin
        // 25,000,000 cycles at 50MHz equals 0.5 seconds (1Hz toggle rate)
        if (counter == 26'd25000000) begin
            slow_clk <= ~slow_clk;
            counter  <= 26'd0;
        end else begin
            counter  <= counter + 26'd1;
        end
    end

    // ------------------------------------------------------------------------
    // 2. DISCRETE DELAY LINE (SHIFT REGISTER PIPELINE: z^-1 ELEMENTS)
    // ------------------------------------------------------------------------
    reg x_n   = 1'b0; // Sample at n
    reg x_n_1 = 1'b0; // Sample at n-1 (1 clock cycle delay)
    reg x_n_2 = 1'b0; // Sample at n-2 (2 clock cycles delay)

    always @(posedge slow_clk) begin
        x_n_2 <= x_n_1;  // Shift sample from (n-1) to (n-2)
        x_n_1 <= x_n;    // Shift sample from (n) to (n-1)
        x_n   <= SW[0];  // Sample new GPIO input into x[n]
    end

    // ------------------------------------------------------------------------
    // 3. COMBINATIONAL SUMMATION & THRESHOLD DETECTION LOGIC
    // ------------------------------------------------------------------------
    wire [1:0] sum;
    
    // Calculate the moving sum: y[n] = x[n] + x[n-1] + x[n-2]
    assign sum = {1'b0, x_n} + {1'b0, x_n_1} + {1'b0, x_n_2};

    // ------------------------------------------------------------------------
    // 4. HARDWARE I/O ASSIGNMENTS & VISUALIZATION
    // ------------------------------------------------------------------------
    
    // Tap History Visualizers
    assign LEDR[0] = x_n;
    assign LEDR[1] = x_n_1;
    assign LEDR[2] = x_n_2;
    assign LEDR[8:3] = 6'b000000; // Tie unused LEDs to ground

    // Filter Decision Output:
    // Assert High only when accumulated energy satisfies threshold (sum >= 2)
    assign LEDR[9] = (sum >= 2'd2) ? 1'b1 : 1'b0;

    // Force 7-Segment display lines HIGH to turn off active-low segments
    assign HEX0 = 8'hFF;

endmodule
