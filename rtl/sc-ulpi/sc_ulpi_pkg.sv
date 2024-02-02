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
//  Module: ULPI Package
//-----------------------------------------------------------------------------

`ifndef _SC_SCBUS_ULPI_PKG_
`define _SC_SCBUS_ULPI_PKG_

package sc_ulpi_pkg;

// ----
// Transmit Command Byte (TX CMD): ULPI spec 3.8.1.1
// --------------------------------------------------

// enum of command code data
typedef enum logic [1:0] {
             ccdSpecial  = 2'b00,    // Special
             ccdTransmit = 2'b01,    // Transmit
             ccdRegWrite = 2'b10,    // Reg Write
             ccdRegRead  = 2'b11     // Reg Read
} ulpiCCD_e;

// ----
// Receive Command Byte (RX CMD): ULPI spec 3.8.1.2
// --------------------------------------------------
/*
 * RxEvent:
 *  Encoded ULPI event signals
 *
 * |Value | RxActive | RxError | HostDisconnect |
 * |------+----------+---------+----------------|
 * |  00  |  0       |  0      |  0             |
 * |  01  |  1       |  0      |  0             |
 * |  11  |  1       |  1      |  0             |
 * |  10  |  X       |  X      |  1             |
 */
typedef enum logic [1:0] {
             noEvent = 2'b00,
             rxActive = 2'b01,
             rxError = 2'b11,
             hostDiscon = 2'b10
} utmiEvent_e;

typedef struct packed {
  logic altInt;
  logic id;
  utmiEvent_e rxEvent;
  logic [1:0] vbusState;
  logic [1:0] lineState;
} rxCmd_s;

// ----
// Upstream and Downstream signalling modes: ULPI spec 4.4
// --------------------------------------------------

// USB signalling modes
typedef enum logic [4:0] {
  tristateDrivers,
  powerUp,
  hostChirp, hostHs, hostFs, hostHsFsSuspend, hostHsFsResume, hostLs, hostLsSuspend, hostLsResume, hostTestJTestK,
  periChirp, periHs, periFs, periHsFsSuspend, periHsFsResume, periLs, periLsSuspend, periLsResume, periTestJTestK,
  otgPeriChirp, otgPeriHs, otgPeriFs, otgPriHsFsSuspend, otgPeriHsFsResume, otgPeriTestJTestK
} usbPortMode_e;

// Signal state
typedef struct packed {
  logic [1:0] xcvrSelect;
  logic termSelect;
  logic [1:0] opMode;
} utmiSignal_s;

const utmiSignal_s utmiXcvrSigs [0:25] = '{
  tristateDrivers:   '{xcvrSelect: 2'b01, termSelect: 1'b0, opMode: 2'b01},
  powerUp:           '{xcvrSelect: 2'b01, termSelect: 1'b0, opMode: 2'b00},

  hostChirp:         '{xcvrSelect: 2'b00, termSelect: 1'b0, opMode: 2'b10},
  hostHs:            '{xcvrSelect: 2'b00, termSelect: 1'b0, opMode: 2'b00},
  hostFs:            '{xcvrSelect: 2'b01, termSelect: 1'b1, opMode: 2'b00},
  hostHsFsSuspend:   '{xcvrSelect: 2'b01, termSelect: 1'b1, opMode: 2'b00},
  hostHsFsResume:    '{xcvrSelect: 2'b01, termSelect: 1'b1, opMode: 2'b10},
  hostLs:            '{xcvrSelect: 2'b10, termSelect: 1'b1, opMode: 2'b00},
  hostLsSuspend:     '{xcvrSelect: 2'b10, termSelect: 1'b1, opMode: 2'b00},
  hostLsResume:      '{xcvrSelect: 2'b10, termSelect: 1'b1, opMode: 2'b10},
  hostTestJTestK:    '{xcvrSelect: 2'b00, termSelect: 1'b0, opMode: 2'b10},

  periChirp:         '{xcvrSelect: 2'b01, termSelect: 1'b1, opMode: 2'b10},
  periHs:            '{xcvrSelect: 2'b01, termSelect: 1'b0, opMode: 2'b00},
  periFs:            '{xcvrSelect: 2'b01, termSelect: 1'b1, opMode: 2'b00},
  periHsFsSuspend:   '{xcvrSelect: 2'b01, termSelect: 1'b1, opMode: 2'b00},
  periHsFsResume:    '{xcvrSelect: 2'b01, termSelect: 1'b1, opMode: 2'b10},
  periLs:            '{xcvrSelect: 2'b01, termSelect: 1'b1, opMode: 2'b00},
  periLsSuspend:     '{xcvrSelect: 2'b01, termSelect: 1'b1, opMode: 2'b00},
  periLsResume:      '{xcvrSelect: 2'b01, termSelect: 1'b1, opMode: 2'b10},
  periTestJTestK:    '{xcvrSelect: 2'b01, termSelect: 1'b0, opMode: 2'b10},
  otgPeriChirp:      '{xcvrSelect: 2'b01, termSelect: 1'b1, opMode: 2'b10},
  otgPeriHs:         '{xcvrSelect: 2'b01, termSelect: 1'b0, opMode: 2'b00},
  otgPeriFs:         '{xcvrSelect: 2'b01, termSelect: 1'b1, opMode: 2'b00},
  otgPriHsFsSuspend: '{xcvrSelect: 2'b01, termSelect: 1'b1, opMode: 2'b00},
  otgPeriHsFsResume: '{xcvrSelect: 2'b01, termSelect: 1'b1, opMode: 2'b10},
  otgPeriTestJTestK: '{xcvrSelect: 2'b00, termSelect: 1'b0, opMode: 2'b10}
};

// ----
// ULPI Register: ULPI spec 4
// --------------------------------------------------

// Register Map: ULPI spec 4.1
//----------------------------
// Address table
typedef enum logic [5:0] {
             vendorIdLow      = 6'h00,
             vendorIdHigh     = 6'h01,
             productIdLow     = 6'h02,
             productIdHigh    = 6'h03,
             funcControl      = 6'h04,
             interfaceControl = 6'h07,
             otgControl       = 6'h0A,
             interruptStatus  = 6'h13,
             interruptLatch   = 6'h14,
             debug            = 6'h15,
             scratchRegister  = 6'h16,
             cpdExtend        = 6'h2F
} ulpiRegMap_e;

// OTG Control Register
typedef struct packed {
  logic UseExternalVbusIndeicator;
  logic DrvVbusExternal;
  logic DrvVbus;
  logic ChrgVbus;
  logic DischrgVbus;
  logic DmPulldown;
  logic DpPulldown;
  logic IdPullup;
} otgControl_s;

// Function Control Register
typedef struct packed {
  logic reserved;
  logic suspendM;
  logic reset;
  logic opMode;
  logic termSelect;
  logic [1:0] xcvrSelect;
} funcControl_s;

endpackage: sc_ulpi_pkg
`endif
