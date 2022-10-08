module mux_8_1_ctrl (
    input   SYS_CLK,
    input   SYS_NRST,

    input   mux_8_1_ctrl_update,

    output  [2:0]mux_8_1_ctrl,
    output  mux_8_1_ctrl_reset
);

    reg [2:0]r_cnt_update;

    assign mux_8_1_ctrl = r_cnt_update;
    assign mux_8_1_ctrl_reset = (r_cnt_update==3'd7)&mux_8_1_ctrl_update;

    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_cnt_update <= 'b0;
        end
        else begin
            if (mux_8_1_ctrl_update)begin
                r_cnt_update <= r_cnt_update + 1'b1;
            end
        end
    end
    
endmodule