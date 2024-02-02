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
//  Module: ULPI Protocol Engine (sc_scbc_upe)
//-----------------------------------------------------------------------------

module sc_ulpi_upe import sc_ulpi_pkg::*; (
  // System Interface
  input ULPICLK,
  input ULPIRSTB,

  // Register Interface
  input REG_REQ,
  output logic REG_ACK,
  input [1:0] REG_CCD,
  input [5:0] REG_CPD,
  input [7:0] REG_EXT_ADDR,
  input [7:0] REG_TX_DATA,

  // Transmit Data Interface
  input TXD_REQ,
  output logic TXD_ACK,
  input [5:0] TXD_CPD,
  input TXD_VALID,
  output TXD_READY,
  input TXD_LAST,
  input [7:0] TXD_DATA,

  // Receive Data Interface
  output logic RXD_CMD_VALID,
  output logic RXD_DATA_VALID,
  output logic [7:0] ULPI_DATA,

  // ULPI Interface
  input [7:0] DATA_I,
  output logic [7:0] DATA_O,
  output DATA_E,
  input DIR,
  output logic STP,
  input NXT
);

// ----
// Internal signal declaration
// --------------------------------------------------
logic ulpiDIR_p;

typedef struct packed {               // Transmit buffer
  logic valid;
  logic last;
  logic [7:0] data;
} ulpiBuf_s;
ulpiBuf_s txBuffer [0:1];
logic txWP, txRP;                     // Transmit buffer write/read pointer
logic txDone;                         // Transmit Done
logic isRegExtend;                    // Extend register access flag

logic turnAround;                     // Turn Around State
assign turnAround = (DIR != ulpiDIR_p);

// ----
// ULPI State Machine
// --------------------------------------------------
typedef enum logic [2:0] {
             ulpiIdle      = 3'b000, // IDLE state
             ulpiTxData    = 3'b010, // Transmit data state
             ulpiRxData    = 3'b011, // Receive data state
             ulpiRegCmd    = 3'b100, // Transmit register command state
             ulpiRegWrData = 3'b101, // Transmit register data state
             ulpiRegRdData = 3'b111  // Receive register data state
} ulpiState_e;
ulpiState_e ulpiState;               // ULPI current state

always_ff @ (posedge ULPICLK or negedge ULPIRSTB) begin
  if (!ULPIRSTB) begin
    REG_ACK <= 1'b0;
    TXD_ACK <= 1'b0;
    RXD_CMD_VALID <= 1'b0;
    RXD_DATA_VALID <= 1'b0;
    ULPI_DATA <= 8'h00;
    txWP <= 0;
    txRP <= 0;
    txBuffer <= '{0, 0};
    txDone <= 1'b0;
    isRegExtend <= 1'b0;
    DATA_O <= 8'h00;
    STP <= 1'b0;
    ulpiDIR_p <= 1'b0;
    ulpiState <= ulpiIdle;
  end
  else begin
    /*
     * At the transition of the DIR signal, the ULPI data bus enters
     * the turnaround state. This occurs both at the rise and fall of
     * DIR.
     */
    ulpiDIR_p <= DIR;

    // Transmit buffer control (double buffer)
    //-----------------------------------------------
    if (TXD_VALID & TXD_READY) begin
      txBuffer[txWP].valid <= 1'b1;
      txBuffer[txWP].last <= TXD_LAST;
      txBuffer[txWP].data <= TXD_DATA;
      txWP <= ~txWP;
    end


    // ULPI state Control
    //-----------------------------------------------
    case (ulpiState)

      // Direction IDLE or Output (DIR = 0)
      // ---------------------------------------
      // IDLE UlpiState
      ulpiIdle: begin
        /*
         * Initialize:
         * This ulpiState machine does not have a completion ulpiState in case
         * ULPI transactions are consecutive. So we must always
         * initialize the signal when we return to the IDLE ulpiState. In
         * particular, it is important to initialize the STP, REG_ACK,
         * and TXD_ACK signals.
         */
        STP <= 1'b0;
        REG_ACK <= 0;
        TXD_ACK <= 0;

        // Data Receice from ULPI PHY
        if (DIR & turnAround)
          ulpiState <= ulpiRxData;

        /* 
         * USB receive in same cycle as register read data:
         * USB receive is delayed. ULPI spec Figure 25, 26
         */
        else if (DIR) begin
          ULPI_DATA <= DATA_I;
          RXD_CMD_VALID <= 1'b1;
          ulpiState <= ulpiRxData;
        end

        // Transmit data request
        else if (TXD_REQ & !TXD_ACK) begin
          DATA_O <= {ccdTransmit, TXD_CPD};
          ulpiState <= ulpiTxData;
        end

        // Register access request
        else if (REG_REQ & !REG_ACK) begin
          DATA_O <= {REG_CCD, REG_CPD};
          isRegExtend <= (REG_CPD == cpdExtend);
          ulpiState <= ulpiRegCmd;
        end
      end

      // Transmit data state
      ulpiTxData: begin
        if (NXT) begin
          // Send STP signal
          if (txDone) begin
            DATA_O <= 8'h00;
            STP <= 1'b1;
            TXD_ACK <= 1'b1;
            txDone <= 1'b0;
            ulpiState <= ulpiIdle;
          end

          // Send transmit data
          else begin
            DATA_O <= txBuffer[txRP].data;
            txDone <= txBuffer[txRP].last;
            txBuffer[txRP].valid <= 1'b0;
            txRP <= ~txRP;
          end
        end
      end

      // Transmit register command state
      ulpiRegCmd: begin
        /*
         * Register access aborted by USB Receive:
         * If USB receive during command transmit for register access,
         * it is aborted. When both NXT and DIR are asserted, the PHY
         * indicates RxActive.
         */
        if (DIR & NXT) begin // ULPI spec Figure 23, 31
          DATA_O <= 8'h00;
          ulpiState <= ulpiRxData;
        end
        else if (NXT) begin
          // Send Extended Address // ULPI spec Figure 29, 30
          if (isRegExtend) begin
            DATA_O <= REG_EXT_ADDR;
            isRegExtend <= 1'b0;
          end
          // Execute register write/read
          else begin
            // Register write
            if (REG_CCD == ccdRegWrite) begin
              DATA_O <= REG_TX_DATA;
              ulpiState <= ulpiRegWrData;
            end
            // Register read
            else if (REG_CCD == ccdRegRead) begin
              DATA_O <= 8'h00;
              ulpiState <= ulpiRegRdData;
            end
          end
        end
      end

      // Register Write Data UlpiState
      ulpiRegWrData: begin
        // Register write aborted by USB Receive:
        if (DIR & NXT) begin // ULPI spec Figure 24
          DATA_O <= 8'h00;
          ulpiState <= ulpiRxData;
        end

        // Complete register write
        else if (NXT) begin
          DATA_O <= 8'h00;
          STP <= 1'b1;
          REG_ACK <= 1;
          ulpiState <= ulpiIdle;
        end
      end

      // Direction: Input (DIR = 1)
      // ---------------------------------------
      // Receive data state
      ulpiRxData: begin
        RXD_CMD_VALID <= 1'b0;
        RXD_DATA_VALID <= 1'b0;
        if (DIR) begin
          ULPI_DATA <= DATA_I;
          // Receive command
          if (!NXT)
            RXD_CMD_VALID <= 1'b1;
          // Receive data
          else
            RXD_DATA_VALID <= 1'b1;
        end

        // Complete register read
        else begin
          DATA_O <= 8'h00;
          ulpiState <= ulpiIdle;
        end
      end

      // Receive register data state
      ulpiRegRdData: begin
        // Receive read data
        if (DIR & !turnAround) begin
          ULPI_DATA <= DATA_I;
          REG_ACK <= 1;
          DATA_O <= 8'h00;
          ulpiState <= ulpiIdle;
        end
      end
    endcase
  end
end
assign TXD_READY = ~(txBuffer[0].valid & txBuffer[1].valid);
assign DATA_E = ~DIR;

endmodule
