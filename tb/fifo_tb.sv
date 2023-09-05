/*
Copyright (C) 2022 Ryan Robertson <rrobertson@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

// simple rx tb
// send a byte of data at a specified baud rate

`timescale 1ns / 1ns

module fifo_tb;

  parameter integer DEPTH = 8;
  parameter integer WIDTH = 32;
  parameter bit     FWFT  = 1;

  logic [2:0] read_delay = $random();
  
  logic clk, rst;
  logic full, wr;
  logic [WIDTH-1:0] din;
  logic [WIDTH-1:0] dout;  
  logic dvld;
  reg rd;

  wire empty;

  bit PASS_FAIL = 1;

  logic [WIDTH-1:0] queue [$];

  fifo #(.FWFT(FWFT), .DEPTH(DEPTH), .WIDTH(WIDTH)) U_DUT (
    .clk   (clk),
    .rst   (rst),
    .full  (full),
    .wr    (wr),
    .din   (din),
    .empty (empty),
    .rd    (rd),
    .dvld  (dvld),
    .dout  (dout)
  );

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(2, U_DUT);
    $dumpvars(1, fifo_tb);
  end

  initial begin
    wr  = 0;
    din = 0;
  end

  // 100 mhz clk
  initial begin
    clk = 0;
    forever clk = #5 ~clk;
  end

  // reset gen
  initial begin
    rst <= 1;
    #1us;
    @(posedge clk)
    rst <= 0;
  end

  initial begin
    $display("test starting");
    $display("read delay of %x", read_delay);
    @(negedge rst);
    @(posedge clk);

    din <= 32'hDEADBEEF;
    repeat(10) @(posedge clk);

    for (int i=0; i<10; i=i+1) begin
      wr  <= 1'b1;
      din <= i;
      @(posedge clk);
    end

    wr  <= 1'b0;
    din <= 32'hDEADBEEF;
    #1us;
    if (PASS_FAIL) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end

  logic gate_rd;
  initial begin
    gate_rd = 1'b0;
    @(posedge wr);
    repeat(4) @(posedge clk);
    gate_rd = 1'b1;
  end

  assign rd = !empty & gate_rd;

  initial begin
    @(negedge rst);
    $display("reset deasserted at %5t", $realtime);
  end

  // checker
  initial begin
    logic [WIDTH-1:0] data_compare;

    fork
      begin
        forever begin
          @(posedge clk);
          if (wr & ~full) queue.push_front(din);          
        end
      end

      begin
        forever begin
          @(posedge clk);
          if ((rd & ~empty & FWFT) || (dvld & !FWFT)) begin
            data_compare = queue.pop_back();

            if (data_compare != dout) begin
              $error("data mismatch, got %x expected %x", dout, data_compare);
              PASS_FAIL = 0;
            end else begin
              $display("read out %x, good", dout);
            end
          end
        end
      end
    join
  end

endmodule