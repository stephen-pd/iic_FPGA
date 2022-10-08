`include "define.v"
module register_array_fifo #(
    parameter dw=128

) (
    input   SYS_CLK,
    input   SYS_NRST,

    input   [5:0]pic_size,
    input   [3:0]mode,
    input   padding,

    //genaddr to register_array
    `ifndef has_mux6_1_no_register_shift
    input   [7:0]fsm_cstate_addr,
    input   gen_addr_req,
    `endif

    //fifo write data
    input   [3:0]register_array_write_addr_index,
    input   [2:0]register_array_write_addr_bit,
    input   register_array_write_rst,

    input   [dw-1 :0]register_array_write_data,
    input   register_array_write_enable,//sram_read_enable
    input   [3:0]register_array_write_size,//eq 9/3
    output  register_array_write_resp,
    //fifo read data
    input   register_array_read_enable,//opu_vld&rdy
    output  [dw*9-1:0]register_array_read_data,

    //fifo status
    output  register_array_empty,
    output  register_array_full,
    
    //mux1152_1
    input   [10:0]register_array_row_sel,
    output  [7:0]register_array_row_data

);

    reg [dw*9-1 :0]register_array[7:0];

    reg [3:0]r_cnt_wdata;
    reg [3:0]wptr;
    reg [3:0]rptr;

    wire [2:0]s_mux_8_1_ctrl;

    wire s_register_array_read_matrix;

    reg [7:0]r_cnt_matrix;
    reg r_register_array_read_line;

    wire [dw*9-1 :0]s_register_array_out;
    wire [2:0]s_mux_6_1_ctrl;

    

    //mux_1152 sel 1
    assign register_array_row_data = {register_array[7][register_array_row_sel], register_array[6][register_array_row_sel], register_array[5][register_array_row_sel], 
                                      register_array[4][register_array_row_sel], register_array[3][register_array_row_sel], register_array[2][register_array_row_sel],
                                      register_array[1][register_array_row_sel], register_array[0][register_array_row_sel]};

    //fifo status
    assign register_array_empty = (wptr == rptr);
    assign register_array_full = (wptr == {~rptr[3],rptr[2:0]});

    //write response
    assign register_array_write_resp = (r_cnt_wdata == (register_array_write_size-4'b0001));
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_cnt_wdata <= 'b0;
        end
        else begin
            if (register_array_write_resp)begin
                r_cnt_wdata <= 'b0;
            end
            else if(register_array_write_enable & (~register_array_full))begin
                r_cnt_wdata <= r_cnt_wdata + 1'b1;
            end
        end
    end

    //wptr
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            wptr <= 'b0;
        end
        else begin
            if ((~register_array_full) & register_array_write_resp)begin
                wptr <= wptr + 1'b1;
            end
        end
    end

    //rptr
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            rptr <= 'b0;
        end
        else begin
            if ((~register_array_empty) & register_array_read_enable)begin
                rptr <= rptr + 1'b1;
            end
        end
    end
    

    mux_8_1_ctrl U_mux_8_1_ctrl
    (
        .SYS_CLK    (SYS_CLK),
        .SYS_NRST   (SYS_NRST),

        .mux_8_1_ctrl_update    (register_array_read_enable),//i

        .mux_8_1_ctrl           (s_mux_8_1_ctrl),//o
        .mux_8_1_ctrl_reset     (s_register_array_read_matrix) //o
    );

    mux_8_1 #(
        .dw(dw)
    )U_mux_8_1(
        .mux_8_1_ctrl   (s_mux_8_1_ctrl),

        .mux_8_1_in_0   (register_array[0]),
        .mux_8_1_in_1   (register_array[1]),
        .mux_8_1_in_2   (register_array[2]),
        .mux_8_1_in_3   (register_array[3]),
        .mux_8_1_in_4   (register_array[4]),
        .mux_8_1_in_5   (register_array[5]),
        .mux_8_1_in_6   (register_array[6]),
        .mux_8_1_in_7   (register_array[7]),

        .mux_8_1_out    (s_register_array_out)
    );
    

    `ifdef has_mux6_1_no_register_shift

    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            register_array[0]    <= 'b0  ;
            register_array[1]    <= 'b0  ;
            register_array[2]    <= 'b0  ;
            register_array[3]    <= 'b0  ;
            register_array[4]    <= 'b0  ;
            register_array[5]    <= 'b0  ;
            register_array[6]    <= 'b0  ;
            register_array[7]    <= 'b0  ;
        end
        else begin
            if (register_array_write_enable & (~register_array_full))begin
                if (register_array_write_rst)begin
                    register_array[register_array_write_addr_bit][(4'd9-register_array_write_addr_index)*dw-1 -:dw] <= 'b0;
                end
                else begin
                    register_array[register_array_write_addr_bit][(4'd9-register_array_write_addr_index)*dw-1 -:dw] <= register_array_write_data;
                end
            end
        end
    end

    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_cnt_matrix <= 'b0 ;
        end
        else begin
            if (r_register_array_read_line)begin
                r_cnt_matrix <= 'b0;
            end
            else if(s_register_array_read_matrix)begin
                r_cnt_matrix <= r_cnt_matrix + 1'b1;
            end
        end
    end
    
    always @(*) begin
        if (mode[0])begin
            r_register_array_read_line = (r_cnt_matrix == (pic_size-'d2+padding+padding)<<1);
        end
        else if (mode[1])begin
            r_register_array_read_line = (r_cnt_matrix == (pic_size-'d2+padding+padding));
        end
        else if (mode[2])begin
            r_register_array_read_line = (r_cnt_matrix == (pic_size-'d3+padding+padding)); 
        end
        else if (mode[3])begin
            r_register_array_read_line = (r_cnt_matrix == 1'b1);
        end
        else begin
            r_register_array_read_line = 'b0;
        end
    end


    mux_6_1_ctrl U_mux_6_1_ctrl (
        .SYS_CLK    (SYS_CLK),
        .SYS_NRST   (SYS_NRST),

        .mux_6_1_ctrl_update(s_register_array_read_matrix),//i
        .mux_6_1_ctrl_reset (r_register_array_read_line),//i, 
        .mode       (mode),

        .mux_6_1_ctrl(s_mux_6_1_ctrl)//o
    );

    mux_6_1 #(
        .DW(dw)
    )U_mux_6_1(
       .mux_6_1_ctrl    (s_mux_6_1_ctrl),
       
       .mux_6_1_in      (s_register_array_out),
       .mux_6_1_out_0   (register_array_read_data[dw*9-1 -:dw]),
       .mux_6_1_out_1   (register_array_read_data[dw*8-1 -:dw]),
       .mux_6_1_out_2   (register_array_read_data[dw*7-1 -:dw]),
       .mux_6_1_out_3   (register_array_read_data[dw*6-1 -:dw]),
       .mux_6_1_out_4   (register_array_read_data[dw*5-1 -:dw]),
       .mux_6_1_out_5   (register_array_read_data[dw*4-1 -:dw]),
       .mux_6_1_out_6   (register_array_read_data[dw*3-1 -:dw]),
       .mux_6_1_out_7   (register_array_read_data[dw*2-1 -:dw]),
       .mux_6_1_out_8   (register_array_read_data[dw*1-1 -:dw])
    );


`else 
    //register shift
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            register_array[0]    <= 'b0  ;
            register_array[1]    <= 'b0  ;
            register_array[2]    <= 'b0  ;
            register_array[3]    <= 'b0  ;
            register_array[4]    <= 'b0  ;
            register_array[5]    <= 'b0  ;
            register_array[6]    <= 'b0  ;
            register_array[7]    <= 'b0  ;
        end
        else begin
            //full_cnn
            if (fsm_cstate_addr==7'b0000010)begin
                if (register_array_write_enable & (~register_array_full))begin
                    if (register_array_write_rst)begin
                        register_array[register_array_write_addr_bit][(4'd9-register_array_write_addr_index)*dw-1 -:dw] <= 'b0;
                    end
                    else begin
                        register_array[register_array_write_addr_bit][(4'd9-register_array_write_addr_index)*dw-1 -:dw] <= register_array_write_data;
                    end
                end
            end
            //right_cnn
            else if (fsm_cstate_addr==7'b0000100)begin
                if (gen_addr_req)begin
                    register_array[register_array_write_addr_bit][(4'd9-'d0)*dw-1 -:dw] <= register_array[register_array_write_addr_bit][(4'd9-'d1)*dw-1 -:dw];
                    register_array[register_array_write_addr_bit][(4'd9-'d1)*dw-1 -:dw] <= register_array[register_array_write_addr_bit][(4'd9-'d2)*dw-1 -:dw];
                    register_array[register_array_write_addr_bit][(4'd9-'d3)*dw-1 -:dw] <= register_array[register_array_write_addr_bit][(4'd9-'d4)*dw-1 -:dw];
                    register_array[register_array_write_addr_bit][(4'd9-'d4)*dw-1 -:dw] <= register_array[register_array_write_addr_bit][(4'd9-'d5)*dw-1 -:dw];
                    register_array[register_array_write_addr_bit][(4'd9-'d6)*dw-1 -:dw] <= register_array[register_array_write_addr_bit][(4'd9-'d7)*dw-1 -:dw];
                    register_array[register_array_write_addr_bit][(4'd9-'d7)*dw-1 -:dw] <= register_array[register_array_write_addr_bit][(4'd9-'d8)*dw-1 -:dw];
                    
                end
                else if (register_array_write_enable & (~register_array_full))begin
                    if (register_array_write_rst)begin
                        register_array[register_array_write_addr_bit][(4'd9-register_array_write_addr_index)*dw-1 -:dw] <= 'b0;
                    end
                    else begin
                        register_array[register_array_write_addr_bit][(4'd9-register_array_write_addr_index)*dw-1 -:dw] <= register_array_write_data;
                    end
                end
            end
            //down1_cnn or down2_cnn
            else if ( (fsm_cstate_addr==7'b0001000)||(fsm_cstate_addr==7'b0100000) )begin
                if (gen_addr_req)begin
                    register_array[register_array_write_addr_bit][(4'd9-'d0)*dw-1 -:dw] <= register_array[register_array_write_addr_bit][(4'd9-'d3)*dw-1 -:dw];
                    register_array[register_array_write_addr_bit][(4'd9-'d1)*dw-1 -:dw] <= register_array[register_array_write_addr_bit][(4'd9-'d4)*dw-1 -:dw];
                    register_array[register_array_write_addr_bit][(4'd9-'d2)*dw-1 -:dw] <= register_array[register_array_write_addr_bit][(4'd9-'d5)*dw-1 -:dw];
                    register_array[register_array_write_addr_bit][(4'd9-'d3)*dw-1 -:dw] <= register_array[register_array_write_addr_bit][(4'd9-'d6)*dw-1 -:dw];
                    register_array[register_array_write_addr_bit][(4'd9-'d4)*dw-1 -:dw] <= register_array[register_array_write_addr_bit][(4'd9-'d7)*dw-1 -:dw];
                    register_array[register_array_write_addr_bit][(4'd9-'d5)*dw-1 -:dw] <= register_array[register_array_write_addr_bit][(4'd9-'d8)*dw-1 -:dw];
                    
                end
                else if (register_array_write_enable & (~register_array_full))begin
                    if (register_array_write_rst)begin
                        register_array[register_array_write_addr_bit][(4'd9-register_array_write_addr_index)*dw-1 -:dw] <= 'b0;
                    end
                    else begin
                        register_array[register_array_write_addr_bit][(4'd9-register_array_write_addr_index)*dw-1 -:dw] <= register_array_write_data;
                    end
                end
            end
            //left_cnn
            else if (fsm_cstate_addr==7'b0010000)begin
                if (gen_addr_req)begin
                    register_array[register_array_write_addr_bit][(4'd9-'d1)*dw-1 -:dw] <= register_array[register_array_write_addr_bit][(4'd9-'d0)*dw-1 -:dw];
                    register_array[register_array_write_addr_bit][(4'd9-'d2)*dw-1 -:dw] <= register_array[register_array_write_addr_bit][(4'd9-'d1)*dw-1 -:dw];
                    register_array[register_array_write_addr_bit][(4'd9-'d4)*dw-1 -:dw] <= register_array[register_array_write_addr_bit][(4'd9-'d3)*dw-1 -:dw];
                    register_array[register_array_write_addr_bit][(4'd9-'d5)*dw-1 -:dw] <= register_array[register_array_write_addr_bit][(4'd9-'d4)*dw-1 -:dw];
                    register_array[register_array_write_addr_bit][(4'd9-'d7)*dw-1 -:dw] <= register_array[register_array_write_addr_bit][(4'd9-'d6)*dw-1 -:dw];
                    register_array[register_array_write_addr_bit][(4'd9-'d8)*dw-1 -:dw] <= register_array[register_array_write_addr_bit][(4'd9-'d7)*dw-1 -:dw];
                    
                end
                else if (register_array_write_enable & (~register_array_full))begin
                    if (register_array_write_rst)begin
                        register_array[register_array_write_addr_bit][(4'd9-register_array_write_addr_index)*dw-1 -:dw] <= 'b0;
                    end
                    else begin
                        register_array[register_array_write_addr_bit][(4'd9-register_array_write_addr_index)*dw-1 -:dw] <= register_array_write_data;
                    end
                end
            end

            
        end
    end
    assign register_array_read_data = s_register_array_out;

`endif

endmodule