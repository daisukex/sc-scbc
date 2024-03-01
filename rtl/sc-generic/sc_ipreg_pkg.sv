//-----------------------------------------------------------------------------
// Copyright 2023 Space Cubics, LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//-----------------------------------------------------------------------------
// Space Cubics IP Core Register Package
//  Version: 1.0.0
//-----------------------------------------------------------------------------

`ifndef _SC_IPREG_PKG_V1_0_SV_
`define _SC_IPREG_PKG_V1_0_SV_

`timescale 1ps/1ps

package sc_ipreg_pkg_v1_0;

// Space Cubics Register Parameter
// --------------------------------------------------
typedef struct packed {
  logic [15:0] addr;     // Define the address of this register
  logic [31:0] valid;    // Define whether a register exists or not
                         // Define bit behavior for write access
  logic [31:0] write;    // - Write 1 sets the bit to 1, and write 0 clears the bit to 0
  logic [31:0] wset;     // - Write 1 sets the bit to 1, and write 0 has no effect
  logic [31:0] wclr;     // - Write 1 clears the bit to 0, and write 0 has no effect
  logic [31:0] ronly;    // - This bit is read-only. All write access is invalid
  logic [31:0] init;     // Define the initial value of this register
  logic [31:0] cnst;     // Define the bits of a constant value
} scRegParam_t;


// Register Address Decode Function
// --------------------------------------------------
typedef struct {
  logic wr;
  logic rd;
} scRegHit_t;

function scRegHit_t isRegHit;
  input scRegParam_t rp; // register param
  input [31:0] cb;       // compare bit
  input [31:0] wa;       // write address
  input [31:0] ra;       // read address
  input we;              // write enable
  input re;              // read enable
begin
  isRegHit.rd = re & ((ra & cb) == (rp.addr & cb));
  isRegHit.wr = we & ((wa & cb) == (rp.addr & cb));
end
endfunction


// Register Read/Write Function
// --------------------------------------------------
function [31:0] scRegWr;
  input scRegParam_t rp; // register param
  input scRegHit_t hit;  // register hit
  input [31:0] rd;       // register data
  input [31:0] wd;       // write data
  input [3:0] en;        // write enable
  integer i;
begin
  // Initialize
  for(i=0; i<32; i=i+1) begin
    if (rp.valid[i] & rp.cnst[i])
      scRegWr[i] = rp.init[i];
    else if (rp.valid[i] & !rp.ronly[i])
      scRegWr[i] = rd[i];
    else
      scRegWr[i] = 1'b0;
  end

  // Register Write
  if (hit.wr) begin
    // Write Data
    for(i=0; i<32; i=i+1) begin
      if (rp.valid[i] & !rp.cnst[i] & en[i/8]) begin
        if (rp.write[i])
          scRegWr[i] = wd[i];
        else if (rp.wset[i] & wd[i])
          scRegWr[i] = 1'b1;
        else if (rp.wclr[i] & wd[i])
          scRegWr[i] = 1'b0;
      end
    end
  end
end
endfunction


// 1-bit Register Read/Write Function
// --------------------------------------------------
function scRegWrBit;
  input scRegParam_t rp;
  input scRegHit_t hit;
  input [31:0] rd;
  input [31:0] wd;
  input [3:0] en;
  input [4:0] bt;
begin
  // Initialize
  if (rp.valid[bt] & rp.cnst[bt])
    scRegWrBit = rp.init[bt];
  else if (rp.valid[bt] & !rp.ronly[bt])
    scRegWrBit = rd[bt];
  else
    scRegWrBit = 1'b0;

  // Register Write
  if (hit.wr) begin
    // Write Data
    if (rp.valid[bt] & !rp.cnst[bt] & en[bt/8]) begin
      if (rp.write[bt])
        scRegWrBit = wd[bt];
      else if (rp.wset[bt] & wd[bt])
        scRegWrBit = 1'b1;
      else if (rp.wclr[bt] & wd[bt])
        scRegWrBit = 1'b0;
    end
  end
end
endfunction


// Register chenge due to write access
// --------------------------------------------------
function scRegWrChange;
  input scRegParam_t rp; // register param
  input scRegHit_t hit;  // register hit
  input [31:0] rd;       // register data
  input [31:0] wd;       // write data
  input [3:0] en;        // write enable
  input [31:0] pos;      // position
  logic [31:0] wa;       // writable
  integer i;
begin
  scRegWrChange = 1'b0;
  wa = rp.valid & ~rp.ronly & (rp.write | rp.wset | rp.wclr);

  for(i=0; i<32; i=i+1) begin
    if (pos[i] & hit.wr & en[i/8] & wa[i]) begin
      if (rp.write[i] & (wd[i] ^ rd[i]))
        scRegWrChange = 1'b1;
      else if (rp.wset[i] & (wd[i] & !rd[i]))
        scRegWrChange = 1'b1;
      else if (rp.wclr[i] & (wd[i] & rd[i]))
        scRegWrChange = 1'b1;
    end
  end
end
endfunction

endpackage
`endif

