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
//  Module: ULPI Interface Controller (sc_scbc_uic)
//-----------------------------------------------------------------------------

module sc_ulpi_uic (
  // System Interface
  input ULPICLK,
  input ULPIRSTB,

  // from/to "Port Controller"
  // -------------------------
  // USB Port Status Interface
  input UPSI_REQ,
  output UPSI_ACK,
  input UPSI_TYPE,
  input [4:0] UPSI_STATE,
  input UPSI_CFG,

  // ULPI Register Low Level Access Interface
  input ULLA_REQ,
  output ULLA_ACK,
  input ULLA_WR0RD1,
  input [7:0] ULLA_ADDR,
  input [7:0] ULLA_WRDATA,

  // ULPI Receive Event
  output ULPI_CSC,
  output [1:0] ULPI_CCS,

  // ULPI PHY Receive Data interface
  output [7:0] URC_DATA,

  // from/to "USB Transaction Controller"
  // ------------------------------------
  // USB Packet Transmit Interface
  input PKT_TX_START,
  output logic PKT_TX_COMP,
  input [3:0] PKT_TX_PID,
  input [6:0] PKT_TX_ADR,
  input [3:0] PKT_TX_EPN,
  input [7:0] PKT_TX_DAT,
  input [10:0] PKT_TX_FMN,
  input [10:0] PKT_TX_NUM,

  // from/to "ULPI PHY"
  // ------------------
  // ULPI PHY Interface
  input [7:0] DATA_I,
  output logic [7:0] DATA_O,
  output logic DATA_E,
  input DIR,
  output logic STP,
  input NXT
);

// ----
// Internal signal declaration
// --------------------------------------------------

// ULPI Register Interface
logic REG_REQ;
logic REG_ACK;
logic [1:0] REG_CCD;
logic [5:0] REG_CPD;
logic [7:0] REG_EXT_ADDR;
logic [7:0] REG_TX_DATA;

// ULPI Protocol Engine Interface
logic TXD_REQ;
logic TXD_ACK;
logic [5:0] TXD_CPD;
logic TXD_VALID;
logic TXD_READY;
logic TXD_LAST;
logic [7:0] TXD_DATA;

// ULPI Receive Data
logic RXD_CMD_VALID;
logic RXD_DATA_VALID;
logic [7:0] ULPI_DATA;

// ----
// ULPI Data Receiver (sc_scbc_udr)
// --------------------------------------------------
sc_ulpi_udr udr (
  // System Interface
  .ULPICLK(ULPICLK),
  .ULPIRSTB(ULPIRSTB),

  // ULPI Receive Data
  .RXD_CMD_VALID(RXD_CMD_VALID),
  .RXD_DATA_VALID(RXD_DATA_VALID),
  .ULPI_DATA(ULPI_DATA),

  // ULPI Receive Event
  .ULPI_CSC(ULPI_CSC),
  .ULPI_CCS(ULPI_CCS)
);

// ----
// ULPI Packet Generator (sc_scbc_upg)
// --------------------------------------------------
sc_ulpi_upg upg (
  // System Interface
  .ULPICLK(ULPICLK),
  .ULPIRSTB(ULPIRSTB),

  // USB Packet Transmit Interface
  .PKT_TX_START(PKT_TX_START),
  .PKT_TX_COMP(PKT_TX_COMP),
  .PKT_TX_PID(PKT_TX_PID),
  .PKT_TX_ADR(PKT_TX_ADR),
  .PKT_TX_EPN(PKT_TX_EPN),
  .PKT_TX_DAT(PKT_TX_DAT),
  .PKT_TX_FMN(PKT_TX_FMN),
  .PKT_TX_NUM(PKT_TX_NUM),

  // ULPI Protocol Engine Interface
  .TXD_REQ(TXD_REQ),
  .TXD_ACK(TXD_ACK),
  .TXD_CPD(TXD_CPD),
  .TXD_VALID(TXD_VALID),
  .TXD_READY(TXD_READY),
  .TXD_LAST(TXD_LAST),
  .TXD_DATA(TXD_DATA)
);

// ----
// ULPI Packet Generator (sc_scbc_upg)
// --------------------------------------------------
sc_ulpi_urc urc (
  // System Interface
  .ULPICLK(ULPICLK),
  .ULPIRSTB(ULPIRSTB),

  // USB Port Status Interface
  .UPSI_REQ(UPSI_REQ),
  .UPSI_ACK(UPSI_ACK),
  .UPSI_TYPE(UPSI_TYPE),
  .UPSI_STATE(UPSI_STATE),
  .UPSI_CFG(UPSI_CFG),

  // ULPI Register Low Level Access Interface
  .ULLA_REQ(ULLA_REQ),
  .ULLA_ACK(ULLA_ACK),
  .ULLA_WR0RD1(ULLA_WR0RD1),
  .ULLA_ADDR(ULLA_ADDR),
  .ULLA_WRDATA(ULLA_WRDATA),

  // ULPI PHY Receive Data interface
  .URC_DATA(URC_DATA),

  // ULPI Register Interface
  .REG_REQ(REG_REQ),
  .REG_ACK(REG_ACK),
  .REG_CCD(REG_CCD),
  .REG_CPD(REG_CPD),
  .REG_EXT_ADDR(REG_EXT_ADDR),
  .REG_TX_DATA(REG_TX_DATA),
  .ULPI_DATA(ULPI_DATA)
);

// ----
// ULPI Protocol Engine (sc_scbc_upe)
// --------------------------------------------------
sc_ulpi_upe upe (
  // System Interface
  .ULPICLK(ULPICLK),
  .ULPIRSTB(ULPIRSTB),

  // ULPI Register Interface
  .REG_REQ(REG_REQ),
  .REG_ACK(REG_ACK),
  .REG_CCD(REG_CCD),
  .REG_CPD(REG_CPD),
  .REG_EXT_ADDR(REG_EXT_ADDR),
  .REG_TX_DATA(REG_TX_DATA),

  // ULPI Protocol Engine Interface
  .TXD_REQ(TXD_REQ),
  .TXD_ACK(TXD_ACK),
  .TXD_CPD(TXD_CPD),
  .TXD_VALID(TXD_VALID),
  .TXD_READY(TXD_READY),
  .TXD_LAST(TXD_LAST),
  .TXD_DATA(TXD_DATA),

  // ULPI Receive Data
  .RXD_CMD_VALID(RXD_CMD_VALID),
  .RXD_DATA_VALID(RXD_DATA_VALID),
  .ULPI_DATA(ULPI_DATA),

  // ULPI PHY Interface
  .DATA_I(DATA_I),
  .DATA_O(DATA_O),
  .DATA_E(DATA_E),
  .DIR(DIR),
  .STP(STP),
  .NXT(NXT)
);

endmodule
