`ifndef UART_REGS_MAP_VH
`define UART_REGS_MAP_VH

localparam [11:2] OFF_UARTDR    = 10'h000; // 0x000
localparam [11:2] OFF_UARTRSR   = 10'h001; // 0x004
localparam [11:2] OFF_UARTFR    = 10'h006; // 0x018
localparam [11:2] OFF_UARTIBRD  = 10'h009; // 0x024
localparam [11:2] OFF_UARTFBRD  = 10'h00A; // 0x028
localparam [11:2] OFF_UARTLCR_H = 10'h00B; // 0x02C
localparam [11:2] OFF_UARTCR    = 10'h00C; // 0x030
localparam [11:2] OFF_UARTIFLS  = 10'h00D; // 0x034
localparam [11:2] OFF_UARTIMSC  = 10'h00E; // 0x038
localparam [11:2] OFF_UARTRIS   = 10'h00F; // 0x03C
localparam [11:2] OFF_UARTMIS   = 10'h010; // 0x040
localparam [11:2] OFF_UARTICR   = 10'h011; // 0x044


// dùng các helper do TB export: apb_write, apb_read, CHECK_EQ

task run_bus_access_rw; 
  reg [15:0] r;
begin
  $display("\n[TC] BUS.Access R/W");
  apb_write(OFF_UARTCR, 16'h0001);
  apb_read (OFF_UARTCR, r); CHECK_EQ("UARTCR R/W", r, 16'h0001);

  apb_read (OFF_UARTFR, r);
  $display("[%0t] [INFO] UARTFR = 0x%04h", $time, r);
end
endtask
`endif
