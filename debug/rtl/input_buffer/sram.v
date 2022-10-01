`include "define.v"
module sram #(
    parameter AW = 10 ,
    parameter DW = 128
) (
    input           SYS_CLK ,
    input           SYS_NRST,

    input  [2   :0] CEN   ,
    input  [2   :0] WEN   ,

    input  [AW-1:0] A0    ,
    input  [AW-1:0] A1    ,
    input  [AW-1:0] A2    ,
    input  [DW-1:0] DIN0  ,
    input  [DW-1:0] DIN1  ,
    input  [DW-1:0] DIN2  ,

    output [DW-1:0] DOUT0 ,
    output [DW-1:0] DOUT1 ,
    output [DW-1:0] DOUT2   
    
);
    
    //===========================================
    // description: sram
    
    `ifdef SIM
        sram_sim U_sram0_sim (
            .clk    (SYS_CLK),
            .addr   (A0),
            .din    (DIN0),
            .ce     (CEN[0]),
            .we     (WEN[0]),
            .dout   (DOUT0)
        );
    
        sram_sim U_sram1_sim (
            .clk    (SYS_CLK),
            .addr   (A1),
            .din    (DIN1),
            .ce     (CEN[1]),
            .we     (WEN[1]),
            .dout   (DOUT1)
        );
    
        sram_sim U_sram2_sim (
            .clk    (SYS_CLK),
            .addr   (A2),
            .din    (DIN2),
            .ce     (CEN[2]),
            .we     (WEN[2]),
            .dout   (DOUT2)
        );
       
    `else 
         //bank0
        sram_1024_32 U_sram00_1024_32 (
            .Q      (DOUT0[32*4-1 :32*3]    ),//out 32 bit
            .CLK    (SYS_CLK                ),
            .CEN    (!CEN[0]                ),//when 1 disable in, when 0 eable in
            .WEN    (!WEN[0]                ),//when 1 read data , when 0 write data
            .A      (A0                     ),//addr input 10bit
            .D      (DIN0 [32*4-1 :32*3]    )//data in 32bit
        );
        sram_1024_32 U_sram01_1024_32 (
            .Q      (DOUT0[32*3-1 :32*2]    ),//out 32 bit
            .CLK    (SYS_CLK                ),
            .CEN    (!CEN[0]                ),//when 1 disable in, when 0 eable in
            .WEN    (!WEN[0]                ),//when 1 read data , when 0 write data
            .A      (A0                     ),//addr input 10bit
            .D      (DIN0 [32*3-1 :32*2]    )//data in 32bit
        );
        sram_1024_32 U_sram02_1024_32 (
            .Q      (DOUT0[32*2-1 :32*1]    ),//out 32 bit
            .CLK    (SYS_CLK                ),
            .CEN    (!CEN[0]                ),//when 1 disable in, when 0 eable in
            .WEN    (!WEN[0]                ),//when 1 read data , when 0 write data
            .A      (A0                     ),//addr input 10bit
            .D      (DIN0 [32*2-1 :32*1]    )//data in 32bit
        );
        sram_1024_32 U_sram03_1024_32 (
            .Q      (DOUT0[32*1-1 :0   ]    ),//out 32 bit
            .CLK    (SYS_CLK                ),
            .CEN    (!CEN[0]                ),//when 1 disable in, when 0 eable in
            .WEN    (!WEN[0]                ),//when 1 read data , when 0 write data
            .A      (A0                     ),//addr input 10bit
            .D      (DIN0 [32*1-1 :0   ]    )//data in 32bit
        );
    
        //bank1
        sram_1024_32 U_sram10_1024_32 (
            .Q      (DOUT1[32*4-1 :32*3]    ),//out 32 bit
            .CLK    (SYS_CLK                ),
            .CEN    (!CEN[1]                ),//when 1 disable in, when 0 eable in
            .WEN    (!WEN[1]                ),//when 1 read data , when 0 write data
            .A      (A1                     ),//addr input 10bit
            .D      (DIN1 [32*4-1 :32*3]    )//data in 32bit
        );
        sram_1024_32 U_sram11_1024_32 (
            .Q      (DOUT1[32*3-1 :32*2]    ),//out 32 bit
            .CLK    (SYS_CLK                ),
            .CEN    (!CEN[1]                ),//when 1 disable in, when 0 eable in
            .WEN    (!WEN[1]                ),//when 1 read data , when 0 write data
            .A      (A1                     ),//addr input 10bit
            .D      (DIN1 [32*3-1 :32*2]    )//data in 32bit
        );
        sram_1024_32 U_sram12_1024_32 (
            .Q      (DOUT1[32*2-1 :32*1]    ),//out 32 bit
            .CLK    (SYS_CLK                ),
            .CEN    (!CEN[1]                ),//when 1 disable in, when 0 eable in
            .WEN    (!WEN[1]                ),//when 1 read data , when 0 write data
            .A      (A1                     ),//addr input 10bit
            .D      (DIN1 [32*2-1 :32*1]    )//data in 32bit
        );
        sram_1024_32 U_sram13_1024_32 (
            .Q      (DOUT1[32*1-1 :0   ]    ),//out 32 bit
            .CLK    (SYS_CLK                ),
            .CEN    (!CEN[1]                ),//when 1 disable in, when 0 eable in
            .WEN    (!WEN[1]                ),//when 1 read data , when 0 write data
            .A      (A1                     ),//addr input 10bit
            .D      (DIN1 [32*1-1 :0   ]    )//data in 32bit
        );
    
        //bank2
        sram_1024_32 U_sram20_1024_32 (
            .Q      (DOUT2[32*4-1 :32*3]    ),//out 32 bit
            .CLK    (SYS_CLK                ),
            .CEN    (!CEN[2]                ),//when 1 disable in, when 0 eable in
            .WEN    (!WEN[2]                ),//when 1 read data , when 0 write data
            .A      (A2                     ),//addr input 10bit
            .D      (DIN2 [32*4-1 :32*3]    )//data in 32bit
        );
        sram_1024_32 U_sram21_1024_32 (
            .Q      (DOUT2[32*3-1 :32*2]    ),//out 32 bit
            .CLK    (SYS_CLK                ),
            .CEN    (!CEN[2]                ),//when 1 disable in, when 0 eable in
            .WEN    (!WEN[2]                ),//when 1 read data , when 0 write data
            .A      (A2                     ),//addr input 10bit
            .D      (DIN2 [32*3-1 :32*2]    )//data in 32bit
        );
        sram_1024_32 U_sram22_1024_32 (
            .Q      (DOUT2[32*2-1 :32*1]    ),//out 32 bit
            .CLK    (SYS_CLK                ),
            .CEN    (!CEN[2]                ),//when 1 disable in, when 0 eable in
            .WEN    (!WEN[2]                ),//when 1 read data , when 0 write data
            .A      (A2                     ),//addr input 10bit
            .D      (DIN2 [32*2-1 :32*1]    )//data in 32bit
        );
        sram_1024_32 U_sram23_1024_32 (
            .Q      (DOUT2[32*1-1 :0   ]    ),//out 32 bit
            .CLK    (SYS_CLK                ),
            .CEN    (!CEN[2]                ),//when 1 disable in, when 0 eable in
            .WEN    (!WEN[2]                ),//when 1 read data , when 0 write data
            .A      (A2                     ),//addr input 10bit
            .D      (DIN2 [32*1-1 :0   ]    )//data in 32bit
        );
    
    `endif 
    

endmodule

