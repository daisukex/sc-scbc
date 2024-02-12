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
//  Module: ULPI Register Access Controller (sc_scbc_urc)
//-----------------------------------------------------------------------------

module sc_ulpi_urc
  import sc_ulpi_pkg::*;
  import sc_usb_pkg::*;
(
  // System Interface
  input ULPICLK,
  input ULPIRSTB,

  // Port Controller Interface
  input UPSI_REQ,
  output logic UPSI_ACK,
  input UPSI_TYPE,
  input [4:0] UPSI_STATE,
  input UPSI_CFG,

  // ULPI Register Low Level Access Interface
  input ULLA_REQ,
  output logic ULLA_ACK,
  input ULLA_WR0RD1,
  input [7:0] ULLA_ADDR,
  input [7:0] ULLA_WRDATA,

  // ULPI Register Access Controller signal
  output [7:0] URC_DATA,

  // ULPI Register Inteface
  output logic REG_REQ,
  input REG_ACK,
  output [1:0] REG_CCD,
  output [5:0] REG_CPD,
  output [7:0] REG_EXT_ADDR,
  output [7:0] REG_TX_DATA,
  input [7:0] ULPI_DATA
);

typedef enum logic {
             portCfg = 0,
             portState
} portType_t;

// Write data of Port Control Register
otgControl_s otgControlData;
funcControl_s funcControlData;

usbConfig_t usbCfg;
assign usbCfg = usbConfig_t'(UPSI_CFG);

usbPortMode_e portMode;
assign portMode = usbPortMode_e'(UPSI_STATE);
assign otgControlData = '{otgContol.DpPulldown: ~usbCfg, otgContol.DmPulldown: ~usbCfg, default: 0};

// ULPI register address fot loe level access
ulpiRegMap_e ulpiRegAddr;
assign ulpiRegAddr = ulpiRegMap_e'(ULLA_ADDR[5:0]);

// ----
// ULPI Register Access State Machine
// --------------------------------------------------
/* There are two types of register access to ULPI:
 * - Register access for USB port control
 * - Free register access for debugging purposes
 * After writing a register for port control, a register read is
 * always performed to confirm that the value has been correctly
 * written to the ULPI device. Debug access is performed at the
 * direction of software. Therefore, the logic does not automatically
 * perform a read after a write access.
 */
typedef enum logic [2:0] {
             urcIdle = 0,  // Idle state
             urcRegWrite,  // Register write state
             urcRegRead,   // Register read state
             urcPortWrite, // Register write state for port control
             urcPortRead,  // Register read state for port control
             urcAckWait    // Register access complete waiting state
} urcState_t;
urcState_t urcState, returnState;
ulpiRegDataPack_s regData; // ULPI Register Access Data

typedef enum logic {portControl, lowLevel} execType_e;
execType_e execType;       // Execut type

always_ff @ (posedge ULPICLK or negedge ULPIRSTB) begin
  if (!ULPIRSTB) begin
    REG_REQ <= 1'b0;
    UPSI_ACK <= 1'b0;
    ULLA_ACK <= 1'b0;
    regData <= 0;
    urcState <= urcIdle;
  end
  else begin
    case (urcState)

      // Idle state
      // --------------------------------------------------
      urcIdle: begin
        UPSI_ACK <= 1'b0;
        ULLA_ACK <= 1'b0;

        // Port control access from port control state machine
        if (UPSI_REQ & !UPSI_ACK) begin
          execType <= portControl;
          if (UPSI_TYPE == portCfg)
            regData <= '{ccd: ccdRegWrite, cpd: otgControl,  ead: 8'h0, txd: otgControlData, rxd: 8'h0};
          else
            regData <= '{ccd: ccdRegWrite, cpd: funcControl, ead: 8'h0, txd: {3'b010, utmiXcvrSigs[portMode]}, rxd: 8'h0};
          REG_REQ <= 1'b1;
          urcState <= urcPortWrite;
        end

        // Low level access from port register
        else if (ULLA_REQ & !ULLA_ACK) begin
          execType <= lowLevel;
          if (ULLA_WR0RD1) begin
            regData <= '{ccd: ccdRegRead,  cpd: ulpiRegAddr, ead: 8'h0, txd: ULLA_WRDATA, rxd: 8'h0};
            urcState <= urcRegRead;
          end
          else begin
            regData <= '{ccd: ccdRegWrite, cpd: ulpiRegAddr, ead: 8'h0, txd: ULLA_WRDATA, rxd: 8'h0};
            urcState <= urcRegWrite;
          end
        end
      end

      // Register write state for port control state
      // --------------------------------------------------
      urcPortWrite: begin
        returnState <= urcPortRead;
        urcState <= urcAckWait;
        REG_REQ <= 1'b1;
      end

      // Register read state for port control
      // --------------------------------------------------
      urcPortRead: begin
        regData.ccd <= ccdRegRead;
        returnState <= urcIdle;
        urcState <= urcAckWait;
        REG_REQ <= 1'b1;
      end

      // Register write/read state
      // --------------------------------------------------
      urcRegWrite, urcRegRead: begin
        returnState <= urcIdle;
        urcState <= urcAckWait;
        REG_REQ <= 1'b1;
      end

      // Ack Wait State
      // --------------------------------------------------
      /*
       * The register access is complete when REG_ACK is asserted by
       * the ulpi controller. If the ULPI controller detects an abort
       * of register access, the ULPI controller will automatically
       * retry. And when the retry is complete, assert REG_ACK.
       */
      urcAckWait: begin
        if (REG_ACK) begin
          if (regData.ccd == ccdRegRead)
            regData.rxd <= ULPI_DATA;

          if (returnState == urcIdle) begin
            if (execType == portControl)
              UPSI_ACK <= 1'b1;
            else if (execType == lowLevel)
              ULLA_ACK <= 1'b1;
          end
          REG_REQ <= 1'b0;
          urcState <= returnState;
        end
      end

      default: begin
        REG_REQ <= 1'b0;
        urcState <= urcIdle;
      end
    endcase
  end
end

assign REG_CCD = regData.ccd;
assign REG_CPD = regData.cpd;
assign REG_TX_DATA = regData.txd;
assign URC_DATA = regData.rxd;

endmodule
