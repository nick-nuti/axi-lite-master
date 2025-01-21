
module ringbuffer_v_to_sv #(
    parameter NUM_ENTRIES=6,
    parameter ADDR_W=32,
    parameter DATA_W=64,
    parameter CMD_RINGBUFFER_TYPE_WIDTH = 1 + ADDR_W + DATA_W + (DATA_W / 8),
    parameter RESP_RINGBUFFER_TYPE_WIDTH = 1 + ADDR_W + DATA_W + 2
)(
        input wire clk,
        input wire resetn,
        output wire buffer_full,
        output wire buffer_empty,
        output wire resp_pop_ready,
    
    // CMD pipe
        // CPU side (CMD in)
        input wire              cmd_push_req, // rising pulse required; keep it high until you see ack
        // struct
        input wire                  cmd_push_struct_op,
        input wire [ADDR_W-1:0]     cmd_push_struct_address,
        input wire [DATA_W-1:0]     cmd_push_struct_wdata,
        input wire [DATA_W/8-1:0]   cmd_push_struct_wstrb,
        //  struct
        output wire                 cmd_push_ack,
        output wire                 cmd_push_req_pulse,
        
        // PL side (CMD out)
        input wire              cmd_pop_req, // rising pulse required; keep it high until you see ack        
        //  struct
        output wire                  cmd_pop_struct_op,
        output wire [ADDR_W-1:0]     cmd_pop_struct_address,
        output wire [DATA_W-1:0]     cmd_pop_struct_wdata,
        output wire [DATA_W/8-1:0]   cmd_pop_struct_wstrb,
        //  struct
        output wire                  cmd_pop_ack,
        output wire                  cmd_pop_req_pulse,
    
    // RESP pipe
        // PL side (RESP in)
        input wire              resp_push_req, // rising pulse required; keep it high until you see ack
        // struct
        input wire                 resp_push_struct_op,
        input wire [ADDR_W-1:0]    resp_push_struct_address,
        input wire [DATA_W-1:0]    resp_push_struct_rdata,
        input wire [2-1:0]         resp_push_struct_status,
        // struct
        output wire                resp_push_ack,
        output wire             resp_push_req_pulse,

        // CPU side (RESP out)
        input wire              resp_pop_req, // rising pulse required; keep it high until you see ack
        // struct
        output wire                 resp_pop_struct_op,
        output wire [ADDR_W-1:0]    resp_pop_struct_address,
        output wire [DATA_W-1:0]    resp_pop_struct_rdata,
        output wire [2-1:0]         resp_pop_struct_status,
        // struct
        output wire                 resp_pop_ack,
        output wire             resp_pop_req_pulse
    );
    
    ringbuffer_ctl #(
    .NUM_ENTRIES(NUM_ENTRIES),
    .CMD_W(CMD_RINGBUFFER_TYPE_WIDTH),
    .RESP_W(RESP_RINGBUFFER_TYPE_WIDTH)
    ) ringbuffer_vtosv0 (
        .clk(clk),
        .resetn(resetn),

        .buffer_full(buffer_full),
        .buffer_empty(buffer_empty),
        .resp_pop_ready(resp_pop_ready),
    
        .cmd_push_req(cmd_push_req),
        .cmd_push_struct({cmd_push_struct_op,cmd_push_struct_address,cmd_push_struct_wdata,cmd_push_struct_wstrb}), //input CMD_RINGBUFFER_TYPE
        .cmd_push_ack(cmd_push_ack),
        .cmd_push_req_pulse(cmd_push_req_pulse),

        .cmd_pop_req(cmd_pop_req),
        .cmd_pop_struct({cmd_pop_struct_op,cmd_pop_struct_address,cmd_pop_struct_wdata,cmd_pop_struct_wstrb}), //output CMD_RINGBUFFER_TYPE
        .cmd_pop_ack(cmd_pop_ack),
        .cmd_pop_req_pulse(cmd_pop_req_pulse),
    
        .resp_push_req(resp_push_req),
        .resp_push_struct({resp_push_struct_op,resp_push_struct_address,resp_push_struct_rdata,resp_push_struct_status}), //input RESP_RINGBUFFER_TYPE
        .resp_push_ack(resp_push_ack),
        .resp_push_req_pulse(resp_push_req_pulse),

        .resp_pop_req(resp_pop_req),
        .resp_pop_struct({resp_pop_struct_op,resp_pop_struct_address,resp_pop_struct_rdata,resp_pop_struct_status}), // output RESP_RINGBUFFER_TYPE
        .resp_pop_ack(resp_pop_ack),
        .resp_pop_req_pulse(resp_pop_req_pulse)
    );
endmodule
