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
//  Module: Space Communication Bus Controller (sc_scbc)
//-----------------------------------------------------------------------------

module sc_scbc # (
  parameter AXI_ID_WIDTH = 1,
  parameter ADDR_WIDTH = 32,
  parameter DATA_BYTE = 4
) (
  // System bus clock and reset
  input SYSCLK,
  input SYSRSTB,
  // Interrupt output
  output INTERRUPT,

  // AXI Slave Interface
  input [AXI_ID_WIDTH-1:0] AXI_S_AWID,
  input [ADDR_WIDTH-1:0] AXI_S_AWADDR,
  input [7:0] AXI_S_AWLEN,
  input [2:0] AXI_S_AWSIZE,
  input [1:0] AXI_S_AWBURST,
  input AXI_S_AWLOCK,
  input [3:0] AXI_S_AWCACHE,
  input [2:0] AXI_S_AWPROT,
  input AXI_S_AWVALID,
  output logic AXI_S_AWREADY,
  input [(DATA_BYTE*8)-1:0] AXI_S_WDATA,
  input [DATA_BYTE-1:0] AXI_S_WSTRB,
  input AXI_S_WLAST,
  input AXI_S_WVALID,
  output AXI_S_WREADY,
  output logic [AXI_ID_WIDTH-1:0] AXI_S_BID,
  output logic [1:0] AXI_S_BRESP,
  output logic AXI_S_BVALID,
  input AXI_S_BREADY,
  input [AXI_ID_WIDTH-1:0] AXI_S_ARID,
  input [ADDR_WIDTH-1:0] AXI_S_ARADDR,
  input [7:0] AXI_S_ARLEN,
  input [2:0] AXI_S_ARSIZE,
  input [1:0] AXI_S_ARBURST,
  input AXI_S_ARLOCK,
  input [3:0] AXI_S_ARCACHE,
  input [2:0] AXI_S_ARPROT,
  input AXI_S_ARVALID,
  output logic AXI_S_ARREADY,
  output [AXI_ID_WIDTH-1:0] AXI_S_RID,
  output logic [(DATA_BYTE*8)-1:0] AXI_S_RDATA,
  output logic [1:0] AXI_S_RRESP,
  output logic AXI_S_RLAST,
  output logic AXI_S_RVALID,
  input AXI_S_RREADY,

  // ULPI Interface
  input ULPI_CLK,
  input [7:0] ULPI_DATA_I,
  output [7:0] ULPI_DATA_O,
  output ULPI_DATA_E,
  input ULPI_DIR,
  output ULPI_STP,
  input ULPI_NXT,

  output ULPI_PWRDWNB,
  output ULPI_RSTB
);

// System Interface Signal
logic ULPIRSTB;
logic UPC_ISR;
logic UPC_ISR_SYNC;

// Register Interface
logic SYS_WENB;
logic ULPI_WENB;
logic [ADDR_WIDTH-1:0] WADR;
logic [31:0] WDAT;
logic [3:0] WENB;
logic SYS_RENB;
logic ULPI_RENB;
logic [ADDR_WIDTH-1:0] RADR;
logic [31:0] GSR_RDAT;
logic [31:0] UPC_RDAT;
logic [31:0] FTC_RDAT;

// USB port status signals
logic UPSI_REQ;
logic UPSI_ACK;
logic UPSI_TYPE;
logic [4:0] UPSI_STATE;
logic UPSI_CFG;
logic UPS_OPERATIONAL;

// ULPI RX Event
logic ULPI_CSC;
logic [1:0] ULPI_CCS;

// Frame timing signals
logic FT_1MS;
logic [15:0] FT_FMNUMBER;

// Low-level access interface to ULPI Register
logic ULLA_REQ;
logic ULLA_ACK;
logic ULLA_WR0RD1;
logic [7:0] ULLA_ADDR;
logic [7:0] ULLA_WRDATA;
// ULPI read data signal
logic [7:0] URC_DATA;

// USB transaction control signals
logic PKT_TX_START;
logic PKT_TX_COMP;
logic [3:0] PKT_TX_PID;
logic [6:0] PKT_TX_ADR;
logic [3:0] PKT_TX_EPN;
logic [7:0] PKT_TX_DAT;
logic [10:0] PKT_TX_FMN;
logic [10:0] PKT_TX_NUM;

// ----
// ULPI PLL Lock Detect
// --------------------------------------------------

sc_scbc_pld # (
  .PLL_DETECT_CYCLE(10)
) pld (
  // System Interface
  .SYSCLK(SYSCLK),
  .SYSRSTB(SYSRSTB),
  .ULPI_RSTB(ULPI_RSTB),
  .ULPI_PWRDWNB(ULPI_PWRDWNB),

  // ULPI Interface
  .ULPICLK(ULPI_CLK),
  .ULPIRSTB(ULPIRSTB),
  .DIR(ULPI_DIR)
);

// ----
// CPU Interface
// --------------------------------------------------
sc_scbc_cif # (
  .AXI_ID_WIDTH(AXI_ID_WIDTH),
  .AXI_ADDR_WIDTH(ADDR_WIDTH),
  .AXI_DATA_BYTE(DATA_BYTE)
) cif (
  // System bus clock and reset
  .AXI_CLK(SYSCLK),
  .AXI_RESETN(SYSRSTB),

  // AXI Interface
  .AXI_S_AWID(AXI_S_AWID),
  .AXI_S_AWADDR(AXI_S_AWADDR),
  .AXI_S_AWLEN(AXI_S_AWLEN),
  .AXI_S_AWSIZE(AXI_S_AWSIZE),
  .AXI_S_AWBURST(AXI_S_AWBURST),
  .AXI_S_AWLOCK(AXI_S_AWLOCK),
  .AXI_S_AWCACHE(AXI_S_AWCACHE),
  .AXI_S_AWPROT(AXI_S_AWPROT),
  .AXI_S_AWVALID(AXI_S_AWVALID),
  .AXI_S_AWREADY(AXI_S_AWREADY),
  .AXI_S_WDATA(AXI_S_WDATA),
  .AXI_S_WSTRB(AXI_S_WSTRB),
  .AXI_S_WLAST(AXI_S_WLAST),
  .AXI_S_WVALID(AXI_S_WVALID),
  .AXI_S_WREADY(AXI_S_WREADY),
  .AXI_S_BID(AXI_S_BID),
  .AXI_S_BRESP(AXI_S_BRESP),
  .AXI_S_BVALID(AXI_S_BVALID),
  .AXI_S_BREADY(AXI_S_BREADY),
  .AXI_S_ARID(AXI_S_ARID),
  .AXI_S_ARADDR(AXI_S_ARADDR),
  .AXI_S_ARLEN(AXI_S_ARLEN),
  .AXI_S_ARSIZE(AXI_S_ARSIZE),
  .AXI_S_ARBURST(AXI_S_ARBURST),
  .AXI_S_ARLOCK(AXI_S_ARLOCK),
  .AXI_S_ARCACHE(AXI_S_ARCACHE),
  .AXI_S_ARPROT(AXI_S_ARPROT),
  .AXI_S_ARVALID(AXI_S_ARVALID),
  .AXI_S_ARREADY(AXI_S_ARREADY),
  .AXI_S_RID(AXI_S_RID),
  .AXI_S_RDATA(AXI_S_RDATA),
  .AXI_S_RRESP(AXI_S_RRESP),
  .AXI_S_RLAST(AXI_S_RLAST),
  .AXI_S_RVALID(AXI_S_RVALID),
  .AXI_S_RREADY(AXI_S_RREADY),

  // ULPI clock and reset
  .ULPICLK(ULPI_CLK),
  .ULPIRSTB(ULPIRSTB),

  // Register Interface
  .SYS_WENB(SYS_WENB),
  .ULPI_WENB(ULPI_WENB),
  .WADR(WADR),
  .WDAT(WDAT),
  .WENB(WENB),
  .SYS_RENB(SYS_RENB),
  .ULPI_RENB(ULPI_RENB),
  .RADR(RADR),
  .GSR_RDAT(GSR_RDAT),
  .UPC_RDAT(UPC_RDAT),
  .FTC_RDAT(FTC_RDAT)
);

// ----
// General Syncronouse Register
// --------------------------------------------------
sc_scbc_gsr # (
  .ADDR_WIDTH(ADDR_WIDTH)
) gsr (
  // System bus clock and resrt
  .SYSCLK(SYSCLK),
  .SYSRSTB(SYSRSTB),
  // System bus interrupt output signal
  .INTERRUPT(INTERRUPT),

  // Register Interface
  .WENB(SYS_WENB),
  .WADR(WADR),
  .WDAT(WDAT),
  .WBEN(WENB),
  .RENB(SYS_RENB),
  .RADR(RADR),
  .RDAT(GSR_RDAT),

  // Interrupt input signal
  .UPC_ISR(UPC_ISR_SYNC),

  // ULPI PHY control signals
  .ULPI_PWRDWNB(ULPI_PWRDWNB),
  .ULPI_RSTB(ULPI_RSTB),
  .ULPI_CLKSTATE(ULPIRSTB)
);

// ----
// Interrupt Signal Synchronizer
// --------------------------------------------------
sc_scbc_iss iss (
  // System bus clock and reset
  .SYSCLK(SYSCLK),
  .SYSRSTB(SYSRSTB),

  // Interrupt asynchronous input signal
  .UPC_ISR(UPC_ISR),

  // Interrupt Synchronus output signal
  .UPC_ISR_SYSCLK(UPC_ISR_SYNC)
);

// ----
// USB Port Controller
// --------------------------------------------------
sc_scbc_upc # (
  .ADDR_WIDTH(ADDR_WIDTH)
) upc (
  // ULPI clock and reset
  .ULPICLK(ULPI_CLK),
  .ULPIRSTB(ULPIRSTB),

  // Port Controller interrupt
  .UPC_ISR(UPC_ISR),

  // Register Interface
  .WENB(ULPI_WENB),
  .WADR(WADR),
  .WDAT(WDAT),
  .WBEN(WENB),
  .RENB(ULPI_RENB),
  .RADR(RADR),
  .RDAT(UPC_RDAT),

  // USB port control signals
  .UPSI_REQ(UPSI_REQ),
  .UPSI_ACK(UPSI_ACK),
  .UPSI_TYPE(UPSI_TYPE),
  .UPSI_STATE(UPSI_STATE),
  .UPSI_CFG(UPSI_CFG),

  // ULPI port status
  .UPS_OPERATIONAL(UPS_OPERATIONAL),

  // USB port event
  .ULPI_CSC(ULPI_CSC),
  .ULPI_CCS(ULPI_CCS),

  // Low-level access interface to ULPI Register
  .ULLA_REQ(ULLA_REQ),
  .ULLA_ACK(ULLA_ACK),
  .ULLA_WR0RD1(ULLA_WR0RD1),
  .ULLA_ADDR(ULLA_ADDR),
  .ULLA_WRDATA(ULLA_WRDATA),
  // ULPI read data signal
  .URC_DATA(URC_DATA),

  // Frame Timing signal
  .FT_1MS(FT_1MS)
);

// ----
// Frame Timing Controller
// --------------------------------------------------
sc_scbc_ftc # (
  .ADDR_WIDTH(ADDR_WIDTH)
) ftc (
  // ULPI clock and reset
  .ULPICLK(ULPI_CLK),
  .ULPIRSTB(ULPIRSTB),

  // Register Interface
  .WENB(ULPI_WENB),
  .WADR(WADR),
  .WDAT(WDAT),
  .WBEN(WENB),
  .RENB(ULPI_RENB),
  .RADR(RADR),
  .RDAT(FTC_RDAT),

  // USB Port Status signals
  .UPS_OPERATIONAL(UPS_OPERATIONAL),

  // Frame Timing signals
  .FT_1MS(FT_1MS),
  .FT_FMNUMBER(FT_FMNUMBER)
);

// ----
// ULPI Transaction Controller
// --------------------------------------------------
sc_scbc_utc utc (
  // ULPI clock and reset
  .ULPICLK(ULPI_CLK),
  .ULPIRSTB(ULPIRSTB),

  // USB port state signal
  .UPS_OPERATIONAL(UPS_OPERATIONAL),

  // Frame timing signal
  .FT_1MS(FT_1MS),

  // USB transaction control signals
  .PKT_TX_START(PKT_TX_START),
  .PKT_TX_COMP(PKT_TX_COMP),
  .PKT_TX_PID(PKT_TX_PID),
  .PKT_TX_ADR(PKT_TX_ADR),
  .PKT_TX_EPN(PKT_TX_EPN),
  .PKT_TX_DAT(PKT_TX_DAT),
  .PKT_TX_NUM(PKT_TX_NUM)
);

// ----
// ULPI Interface Controller
// --------------------------------------------------
sc_ulpi_uic uic (
  // ULPI clock and reset
  .ULPICLK(ULPI_CLK),
  .ULPIRSTB(ULPIRSTB),

  // USB Port Status Interface
  .UPSI_REQ(UPSI_REQ),
  .UPSI_ACK(UPSI_ACK),
  .UPSI_TYPE(UPSI_TYPE),
  .UPSI_STATE(UPSI_STATE),
  .UPSI_CFG(UPSI_CFG),

  // USB port event
  .ULPI_CSC(ULPI_CSC),
  .ULPI_CCS(ULPI_CCS),

  // USB Transaction Interface
  .PKT_TX_START(PKT_TX_START),
  .PKT_TX_COMP(PKT_TX_COMP),
  .PKT_TX_PID(PKT_TX_PID),
  .PKT_TX_ADR(PKT_TX_ADR),
  .PKT_TX_EPN(PKT_TX_EPN),
  .PKT_TX_DAT(PKT_TX_DAT),
  .PKT_TX_FMN(FT_FMNUMBER[10:0]),
  .PKT_TX_NUM(PKT_TX_NUM),

  // Low-level access interface to ULPI Register
  .ULLA_REQ(ULLA_REQ),
  .ULLA_ACK(ULLA_ACK),
  .ULLA_WR0RD1(ULLA_WR0RD1),
  .ULLA_ADDR(ULLA_ADDR),
  .ULLA_WRDATA(ULLA_WRDATA),
  // ULPI read data signal
  .URC_DATA(URC_DATA),

  // ULPI PHY Interface
  .DATA_I(ULPI_DATA_I),
  .DATA_O(ULPI_DATA_O),
  .DATA_E(ULPI_DATA_E),
  .DIR(ULPI_DIR),
  .STP(ULPI_STP),
  .NXT(ULPI_NXT)
);

endmodule
