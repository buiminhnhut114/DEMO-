`timescale 1ns/1ps
`default_nettype none


// =======================================================
module test_bench;

  // ---------------- Clocks & Resets ----------------
  reg PCLK, UARTCLK;
  initial begin PCLK=0;      forever #5  PCLK=~PCLK;   end   // 100 MHz
  initial begin UARTCLK=0;   forever #7  UARTCLK=~UARTCLK; end

  reg         PRESETn;
  reg         nUARTRST;

  // ---------------- APB ----------------
  reg         PSEL, PENABLE, PWRITE;
  reg  [11:2] PADDR;        // word-aligned address
  reg  [15:0] PWDATA;
  wire [15:0] PRDATA;

  // ---------------- On-chip / Pads ----------------
  reg  nUARTCTS, nUARTDCD, nUARTDSR, nUARTRI;
  reg  UARTRXD, SIRIN;
  reg  SCANENABLE, SCANINPCLK, SCANINUCLK;
  reg  UARTTXDMACLR, UARTRXDMACLR;

  wire UARTMSINTR, UARTRXINTR, UARTTXINTR, UARTRTINTR, UARTEINTR, UARTINTR;
  wire UARTTXD, nSIROUT, nUARTOut2, nUARTOut1, nUARTRTS, nUARTDTR;
  wire SCANOUTPCLK, SCANOUTUCLK;
  wire UARTTXDMASREQ, UARTTXDMABREQ, UARTRXDMASREQ, UARTRXDMABREQ;

  // ---------------- PASS/FAIL counters ----------------
  integer pass_cnt, fail_cnt;
  initial begin pass_cnt = 0; fail_cnt = 0; end

  // Small helpers for APB BFM
  task apb_reset;
  begin
    PSEL=0; PENABLE=0; PWRITE=0;
    PADDR={10{1'b0}}; PWDATA=16'h0;
  end endtask

  task apb_write(input [11:2] addr_w, input [15:0] wdata);
  begin
    @(posedge PCLK);
    PSEL<=1; PENABLE<=0; PWRITE<=1; PADDR<=addr_w; PWDATA<=wdata; // SETUP
    @(posedge PCLK); PENABLE<=1;                                     // ENABLE
    @(posedge PCLK); PSEL<=0; PENABLE<=0; PWRITE<=0;                 // END
  end endtask

  task apb_read(input [11:2] addr_w, output [15:0] rdata);
  begin
    @(posedge PCLK);
    PSEL<=1; PENABLE<=0; PWRITE<=0; PADDR<=addr_w;                    // SETUP
    @(posedge PCLK); PENABLE<=1;                                      // ENABLE
    @(posedge PCLK); rdata = PRDATA; PSEL<=0; PENABLE<=0;             // END
  end endtask

  // PASS/FAIL report macros
  task CHECK_EQ(input [8*48-1:0] tag, input [15:0] act, input [15:0] exp);
  begin
    if (act !== exp) begin
      $display("[%0t] [FAIL] %0s exp=0x%04h act=0x%04h", $time, tag, exp, act);
      fail_cnt = fail_cnt + 1;
    end else begin
      $display("[%0t] [PASS] %0s = 0x%04h", $time, tag, act);
      pass_cnt = pass_cnt + 1;
    end
  end endtask

  // ---------------- Global reset & defaults ----------------
  initial begin
    PRESETn=0; nUARTRST=0;
    nUARTCTS=1; nUARTDCD=1; nUARTDSR=1; nUARTRI=1;
    UARTRXD=1; SIRIN=1;
    SCANENABLE=0; SCANINPCLK=0; SCANINUCLK=0;
    UARTTXDMACLR=0; UARTRXDMACLR=0;
    apb_reset();
    repeat(8) @(posedge PCLK);
    PRESETn=1;
    repeat(4) @(posedge UARTCLK);
    nUARTRST=1;
  end

  // =====================================================================
  // >>>>>>>>>>>>>>>>>>>>>>>>>  D U M M Y   M O D E L  <<<<<<<<<<<<<<<<<<<
  //  DUMMY CHỈ Ở TRONG TESTBENCH — để mô phỏng mà KHÔNG CẦN RTL
  //  Khi chạy RTL thật (Uart.v): compile với +define+USE_RTL
  //  => Khối dưới đây sẽ bị disable tự động.
  // =====================================================================
`ifndef USE_RTL
  // --------- Dummy register map (tối thiểu để test BUS) ----------
  // Offsets (word address)
  localparam [9:0] A_UARTDR    = 10'h000; // 0x000
  localparam [9:0] A_UARTRSR   = 10'h001; // 0x004
  localparam [9:0] A_UARTFR    = 10'h006; // 0x018
  localparam [9:0] A_UARTIBRD  = 10'h009; // 0x024
  localparam [9:0] A_UARTFBRD  = 10'h00A; // 0x028
  localparam [9:0] A_UARTLCR_H = 10'h00B; // 0x02C
  localparam [9:0] A_UARTCR    = 10'h00C; // 0x030
  localparam [9:0] A_UARTIFLS  = 10'h00D; // 0x034
  localparam [9:0] A_UARTIMSC  = 10'h00E; // 0x038
  localparam [9:0] A_UARTRIS   = 10'h00F; // 0x03C
  localparam [9:0] A_UARTMIS   = 10'h010; // 0x040
  localparam [9:0] A_UARTICR   = 10'h011; // 0x044
  localparam [9:0] A_UARTDMACR = 10'h012; // 0x048

  // Minimal registers
  reg [15:0] r_DR, r_RSR, r_FR, r_IBRD, r_FBRD, r_LCR_H, r_CR, r_IFLS, r_IMSC, r_DMACR;
  reg [15:0] r_RIS, r_MIS;

  wire wr_en = PSEL & PENABLE & PWRITE;

  // Reset behavior
  always @(negedge PRESETn or negedge nUARTRST) begin
    if (!PRESETn || !nUARTRST) begin
      r_DR   <= 16'h0000;
      r_RSR  <= 16'h0000;
      // FR: TXFE=1, RXFE=1, BUSY=0 (đặt các bit tiêu biểu)
      r_FR   <= 16'b0000_1001_1000_0000;
      r_IBRD <= 16'h0000;
      r_FBRD <= 16'h0000;
      r_LCR_H<= 16'h0000;
      r_CR   <= 16'h0300;  // như spec: bit 9..8 = 1
      r_IFLS <= 16'h0012;  // reset trong spec
      r_IMSC <= 16'h0000;
      r_DMACR<= 16'h0000;
      r_RIS  <= 16'h0000;
      r_MIS  <= 16'h0000;
    end
  end

  // Writes
  always @(posedge PCLK) if (PRESETn && wr_en) begin
    case (PADDR)
      A_UARTDR    : r_DR      <= {8'h00, PWDATA[7:0]};
      A_UARTIBRD  : r_IBRD    <= PWDATA;
      A_UARTFBRD  : r_FBRD    <= PWDATA;
      A_UARTLCR_H : r_LCR_H   <= PWDATA;
      A_UARTCR    : r_CR      <= PWDATA;
      A_UARTIFLS  : r_IFLS    <= PWDATA;
      A_UARTIMSC  : r_IMSC    <= PWDATA;
      A_UARTICR   : begin
        // Clear bits: error & timeout vùng 10:7 và 6
        r_RIS[10:7] <= r_RIS[10:7] & ~PWDATA[10:7];
        r_RIS[6]    <= r_RIS[6]    & ~PWDATA[6];
        r_RSR[3:0]  <= r_RSR[3:0]  & ~PWDATA[3:0];
      end
      default: ;
    endcase
  end

  // Reads
  reg [15:0] pr;
  always @(*) begin
    pr = 16'h0000;
    case (PADDR)
      A_UARTDR    : pr = r_DR;
      A_UARTRSR   : pr = r_RSR;
      A_UARTFR    : pr = r_FR;
      A_UARTIBRD  : pr = r_IBRD;
      A_UARTFBRD  : pr = r_FBRD;
      A_UARTLCR_H : pr = r_LCR_H;
      A_UARTCR    : pr = r_CR;
      A_UARTIFLS  : pr = r_IFLS;
      A_UARTRIS   : pr = r_RIS;
      A_UARTMIS   : pr = r_MIS;
      A_UARTDMACR : pr = r_DMACR;
      default     : pr = 16'h0000;
    endcase
  end
  assign PRDATA = pr;

  // MIS/Interrupts (giản lược)
  always @(*) r_MIS = r_RIS & r_IMSC;
  assign UARTMSINTR   = |r_MIS[3:0];
  assign UARTRXINTR   =  r_MIS[4];
  assign UARTTXINTR   =  r_MIS[5];
  assign UARTRTINTR   =  r_MIS[6];
  assign UARTEINTR    = |r_MIS[10:7];
  assign UARTINTR     = |r_MIS[10:0];

  // Tie-off outputs cho dummy
  assign UARTTXD=1'b1; assign nSIROUT=1'b1;
  assign nUARTOut1=1'b1; assign nUARTOut2=1'b1;
  assign nUARTRTS=1'b1;  assign nUARTDTR=1'b1;
  assign SCANOUTPCLK=1'b0; assign SCANOUTUCLK=1'b0;
  assign UARTTXDMASREQ=1'b0; assign UARTTXDMABREQ=1'b0;
  assign UARTRXDMASREQ=1'b0; assign UARTRXDMABREQ=1'b0;

`else
  // =================================================================
  // >>>>>>>>>>>>>>>>>>>>>>>>>  R T L   T H Ậ T  <<<<<<<<<<<<<<<<<<<<<<
  //  Khi build với RTL thật:
  //    vlog +define+USE_RTL tb_uart_apb_top.v Uart.v
  //  Dưới đây là DUT đã gán tên module top là "Uart" (uut).
  // =================================================================
  Uart uut (
    .PCLK(PCLK), .UARTCLK(UARTCLK),
    .PRESETn(PRESETn), .nUARTRST(nUARTRST),
    .PSEL(PSEL), .PENABLE(PENABLE), .PWRITE(PWRITE),
    .PADDR(PADDR), .PWDATA(PWDATA), .PRDATA(PRDATA),

    .nUARTCTS(nUARTCTS), .nUARTDCD(nUARTDCD), .nUARTDSR(nUARTDSR), .nUARTRI(nUARTRI),
    .UARTRXD(UARTRXD), .SIRIN(SIRIN),

    .SCANENABLE(SCANENABLE), .SCANINPCLK(SCANINPCLK), .SCANINUCLK(SCANINUCLK),

    .UARTTXDMACLR(UARTTXDMACLR), .UARTRXDMACLR(UARTRXDMACLR),

    .UARTMSINTR(UARTMSINTR), .UARTRXINTR(UARTRXINTR), .UARTTXINTR(UARTTXINTR),
    .UARTRTINTR(UARTRTINTR), .UARTEINTR(UARTEINTR), .UARTINTR(UARTINTR),

    .UARTTXD(UARTTXD), .nSIROUT(nSIROUT), .nUARTOut2(nUARTOut2), .nUARTOut1(nUARTOut1),
    .nUARTRTS(nUARTRTS), .nUARTDTR(nUARTDTR),

    .SCANOUTPCLK(SCANOUTPCLK), .SCANOUTUCLK(SCANOUTUCLK),

    .UARTTXDMASREQ(UARTTXDMASREQ), .UARTTXDMABREQ(UARTTXDMABREQ),
    .UARTRXDMASREQ(UARTRXDMASREQ), .UARTRXDMABREQ(UARTRXDMABREQ)
  );
`endif
  // ======================== KẾT THÚC PHẦN DUMMY/RTL =====================

  // ---------------- Run tests & Summary ----------------
  initial begin
    run_test();   // (định nghĩa trong run_test.v)
    $display("\n==================== SUMMARY ====================");
    $display("PASS = %0d, FAIL = %0d", pass_cnt, fail_cnt);
    $display("=================================================\n");
    if (fail_cnt != 0) $fatal(1, "Some tests FAILED");
    $finish;
  end

  `include "run_test.v"

endmodule
`default_nettype wire