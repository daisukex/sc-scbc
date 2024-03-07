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
//  Module: Slave Access Selector (sc_scbc_sas)
//-----------------------------------------------------------------------------

module sc_scbc_sas
  import sc_scbc_reg_pkg::*;
# (
  ADDR_WIDTH = 32
) (
  // System bus clock and reset
  input SYSCLK,
  input SYSRSTB,

  // Register interface
  sc_regbus_if.regif REGBUS,

  // Register interface data and control
  output SYNC_WENB,
  output ASYNC_WENB,
  input ASYNC_WCOMP,
  output [ADDR_WIDTH-1:0] WADR,
  output [31:0] WDAT,
  output [3:0] WENB,
  output SYNC_RENB,
  output ASYNC_RENB,
  input ASYNC_RCOMP,
  output [ADDR_WIDTH-1:0] RADR,
  input [31:0] GSR_RDAT,
  input [31:0] UPC_RDAT,
  input [31:0] FTC_RDAT
);

// ----
// Write Channel
// --------------------------------------------------
logic hitAsyncWrite, hitSyncWrite;
assign hitSyncWrite = ~isAsyncReg(RegAdvancedParam[`regNum(REGBUS.WADR)]) & |REGBUS.WENB;
assign hitAsyncWrite = isAsyncReg(RegAdvancedParam[`regNum(REGBUS.WADR)]) & |REGBUS.WENB;
logic isAsyncWriteCycle;
logic [ADDR_WIDTH-1:0] latchWadr;
logic [3:0]  latchWenb;
logic [31:0] latchWdat;

always @ (posedge SYSCLK) begin
  if (!SYSRSTB) begin
    isAsyncWriteCycle <= 1'b0;
    latchWdat <= 32'h0000_0000;
  end
  else if (isAsyncWriteCycle & ASYNC_WCOMP)
    isAsyncWriteCycle <= 1'b0;
  else if (hitAsyncWrite & !isAsyncWriteCycle) begin
    isAsyncWriteCycle <= 1'b1;
    latchWenb <= REGBUS.WENB;
    latchWadr <= REGBUS.WADR;
    latchWdat <= REGBUS.WDAT;
  end
end

assign SYNC_WENB  = hitSyncWrite  & ~isAsyncWriteCycle;
assign ASYNC_WENB = hitAsyncWrite & ~isAsyncWriteCycle;
assign WADR = (isAsyncWriteCycle) ? latchWadr: REGBUS.WADR;
assign WDAT = (isAsyncWriteCycle) ? latchWdat: REGBUS.WDAT;
assign WENB = (isAsyncWriteCycle) ? latchWenb: REGBUS.WENB;
assign REGBUS.WWAT = (hitSyncWrite | hitAsyncWrite) & isAsyncWriteCycle;
assign REGBUS.WERR = 1'b0;

// ----
// Read Channel
// --------------------------------------------------
logic hitSyncRead, hitAsyncRead;
assign hitSyncRead = ~isAsyncReg(RegAdvancedParam[`regNum(REGBUS.RADR)]) & REGBUS.RENB;
assign hitAsyncRead = isAsyncReg(RegAdvancedParam[`regNum(REGBUS.RADR)]) & REGBUS.RENB;
logic isReadCycle, isSyncReadCycle, isAsyncReadCycle;
assign isReadCycle = (isSyncReadCycle | isAsyncReadCycle);
logic [ADDR_WIDTH-1:0] latchRadr;
RegRoot_t readSelect;

always @ (posedge SYSCLK) begin
  if (!SYSRSTB) begin
    isSyncReadCycle <= 1'b0;
    isAsyncReadCycle <= 1'b0;
    latchRadr <= 0;
  end
  else begin
    isSyncReadCycle <= 1'b0;
    if (isAsyncReadCycle & ASYNC_RCOMP)
      isAsyncReadCycle <= 1'b0;
    else if (!isReadCycle) begin
      if (hitAsyncRead) begin
        isAsyncReadCycle <= 1'b1;
        latchRadr <= REGBUS.RADR;
      end
      else if (hitSyncRead)
        isSyncReadCycle <= 1'b1;
    end
  end
end

assign SYNC_RENB  = hitSyncRead  & ~isReadCycle;
assign ASYNC_RENB = hitAsyncRead & ~isReadCycle;
assign RADR = (isAsyncReadCycle) ? latchRadr: REGBUS.RADR;
assign REGBUS.RWAT = isAsyncReadCycle;
assign REGBUS.RERR = 1'b0;

always @ (posedge SYSCLK) begin
  if (!SYSRSTB)
    readSelect <= GSR;
  else if (REGBUS.RENB)
    readSelect <= RegRoot(RegAdvancedParam[`regNum(REGBUS.RADR)]);
end

always_comb begin
  case (readSelect)
        GSR: REGBUS.RDAT = GSR_RDAT;
        UPC: REGBUS.RDAT = UPC_RDAT;
        FTC: REGBUS.RDAT = FTC_RDAT;
    default: REGBUS.RDAT = GSR_RDAT;
  endcase
end

endmodule
