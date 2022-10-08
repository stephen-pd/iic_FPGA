
//*******************************************************************************************************
//**                                         Verilog Model                                             **
//**                                                                                                   **
//**                                      ALL RIGHTS RESERVED                                          **
//*******************************************************************************************************
`timescale 1ns/1ps
`celldefine
//*******************************************************************************************************
//XMC55_SP_RF:v1.0
//
//Instance Name:  sram_1024_32
//Word Depth:     1024
//Word Width:     32
//ColMux:         4
//Bit Write:      off
//Test Mode:      off
//Created Data:   9-6-2022 19:11
//*******************************************************************************************************
//If POWER_PINS is defined, it selects the module w/ power & ground ports
`ifdef POWER_PINS 
module sram_1024_32 ( Q, CLK, CEN, WEN, 
			  VDD, VSS, 
			  A,  D); 
`else 
module sram_1024_32 ( Q, CLK, CEN, WEN, 
			  A, D); 
`endif 
 
parameter     Bits = 32; 
parameter     Word_Depth = 1024; 
parameter     Add_Width = 10; 
parameter     Wen_Width = 32; 
parameter     Word_Pt = 1; 
parameter     TM_Width = 10; 
 
`ifdef POWER_PINS 
inout		      VDD;
inout		      VSS;
`endif 

output [Bits-1:0]     Q;
input		      CLK;
input		      CEN;
input		      WEN;


input [Add_Width-1:0] A;
input [Bits-1:0]      D;

reg [Bits-1:0]        Q_int;

reg [Bits-1:0]        mem_array[Word_Depth-1:0];

wire [Add_Width-1:0]  A_int;
wire		      CLK_int;
wire		      CEN_int;
wire		      WEN_int;
wire [Wen_Width-1:0]  BWEN_int;
wire [Bits-1:0]       D_int;

reg  [Bits-1:0]       Q_latched;
reg  [Add_Width-1:0]  A_latched;
reg  [Bits-1:0]       D_latched;
reg		      CEN_latched;
reg		      LAST_CLK;
reg		      WEN_latched;
reg [Wen_Width-1:0]   BWEN_latched;
reg		      CEN_flag;
reg		      CLK_CYC_flag;
reg		      CLK_H_flag;
reg		      CLK_L_flag;
reg                   WEN_flag; 
reg [Wen_Width-1:0]   BWEN_flag;
reg                   VIO_flag;
reg                   LAST_VIO_flag;
reg [Add_Width-1:0]   A_flag;
reg [Bits-1:0]        D_flag;

reg		      LAST_CEN_flag;
reg		      LAST_WEN_flag;
reg [Wen_Width-1:0]   LAST_BWEN_flag;
reg [Add_Width-1:0]   LAST_A_flag;
reg [Bits-1:0]        LAST_D_flag;
reg		      LAST_CLK_CYC_flag;
reg		      LAST_CLK_H_flag;
reg		      LAST_CLK_L_flag;
reg [Bits-1:0]        data_tmp;

wire		      CE_flag;
wire		      clkconf_flag;
 
reg		      A0_flag; 
reg		      A1_flag; 
reg		      A2_flag; 
reg		      A3_flag; 
reg		      A4_flag; 
reg		      A5_flag; 
reg		      A6_flag; 
reg		      A7_flag; 
reg		      A8_flag; 
reg		      A9_flag; 
reg		      D0_flag; 
wire		      WR0_flag; 
assign WR0_flag=(!CEN_int && !WEN_int && !BWEN_int[0]); 
reg		      D1_flag; 
wire		      WR1_flag; 
assign WR1_flag=(!CEN_int && !WEN_int && !BWEN_int[1]); 
reg		      D2_flag; 
wire		      WR2_flag; 
assign WR2_flag=(!CEN_int && !WEN_int && !BWEN_int[2]); 
reg		      D3_flag; 
wire		      WR3_flag; 
assign WR3_flag=(!CEN_int && !WEN_int && !BWEN_int[3]); 
reg		      D4_flag; 
wire		      WR4_flag; 
assign WR4_flag=(!CEN_int && !WEN_int && !BWEN_int[4]); 
reg		      D5_flag; 
wire		      WR5_flag; 
assign WR5_flag=(!CEN_int && !WEN_int && !BWEN_int[5]); 
reg		      D6_flag; 
wire		      WR6_flag; 
assign WR6_flag=(!CEN_int && !WEN_int && !BWEN_int[6]); 
reg		      D7_flag; 
wire		      WR7_flag; 
assign WR7_flag=(!CEN_int && !WEN_int && !BWEN_int[7]); 
reg		      D8_flag; 
wire		      WR8_flag; 
assign WR8_flag=(!CEN_int && !WEN_int && !BWEN_int[8]); 
reg		      D9_flag; 
wire		      WR9_flag; 
assign WR9_flag=(!CEN_int && !WEN_int && !BWEN_int[9]); 
reg		      D10_flag; 
wire		      WR10_flag; 
assign WR10_flag=(!CEN_int && !WEN_int && !BWEN_int[10]); 
reg		      D11_flag; 
wire		      WR11_flag; 
assign WR11_flag=(!CEN_int && !WEN_int && !BWEN_int[11]); 
reg		      D12_flag; 
wire		      WR12_flag; 
assign WR12_flag=(!CEN_int && !WEN_int && !BWEN_int[12]); 
reg		      D13_flag; 
wire		      WR13_flag; 
assign WR13_flag=(!CEN_int && !WEN_int && !BWEN_int[13]); 
reg		      D14_flag; 
wire		      WR14_flag; 
assign WR14_flag=(!CEN_int && !WEN_int && !BWEN_int[14]); 
reg		      D15_flag; 
wire		      WR15_flag; 
assign WR15_flag=(!CEN_int && !WEN_int && !BWEN_int[15]); 
reg		      D16_flag; 
wire		      WR16_flag; 
assign WR16_flag=(!CEN_int && !WEN_int && !BWEN_int[16]); 
reg		      D17_flag; 
wire		      WR17_flag; 
assign WR17_flag=(!CEN_int && !WEN_int && !BWEN_int[17]); 
reg		      D18_flag; 
wire		      WR18_flag; 
assign WR18_flag=(!CEN_int && !WEN_int && !BWEN_int[18]); 
reg		      D19_flag; 
wire		      WR19_flag; 
assign WR19_flag=(!CEN_int && !WEN_int && !BWEN_int[19]); 
reg		      D20_flag; 
wire		      WR20_flag; 
assign WR20_flag=(!CEN_int && !WEN_int && !BWEN_int[20]); 
reg		      D21_flag; 
wire		      WR21_flag; 
assign WR21_flag=(!CEN_int && !WEN_int && !BWEN_int[21]); 
reg		      D22_flag; 
wire		      WR22_flag; 
assign WR22_flag=(!CEN_int && !WEN_int && !BWEN_int[22]); 
reg		      D23_flag; 
wire		      WR23_flag; 
assign WR23_flag=(!CEN_int && !WEN_int && !BWEN_int[23]); 
reg		      D24_flag; 
wire		      WR24_flag; 
assign WR24_flag=(!CEN_int && !WEN_int && !BWEN_int[24]); 
reg		      D25_flag; 
wire		      WR25_flag; 
assign WR25_flag=(!CEN_int && !WEN_int && !BWEN_int[25]); 
reg		      D26_flag; 
wire		      WR26_flag; 
assign WR26_flag=(!CEN_int && !WEN_int && !BWEN_int[26]); 
reg		      D27_flag; 
wire		      WR27_flag; 
assign WR27_flag=(!CEN_int && !WEN_int && !BWEN_int[27]); 
reg		      D28_flag; 
wire		      WR28_flag; 
assign WR28_flag=(!CEN_int && !WEN_int && !BWEN_int[28]); 
reg		      D29_flag; 
wire		      WR29_flag; 
assign WR29_flag=(!CEN_int && !WEN_int && !BWEN_int[29]); 
reg		      D30_flag; 
wire		      WR30_flag; 
assign WR30_flag=(!CEN_int && !WEN_int && !BWEN_int[30]); 
reg		      D31_flag; 
wire		      WR31_flag; 
assign WR31_flag=(!CEN_int && !WEN_int && !BWEN_int[31]); 
 
assign BWEN_int = {Wen_Width{1'b0}};


buf q_buf[Bits-1:0] (Q, Q_int);
buf (CLK_int, CLK);
buf (CEN_int, CEN);
buf (WEN_int, WEN);

buf a_buf[Add_Width-1:0] (A_int, A);
buf d_buf[Bits-1:0] (D_int, D);     

integer      i,j,wenn,lb,hb;
integer      n;

//assign Q_int= Q_latched;
assign CE_flag=!CEN_int;

always @(CLK_int)
begin
    casez({LAST_CLK, CLK_int})
    2'b01: begin
        CEN_latched = CEN_int;
        WEN_latched = WEN_int;
        BWEN_latched = BWEN_int;
        A_latched = A_int;
        D_latched = D_int;
        rw_mem;
        end
    2'b10,
    2'bx?,
    2'b00,
    2'b11: ;
    2'b?x: begin
        for(i=0;i<Word_Depth;i=i+1)
        mem_array[i]={Bits{1'bx}};
        Q_latched={Bits{1'bx}};
        rw_mem;
        end
    endcase
    LAST_CLK=CLK_int;
end
 
`ifdef POWER_PINS 
always@(VDD, VSS, Q_latched) 
begin  
    if (VDD === 1'bx || VDD === 1'bz) 
    begin 
        $display("Warning: Unknown value for VDD %b in %m at %0t", VDD, $time); 
        Q_int = {Bits{1'bx}}; 
    end 
    else if (VSS === 1'bx || VSS === 1'bz) 
    begin 
        $display("Warning: Unknown value for VSS %b in %m at %0t", VSS, $time); 
        Q_int = {Bits{1'bx}}; 
    end 
    else 
        Q_int = Q_latched; 
end 
`else 
always@(Q_latched) 
begin  
    Q_int = Q_latched; 
end 
`endif 
 
always @(  CEN_flag  or WEN_flag 
        or D0_flag 
        or D1_flag 
        or D2_flag 
        or D3_flag 
        or D4_flag 
        or D5_flag 
        or D6_flag 
        or D7_flag 
        or D8_flag 
        or D9_flag 
        or D10_flag 
        or D11_flag 
        or D12_flag 
        or D13_flag 
        or D14_flag 
        or D15_flag 
        or D16_flag 
        or D17_flag 
        or D18_flag 
        or D19_flag 
        or D20_flag 
        or D21_flag 
        or D22_flag 
        or D23_flag 
        or D24_flag 
        or D25_flag 
        or D26_flag 
        or D27_flag 
        or D28_flag 
        or D29_flag 
        or D30_flag 
        or D31_flag 
        or A0_flag 
        or A1_flag 
        or A2_flag 
        or A3_flag 
        or A4_flag 
        or A5_flag 
        or A6_flag 
        or A7_flag 
        or A8_flag 
        or A9_flag 
        or CLK_H_flag   or CLK_L_flag 
        or CLK_CYC_flag ) 

begin
      update_flag_bus;
      CEN_latched = (CEN_flag!==LAST_CEN_flag) ? 1'bx : CEN_latched ;
      WEN_latched = (WEN_flag!==LAST_WEN_flag) ? 1'bx : WEN_latched ;
      for (n=0; n<Wen_Width; n=n+1)
      BWEN_latched[n] = (BWEN_flag[n]!==LAST_BWEN_flag[n]) ? 1'bx : BWEN_latched[n] ;
      for (n=0; n<Add_Width; n=n+1)
      A_latched[n] = (A_flag[n]!==LAST_A_flag[n]) ? 1'bx : A_latched[n] ;
      for (n=0; n<Bits; n=n+1)
      D_latched[n] = (D_flag[n]!==LAST_D_flag[n]) ? 1'bx : D_latched[n] ;
      LAST_CEN_flag = CEN_flag;
      LAST_WEN_flag = WEN_flag;
      LAST_BWEN_flag = BWEN_flag;
      LAST_A_flag = A_flag;
      LAST_D_flag = D_flag;
      LAST_CLK_CYC_flag = CLK_CYC_flag;
      LAST_CLK_H_flag = CLK_H_flag;
      LAST_CLK_L_flag = CLK_L_flag;
      rw_mem;

end

 task rw_mem;
    begin
      if(CEN_latched==1'b0)
        begin
          if (WEN_latched==1'b1)
            begin
              if(^(A_latched)==1'bx)
                Q_latched={Bits{1'bx}};
              else
                Q_latched=mem_array[A_latched];
            end
          else if (WEN_latched==1'b0)
          begin
            for (wenn=0; wenn<Wen_Width; wenn=wenn+1)
              begin
                lb=wenn*Word_Pt;
                if ( (lb+Word_Pt) >= Bits) hb=Bits-1;
                else hb=lb+Word_Pt-1;
                if (BWEN_latched[wenn]==1'b1)
                  begin
                    if(^(A_latched)==1'bx)
                      for (i=lb; i<=hb; i=i+1) Q_latched[i]=1'bx;
                    else
                      begin
                      data_tmp=mem_array[A_latched];
                      for (i=lb; i<=hb; i=i+1) Q_latched[i]=data_tmp[i];
                      end
                  end
                else if (BWEN_latched[wenn]==1'b0)
                  begin
                    if (^(A_latched)==1'bx)
                      begin
                        for (i=0; i<Word_Depth; i=i+1)
                          begin
                            data_tmp=mem_array[i];
                            for (j=lb; j<=hb; j=j+1) data_tmp[j]=1'bx;
                            mem_array[i]=data_tmp;
                          end
                        for (i=lb; i<=hb; i=i+1) Q_latched[i]=1'bx;
                      end
                    else
                      begin
                        data_tmp=mem_array[A_latched];
                        for (i=lb; i<=hb; i=i+1) data_tmp[i]=D_latched[i];
                        mem_array[A_latched]=data_tmp;
                        for (i=lb; i<=hb; i=i+1) Q_latched[i]=data_tmp[i];
                      end
                  end
                else
                  begin
                    for (i=lb; i<=hb;i=i+1) Q_latched[i]=1'bx;
                    if (^(A_latched)==1'bx)
                      begin
                        for (i=0; i<Word_Depth; i=i+1)
                          begin
                            data_tmp=mem_array[i];
                            for (j=lb; j<=hb; j=j+1) data_tmp[j]=1'bx;
                            mem_array[i]=data_tmp;
                          end
                      end
                    else
                      begin
                        data_tmp=mem_array[A_latched];
                        for (i=lb; i<=hb; i=i+1) data_tmp[i]=1'bx;
                        mem_array[A_latched]=data_tmp;
                      end
                 end
               end
             end
           else
             begin
               for (wenn=0; wenn<Wen_Width; wenn=wenn+1)
               begin
                 lb=wenn*Word_Pt;
                 if ( (lb+Word_Pt) >= Bits) hb=Bits-1;
                 else hb=lb+Word_Pt-1;
                 if (BWEN_latched[wenn]==1'b1)
                  begin
                    if(^(A_latched)==1'bx)
                      for (i=lb; i<=hb; i=i+1) Q_latched[i]=1'bx;
                    else
                      begin
                      data_tmp=mem_array[A_latched];
                      for (i=lb; i<=hb; i=i+1) Q_latched[i]=data_tmp[i];
                      end
                  end
                else
                  begin
                    for (i=lb; i<=hb;i=i+1) Q_latched[i]=1'bx;
                    if (^(A_latched)==1'bx)
                      begin
                        for (i=0; i<Word_Depth; i=i+1)
                          begin
                            data_tmp=mem_array[i];
                            for (j=lb; j<=hb; j=j+1) data_tmp[j]=1'bx;
                            mem_array[i]=data_tmp;
                          end
                      end
                    else
                      begin
                        data_tmp=mem_array[A_latched];
                        for (i=lb; i<=hb; i=i+1) data_tmp[i]=1'bx;
                        mem_array[A_latched]=data_tmp;
                      end
                 end
               end
             end
           end
         else if (CEN_latched==1'bx)
           begin
             for (wenn=0;wenn<Wen_Width;wenn=wenn+1)
            begin
              lb=wenn*Word_Pt;
              if ((lb+Word_Pt)>=Bits) hb=Bits-1;
              else hb=lb+Word_Pt-1;
              if(WEN_latched==1'b1 || BWEN_latched[wenn]==1'b1)
                for (i=lb;i<=hb;i=i+1) Q_latched[i]=1'bx;
              else
                begin
                  for (i=lb;i<=hb;i=i+1) Q_latched[i]=1'bx;
                  if(^(A_latched)==1'bx)
                    begin
                      for (i=0;i<Word_Depth;i=i+1)
                        begin
                          data_tmp=mem_array[i];
                          for (j=lb;j<=hb;j=j+1) data_tmp[j]=1'bx;
                          mem_array[i]=data_tmp;
                        end
                    end
                  else
                    begin
                      data_tmp=mem_array[A_latched];
                      for (i=lb;i<=hb;i=i+1) data_tmp[i]=1'bx;
                      mem_array[A_latched]=data_tmp;
                    end
                end
            end
        end
    end
  endtask
 
task x_mem; 
begin 
    for(i=0;i<Word_Depth;i=i+1) 
    mem_array[i]={Bits{1'bx}}; 
end 
endtask 
 
task update_flag_bus; 
begin 
BWEN_flag = {Wen_Width{1'b0}}; 
A_flag = { 
            A9_flag, 
            A8_flag, 
            A7_flag, 
            A6_flag, 
            A5_flag, 
            A4_flag, 
            A3_flag, 
            A2_flag, 
            A1_flag, 
            A0_flag }; 
D_flag = { 
            D31_flag, 
            D30_flag, 
            D29_flag, 
            D28_flag, 
            D27_flag, 
            D26_flag, 
            D25_flag, 
            D24_flag, 
            D23_flag, 
            D22_flag, 
            D21_flag, 
            D20_flag, 
            D19_flag, 
            D18_flag, 
            D17_flag, 
            D16_flag, 
            D15_flag, 
            D14_flag, 
            D13_flag, 
            D12_flag, 
            D11_flag, 
            D10_flag, 
            D9_flag, 
            D8_flag, 
            D7_flag, 
            D6_flag, 
            D5_flag, 
            D4_flag, 
            D3_flag, 
            D2_flag, 
            D1_flag, 
            D0_flag }; 
end 
endtask 
 
endmodule 
 
 

`endcelldefine
//*******************************************************************************************************
