`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/07/2025 01:24:56 AM
// Design Name: 
// Module Name: ringbuffer_ctl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// CPU CMD RINGBUFFER:
    // 1. input to CMD RINGBUFFER + posedge pulse req
    // 2. output CMD RINGBUFFER to PL on req
// PL RESP RINGBUFFER:
    // 1. input to RESP RINGBUFFER from PL on req
    // 2. output RESP RINGBUFFER to CPU + posedge pulse req

module ringbuffer_ctl #(
                    parameter NUM_ENTRIES,
                    parameter CMD_W,
                    parameter RESP_W
                    )
(
        input wire clk,
        input wire resetn,
    
        // INFO: making this easy to follow;
        // - entries increased by number of commands pushed in
        // - entries reduced when response is popped out
        output wire buffer_full,
        output wire buffer_empty,
        output wire resp_pop_ready,
    
    // CMD pipe
        // CPU side (CMD in)
        input wire              cmd_push_req, // rising pulse required; keep it high until you see ack
        input [(CMD_W-1):0]     cmd_push_struct,
        output wire             cmd_push_ack,
        output wire             cmd_push_req_pulse,
 
        // PL side (CMD out)
        input wire              cmd_pop_req, // rising pulse required; keep it high until you see ack
        output [(CMD_W-1):0]    cmd_pop_struct,
        output wire             cmd_pop_ack,
        output wire             cmd_pop_req_pulse,
    
    // RESP pipe
        // PL side (RESP in)
        input wire              resp_push_req, // rising pulse required; keep it high until you see ack
        input [(RESP_W-1):0]    resp_push_struct,
        output wire             resp_push_ack,
        output wire             resp_push_req_pulse,

        // CPU side (RESP out)
        input wire              resp_pop_req, // rising pulse required; keep it high until you see ack
        output [(RESP_W-1):0]   resp_pop_struct,
        output wire             resp_pop_ack,
        output wire             resp_pop_req_pulse
    );
    
    wire cmd_buffer_full;
    wire cmd_buffer_empty;
    wire resp_buffer_full;
    wire resp_buffer_empty;
    
    // CMD push
    req_pulse_ack cmd_push_req_ack (
        .clk(clk),
        .rstn(resetn),
        .req(cmd_push_req),
        .req_en(~cmd_buffer_full),
        .req_pulse_out(cmd_push_req_pulse),
        .ack(cmd_push_ack)
    );
    
    // CMD pop
    req_pulse_ack cmd_pop_req_ack (
        .clk(clk),
        .rstn(resetn),
        .req(cmd_pop_req),
        .req_en(~cmd_buffer_empty),
        .req_pulse_out(cmd_pop_req_pulse),
        .ack(cmd_pop_ack)
    );
    
    // RESP push
    req_pulse_ack resp_push_req_ack (
        .clk(clk),
        .rstn(resetn),
        .req(resp_push_req),
        .req_en(~resp_buffer_full),
        .req_pulse_out(resp_push_req_pulse),
        .ack(resp_push_ack)
    );
    
    // RESP pop
    req_pulse_ack resp_pop_req_ack (
        .clk(clk),
        .rstn(resetn),
        .req(resp_pop_req),
        .req_en(~resp_buffer_empty),
        .req_pulse_out(resp_pop_req_pulse),
        .ack(resp_pop_ack)
    );
    
    ringbuffer # (
        .NUM_ENTRIES(NUM_ENTRIES),
        .DATA_W(CMD_W)
    ) cmd_ringbuffer (
    .clk(clk),
    .resetn(resetn),
    .wr_en(cmd_push_req_pulse),
    .rd_en(cmd_pop_req_pulse),
    .din(cmd_push_struct),
    .dout(cmd_pop_struct),
    .full(cmd_buffer_full),
    .empty(cmd_buffer_empty)
    );
    
    ringbuffer # (
        .NUM_ENTRIES(NUM_ENTRIES),
        .DATA_W(RESP_W)
    ) resp_ringbuffer (
    .clk(clk),
    .resetn(resetn),
    .wr_en(resp_push_req_pulse),
    .rd_en(resp_pop_req_pulse),
    .din(resp_push_struct),
    .dout(resp_pop_struct),
    .full(resp_buffer_full),
    .empty(resp_buffer_empty)
    );
    
    assign buffer_full = (cmd_buffer_full || resp_buffer_full);
    assign buffer_empty = (cmd_buffer_empty && resp_buffer_empty);
    
    assign resp_pop_ready = ~resp_buffer_empty;
endmodule
