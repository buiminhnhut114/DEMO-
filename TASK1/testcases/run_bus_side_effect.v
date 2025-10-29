`ifndef RUN_BUS_SIDE_EFFECT_V
`define RUN_BUS_SIDE_EFFECT_V

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


task run_bus_side_effect; 
  reg [15:0] r;
begin
  $display("\n[TC] BUS.Side-effect path (DR/ECR/ICR)");
  apb_write(OFF_UARTDR,  16'h00AA);
  apb_write(OFF_UARTICR, 16'h0F80); // clear nhóm error/timeout nếu có
  apb_read (OFF_UARTRIS, r);
  $display("[%0t] [INFO] RIS after ICR clear = 0x%04h", $time, r);
end
endtask
`endif
