`timescale 1ns / 1ps

import axi_vip_pkg::*;
import design_1_axi_vip_0_0_pkg::*;

module axilite_master_tb();
//
xil_axi_uint slv_mem_agent_verbosity = 0;
design_1_axi_vip_0_0_slv_mem_t slv_mem_agent;

//
reg aclk;
reg aresetn;
wire aresetn_out;
//


`define BYTE_SIZE 8
`define ADDR_W 32
`define DATA_W 64
`define STRB_SIZE (`DATA_W/`BYTE_SIZE)

reg  [`ADDR_W-1:0] u_addr [0:9] = 
{
    'h10000000, //0
    'h10000040, //0
    'h10000080, //15
    'h10000C00, //0
    'h10000C40, //0
    'h10000C80, //0
    'h20000CC0, //15
    'h300010C0, //15
    'h30001500, //0
    'h30001540  //0
};

reg  [3:0]  u_b_len [0:9] =
{
'h0,
'h0,
'd15,
'h0,
'h0,
'h0,
'd15,
'd15,
'h0,
'h0
};

bit  [`DATA_W-1:0] u_data_in [0:9] =
{
'hF8F4F2F1,
'h87654321,
'h0000000A,
'h12345678,
'h08060402,
'h07050301,
'h1000000A,
'hF0A0E0B0,
'hBADCAFEEBADCAFEE,
'hDEADBEEFDEADBEEF
};

bit  [`DATA_W-1:0] u_data_out [0:54];

bit  [`DATA_W-1:0] cmp_data_diff;
bit  [`DATA_W-1:0] strb_val;
bit  [`DATA_W-1:0] strb_data_in, strb_data_out;


reg   [7:0] w_strb [0:9] =
{
'b11111111,
'b11111111,
'b11111111,
'b11111111,
'b11111111,
'b11111111,
'b00001111,
'b11110000,
'b00000001,
'b10101010
};

reg         user_start;
wire        user_start_ack;

wire        user_free;
wire [1:0]  user_status;

logic fifo_empty;
logic fifo_full;
logic resp_pop_ready;
//

reg  [`ADDR_W-1:0] user_addr_in;
bit  [`DATA_W-1:0] user_data_in;
bit  [`DATA_W-1:0] user_data_out;

logic resp_pop_req;
logic resp_pop_ack;
logic resp_pop_struct_op;
logic [`ADDR_W-1:0] resp_pop_struct_address;

reg         user_data_out_en;
reg  [7:0]  user_w_strb;
int         running_index;
//
reg axi_ready;
//
reg user_w_r;
//
reg compare_w_r_arrays;
int cmp_it;
longint current_addr;
//
reg resp_pop_pulse;

integer file, i;
//

initial
begin
    axi_ready = 0;
    slv_mem_agent = new("slave vip agent",d1w0.design_1_i.axi_vip_0.inst.IF);
    slv_mem_agent.set_agent_tag("Slave VIP");
    slv_mem_agent.set_verbosity(slv_mem_agent_verbosity);
    slv_mem_agent.start_slave();
    //slv_mem_agent.mem_model.pre_load_mem("compile.sh", 0);
    //slv_mem_agent.mem_model.pre_load_mem("vip_mem_out.mem", 0);
    //slv_mem_agent.mem_model.set_mem_depth(1024);
    
    axi_ready = 1;
end

initial
begin
    aclk = 0;
    aresetn = 0;
    user_addr_in = 'h0;
    user_data_in = 'h0;
    user_w_strb = 'h0;
    user_start = 'h0;
    user_w_r = 'h0;
    compare_w_r_arrays = 0;
    resp_pop_req = 0;
end

always
begin
    #8ns aclk = ~aclk;
end

initial
begin
    wait(axi_ready);
    aresetn = 0;
    #1us;
    @(posedge aclk)
    aresetn = 1;
    #5us;
    
    #10us;

//AXI WRITES    
    user_start      = 1'd0;
    
    //#5ms;
    @(posedge aclk);
    
    fork
        begin
            for(int i = 0; i < 10; i++)
            begin
                wait(~fifo_full);
                @(posedge aclk);
                
                user_addr_in        = u_addr[i];
                user_w_strb         = w_strb[i];
                user_data_in        = u_data_in[i];
                user_start          <= 1'd1;
                
                wait(user_start_ack);
                //@(posedge aclk);
                
                user_start          <= 1'd0;
                
                @(posedge aclk);
            end
        end
        
        begin
            for(int b = 0; b < 10; b++)
            begin
                wait(resp_pop_ready);
                @(posedge aclk);
                
                resp_pop_req <= 1;
                
                wait(resp_pop_ack);
                
                resp_pop_req <= 1'd0;
                
                @(posedge aclk);
            end
        end
    join
    #5us; 
    
//AXI READS

    @(posedge aclk);
    user_start      = 1'd0;
    user_w_r = 'h1;
    @(posedge aclk);

    fork
        begin
            for(int a = 0; a < 10; a++)
            begin
                wait(~fifo_full);
                @(posedge aclk);
                
                user_addr_in        <= u_addr[a];
                user_start          <= 1'd1;
                
                wait(user_start_ack);
                
                user_start          <= 1'd0;
                
                @(posedge aclk);
            end
        end
        
        begin
            int c = 0;
            
            //for(int c = 0; c < 10; c++)
            while(c < 10)
            begin
                wait(resp_pop_ready);
                @(posedge aclk);
                
                resp_pop_req <= 1;
                
                wait(resp_pop_pulse); // realistically this will require a dff with an enable to store this, if using a cpu this is switched too fast
                //wait(resp_pop_ack);
                
                u_data_out[c] = user_data_out;
                
                wait(resp_pop_ack);
                @(posedge aclk);
                resp_pop_req  <= 1'd0;
                
                @(posedge aclk);
                c++;
            end
        end
    join

//////////////////////////////////////////////////////////////////////////////////    

    #10us;
    
    current_addr = 0;

    for(cmp_it = 0; cmp_it < 10; cmp_it++)
    begin
    
        current_addr = u_addr[cmp_it];
        strb_val = 'd0;
        
        for(int y = `STRB_SIZE; y >= 0; y--)
        begin
            strb_val = (strb_val << 8) | ((w_strb[cmp_it][y]) ? 8'hFF : 8'h0);
        end
        
        //current_addr = current_addr + ((`DATA_W)*i);
        strb_data_in = u_data_in[cmp_it] & strb_val;
        strb_data_out = u_data_out[cmp_it] & strb_val;
        cmp_data_diff = (strb_data_in) ^ (strb_data_out);
            
        if(|cmp_data_diff)
        begin
            $display("ADDRESS:0x%X, DATA WRITTEN:0x%X -> DATA WRITTEN w/ STROBE(0b%b): 0x%X, DATA READ: 0x%X, NOT EQUAL", current_addr, u_data_in[cmp_it], w_strb[cmp_it], strb_data_in, strb_data_out);
        end
        
        else
        begin
            $display("ADDRESS:0x%X, DATA WRITTEN:0x%X -> DATA WRITTEN w/ STROBE(0b%b): 0x%X, DATA READ: 0x%X, EQUAL", current_addr, u_data_in[cmp_it], w_strb[cmp_it], strb_data_in, strb_data_out);
        end
    end

    $finish;
end
  
design_1_wrapper d1w0(
    .aclk_0(aclk),
    .aresetn_0(aresetn),
    
    .buffer_empty_0(fifo_empty),
    .buffer_full_0(fifo_full),
    .resp_pop_ready_0(resp_pop_ready),
    
    .cmd_push_req_0(user_start),
    .cmd_push_ack_0(user_start_ack),
    .cmd_push_struct_op_0(user_w_r),
    .cmd_push_struct_address_0(user_addr_in),
    .cmd_push_struct_wdata_0(user_data_in),
    .cmd_push_struct_wstrb_0(user_w_strb),
    
    .resp_pop_req_0(resp_pop_req),
    .resp_pop_ack_0(resp_pop_ack),
    .resp_pop_struct_op_0(resp_pop_struct_op),
    .resp_pop_struct_address_0(resp_pop_struct_address),
    .resp_pop_struct_rdata_0(user_data_out),
    .resp_pop_struct_status_0(user_status),
    .resp_pop_req_pulse_0(resp_pop_pulse)
    );

endmodule
