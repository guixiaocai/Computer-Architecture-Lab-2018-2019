module cpu_axi_interface(
    input          clk,
    input          resetn,
    
    //inst sram-like 
    input          inst_req,     //master -> slave
    input          inst_wr,      //master -> slave
    input   [ 1:0] inst_size,    //master -> slave
    input   [31:0] inst_addr,    //master -> slave
    input   [31:0] inst_wdata,   //master -> slave
    output  [31:0] inst_rdata,   //master -> slave
    output         inst_addr_ok, //master -> slave
    output         inst_data_ok, //master -> slave
    
    //data sram-like 
    input          data_req,     //master -> slave
    input          data_wr,      //master -> slave
    input   [ 1:0] data_size,    //master -> slave
    input   [31:0] data_addr,    //master -> slave
    input   [31:0] data_wdata,   //master -> slave
    output  [31:0] data_rdata,   //master -> slave
    output         data_addr_ok, //master -> slave
    output         data_data_ok, //master -> slave

    //axi
    //ar
    output  [ 3:0] arid,         //master -> slave
    output  [31:0] araddr,       //master -> slave
    output  [ 7:0] arlen,        //1'b0
    output  [ 2:0] arsize,       //master -> slave
    output  [ 1:0] arburst,      //2'b1
    output  [ 1:0] arlock,       //1'b0
    output  [ 3:0] arcache,      //1'b0
    output  [ 2:0] arprot,       //1'b0
    output         arvalid,      //master -> slave
    input          arready,      //slave -> master
    //r
    input   [ 3:0] rid,          //slave -> master
    input   [31:0] rdata,        //slave -> master
    input   [ 1:0] rresp,        //Ignore
    input          rlast,        //Ignore
    input          rvalid,       //slave -> master
    output         rready,       //master -> slave
    //aw
    output  [ 3:0] awid,         //master -> slave
    output  [31:0] awaddr,       //master -> slave
    output  [ 7:0] awlen,        //1'b0
    output  [ 2:0] awsize,       //master -> slave
    output  [ 1:0] awburst,      //2'b1
    output  [ 1:0] awlock,       //1'b0
    output  [ 3:0] awcache,      //1'b0
    output  [ 2:0] awprot,       //1'b0
    output         awvalid,      //master -> slave
    input          awready,      //slave -> master
    //w
    output  [ 3:0] wid,          //1'b1
    output  [31:0] wdata,        //master -> slave
    output  [ 3:0] wstrb,        //master -> slave
    output         wlast,        //1'b1
    output         wvalid,       //master -> slave
    input          wready,       //slave -> master
    //b
    input   [ 3:0] bid,          //Ignore
    input   [ 1:0] bresp,        //Ignore
    input          bvalid,       //slave -> master
    output         bready        //master -> slave
);
//  STATE REG
reg is_req_data;
reg is_req_inst;
reg is_req_write;
reg raddr_arrived;
reg waddr_arrived;
reg wdata_arrived;

//  DATA REG
reg [ 1:0] size_i;
reg [31:0] addr_i;
reg [31:0] wdata_i;

wire is_finished; 
 
always @(posedge clk) begin
  if(!resetn) begin
  	is_req_data     <= 1'b0;
  	is_req_inst     <= 1'b0;
  	is_req_write    <= 1'b0;
  	raddr_arrived   <= 1'b0;
  	waddr_arrived   <= 1'b0;
  	wdata_arrived   <= 1'b0;
  	addr_i          <= 1'b0;
  	wdata_i         <= 1'b0;
  	size_i          <= 1'b0;
  end
  else begin
     //  is_req_inst
    if( inst_req && !is_req_inst )
      is_req_inst   <= 1'b1;
      
  	//  is_req_data
  	if( data_req && !is_req_data )
  	  is_req_data   <= 1'b1;

  	//  raddr_arrived
  	if( arvalid && arready )
  	  raddr_arrived <= 1'b1;
  	  
  	//  waddr_arrived
  	if( awvalid && awready )
  	  waddr_arrived <= 1'b1;
  
  	//  wdata_arrived
  	if( wvalid && wready )
  	  wdata_arrived <= 1'b1;

    if(is_finished) begin
      is_req_inst   <= 1'b0;
      is_req_data   <= 1'b0;
      raddr_arrived <= 1'b0;
      waddr_arrived <= 1'b0;
      wdata_arrived <= 1'b0;
    end

  	//  is_req_write  addr_i  wdata_i  size_i
  	if( data_req && data_addr_ok ) begin         // from cpu to 
  	  is_req_write  <= data_wr;                  // First service data_req
  	  addr_i        <= data_addr;
  	  wdata_i       <= data_wdata;
  	  size_i        <= data_size;
  	end
  	else if( inst_req && inst_addr_ok ) begin
  	  is_req_write  <= inst_wr;
      addr_i        <= inst_addr;
      wdata_i       <= inst_wdata;
      size_i        <= inst_size;
    end
  end
end

assign is_finished = (raddr_arrived && rvalid && rready && (arid == rid) ) || // Address arrived & data valid & ready & aid = id
                     (waddr_arrived && bvalid && bready && (awid == wid) ) ;  

//###   cpu->cpu_axi_interface   ###
//###   inst sram-like   ###
assign inst_rdata   = rdata;
assign inst_addr_ok =!is_req_data && !is_req_inst && !data_req && inst_req;
assign inst_data_ok = is_req_inst &&  is_finished && !data_req ;

//###   data sram-like   ###
assign data_rdata   = rdata;
assign data_addr_ok =!is_req_data && !is_req_inst && data_req;
assign data_data_ok = is_req_data &&  is_finished ; 

//###   cpu_axi_interface->RAM   ###
//###   Addr_Read   ###
assign arid         = (is_req_data && !is_req_write)? 4'b00:  // Data
                      (is_req_inst && !is_req_write)? 4'b01:  // Inst
                                                      4'b10;  // No sense
assign araddr       = addr_i;
assign arlen        = 8'b0;
assign arsize       = size_i;
assign arburst      = 2'b1;
assign arlock       = 2'b0;
assign arcache      = 4'b0;
assign arprot       = 3'b0;
assign arvalid      = (is_req_inst || is_req_data) && !is_req_write && !raddr_arrived;  // is requiring && not write && Addr's not arrived

//###   Data_Read   ###
assign rready       = 1'b1;

//###   Addr_Write   ###
assign awid         = 4'b0;
assign awaddr       = addr_i;
assign awlen        = 8'b0;
assign awsize       = size_i;
assign awburst      = 2'b1;
assign awlock       = 2'b0;
assign awcache      = 4'b0;
assign awprot       = 3'b0;
assign awvalid      = (is_req_inst || is_req_data) &&  is_req_write && !waddr_arrived;  // is requiring &&     write && Addr's not arrived

//###   Data_Write   ###
assign wid          = 4'b0;
assign wdata        = wdata_i;
assign wstrb        = (size_i == 2'b00 && addr_i[1:0] == 2'b00)?  4'b0001:
                      (size_i == 2'b00 && addr_i[1:0] == 2'b01)?  4'b0010:
                      (size_i == 2'b00 && addr_i[1:0] == 2'b10)?  4'b0100:
                      (size_i == 2'b00 && addr_i[1:0] == 2'b11)?  4'b1000:
                      (size_i == 2'b01 && addr_i[1:0] == 2'b00)?  4'b0011:
                      (size_i == 2'b01 && addr_i[1:0] == 2'b10)?  4'b1100:
                      (size_i == 2'b10 && addr_i[1:0] == 2'b00)?  4'b1111:
                                                                  4'b0000;
assign wlast        = 1'b1;
assign wvalid       = (is_req_inst || is_req_data) &&  is_req_write && !wdata_arrived;  // is requiring &&     write && Data's not arrived

//###   b   ###
assign bready       = 1'b1;
endmodule