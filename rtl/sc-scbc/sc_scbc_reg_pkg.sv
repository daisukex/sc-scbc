//-----------------------------------------------------------------------------
// Copyright 2024 Space Cubics, LLC
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
// Space Cubics Standard IP Core
//  Space Communication Bus Controller
//  Module: Register Package (sc_scbc_reg_pkg)
//-----------------------------------------------------------------------------

`ifndef _SC_SCBC_REG_PKG_SV_
`define _SC_SCBC_REG_PKG_SV_

`timescale 1ps/1ps

package sc_scbc_reg_pkg;

import sc_ipreg_pkg_v1_0::*;

`define regNum(addr) (32'h0000_FFFF & addr) >> 2

localparam addrDecodeBits = 32'h0000_FFFC;

// ----
// SCBC Version Register
// --------------------------------------------------
// Register Parameter
typedef struct packed {
  logic [7:0] majorVer;                               // Major Version
  logic [7:0] minorVer;                               // Minor Version
  logic [15:0] patchVer;                              // Patch Version
} scbcVer_t;

const scRegParam_t scbcVer_p = {16'h0000,             // Base addres
                                32'h0000_0000,        // Valid
                                32'h0000_0000,        // Write
                                32'h0000_0000,        // Write set
                                32'h0000_0000,        // Write clear
                                32'hFFFF_FFFF,        // Read only
                                32'hxxxx_xxxx,        // Initial Value
                                32'h0000_0000};       // Constant

// ----
// ULPI PHY Control Status Register
// --------------------------------------------------

// Register Description
typedef struct packed {
  logic [31:17] reserved3;                            // Reserved
  logic ulpiClkSt;                                    // ULPI clock status
  logic [15:5] reserved2;                             // Reserved
  logic ulpiReset;                                    // ULPI Reset
  logic [3:1] reserved1;                              // Reserved
  logic ulpiPowerDown;                                // ULPI Power Down
} scbcUPC_t;

// Register Parameter
const scRegParam_t scbcUPC_p = {16'h0004,            // Base Address
                                32'h0000_0011,       // Valid
                                32'h0000_0011,       // Write
                                32'h0000_0000,       // Write set
                                32'h0000_0000,       // Write clear
                                32'h0001_0000,       // Read only
                                32'h0000_0011,       // Initial Value
                                32'h0000_0000};      // Constant

// ----
// SCBC Configuration Register
// --------------------------------------------------

// Register Description
typedef struct packed {
  logic [31:2] reserved1;                             // Reserved
  logic deviceMode;                                   // Device Mode
  logic hostMode;                                     // Host Mode
} scbcCfg_t;

// Register Parameter
const scRegParam_t scbcCfg_p = {16'h0008,             // Base Address
                                32'h0000_0003,        // Valid
                                32'h0000_0003,        // Write
                                32'h0000_0000,        // Write set
                                32'h0000_0000,        // Write clear
                                32'h0001_0000,        // Read only
                                32'h0000_0000,        // Initial Value
                                32'h0000_0000};       // Constant

// ----
// SCBC Interrupt Status Register
// --------------------------------------------------

// Register Description
typedef struct packed {
  logic portStatusST;
} scbcISR_t;

// Register Parameter
const scRegParam_t scbcISR_p = {16'h0010,             // Base Address
                                32'h0000_0000,        // Valid
                                32'h0000_0000,        // Write
                                32'h0000_0000,        // Write set
                                32'h0000_0000,        // Write clear
                                32'h0000_0001,        // Read only
                                32'h0000_0000,        // Initial Value
                                32'h0000_0000};       // Constant

// ----
// SCBC Interrupt Enable Register
// --------------------------------------------------

// Register Description
typedef struct packed {
  logic portStatusEN;
} scbcIER_t;

// Register Parameter
const scRegParam_t scbcIER_p = {16'h0014,             // Base Address
                                32'h0000_0001,        // Valid
                                32'h0000_0001,        // Write
                                32'h0000_0000,        // Write set
                                32'h0000_0000,        // Write clear
                                32'h0000_0000,        // Read only
                                32'h0000_0000,        // Initial Value
                                32'h0000_0000};       // Constant

// ----
// USB Port Status Register
// --------------------------------------------------

// Register Description
typedef struct packed {
  logic [31:20] reserved3;                            // Reserved
  logic prsc;                                         // Port Reset Status Change
  logic pssc;                                         // Port Suspend Status Change
  logic pesc;                                         // Port Enable Status Change
  logic csc;                                          // Connect Status Change
  logic reserved2;                                    // Reserved
  logic spe;                                          // Set Port Enable (fot Debug)
  logic cpp;                                          // Clear Port Power
  logic spp;                                          // Set Port Power
  logic cps;                                          // Clear Port Status
  logic sps;                                          // Set Port Suspend 
  logic spr;                                          // Set Port Reset
  logic cpe;                                          // Clear Port Enable
  logic [7:6] reserved1;                              // Reserved
  logic pps;                                          // Port Power Status
  logic lsda;                                         // Low Speed Device Attached
  logic prs;                                          // Port Reset Status
  logic pss;                                          // Port Suspend Status
  logic pes;                                          // Port Enable Status
  logic ccs;                                          // Current Connect Status
} scbcUPS_t;

// Register Parameter
const scRegParam_t scbcUPS_p = {16'h0020,             // Base Address
                                32'h000B_7F00,        // Valid
                                32'h0000_0000,        // Write
                                32'h0000_7F00,        // Write set
                                32'h000B_0000,        // Write clear
                                32'h0000_003F,        // Read only
                                32'h0000_0000,        // Initial Value
                                32'h0000_0000};       // Constant

// ----
// Frame Interval Register
// --------------------------------------------------

// Register Description
typedef struct packed {
  logic [31:16] reserved;                             // Reserved
  logic [15:0] fmInterval;                            // Frame Interval
} scbcFmI_t;

// Register Parameter
const scRegParam_t scbcFmI_p = {16'h0030,             // Base Address
                                32'h0001_FFFF,        // Valid
                                32'h0001_FFFF,        // Write
                                32'h0000_0000,        // Write set
                                32'h0000_0000,        // Write clear
                                32'h0000_0000,        // Read only
                                32'h0000_EA5F,        // Initial Value
                                32'h0000_0000};       // Constant

// ----
// Frame Remaining Register
// --------------------------------------------------

// Register Description
typedef struct packed {
  logic fmRToggle;
  logic [30:17] reserved1;
  logic fmEnable;                                     // Frame Enable
  logic [15:0] fmRemaining;
} scbcFmR_t;

// Register Parameter
const scRegParam_t scbcFmR_p = {16'h0034,             // Base Address
                                32'h8001_FFFF,        // Valid
                                32'h0001_0000,        // Write
                                32'h0000_0000,        // Write set
                                32'h0000_0000,        // Write clear
                                32'h8000_FFFF,        // Read only
                                32'h0000_0000,        // Initial Value
                                32'h0000_0000};       // Constant

// ----
// Frame Number Register
// --------------------------------------------------

// Register Description
typedef struct packed {
  logic [31:17] reserved1;                            // Reserved
  logic fmNMode;                                      // Frame Number Mode
  logic [15:0] fmNumber;                              // Frame Number
} scbcFmN_t;

// Register Parameter
const scRegParam_t scbcFmN_p = {16'h0038,             // Base Address
                                32'h8001_FFFF,        // Valid
                                32'h0001_FFFF,        // Write
                                32'h0000_0000,        // Write set
                                32'h0000_0000,        // Write clear
                                32'h0000_FFFF,        // Read only
                                32'h0000_0000,        // Initial Value
                                32'h0000_0000};       // Constant

// ----
// ULPI Low-Level Access Register
// --------------------------------------------------

// Register Description
typedef struct packed {
  logic [7:0] rdData;
  logic [7:0] wrData;
  logic [7:0] addr;
  logic [7:5] reserved2;
  logic wr0rd1;
  logic [3:1] reserved1;
  logic busy;
} scbcULLA_t;

// Register Parameter
const scRegParam_t scbcULLA_p = {16'h0040,            // Base Address
                                 32'hFFFF_FF11,       // Valid
                                 32'h00FF_FF10,       // Write
                                 32'h0000_0001,       // Write set
                                 32'h0000_0000,       // Write clear
                                 32'h0000_0000,       // Read only
                                 32'h0000_0000,       // Initial Value
                                 32'h0000_0000};      // Constant

// Advanced register parameter table
// --------------------------------------------------
localparam synchronous = 0;
localparam asynchronous = 1;
localparam notassigned = 0;
typedef enum logic [1:0] {GSR=0, UPC, FTC, unknown} RegRoot_t;

typedef struct packed {
  logic sync;
  RegRoot_t root;
} scAdvancedRegParam;

const scAdvancedRegParam RegAdvancedParam [0:20] = '{
  `regNum(16'h0000): '{sync: synchronous,  root: GSR},      // SCBC Version Register
  `regNum(16'h0004): '{sync: synchronous,  root: GSR},      // ULPI PHY Control Regsier
  `regNum(16'h0008): '{sync: asynchronous, root: UPC},      // SCBC Configuration Register
  `regNum(16'h0010): '{sync: synchronous,  root: GSR},      // SCBC Interrupt Status Regsier
  `regNum(16'h0014): '{sync: synchronous,  root: GSR},      // SCBC Interrupt Enable Register
  `regNum(16'h0020): '{sync: asynchronous, root: UPC},      // USB Port Status Register
  `regNum(16'h0030): '{sync: asynchronous, root: FTC},      // Frame Interval Register
  `regNum(16'h0034): '{sync: asynchronous, root: FTC},      // Frame Remaining Register
  `regNum(16'h0038): '{sync: asynchronous, root: FTC},      // Frame Number Register
  `regNum(16'h003C): '{sync: asynchronous, root: unknown},  // -
  `regNum(16'h0040): '{sync: asynchronous, root: UPC},      // ULPI Row Level Access Register
              default: '{sync: notassigned,  root: unknown}}; // 

// Identifying register characteristics
// --------------------------------------------------
function integer isAsyncReg;
  input scAdvancedRegParam rap;
begin
  isAsyncReg = rap.sync;
end
endfunction

function RegRoot_t RegRoot;
  input scAdvancedRegParam rap;
begin
  RegRoot = rap.root;
end
endfunction

endpackage

`endif
