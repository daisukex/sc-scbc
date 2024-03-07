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
//  Module: USB Port State Machine (sc_scbc_ups)
//-----------------------------------------------------------------------------

module sc_scbc_ups
  import sc_ulpi_pkg::*;
(
  // ULPI clock and reset
  input ULPICLK,
  input ULPIRSTB,

  // USB Port Register signals
  input CFG_HOST,
  input CFG_DEVICE,
  input PRESET_REQ,

  // USB port control signals
  output logic UPSI_REQ,
  input UPSI_ACK,
  output logic UPSI_TYPE,
  output usbPortMode_e UPSI_STATE,
  output logic UPSI_CFG,
  input [7:0] URC_DATA,

  // USB port status signals
  output logic UPS_CONNECT,
  output logic UPS_RESET,
  output logic UPS_OPERATIONAL,
  output logic UPS_SUSPEND,

  // ULPI port event signal
  input [1:0] ULPI_CCS,

  // Frame Timing signal
  input FT_1MS
);


// ----
// USB IP Configuration
// --------------------------------------------------
typedef enum logic {
             hostMode = 0,
             deviceMode
} usbConfig_t;

typedef enum logic {
             portCfg = 0,
             portState
} portType_t;


usbConfig_t host0device1;
logic usbConfig;
always_ff @ (posedge ULPICLK) begin
  if (!ULPIRSTB)
    usbConfig <= 1'b0;
  else begin
    if (CFG_HOST ^ CFG_DEVICE)
      usbConfig <= 1'b1;
    else
      usbConfig <= 1'b0;
  end
end
assign host0device1 = (!CFG_HOST & CFG_DEVICE) ? deviceMode: hostMode;

// ----
// USB Port State Machine
// --------------------------------------------------
typedef enum logic [3:0] {
             portOff,
             portTrans,
             portUnconf,
             portDiscon,
             portConnect,
             portDisable,
             portReset,
             portOperation,
             portSuspend,
             portResume
} upsm_t;
upsm_t ptState, nextState;

logic disconEvent;
assign disconEvent = (ptState == portDisable |
                      ptState == portReset |
                      ptState == portOperation) & ~ULPI_CCS[0];
logic unconfEvent;
assign unconfEvent = (ptState == portDiscon |
                      ptState == portDisable |
                      ptState == portReset |
                      ptState == portOperation) & ~usbConfig;

logic [3:0] portCount;
always_ff @ (posedge ULPICLK) begin
  if (!ULPIRSTB) begin
    UPSI_REQ <= 1'b0;
    UPSI_TYPE <= 0;
    UPSI_STATE <= tristateDrivers;
    UPSI_CFG <= logic'(hostMode);
    portCount <= 0;
    UPS_CONNECT <= 1'b0;
    UPS_RESET <= 1'b0;
    UPS_OPERATIONAL <= 1'b0;
    UPS_SUSPEND <= 1'b0;
    nextState <= portOff;
    ptState <= portOff;
  end
  else begin

    // Enter Unconfig State
    if (unconfEvent) begin
      UPS_CONNECT <= 1'b0;
      UPS_RESET <= 1'b0;
      UPS_OPERATIONAL <= 1'b0;
      UPS_SUSPEND <= 1'b0;
      UPSI_REQ <= 1'b1;
      UPSI_TYPE <= portCfg;
      UPSI_CFG <= logic'(deviceMode);
      nextState <= portOff;
      ptState <= portTrans;
    end

    // Enter Disconnect
    else if (disconEvent) begin
      UPS_CONNECT <= 1'b0;
      UPS_RESET <= 1'b0;
      UPS_OPERATIONAL <= 1'b0;
      UPS_SUSPEND <= 1'b0;
      UPSI_REQ <= 1'b1;
      UPSI_TYPE <= portState;
      UPSI_STATE <= hostFs;
      nextState <= portDiscon;
      ptState <= portTrans;
    end

    // Reset State
    else if (ptState == portOff) begin
      UPSI_REQ <= 1'b1;
      UPSI_TYPE <= portState;
      UPSI_STATE <= tristateDrivers;
      nextState <= portUnconf;
      ptState <= portTrans;
    end

    // Unconfig State
    else if (ptState == portUnconf) begin
      if (UPSI_REQ & UPSI_ACK) begin
        UPSI_REQ <= 1'b1;
        UPSI_TYPE <= portState;
        if (CFG_HOST)
          UPSI_STATE <= hostFs;
        nextState <= portDiscon;
        ptState <= portTrans;
      end
      else if (!UPSI_REQ & usbConfig) begin
        UPSI_REQ <= 1'b1;
        UPSI_TYPE <= portCfg;
        UPSI_CFG <= host0device1;
      end
    end

    // Disconnect State
    else if (ptState == portDiscon) begin
      if (ULPI_CCS[0]) begin
        UPS_CONNECT <= 1'b1;
        nextState <= portDisable;
        ptState <= portDisable;
      end
    end

    // Disable State
    else if (ptState == portDisable) begin
      if (PRESET_REQ) begin
        UPS_RESET <= 1'b1;
        portCount <= 0;
        UPSI_REQ <= 1'b1;
        UPSI_TYPE <= portState;
        UPSI_STATE <= hostChirp;
        nextState <= portReset;
        ptState <= portTrans;
      end
    end

    // Port Reset
    else if (ptState == portReset) begin
      if (portCount == 10 & FT_1MS) begin
        UPS_RESET <= 1'b0;
        UPS_OPERATIONAL <= 1'b1;
        UPSI_REQ <= 1'b1;
        UPSI_TYPE <= portState;
        UPSI_STATE <= hostFs;
        nextState <= portOperation;
        ptState <= portTrans;
      end
      else if (FT_1MS)
        portCount <= portCount + 1;
    end

    // Port Operational
    else if (ptState == portOperation) begin
      if (PRESET_REQ) begin
        UPS_RESET <= 1'b1;
        UPS_OPERATIONAL <= 1'b0;
        portCount <= 0;
        UPSI_REQ <= 1'b1;
        UPSI_TYPE <= portState;
        UPSI_STATE <= hostChirp;
        nextState <= portReset;
        ptState <= portTrans;
      end
    end

    // Port State Transfer state
    else if (ptState == portTrans) begin
      if (UPSI_REQ & UPSI_ACK) begin
        UPSI_REQ <= 1'b0;
        ptState <= nextState;
      end
    end

  end
end

endmodule
