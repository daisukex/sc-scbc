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
//  AXI Bus IP
//  Module: AXI Slave Controller (sc_axiip_slave)
//-----------------------------------------------------------------------------

module sc_axiip_slave # (
  parameter AXI_ID_WIDTH = 1,
  parameter AXI_ADDR_WIDTH = 32,
  parameter AXI_DATA_BYTE = 4
) (
  // System Interface
  input AXI_CLK,
  input AXI_RESETN,

  // AXI Slave Interface
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

  // Register Interface
  output logic [AXI_ADDR_WIDTH-1:0] REG_WADR,
  output logic [9:0] REG_WTYP,
  output logic [AXI_DATA_BYTE-1:0] REG_WENB,
  output logic [(AXI_DATA_BYTE*8)-1:0] REG_WDAT,
  input REG_WWAT,
  input REG_WERR,

  output logic [AXI_ADDR_WIDTH-1:0] REG_RADR,
  output logic [9:0] REG_RTYP,
  output logic REG_RENB,
  input [(AXI_DATA_BYTE*8)-1:0] REG_RDAT,
  input REG_RWAT,
  input REG_RERR
);

typedef enum bit [1:0] {
             AXI_IDLE = 2'b00,
             AXI_DATA = 2'b01,
             AXI_LAST = 2'b10,
             AXI_RESP = 2'b11
} axi_st;

typedef enum bit [1:0] {
             AXI_B_FIXED = 2'b00,
             AXI_B_INCR  = 2'b01,
             AXI_B_WRAP  = 2'b10,
             AXI_B_RESV  = 2'b11
} axi_burst;

typedef struct packed {
  bit wp, rp;
  logic [1:0] valid;
  logic [1:0][AXI_DATA_BYTE*8-1:0] data;
  logic [1:0] last, err;
  logic [1:0][AXI_DATA_BYTE-1:0] wen;
} buf_s;

typedef struct packed {
  logic [AXI_ID_WIDTH-1:0] id;
  logic [AXI_ADDR_WIDTH-1:0] addr;
  logic [7:0] len;
  logic [2:0] size;
  logic [1:0] burst;
} axi_ach_s;

typedef struct packed {
  axi_st st;
  logic [7:0] count;
  logic [AXI_ADDR_WIDTH-1:0] addr;
} axi_ctrl_s;

localparam AXI_DATA_UNIT = (AXI_DATA_BYTE*8 ==  16) ? 1:
                           (AXI_DATA_BYTE*8 ==  32) ? 2:
                           (AXI_DATA_BYTE*8 ==  64) ? 3:
                           (AXI_DATA_BYTE*8 == 128) ? 4:
                           (AXI_DATA_BYTE*8 == 256) ? 5: 0;

// AXI Write Address/Data Channel
//-----------------------------------------------
axi_ctrl_s w_ctrl;
axi_ach_s w_adch;
buf_s w_buf;
wire w_buf_empty = ~(w_buf.valid[0] | w_buf.valid[1]);
wire w_buf_full  =   w_buf.valid[0] & w_buf.valid[1];

logic [AXI_ADDR_WIDTH-1:0] w_wb_mask;
assign w_wb_mask = {{AXI_ADDR_WIDTH-8{1'b1}}, ~w_adch.len} << w_adch.size;

always @ (posedge AXI_CLK) begin
  if (!AXI_RESETN) begin
    w_ctrl <= 0;
    w_adch <= 0;
    w_buf <= 0;
    AXI_S_AWREADY <= 1'b0;
    AXI_S_BID <= 0;
    AXI_S_BRESP <= 2'b00;
    AXI_S_BVALID <= 1'b0;
  end
  else begin

    // AXI Write Address Channel
    if (w_ctrl.st == AXI_IDLE & !AXI_S_AWREADY)
      AXI_S_AWREADY <= 1'b1;

    if (AXI_S_AWREADY & AXI_S_AWVALID) begin
      w_adch.id <= AXI_S_AWID;
      w_adch.addr <= AXI_S_AWADDR;
      w_adch.len <= AXI_S_AWLEN;
      w_adch.size <= AXI_S_AWSIZE;
      w_adch.burst <= AXI_S_AWBURST;
      w_ctrl.addr <= AXI_S_AWADDR;
      w_ctrl.st <= AXI_DATA;
      w_ctrl.count <= AXI_S_AWLEN;
      AXI_S_AWREADY <= 1'b0;
    end

    // AXI Write Data Channel
    if (AXI_S_WREADY & AXI_S_WVALID) begin
      w_buf.data[w_buf.wp] <= AXI_S_WDATA;
      w_buf.wen[w_buf.wp] <= AXI_S_WSTRB;
      w_buf.valid[w_buf.wp] <= 1'b1;
      w_buf.last[w_buf.wp] <= AXI_S_WLAST;
      if (AXI_S_WLAST)
        w_ctrl.st <= AXI_LAST;
      w_buf.wp <= ~w_buf.wp;
    end

    // AXI Write Responce Channel
    if (w_ctrl.st == AXI_RESP) begin
      AXI_S_BID <= w_adch.id;
      AXI_S_BRESP <= {1'b0, w_buf.err[0]};
      AXI_S_BVALID <= 1'b1;
      if (AXI_S_BVALID & AXI_S_BREADY) begin
        AXI_S_BID <= 0;
        AXI_S_BRESP <= 2'b00;
        AXI_S_BVALID <= 1'b0;
        w_buf.err[0] <= 1'b0;
        w_ctrl.st <= AXI_IDLE;
      end
    end

    // Register Interface
    if (~w_buf_empty & !REG_WWAT) begin
      w_buf.valid[w_buf.rp] <= 1'b0;
      w_buf.rp <= ~w_buf.rp;
      w_buf.err[0] <= REG_WERR;
      if (w_buf.last[w_buf.rp])
        w_ctrl.st <= AXI_RESP;
      else begin
        if (w_adch.burst == AXI_B_INCR)
          w_ctrl.addr <= w_ctrl.addr + (1 << w_adch.size);
        else if (w_adch.burst == AXI_B_WRAP) begin
          w_ctrl.addr <= ( w_wb_mask & w_adch.addr) |
                         (~w_wb_mask & (w_ctrl.addr + (1 << w_adch.size)));
        end
      end
    end
    if (!REG_WWAT & |REG_WENB) begin
      if (w_ctrl.count != 0)
        w_ctrl.count <= w_ctrl.count - 1;
    end
  end
end
assign AXI_S_WREADY = (w_ctrl.st == AXI_DATA) & ~w_buf_full;
assign REG_WADR = {w_ctrl.addr[AXI_ADDR_WIDTH-1:AXI_DATA_UNIT], {AXI_DATA_UNIT{1'b0}}};
assign REG_WTYP = (w_ctrl.count == 0) ? 0: {w_adch.burst, w_ctrl.count};
assign REG_WENB = (~w_buf_empty) ? w_buf.wen[w_buf.rp]: 0;
assign REG_WDAT = w_buf.data[w_buf.rp];

// AXI Read Address/Data Channel
//-----------------------------------------------
axi_ctrl_s r_ctrl;
axi_ach_s r_adch;
buf_s r_buf;
typedef struct packed {
  logic pt;
  logic [1:0] valid;
  logic [1:0] last;
} r_req_s;
r_req_s r_req;
wire r_buf_empty = ~(r_buf.valid[0] | r_buf.valid[1]);
wire r_buf_full  =   r_buf.valid[0] & r_buf.valid[1];
wire r_req_empty = ~(r_req.valid[0] | r_req.valid[1]);
wire r_req_full  =   r_req.valid[0] & r_req.valid[1];

logic [AXI_ADDR_WIDTH-1:0] r_wb_mask;
assign r_wb_mask = {{AXI_ADDR_WIDTH-8{1'b1}}, ~r_adch.len} << r_adch.size;

always @ (posedge AXI_CLK) begin
  if (!AXI_RESETN) begin
    r_ctrl <= 0;
    r_adch <= 0;
    r_buf <= 0;
    r_req <= 0;
    REG_RENB <= 1'b0;
    AXI_S_RVALID <= 1'b0;
    AXI_S_RDATA <= 0;
    AXI_S_RRESP <= 2'b00;
    AXI_S_RLAST <= 1'b0;
    AXI_S_ARREADY <= 1'b0;
  end
  else begin

    // AXI Read Address Channel
    if (r_ctrl.st == AXI_IDLE & !AXI_S_ARREADY)
      AXI_S_ARREADY <= 1'b1;

    if (AXI_S_ARVALID & AXI_S_ARREADY) begin
      r_adch.id <= AXI_S_ARID;
      r_adch.addr <= AXI_S_ARADDR;
      r_adch.len <= AXI_S_ARLEN;
      r_adch.size <= AXI_S_ARSIZE;
      r_adch.burst <= AXI_S_ARBURST;
      r_ctrl.addr <= AXI_S_ARADDR;
      r_ctrl.count <= AXI_S_ARLEN;
      AXI_S_ARREADY <= 1'b0;
      r_ctrl.st <= AXI_DATA;
    end

    // AXI Read Data Channel
    if (AXI_S_RVALID & AXI_S_RREADY) begin
      r_buf.valid[r_buf.rp] <= 1'b0;
      r_buf.rp <= ~r_buf.rp;
      AXI_S_RVALID <= 1'b0;
      if (AXI_S_RLAST) begin
        r_adch.id <= 0;
        AXI_S_RRESP <= 2'b00;
        AXI_S_RLAST <= 1'b0;
        r_ctrl.st <= AXI_IDLE;
      end
      if (r_buf_full) begin
        AXI_S_RVALID <= 1'b1;
        AXI_S_RDATA <= r_buf.data[~r_buf.rp];
        AXI_S_RLAST <= r_buf.last[~r_buf.rp];
        AXI_S_RRESP <= {r_buf.err[~r_buf.rp], 1'b0};
      end
    end
    else if (~r_buf_empty) begin
      AXI_S_RVALID <= 1'b1;
      AXI_S_RDATA <= r_buf.data[r_buf.rp];
      AXI_S_RLAST <= r_buf.last[r_buf.rp];
      AXI_S_RRESP <= {r_buf.err[r_buf.rp], 1'b0};
    end

    // Register Interface
    if (!r_req_empty & !REG_RWAT) begin
      r_req.valid[r_buf.wp] <= 1'b0;
      r_buf.data[r_buf.wp] <= REG_RDAT;
      r_buf.last[r_buf.wp] <= r_req.last[r_buf.wp];
      r_buf.err[r_buf.wp] <= REG_RERR;
      r_buf.valid[r_buf.wp] <= 1'b1;
      r_buf.wp <= ~r_buf.wp;
    end

    if (r_ctrl.st == AXI_IDLE) begin
      if (AXI_S_ARVALID & AXI_S_ARREADY)
        REG_RENB <= 1'b1;
    end
    else if (r_ctrl.st == AXI_DATA) begin
      if (REG_RENB & !REG_RWAT) begin
        r_req.valid[r_req.pt] <= 1'b1;
        r_req.pt <= ~r_req.pt;
        r_req.last[r_req.pt] <= (r_ctrl.count == 0);
        if (r_ctrl.count == 0)
          r_ctrl.st <= AXI_LAST;
      end

      if (!REG_RWAT) begin
        if ((~REG_RENB & ~r_req.valid[r_req.pt] & ~r_buf.valid[r_req.pt]) |
            ( REG_RENB & ~r_req.valid[~r_req.pt] & ~r_buf.valid[~r_req.pt])) begin
          if (r_ctrl.count == 0) begin
            REG_RENB <= 1'b0;
          end
          else begin
            REG_RENB <= 1'b1;
            r_ctrl.count <= r_ctrl.count - 1;
            if (r_adch.burst == AXI_B_INCR)
              r_ctrl.addr <= r_ctrl.addr + (1 << r_adch.size);
            else if (r_adch.burst == AXI_B_WRAP) begin
              r_ctrl.addr <= ( r_wb_mask & r_adch.addr) |
                             (~r_wb_mask & (r_ctrl.addr + (1 << r_adch.size)));
            end
          end
        end
        else
          REG_RENB <= 1'b0;
      end
    end
  end
end
assign AXI_S_RID = r_adch.id;
assign REG_RADR = {r_ctrl.addr[AXI_ADDR_WIDTH-1:AXI_DATA_UNIT], {AXI_DATA_UNIT{1'b0}}};
assign REG_RTYP = (r_ctrl.count == 0) ? 0: {r_adch.burst, r_ctrl.count};

endmodule
