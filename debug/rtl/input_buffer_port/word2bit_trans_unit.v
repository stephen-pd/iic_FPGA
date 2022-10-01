// +FHEADER ==================================================
// FilePath       : \MPW2022_11\rtl\inputBuffer\word2bit_trans_unit.v
// Author         : Ziheng Zhou ziheng.zhou.1999@qq.com
// CreateDate     : 2022-08-30 14:37:18
// LastEditors    : Ziheng Zhou ziheng.zhou.1999@qq.com
// LastEditTime   : 2022-09-16 13:39:59
// Description    : 
//                  
// 
//                  
// 
// Rev 1.0    
//                  
// 
// -FHEADER ==================================================
module word2bit_trans_unit #(
    parameter MAX_CHANNEL_NUM = 128
)(
    input   wire                                        clk_i,
    input   wire                                        rst_n_i,
                        
    input   wire    [7:0]                               wordser_data_i,           // 8bit
    input   wire                                        wordser_data_vld_i,

    input   wire    [$clog2(MAX_CHANNEL_NUM)-1:0]       channel_num_i,

    output  wire    [MAX_CHANNEL_NUM-1:0]               bitpar_data_o,          // 128 x 1bit
    output  reg                                         bitpar_data_vld_o,
    input   wire                                        bitpar_data_rdy_i,

    input   wire                                        new_packet_i,
    output  reg                                         packet_received_o,       //inputBuf has received a packet, token table + 1
    output  wire                                        trans_done_o
);


    reg     [7:0]                           trans_buf   [MAX_CHANNEL_NUM-1:0];

    reg     [$clog2(MAX_CHANNEL_NUM)-1:0]   wr_cnt;
    reg     [2:0]                           rd_cnt;

    reg                                     wr_done;

    wire                                    datapar_fire;

    assign datapar_fire = bitpar_data_vld_o && bitpar_data_rdy_i;

    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            wr_cnt <= 'h0;
        end
        else if(packet_received_o) begin
            wr_cnt <= 'h0;
        end
        else if(wr_cnt == channel_num_i) begin
            wr_cnt <= channel_num_i;
        end
        else if(wordser_data_vld_i) begin
            wr_cnt <= wr_cnt + 1'b1;
        end
        else begin
            wr_cnt <= wr_cnt;
        end
    end

    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            wr_done <= 1'b0;
        end
        else if(packet_received_o) begin
            wr_done <= 1'b0;
        end
        else if(wr_cnt == channel_num_i && wordser_data_vld_i) begin
            wr_done <= 1'b1;
        end
        else begin
            wr_done <= wr_done;
        end
    end
    assign trans_done_o = wr_done;

    genvar i;
    generate
        for(i=0; i<MAX_CHANNEL_NUM; i=i+1) begin : WR_TRANS_BUF
            always @(posedge clk_i or negedge rst_n_i) begin
                if(!rst_n_i) begin
                    trans_buf[i] <= 8'h0;
                end
                else if(packet_received_o) begin
                    trans_buf[i] <= 8'b0;
                end
                else if(wr_cnt == i && wordser_data_vld_i) begin
                    trans_buf[i] <= wordser_data_i;
                end
                else begin
                    trans_buf[i] <= trans_buf[i];
                end
            end
        end
    endgenerate

    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            rd_cnt <= 'h0;
        end
        else if(packet_received_o) begin
            rd_cnt <= 'h0;
        end
        else if(rd_cnt == 'h7 && datapar_fire) begin
            rd_cnt <= rd_cnt;
        end
        else if(datapar_fire) begin
            rd_cnt <= rd_cnt + 1'b1;
        end
    end

    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            bitpar_data_vld_o <= 1'b0;
        end
        else if(rd_cnt == 'h7 && datapar_fire || packet_received_o) begin
            bitpar_data_vld_o <= 1'b0;
        end
        else if(wr_done) begin
            bitpar_data_vld_o <= 1'b1;
        end
        else begin
            bitpar_data_vld_o <= 1'b0;
        end
    end

    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            packet_received_o <= 1'b0;
        end
        else if(new_packet_i) begin
            packet_received_o <= 1'b0;
        end
        else if(rd_cnt == 'h7 && datapar_fire) begin
            packet_received_o <= 1'b1;
        end
        else begin
            packet_received_o <= packet_received_o;
        end
    end

    generate
        for (i=0; i<MAX_CHANNEL_NUM; i=i+1) begin : RD_TRANS_BUF
            assign bitpar_data_o[i] = trans_buf[i][rd_cnt];
        end
    endgenerate

    
endmodule