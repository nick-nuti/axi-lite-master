

module axilite_master #(
    parameter ADDR_W=32,
    parameter DATA_W=64,
    parameter FLOP_READ_DATA=0,
    parameter USER_START_HAS_PULSE_CONTROL=0
)
(
  /**************** Write Address Channel Signals ****************/
  output reg [ADDR_W-1:0]              m_axi_awaddr, // address (done)
  output reg [3-1:0]                   m_axi_awprot = 3'b000, // protection - privilege and securit level of transaction
  output reg                           m_axi_awvalid, // (done)
  input  wire                          m_axi_awready, // (done)
  /**************** Write Data Channel Signals ****************/
  output reg [DATA_W-1:0]              m_axi_wdata, // (done)
  output reg [DATA_W/8-1:0]            m_axi_wstrb, // (done)
  output reg                           m_axi_wvalid, // set to 1 when data is ready to be transferred (done)
  input  wire                          m_axi_wready, // (done)
  /**************** Write Response Channel Signals ****************/
  input  wire [2-1:0]                  m_axi_bresp, // (done) write response - status of the write transaction (00 = okay, 01 = exokay, 10 = slverr, 11 = decerr)
  input  wire                          m_axi_bvalid, // (done) write response valid - 0 = response not valid, 1 = response is valid
  output reg                           m_axi_bready, // (done) write response ready - 0 = not ready, 1 = ready
  /**************** Read Address Channel Signals ****************/
  output reg [ADDR_W-1:0]              m_axi_araddr, // address
  output reg [3-1:0]                   m_axi_arprot = 3'b000, // protection - privilege and securit level of transaction
  output reg                           m_axi_arvalid, // 
  input  wire                          m_axi_arready, // 
  /**************** Read Data Channel Signals ****************/
  output reg                           m_axi_rready, // read ready - 0 = not ready, 1 = ready
  input  wire [DATA_W-1:0]             m_axi_rdata, // 
  input  wire                          m_axi_rvalid, // read response valid - 0 = response not valid, 1 = response is valid
  /**************** Read Response Channel Signals ****************/
  input  wire [2-1:0]                  m_axi_rresp, // read response - status of the read transaction (00 = okay, 01 = exokay, 10 = slverr, 11 = decerr)
  /**************** System Signals ****************/
  input wire                           aclk,
  input wire                           aresetn,
  /**************** User Control Signals ****************/
  input  wire                          user_start,
  input  wire                          user_w_r, // 0 = write, 1 = read
  input  wire [DATA_W/8-1:0]           user_data_strb,
  input  wire [DATA_W-1:0]             user_data_in,
  input  wire [ADDR_W-1:0]             user_addr_in,
  output reg                          user_free,
  output reg  [1:0]                   user_status,
  output reg  [DATA_W-1:0]            user_data_out,
  output reg                          user_data_out_en
);

// AXI FSM ---------------------------------------------------
    localparam IDLE             = 3'b000;
    localparam WRITE            = 3'b001;
    localparam WRITE_RESPONSE   = 3'b010;
    localparam READ_RESPONSE    = 3'b011;
    //localparam DEACTIVATE_START = 3'b100;
       
    reg [2:0] axi_cs, axi_ns;
   
    always @ (posedge aclk or negedge aresetn)
    begin
        if(~aresetn)
        begin
            axi_cs <= IDLE;
        end
       
        else
        begin
            axi_cs <= axi_ns;
        end
    end
    
    generate
        if(USER_START_HAS_PULSE_CONTROL)
        begin
            always @ (*)
            begin
                case(axi_cs)
                IDLE:
                begin
                    if(m_axi_awready & user_start & ~user_w_r)
                    begin
                        axi_ns = WRITE;
                    end
        
                    else if(m_axi_arready & user_start & user_w_r)
                    begin
                        axi_ns = READ_RESPONSE;
                    end
                   
                    else
                    begin
                        axi_ns = IDLE;
                    end
                end
               
                WRITE:
                begin
                    if(m_axi_wready)
                    begin
                        axi_ns = WRITE_RESPONSE;
                    end
                   
                    else
                    begin
                        axi_ns = WRITE;
                    end
                end
               
                WRITE_RESPONSE:
                begin
                    if(m_axi_bvalid)
                    begin
                        axi_ns = IDLE;
                    end
                    else axi_ns = WRITE_RESPONSE;
                end
        
                READ_RESPONSE:
                begin
                    if(m_axi_rvalid)
                    begin
                        axi_ns = IDLE;
                    end
                   
                    else
                    begin
                        axi_ns = READ_RESPONSE;
                    end
                end
               
                default: axi_ns = IDLE;
                endcase
            end
        end
        
        else
        begin
            localparam DEACTIVATE_START = 3'b100;
        
            always @ (*)
            begin
                case(axi_cs)
                IDLE:
                begin
                    if(m_axi_awready & user_start & ~user_w_r)
                    begin
                        axi_ns = WRITE;
                    end
        
                    else if(m_axi_arready & user_start & user_w_r)
                    begin
                        axi_ns = READ_RESPONSE;
                    end
                   
                    else
                    begin
                        axi_ns = IDLE;
                    end
                end
               
                WRITE:
                begin
                    if(m_axi_wready)
                    begin
                        axi_ns = WRITE_RESPONSE;
                    end
                   
                    else
                    begin
                        axi_ns = WRITE;
                    end
                end
               
                WRITE_RESPONSE:
                begin
                    if(m_axi_bvalid)
                    begin
                        if(user_start) axi_ns = DEACTIVATE_START;
                        else axi_ns = IDLE;
                    end
                    else axi_ns = WRITE_RESPONSE;
                end
        
                READ_RESPONSE:
                begin
                    if(m_axi_rvalid)
                    begin
                        if(user_start) axi_ns = DEACTIVATE_START;
                        else axi_ns = IDLE;
                    end
                   
                    else
                    begin
                        axi_ns = READ_RESPONSE;
                    end
                end
                
                DEACTIVATE_START:
                begin
                    if(user_start) axi_ns = DEACTIVATE_START;
                    else axi_ns = IDLE;
                end
               
                default: axi_ns = IDLE;
                endcase
            end
        end
    endgenerate

// AXI WRITE ---------------------------------------------------
    always @ (*)
    begin
        m_axi_awvalid <= ((axi_cs==IDLE) && (axi_ns==WRITE)) ? 1 : 0;
        m_axi_awaddr  <= ((axi_cs==IDLE) && (axi_ns==WRITE)) ? user_addr_in : 0;
        m_axi_wvalid  <= (axi_cs==WRITE) ? 1 : 0;
        m_axi_wdata   <= (axi_cs==WRITE) ? user_data_in : 0;
        m_axi_wstrb   <= (axi_cs==WRITE) ? user_data_strb : 0;
        m_axi_bready  <= ((axi_cs == WRITE_RESPONSE)&& m_axi_bvalid) ? 1'b1 : 'h0;
    end

// AXI READ ---------------------------------------------------    
    always @ (*)
    begin
        m_axi_araddr      <= ((axi_cs==IDLE) && (axi_ns==READ_RESPONSE)) ? user_addr_in : 0;
        m_axi_arvalid     <= ((axi_cs==IDLE) && (axi_ns==READ_RESPONSE)) ? 1 : 0;
        m_axi_rready      <= (axi_cs==READ_RESPONSE) ? 1 : 0;
        //user_data_out     <= (axi_cs==READ_RESPONSE) ? m_axi_rdata : 0;
        //user_data_out_en  <= (axi_cs==READ_RESPONSE) ? m_axi_rvalid : 0;
    end
    
    generate
        if(FLOP_READ_DATA)
        begin
            always @ (posedge aclk)
            begin
                if((axi_cs==IDLE) && (axi_ns!=IDLE))
                begin
                    user_data_out     <= 0;
                    user_data_out_en  <= 0;

                    user_status       <= 0;
                end

                else if(axi_cs==WRITE_RESPONSE)
                begin
                    user_data_out_en <= m_axi_bvalid;

                    user_status <= m_axi_bresp;
                end
                
                else if(axi_cs==READ_RESPONSE)
                begin
                    user_data_out     <= m_axi_rdata;
                    user_data_out_en  <= m_axi_rvalid;

                    user_status       <= m_axi_rresp;
                end
            end
        end
        
        else
        begin
            always @ (*)
            begin
                user_data_out     <= (axi_cs==READ_RESPONSE) ? m_axi_rdata : 0;
                user_data_out_en  <= (axi_cs==READ_RESPONSE) ? m_axi_rvalid : 0;

                user_status       <= (m_axi_bvalid) ? m_axi_bresp : ((m_axi_rvalid) ? m_axi_rresp : 0);
            end
        end
    endgenerate

    always @ (*)
    begin
        user_free       = (axi_ns == IDLE) ? 1'b1 : 1'b0;
    end
// STATUS   ---------------------------------------------------
endmodule
