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

`timescale 1ns / 1ns

module bram #(
  parameter integer DEPTH = 8,
  parameter integer WIDTH = 32)
(
  // globals
  input  logic                     clk,
  // port a, read/write
  input  logic                     wea,
  input  logic [$clog2(DEPTH)-1:0] addra,
  input  logic [WIDTH-1:0]         dina,
  output logic [WIDTH-1:0]         douta,
  // port b, read only
  input  logic                     rd,
  input  logic [$clog2(DEPTH)-1:0] addrb,
  output logic [WIDTH-1:0]         doutb  
);

  logic [WIDTH-1:0] mem [DEPTH-1:0];

  initial begin
    for (integer i=0; i<DEPTH; i++) begin
      mem[i] = 32'hDEADBEEF;
      $dumpvars(0, mem[i]);
    end
  end

  always @(posedge clk) begin
    if (wea)
      mem[addra] <= dina;
    
    douta <= mem[addra];
  end

  always @(posedge clk) begin
    doutb <= mem[addrb];
  end

endmodule