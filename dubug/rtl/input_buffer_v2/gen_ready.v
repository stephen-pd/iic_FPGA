module gen_ready (
    input   SYS_CLK,
    input   SYS_NRST,

    input   input_buffer_write_hsync,
    input   input_buffer_write_sop,

    input   [5:0]pic_size,
    input   padding,
    input   [3:0]mode,

    input   genraddr_end,
    //sram to reg
    input   register_array_fifo_empty,
    output  input_buffer_write_hsync_eq2,

    input   sram2reg_valid,
    output  sram2reg_ready,
    //data to inputbuffer
    input   input_buffer_write_valid,
    output  input_buffer_write_ready,
    //register_array to opu
    output  register2opu_valid,
    input   register2opu_ready
);

    reg [7:0]r_cnt_hsync;

    //sram2reg_ready
    reg sram2reg_ready_rise;
    wire sram2reg_ready_fall;
    reg r_sram2reg_ready;
    wire sram2reg_handshanke;
    reg [15:0]r_cnt_wdata;
    reg wdata_end;

    wire s_cnt_hsync_eq4;
    reg  r_genraddr_done;
    reg  r_w1bank_done;
    reg  r_wdata_done;
    //inputbuffer_ready
    wire input_buffer_write_ready_rise;
    reg  input_buffer_write_ready_fall;
    reg  r_input_buffer_write_ready;
    wire input_buffer_write_handshake;
    //register2opu_ready
    reg r_register2opu_valid;
    wire register2opu_handshanke;
    

    assign sram2reg_ready = r_sram2reg_ready;
    assign input_buffer_write_ready = r_input_buffer_write_ready;
    assign register2opu_valid = r_register2opu_valid;

    assign input_buffer_write_handshake = input_buffer_write_ready & input_buffer_write_valid;
    assign sram2reg_handshanke = sram2reg_valid & sram2reg_ready;
    assign register2opu_handshanke = register2opu_valid & register2opu_ready;

    //wdata_end
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_cnt_wdata <= 'b0;
        end
        else begin
            if (input_buffer_write_sop || wdata_end)begin
                r_cnt_wdata <= 'b0;
            end
            else if(input_buffer_write_handshake)begin
                r_cnt_wdata <= r_cnt_wdata + 1'b1;
            end
        end
    end

    

    always @(*) begin
        if (mode[3])begin
            wdata_end = (r_cnt_wdata == pic_size<<3);
        end else begin
            wdata_end = (r_cnt_hsync == pic_size+padding);
        end
    end
    //cnt_hsync
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_cnt_hsync <= 'b0;
        end
        else begin
            if (input_buffer_write_sop)begin
                r_cnt_hsync <= padding;
            end
            else if(input_buffer_write_hsync)begin
                r_cnt_hsync <= r_cnt_hsync + 1'b1;
            end
        end
    end

    assign input_buffer_write_hsync_eq2 = (r_cnt_hsync == 1'b1)&input_buffer_write_hsync;
    assign s_cnt_hsync_eq4 = (r_cnt_hsync == 'd3)&input_buffer_write_hsync;

    //genraddr_done ,w1bank_done ,wdata_done
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_genraddr_done <= 'b0;
        end 
        else begin
            if (sram2reg_handshanke)begin
                r_genraddr_done <= 'b0;
            end 
            else if(genraddr_end)begin
                r_genraddr_done <= 1'b1;
            end
        end
    end

    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_w1bank_done <= 'b0;
        end 
        else begin
            if (sram2reg_handshanke)begin
                r_w1bank_done <= 'b0;
            end 
            else if( (r_cnt_hsync>3)&(r_cnt_hsync[0]==1'b1)&input_buffer_write_hsync )begin
                r_w1bank_done <= 1'b1;
            end
        end
    end
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_wdata_done <= 'b0;
        end 
        else begin
            if (sram2reg_handshanke)begin
                r_wdata_done <= 'b0;
            end 
            else if(wdata_end)begin
                r_wdata_done <= 1'b1;
            end
        end
    end

    //sram2reg_ready
    always @(*) begin
        if (mode[3])begin
            sram2reg_ready_rise = wdata_end;
        end
        else begin
            sram2reg_ready_rise = register_array_fifo_empty&
                                  ( s_cnt_hsync_eq4 ||
                                   (r_w1bank_done&r_genraddr_done)||
                                   (r_wdata_done&r_genraddr_done));
        end
    end
    assign sram2reg_ready_fall = sram2reg_handshanke;
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_sram2reg_ready <= 'b0;
        end
        else begin
            if (sram2reg_ready_fall)begin
                r_sram2reg_ready <= 'b0;
            end
            else if(sram2reg_ready_rise)begin
                r_sram2reg_ready <= 1'b1;
            end
        end
    end
    //input_buffer_write_ready
    assign input_buffer_write_ready_rise = sram2reg_handshanke || input_buffer_write_sop;
    always @(*) begin
        if (mode[3])begin
            input_buffer_write_ready_fall = wdata_end;
        end
        else begin
            input_buffer_write_ready_fall = (s_cnt_hsync_eq4 ||
                                             ((r_cnt_hsync>'d3)&(r_cnt_hsync[0]==1'b1)&input_buffer_write_hsync) ||  
                                            wdata_end);
        end
    end

    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_input_buffer_write_ready <= 'b0;
        end
        else begin
            if (input_buffer_write_ready_rise)begin
                r_input_buffer_write_ready <= 1'b1;
            end
            else if(input_buffer_write_ready_fall)begin
                r_input_buffer_write_ready <= 1'b0;
            end
        end
    end

    //register2opu_ready
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_register2opu_valid <= 'b0;
        end else begin
            if (register2opu_handshanke)begin
                r_register2opu_valid <= 1'b0;
            end
            else if (~register_array_fifo_empty)begin
                r_register2opu_valid <= 1'b1;
            end
        end
    end


    
endmodule