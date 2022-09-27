`timescale 1ns/1ps
//`define SIM_ONLY_TB 1
module tb_top #(
    parameter   clk_period  = 10    ,//100M Hz
    parameter   pic_size    = 8    ,
    parameter   dw          = 128   ,
    parameter   aw          = 10    
);

reg             sys_clk     ;
reg             SYS_NRST     ;
reg [dw-1 :0]   data        ;
reg [7    :0]   bitsel      ;
reg [7    :0]   cnt         ;
reg             data_vld    ;
reg             data_hsync  ;
reg             data_sop    ;

reg [aw-1 :0]r_wraddr_start ;
reg [7    :0]r_pic_size     ;
reg          padding      ;
reg [3    :0]mode         ;  
reg          r_opu_1152_rdy ;
reg          r_sram2reg_vld ;

reg [7    :0]count_i        ;

wire [3    :0]sram_status    ;

//reg [4    :0]r_buf_opu_vld  ;//store 5 period of opu_vld
//reg          r_opu_vld_nclk ;//s_opu_vld_nclk delay one clk

reg matrix_done ;


wire [dw*9-1 :0]s_opu_1152  ;
wire [7      :0]s_reg_array_row ;

wire            s_opu_vld_nclk;//5 period of opu_vld eq 5'b11111

`ifdef SIM_ONLY_TB
    reg         s_sram2reg_rdy ;
    reg         s_opu_1152_vld ;
    reg         s_wready       ;
    reg         temp           ;
    //===========================================
    // description: simulate the opu vld signal, when rdy&vld , opu vld down
    initial begin
        s_opu_1152_vld  = 0     ;
        temp            = 0     ;
        s_wready        = 1     ;
        #(100*clk_period)       ;
        @(posedge sys_clk)      ;
        temp  = 1               ;//indicate the opu prepare data ok    
    end

    always @(posedge sys_clk) begin
        if (s_opu_1152_vld & r_opu_1152_rdy)begin
            s_opu_1152_vld  <= 'b0  ;
        end else if(temp)begin
            s_opu_1152_vld  <= 1'b1  ;
        end
    end

`else 
    wire         s_sram2reg_rdy ;
    wire         s_opu_1152_vld ;
    wire         s_wready       ;

    top U_top (
    .SYS_CLK    (sys_clk    ),
    .SYS_NRST    (SYS_NRST  ),

    .DATA       (data       ),
    .DATA_VLD   (data_vld   ),
    .DATA_HSYNC (data_hsync ),
    .DATA_SOP   (data_sop   ),

    .WRADDR_START   (r_wraddr_start ),

    .SRAM2REG_VLD   (r_sram2reg_vld),
    .SRAM2REG_RDY   (s_sram2reg_rdy),

    .OPU_1152_RDY   (r_opu_1152_rdy),
    .OPU_1152_VLD   (s_opu_1152_vld),
    .PIC_SIZE       (r_pic_size ),
    .PADDING        (padding  ),
    .MODE           (mode     ),

    .WREADY         (s_wready   ),

    .OPU_1152       (s_opu_1152 ),
    .CTRL_MUX_1152_1('b0        ), 
    .REG_ARRAY_ROW  (s_reg_array_row),
    .SRAM_STATUS    (sram_status)

); 
`endif 

reg [pic_size*8-1 :0]   picture [pic_size-1 :0]     ;//define a picture pic_size*pic_size, each pix is 8bit
reg [7            :0]   matrix  [8          :0]     ;//define a matrix 3x3 ,each is 8bit, sum has nine 8bit data

reg     [7  :0]     x       ;
reg     [7  :0]     y       ;//the left and up side of matrix position in a picture


wire    [7  :0]     matrix0     ;
wire    [7  :0]     matrix1     ;
wire    [7  :0]     matrix2     ;
wire    [7  :0]     matrix3     ;
wire    [7  :0]     matrix4     ;
wire    [7  :0]     matrix5     ;
wire    [7  :0]     matrix6     ;
wire    [7  :0]     matrix7     ;
wire    [7  :0]     matrix8     ; //9 num,each num is 8bit

reg [2:0]       bit             ;
wire [dw*9-1 :0] standar_opu_1152;
reg [7:0]       matrix_cnt      ;
reg [7:0]       line_cnt        ;

wire [7:0]temp_y_ad_2    ;
    wire [7:0]temp_x_ad_1    ;
    assign temp_x_ad_1 = x + 1  ;
    assign temp_y_ad_2 = y + 2  ;

    wire [7:0]temp_pic_sub_x4    ;
    wire [7:0]temp_pic_sub_x3   ;
    assign temp_pic_sub_x3 = (r_pic_size-8'd1-x)   ;
    assign temp_pic_sub_x4 = (r_pic_size-8'd1-x-8'd1)  ;



// assign matrix0 = matrix[0]  ;//just for look up , no use
// assign matrix1 = matrix[1]  ;
// assign matrix2 = matrix[2]  ;
// assign matrix3 = matrix[3]  ;
// assign matrix4 = matrix[4]  ;
// assign matrix5 = matrix[5]  ;
// assign matrix6 = matrix[6]  ;
// assign matrix7 = matrix[7]  ;
// assign matrix8 = matrix[8]  ;
//===========================================
// description: for check data to bank 0/1 is right 
always @(posedge sys_clk) begin
    if (sram_status == 4'b1000) begin
   //     $stop;
    end
end

//===========================================
// description: initial signal and picture
integer     i   ;
integer     j   ;
initial begin
    padding = 1             ;
    x       = 0-padding     ;
    y       = 0-padding     ;

    matrix_cnt  = 0         ;
    line_cnt    = 0         ;
    bit         = 0         ;
    matrix_done = 1         ;

    count_i     = 0         ;
    data_sop    = 0         ;
    data_hsync  = 0         ;
    cnt         = 0         ;

    r_wraddr_start  = 0         ;//start_wraddr
    r_pic_size      = pic_size  ;//pic_size
    mode            = 4'b0001   ;//mode0

    SYS_NRST     = 0         ;
    repeat(20) @(posedge sys_clk)   ;//SYS_NRST
    SYS_NRST     = 1         ;

    for(i=0 ; i<pic_size ; i=i+1)begin//simulate the picture data
        for(j=0 ; j<pic_size ; j=j+1)begin
            picture[i][8*(pic_size-1-j) +:8] = i + j*pic_size  ;
        end
    end
end

//===========================================
// description: when opu rdy&vld , means opu read 1bit of matrix done

initial begin
    @(posedge SYS_NRST)  ;
    forever begin
        @(negedge (s_opu_1152_vld & r_opu_1152_rdy))begin
            bit <= bit + 1  ;
            if(bit == 7)begin
                matrix_done <= 1'b1 ;
            end else begin
                matrix_done <= 1'b0 ;
            end
        end
    end
end

//===========================================
// description: the x , y update when opu read one matrix out
wire [7 : 0]line_num    ;//one line has how many matrix
assign line_num = padding ? ((pic_size-2+padding*2)*2) : ((pic_size-2)*2)   ;
initial begin
    forever begin
        @(posedge (matrix_done))begin
            matrix_cnt <= matrix_cnt+1              ;
                    
            if(matrix_cnt % line_num == (line_num - 1'b1))begin
                line_cnt<= line_cnt + 1'b1              ;
                x       <= (line_cnt+1)*2 - padding     ;
                y       <= 0 - padding                  ;
            end else begin
                if(matrix_cnt%4 == 0) x<=x+1'b1        ;
                if(matrix_cnt%4 == 1) y<=y+1'b1        ;
                if(matrix_cnt%4 == 2) x<=x-1'b1        ;
                if(matrix_cnt%4 == 3) y<=y+1'b1        ;
            end
        end
    end
end
//===========================================
// description: x , y update the matrix 3x3
// initial begin
//     @(posedge SYS_NRST)              ;

//     forever begin
//         @(posedge matrix_done)begin
//             MATRIX_3x3_UPDATE(x , y)    ; 
//         end
//     end
// end
assign  matrix0 = ((x < r_pic_size)&(y < r_pic_size)) ? picture[y  ][(r_pic_size-8'd1-x)*8'd8 +:8] : 'b0                        ;
assign  matrix1 = ((x+8'd1< r_pic_size)&(y < r_pic_size)) ? picture[y  ][(r_pic_size-8'd1-x-8'd1)*8'd8 +:8] : 'b0               ;
assign  matrix2 = ((x+8'd2< r_pic_size)&(y < r_pic_size)) ? picture[y  ][(r_pic_size-8'd1-x-8'd2)*8'd8 +:8] : 'b0               ;
assign  matrix3 = ((x < r_pic_size)&(y+8'd1 < r_pic_size)) ? picture[y+8'd1 ][(r_pic_size-8'd1-x)*8'd8 +:8] : 'b0               ;
assign  matrix4 = ((x+8'd1< r_pic_size)&(y+2'd1 < r_pic_size)) ? picture[y+2'd1 ][temp_pic_sub_x4*8'd8 +:8] : 'b0               ;
assign  matrix5 = ((x+8'd2< r_pic_size)&(y+2'd1< r_pic_size)) ? picture[y+2'd1 ][(r_pic_size-8'd1-x-8'd2)*8'd8 +:8] : 'b0       ;
assign  matrix6 = ((x < r_pic_size)&(y+2'd2 < r_pic_size)) ? picture[temp_y_ad_2 ][(r_pic_size-8'd1-x)*8'd8 +:8] : 'b0          ;
assign  matrix7 = ((x+8'd1< r_pic_size)&(y+2'd2 < r_pic_size)) ? picture[temp_y_ad_2 ][(r_pic_size-8'd1-x-8'd1)*8'd8 +:8] : 'b0 ;
assign  matrix8 = ((x+8'd2< r_pic_size)&(y+2'd2 < r_pic_size)) ? picture[temp_y_ad_2 ][(r_pic_size-8'd1-x-8'd2)*8'd8 +:8] : 'b0 ;
//===========================================
// description: matrix 3x3  update standar_opu_1152
assign standar_opu_1152 = {{128{matrix0[bit]}}  ,{128{matrix1[bit]}} ,{128{matrix2[bit]}}
                       ,   {128{matrix3[bit]}}  ,{128{matrix4[bit]}} ,{128{matrix5[bit]}}
                       ,   {128{matrix6[bit]}}  ,{128{matrix7[bit]}} ,{128{matrix8[bit]}} };


//===========================================
// description: generate clk
initial begin//clock
    sys_clk  = 'b0    ;
    forever #(clk_period/2) sys_clk = ~sys_clk  ;
end

//===========================================
// description: generate data_sop , data ，data_hsync
initial begin
    
    @(posedge SYS_NRST)  ;
    repeat(5) @(posedge sys_clk)  ;
    data_sop = 1         ;
    @(posedge sys_clk)   ;   
    data_sop= 0          ;
    
    repeat(pic_size*pic_size)begin
        GEN_PACK(cnt);
        if (cnt%pic_size == (pic_size - 1))begin//data_hsync
            data_hsync = 1      ;
            @(posedge sys_clk)  ;
            data_hsync = 0      ;
        end
        repeat(10)  @(posedge sys_clk);
        cnt = cnt + 1;
    end

    repeat(100000) @(posedge sys_clk)  ;
    $stop                           ;
    
end
//===========================================
// description: compare standar_opu with opu_1152
always @(posedge sys_clk) begin
    if (s_opu_1152_vld & r_opu_1152_rdy)begin
        if(standar_opu_1152 == s_opu_1152)begin
            $display("picture picture of axis is (%d , %d) in %d bit right!!!",x,y,bit);
        end else begin
            $display("picture picture of axis is (%d , %d) in %d bit wrong!!!",x,y,bit);
        end
    end
end


task GEN_PACK;
    input   [7:0]   cnt ;
    begin
        bitsel  = 0 ;
        repeat(8) begin
            data    ={ 128{cnt[bitsel]} };
            data_vld= 0         ;
            repeat(5) @(posedge sys_clk);
            wait(s_wready)  ;
           // @(posedge s_wready) ;
            data_vld = 1;
            @(posedge sys_clk)  ; 
            data_vld = 0        ;
            bitsel   = bitsel +1;
        end
    end
endtask

task MATRIX_3x3_UPDATE  ;
    input   [7:0]   x   ;
    input   [7:0]   y   ;//the left and up position of matrix

    
    begin
        if ((x < r_pic_size)&(y < r_pic_size))begin
            matrix[0]   = picture[y  ][(r_pic_size-8'd1-x)*8 +:8]   ;
        end else begin
            matrix[0]   = 'b0  ;
        end
        if ((x+8'd1< r_pic_size)&(y < r_pic_size))begin
            matrix[1]   = picture[y  ][(r_pic_size-8'd1-x-8'd1)*8'd8 +:8]   ;
        end else begin
            matrix[1]   = 'b0  ;
        end
        if ((x+8'd2< r_pic_size)&(y < r_pic_size))begin
            matrix[2]   = picture[y  ][(r_pic_size-8'd1-x-8'd2)*8 +:8]   ;
        end else begin
            matrix[2]   = 'b0  ;
        end
        if ((x < r_pic_size)&(y+8'd1 < r_pic_size))begin
            matrix[3]   = picture[y+8'd1 ][(r_pic_size-8'd1-x)*8 +:8]   ;
        end else begin
            matrix[3]   = 'b0  ;
        end
        if ((x+8'd1< r_pic_size)&(y+2'd1 < r_pic_size))begin
            matrix[4]   = picture[y+2'd1 ][temp_pic_sub_x4*8 +:8]   ;
        end else begin
            matrix[4]   = 'b0  ;
        end
        if ((x+8'd2< r_pic_size)&(y+2'd1< r_pic_size))begin
            matrix[5]   = picture[y+2'd1 ][(r_pic_size-8'd1-x-8'd2)*8 +:8]   ;
        end else begin
            matrix[5]   = 'b0  ;
        end
        if ((x < r_pic_size)&(y+2'd2 < r_pic_size))begin
            matrix[6]   = picture[temp_y_ad_2 ][(r_pic_size-8'd1-x)*8 +:8]   ;
        end else begin
            matrix[6]   = 'b0  ;
        end
        if ((x+8'd1< r_pic_size)&(y+2'd2 < r_pic_size))begin
            matrix[7]   = picture[temp_y_ad_2 ][(r_pic_size-8'd1-x-8'd1)*8'd8 +:8]   ;
        end else begin
            matrix[7]   = 'b0  ;
        end
        if ((x+8'd2< r_pic_size)&(y+2'd2 < r_pic_size))begin
            matrix[8]   = picture[temp_y_ad_2 ][(r_pic_size-8'd1-x-8'd2)*8 +:8]   ;
        end else begin
            matrix[8]   = 'b0  ;
        end
    end
endtask

initial begin
    r_opu_1152_rdy = 0  ;//opu_1152_vld

    repeat(2000) begin
        @(posedge s_opu_1152_vld)begin
       // wait (s_opu_1152_vld)begin
            repeat(20)begin
                @(posedge sys_clk)      ;
            end
            @(posedge sys_clk)      ;
            r_opu_1152_rdy = 1      ;//opu_1152_rdy
            @(posedge sys_clk)      ;
        //  #clk_period             ;
            r_opu_1152_rdy = 0;
            count_i = count_i + 1   ;

        end
        

    end

end

initial begin
    r_sram2reg_vld = 0  ;
    repeat(1000) begin
        @(posedge s_sram2reg_rdy)begin
            @(posedge sys_clk)      ;
            @(posedge sys_clk)      ;
            @(posedge sys_clk)      ;
            @(posedge sys_clk)      ;
            @(posedge sys_clk)      ;
            r_sram2reg_vld = 1      ;//r_sram2reg_vld
            @(posedge sys_clk)      ;
            r_sram2reg_vld = 0      ;
 
        end
        
    end
end


    
endmodule

