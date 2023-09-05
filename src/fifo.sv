/*
Copyright (C) 2023 Ryan Robertson <rrobertson@gmail.com>

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

`timescale 1ns / 1ns

// fwft fifo w/ sync bram
module fifo
#(
  parameter integer FWFT  = 1,
  parameter integer WIDTH = 32,
  parameter integer DEPTH = 1024
)
(
  // globals
  input  logic             clk,
  input  logic             rst,
  output logic             full,
  input  logic             wr,
  input  logic [WIDTH-1:0] din,
  output logic             empty,
  input  logic             rd,
  output logic             dvld,
  output logic [WIDTH-1:0] dout
);

  logic fifo_wr, fifo_rd;
  logic wptr_fe, rptr_fe;
  logic [$clog2(DEPTH)-1:0] wptr;
  logic [$clog2(DEPTH)-1:0] rptr;
  logic [$clog2(DEPTH)-1:0] rptr_lookahead;
  logic [WIDTH-1:0] fifo_din;
  logic [WIDTH-1:0] fifo_dout;

  bram #(.DEPTH(DEPTH), .WIDTH(WIDTH)) U_MEMORY (
    .clk   (clk),
    // port a
    .addra (wptr),
    .wea   (fifo_wr),
    .dina  (fifo_din),
    .douta (),
    // port b
    .rd    (fifo_rd),
    .addrb (rptr_lookahead),
    .doutb (fifo_dout)
  );

  assign fifo_wr = wr & ~full;
  assign fifo_rd = rd & ~empty;

  assign empty = wptr == rptr && wptr_fe == rptr_fe;
  assign full  = wptr == rptr && wptr_fe != rptr_fe;

  assign fifo_din = din;

  always @(posedge clk) begin
    if (rst) begin
      wptr    <= '0;
      wptr_fe <= 1'b0;
    end else begin
      if (fifo_wr)
        {wptr_fe, wptr} <= wptr + 1'b1;
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      rptr    <= '0;
      rptr_fe <= 1'b0;
    end else begin
      if (fifo_rd)
        {rptr_fe, rptr} <= rptr + 1'b1;
    end
  end

  assign rptr_lookahead = fifo_rd & FWFT ? rptr + 1'b1 : rptr;

  generate
    if (FWFT) begin
      logic [WIDTH-1:0] din_q;
      logic             ft; // fallthrough
      logic             ft_continue;

      assign ft = wr & empty;

      always @(posedge clk) begin
        if (rst) begin
          ft_continue  <= 1'b0;
          din_q        <= '0;
        end else begin
          din_q       <= din;
          ft_continue <= ft | (ft_continue & rd);
        end
      end

      assign dout = ft | ft_continue ? din_q : fifo_dout;
    end else begin
      always_ff @(posedge clk)
        dvld <= fifo_rd;

      assign dout = fifo_dout;
    end
  endgenerate

endmodule
