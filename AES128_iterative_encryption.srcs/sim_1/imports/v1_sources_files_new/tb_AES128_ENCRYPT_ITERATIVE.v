`timescale 1ns / 1ps

module tb_AES128_ENCRYPT_ITERATIVE;

localparam integer CLKS_PER_BIT = 868;
localparam integer CLK_PERIOD_NS = 10;
localparam integer BIT_PERIOD_NS = CLKS_PER_BIT * CLK_PERIOD_NS;

localparam [127:0] TEST_PLAINTEXT  = 128'h4142434445464748494a4b4c4d4e4f51;
localparam [127:0] TEST_KEY        = 128'h000102030405060708090a0b0c0d0e0f;
localparam [127:0] TEST_CIPHERTEXT = 128'h2682c7cc07bf0f585db9a92a5dedb25f;

reg clk_fpga = 1'b0;
reg reset = 1'b1;
reg rx = 1'b1;
wire tx;
wire [7:0] leds;
wire done_led;

reg [7:0] received [0:15];
integer i;

AES128_ENCRYPT_UART_WRAPPER #(
    .CLKS_PER_BIT(CLKS_PER_BIT),
    .AES_WAIT_CYCLES(140)
) dut (
    .clk_fpga(clk_fpga),
    .reset(reset),
    .rx(rx),
    .tx(tx),
    .leds(leds),
    .done_led(done_led)
);

always #(CLK_PERIOD_NS/2) clk_fpga = ~clk_fpga;

task uart_send_byte;
    input [7:0] value;
    integer bit_index;
    begin
        rx = 1'b0;
        #(BIT_PERIOD_NS);
        for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
            rx = value[bit_index];
            #(BIT_PERIOD_NS);
        end
        rx = 1'b1;
        #(BIT_PERIOD_NS);
    end
endtask

task uart_read_byte;
    output [7:0] value;
    integer bit_index;
    begin
        wait (tx === 1'b1);
        @(negedge tx);
        #(BIT_PERIOD_NS + (BIT_PERIOD_NS/2));
        for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
            value[bit_index] = tx;
            #(BIT_PERIOD_NS);
        end
        if (tx !== 1'b1) begin
            $error("UART TX stop bit was not high");
        end
        #(BIT_PERIOD_NS/2);
    end
endtask

task send_block_msb_first;
    input [127:0] block;
    integer byte_index;
    begin
        for (byte_index = 0; byte_index < 16; byte_index = byte_index + 1) begin
            uart_send_byte(block[127 - (byte_index * 8) -: 8]);
        end
    end
endtask

task read_ciphertext;
    integer byte_index;
    begin
        for (byte_index = 0; byte_index < 16; byte_index = byte_index + 1) begin
            uart_read_byte(received[byte_index]);
        end
    end
endtask

task send_transaction;
    input [127:0] plaintext;
    input [127:0] key;
    input [127:0] expected;
    begin
        send_block_msb_first(plaintext);
        send_block_msb_first(key);
        send_block_msb_first(expected);
    end
endtask

task expect_received_ciphertext;
    input [127:0] expected;
    integer byte_index;
    reg [127:0] observed;
    begin
        observed = 128'd0;
        for (byte_index = 0; byte_index < 16; byte_index = byte_index + 1) begin
            observed[127 - (byte_index * 8) -: 8] = received[byte_index];
        end

        $display("Observed ciphertext = %h", observed);
        $display("Expected ciphertext = %h", expected);

        if (observed !== expected) begin
            $error("UART ciphertext mismatch");
        end
    end
endtask

initial begin
    $display("Starting UART AES-128 encryption verification testbench");

    repeat (20) @(posedge clk_fpga);
    reset = 1'b0;
    repeat (5) @(posedge clk_fpga);

    if (done_led !== 1'b0) begin
        $error("done_led asserted before any matching transaction");
    end

    fork
        send_transaction(TEST_PLAINTEXT, TEST_KEY, TEST_CIPHERTEXT);
        read_ciphertext();
    join
    expect_received_ciphertext(TEST_CIPHERTEXT);

    repeat (20) @(posedge clk_fpga);
    if (done_led !== 1'b1) begin
        $error("done_led did not assert for matching expected ciphertext");
    end
    if (leds !== TEST_CIPHERTEXT[7:0]) begin
        $error("leds do not show final ciphertext byte");
    end

    $display("UART AES-128 encryption verification PASS");
    $finish;
end

endmodule
