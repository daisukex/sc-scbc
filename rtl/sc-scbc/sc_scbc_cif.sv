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
//  Module: CPU Interface (sc_scbc_cif)
//-----------------------------------------------------------------------------

module sc_scbc_cif # (
  parameter AXI_ID_WIDTH = 1,
  parameter AXI_ADDR_WIDTH = 32,
  parameter AXI_DATA_BYTE = 4
) (
  // System bus clock and reset
  input AXI_CLK,
  input AXI_RESETN,

  // AXI Interface
  input [AXI_ID_WIDTH-1:0] AXI_S_AWID,
  input [AXI_ADDR_WIDTH-1:0] AXI_S_AWADDR,
  input [7:0] AXI_S_AWLEN,
  input [2:0] AXI_S_AWSIZE,
  input [1:0] AXI_S_AWBURST,
  input AXI_S_AWLOCK,
  input [3:0] AXI_S_AWCACHE,
  input [2:0] AXI_S_AWPROT,
  input AXI_S_AWVALID,
  output logic AXI_S_AWREADY,
  input [(AXI_DATA_BYTE*8)-1:0] AXI_S_WDATA,
  input [AXI_DATA_BYTE-1:0] AXI_S_WSTRB,
  input AXI_S_WLAST,
  input AXI_S_WVALID,
  output AXI_S_WREADY,
  output logic [AXI_ID_WIDTH-1:0] AXI_S_BID,
  output logic [1:0] AXI_S_BRESP,
  output logic AXI_S_BVALID,
  input AXI_S_BREADY,
  input [AXI_ID_WIDTH-1:0] AXI_S_ARID,
  input [AXI_ADDR_WIDTH-1:0] AXI_S_ARADDR,
  input [7:0] AXI_S_ARLEN,
  input [2:0] AXI_S_ARSIZE,
  input [1:0] AXI_S_ARBURST,
  input AXI_S_ARLOCK,
  input [3:0] AXI_S_ARCACHE,
  input [2:0] AXI_S_ARPROT,
  input AXI_S_ARVALID,
  output logic AXI_S_ARREADY,
  output [AXI_ID_WIDTH-1:0] AXI_S_RID,
  output logic [(AXI_DATA_BYTE*8)-1:0] AXI_S_RDATA,
  output logic [1:0] AXI_S_RRESP,
  output logic AXI_S_RLAST,
  output logic AXI_S_RVALID,
  input AXI_S_RREADY,

  // ULPI clock and reset
  input ULPICLK,
  input ULPIRSTB,

  // Register interface
  output SYS_WENB,
  output ULPI_WENB,
  output [AXI_ADDR_WIDTH-1:0] WADR,
  output [31:0] WDAT,
  output [3:0] WENB,
  output SYS_RENB,
  output ULPI_RENB,
  output [AXI_ADDR_WIDTH-1:0] RADR,
  input [31:0] GSR_RDAT,
  input [31:0] UPC_RDAT,
  input [31:0] FTC_RDAT
);


sc_regbus_if regBus();
logic [31:0] REG_WADR;
logic [9:0] REG_WTYP;
logic [3:0] REG_WENB;
logic [31:0] REG_WDAT;
logic REG_WWAT;
logic REG_WERR;
logic [31:0] REG_RADR;
logic [9:0] REG_RTYP;
logic REG_RENB;
logic [31:0] REG_RDAT;
logic REG_RWAT;
logic REG_RERR;
assign regBus.WADR = REG_WADR;
assign regBus.WTYP = REG_WTYP;
assign regBus.WENB = REG_WENB;
assign regBus.WDAT = REG_WDAT;
assign REG_WWAT = regBus.WWAT;
assign REG_WERR = regBus.WERR;
assign regBus.RADR = REG_RADR;
assign regBus.RTYP = REG_RTYP;
assign regBus.RENB = REG_RENB;
assign REG_RDAT = regBus.RDAT;
assign REG_RWAT = regBus.RWAT;
assign REG_RERR = regBus.RERR;

logic SAS_ASYNC_WENB;
logic SSS_ASYNC_WCOMP;
logic SAS_ASYNC_RENB;
logic SSS_ASYNC_RCOMP;

// ----
// AXI IP Slave controller
// --------------------------------------------------
sc_axiip_slave # (
  .AXI_ID_WIDTH(AXI_ID_WIDTH),
  .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
  .AXI_DATA_BYTE(AXI_DATA_BYTE)
) axis (
  // AXI bus clock and reset
  .AXI_CLK(AXI_CLK),
  .AXI_RESETN(AXI_RESETN),

  // AXI Slave interface
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

  // Register interface
  .REG_WADR(REG_WADR),
  .REG_WTYP(REG_WTYP),
  .REG_WENB(REG_WENB),
  .REG_WDAT(REG_WDAT),
  .REG_WWAT(REG_WWAT),
  .REG_WERR(REG_WERR),

  .REG_RADR(REG_RADR),
  .REG_RTYP(REG_RTYP),
  .REG_RENB(REG_RENB),
  .REG_RDAT(REG_RDAT),
  .REG_RWAT(REG_RWAT),
  .REG_RERR(REG_RERR)
);

// ----
// Slave Access Selector
// --------------------------------------------------
sc_scbc_sas # (
  .ADDR_WIDTH(AXI_ADDR_WIDTH)
) sas (
  // System bus clock and reset
  .SYSCLK(AXI_CLK),
  .SYSRSTB(AXI_RESETN),

  // Register interface
  .REGBUS(regBus),

  // Register interface data and control
  .SYNC_WENB(SYS_WENB),
  .ASYNC_WENB(SAS_ASYNC_WENB),
  .ASYNC_WCOMP(SSS_ASYNC_WCOMP),
  .WADR(WADR),
  .WDAT(WDAT),
  .WENB(WENB),
  .SYNC_RENB(SYS_RENB),
  .ASYNC_RENB(SAS_ASYNC_RENB),
  .ASYNC_RCOMP(SSS_ASYNC_RCOMP),
  .RADR(RADR),
  .GSR_RDAT(GSR_RDAT),
  .UPC_RDAT(UPC_RDAT),
  .FTC_RDAT(FTC_RDAT)
);

// ----
// Slave Signal Synchronizer
// --------------------------------------------------
sc_scbc_sss sss (
  // System bus clock and reset
  .SYSCLK(AXI_CLK),
  .SYSRSTB(AXI_RESETN),

  // ULPI clock and reset
  .ULPICLK(ULPICLK),
  .ULPIRSTB(ULPIRSTB),

  // Register interface asynchronous handshake
  .SYS_WENB(SAS_ASYNC_WENB),
  .SYS_WCOMP(SSS_ASYNC_WCOMP),
  .SYS_RENB(SAS_ASYNC_RENB),
  .SYS_RCOMP(SSS_ASYNC_RCOMP),

  // Register interface write and read enable
  .ULPI_WENB(ULPI_WENB),
  .ULPI_RENB(ULPI_RENB)
);

endmodule
