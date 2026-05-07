//////////////////////////////////ahb_bus_matrix_top.v//////////////////////
  /********************************************************************************************

  Copyright 2024 - Maven Silicon Softech Pvt Ltd.  

  www.maven-silicon.com

  All Rights Reserved.

  This source code is an unpublished work belongs to Maven Silicon Softech Pvt Ltd.
  It is not to be shared with or used by any third parties who have not enrolled for our paid 
  training courses or received any written authorization from Maven Silicon.

  Filename                :       ahb_bus_matrix_top.v   

  module Name             :       ahb_bus_matrix_top

  Description             :       Top module of AHB Bus MAtrix

  Author Name             :       K Sriguru

  Support e-mail          :       For any queries, reach out to us on "techsupport_vm@maven-silicon.com" 

  Version                 :       1.0

  *********************************************************************************************/  




  module ahb_bus_matrix_top #(parameter N=15)(
                                             input              HCLK,       // System Clock
                                             input              HRESETn,    // System Reset
                                             input  [(N*4)-1:0] REMAP,	    // REMAP input
                                             input  [N-1:0]     HSELS,      // Slave Select from AHB (1 bit for 2 ip stage)
                                             input  [(N*32)-1:0]HADDRS,     // Address bus from AHB
                                             input  [(N*32)-1:0]HWDATAS,    // Write data
                                             input  [(N*2)-1:0] HTRANSS,    // Transfer type from AHB
                                             input  [N-1:0]     HWRITES,    // Transfer direction from AHB
                                             input  [(N*3)-1:0] HSIZES,     // Transfer size from AHB
                                             input  [(N*3)-1:0] HBURSTS,    // Burst type from AHB
                                             input  [(N*4)-1:0] HPROTS,     // Protection control from AHB
                                             input  [(N*4)-1:0] HMASTERS,   // Master number from AHB
                                             input  [N-1:0]     HMASTLOCKS, // Locked Sequence  from AHB
                                             input  [(N*2)-1:0] HRESPM,     // Input to decode stage from AHB slave
                                             input  [(N*32)-1:0]HRDATAM,    // Input to decode stage from AHB slave
                                             input  [N-1:0]	HREADYOUTM, // Feedback HREADY from AHB slave to master

                                             output [N-1:0]     HREADYOUTS, // HREADYOUT input to AHB master from slave
                                             output [(N*2)-1:0] HRESPS,     // Transfer response to AHB 
                                             output [(N*32)-1:0]HRDATAS,    // read data from slave
                                             output [N-1:0]	HSELM,	    // Slave Select
                                             output [(N*32)-1:0]HADDRM,	    // Address bus
                                             output [(N*2)-1:0] HTRANSM,    // Transfer type
                                             output [N-1:0]	HWRITEM,    // Transfer direction
                                             output [(N*3)-1:0] HSIZEM,	    // Transfer size
                                             output [(N*3)-1:0] HBURSTM,    // Burst type
                                             output [(N*4)-1:0] HPROTM,	    // Protection control
                                             output [(N*4)-1:0] HMASTERM,   // Master Select
                                             output [N-1:0]	HMASTLOCKM, // iLocked Sequence
					     output [(N*32)-1:0]HWDATAM,    // Write data
					     output [N-1:0]	HREADYM	    // Master to slave
                                             );


  wire [N-1:0]       sel_ip;          // HSEL output of ip stage to op stage
  wire [(N*32)-1:0]  addr_ip;         // HADDR output of ip stage to op stage
  wire [(N*2)-1:0]   trans_ip;        // HTRANS output of ip stage to op stage
  wire [N-1:0]       write_ip;        // HWRITE output of ip stage to op stage
  wire [(N*3)-1:0]   size_ip;         // HSIZE output of ip stage to op stage
  wire [(N*3)-1:0]   burst_ip;        // HBURST output of ip stage to op stage
  wire [(N*4)-1:0]   prot_ip;         // HPROT output of ip stage to op stage
  wire [(N*4)-1:0]   master_ip;       // HMASTER output of ip stage to op stage
  wire [N-1:0]       mastlock_ip;     // HMASTLOCK output of ip stage to op stage
  wire [N-1:0]	     hreadym;

  wire [N-1:0]       active_ip;        // active_ip signal from decode stage to ip stage
  wire [N-1:0]       readyout_ip;      // HREADYOUT input from decode stage to ip stage
  wire [(N*2)-1:0]   resp_ip;          // HRESP input from decode stage to ip stage

  wire [N-1:0]       sel_out[N-1:0];   // mem to store sel_out of decode stage 
  reg  [N-1:0]       sel_op[N-1:0];    // wire for op stage from decode stage

  wire [N-1:0]       active_op[N-1:0]; // mem to store active_op of op stage
  reg  [N-1:0]	     active_dec[N-1:0];// wire for decode stage from op stage
  wire  [N-1:0]       hreadymuxm[N-1:0];       // wire for decode stage from op stage
  reg [N-1:0]       hready[N-1:0];       // wire for decode stage from op stage
  wire [N-1:0]       hreadyoutm;       // wire for output stage from decode stage

  integer a,b;

  genvar i;

  generate for(i=0;i<N;i=i+1)
    begin
      input_stage IS (.HCLK(HCLK),
	              .HRESETn(HRESETn),
		      .HSELS(HSELS[i]),                                     /////////top input
		      .HADDRS(HADDRS[((i*32)+32)-1:(i*32)]),                /////////top input
		      .HTRANSS(HTRANSS[((i*2)+2)-1:(i*2)]),                 /////////top input
		      .HWRITES(HWRITES[i]),                                 /////////top input
		      .HSIZES(HSIZES[((i*3)+3)-1:(i*3)]),                   /////////top input
		      .HBURSTS(HBURSTS[((i*3)+3)-1:(i*3)]),                 /////////top input
		      .HPROTS(HPROTS[((i*4)+4)-1:(i*4)]),                   /////////top input
		      .HMASTERS(HMASTERS[((i*4)+4)-1:(i*4)]),               /////////top input
		      .HMASTLOCKS(HMASTLOCKS[i]),                           /////////top input
		      .active_ip(active_ip[i]),                             /////////wire from decode stage
		      .readyout_ip(readyout_ip[i]),                         /////////wire from decode stage
		      .resp_ip(resp_ip[((i*2)+2)-1:(i*2)]),                 /////////wire from decode stage
		      .HREADYOUTS(HREADYOUTS[i]),                           /////////top output
		      .HRESPS(HRESPS[((i*2)+2)-1:(i*2)]),                   /////////top output
		      .sel_ip(sel_ip[i]),                                   /////////to decode stage
		      .addr_ip(addr_ip[((i*32)+32)-1:(i*32)]),              /////////to decode stage & op stage
		      .trans_ip(trans_ip[((i*2)+2)-1:(i*2)]),               /////////to decode stage & op stage
		      .write_ip(write_ip[i]),                               /////////to op stage
		      .size_ip(size_ip[((i*3)+3)-1:(i*3)]),                 /////////to op stage
		      .burst_ip(burst_ip[((i*3)+3)-1:(i*3)]),               /////////to op stage
		      .prot_ip(prot_ip[((i*4)+4)-1:(i*4)]),                 /////////to op stage
		      .master_ip(master_ip[((i*4)+4)-1:(i*4)]),             /////////to op stage
		      .mastlock_ip(mastlock_ip[i]),                         /////////to op stage
		      .HREADYM(hreadym[i])                                  /////////to decode stage
             	      );


      decode_stage#(N) DS(.HCLK(HCLK),
               	          .HRESETn(HRESETn),
  			  .remap(REMAP[((i*4)+4)-1:(i*4)]),                 /////////top input
  			  .HREADYS(hreadym[i]),                             /////////from ip stage
			  .hmaster(master_ip[((i*4)+4)-1:(i*4)]),           /////////from ip stage
			  .sel_dec(sel_ip[i]),                              /////////from ip stage
  			  .decode_addr_dec(addr_ip[((i*32)+32)-1:(i*32)]),  /////////from ip stage
  			  .trans_dec(trans_ip[((i*2)+2)-1:(i*2)]),          /////////from ip stage
  			  .hwrite(write_ip[i]),                             /////////from ip stage
  			  .active_dec(active_dec[i]),                       /////////from op stage
  			  .readyout_dec(hready[i]),                         /////////from op stage
  			  .resp_dec(HRESPM),                                /////////top input
  			  .rdata_dec(HRDATAM),                              /////////top input
  			  .sel_out(sel_out[i]),                             /////////to op stage
  			  .active_decode(active_ip[i]),                     /////////to ip stage [i]
  			  .HREADYOUTS(readyout_ip[i]),                      /////////to ip stage [i]
			  .HRESPS(resp_ip[((i*2)+2)-1:(i*2)]),              /////////to ip stage [i]
  			  .HRDATAS(HRDATAS[((i*32)+32)-1:(i*32)]),          /////////top output	
			  .HREADYIN(hreadyoutm[i])                          /////////to output stage
 		          );
			


      output_stage#(N) OS(.HCLK(HCLK),
	                  .HRESETn(HRESETn),
  			  .sel_op(sel_op[i]),                               /////////from all decode stage
  			  .addr_op(addr_ip),                                /////////from all decode stage
  			  .trans_op(trans_ip),                              /////////from all ip stage
  			  .write_op(write_ip),                              /////////from all ip stage
  			  .size_op(size_ip),                                /////////from all ip stage
  			  .burst_op(burst_ip),                              /////////from all ip stage
  			  .prot_op(prot_ip),                                /////////from all ip stage
  			  .master_op(master_ip),                            /////////from all ip stage
  			  .mastlock_op(mastlock_ip),                        /////////from all ip stage
  			  .wdata_op(HWDATAS),                               /////////from Top
  			  .HREADYOUTM(HREADYOUTM[i]),                       /////////from Top
  			  .hreadyout(hreadyoutm),                           /////////from decode stage
  			  .active_op(active_op[i]),                         /////////to decode stage
  			  .HSELM(HSELM[i]),                                 /////////top output
  			  .HADDRM(HADDRM[((i*32)+32)-1:(i*32)]),            /////////top output
  			  .HTRANSM(HTRANSM[((i*2)+2)-1:(i*2)]),             /////////top output
  			  .HWRITEM(HWRITEM[i]),                             /////////top output
  			  .HSIZEM(HSIZEM[((i*3)+3)-1:(i*3)]),               /////////top output
  			  .HBURSTM(HBURSTM[((i*3)+3)-1:(i*3)]),             /////////top output
  			  .HPROTM(HPROTM[((i*4)+4)-1:(i*4)]),               /////////top output
  			  .HMASTERM(HMASTERM[((i*4)+4)-1:(i*4)]),           /////////top output
  			  .HMASTLOCKM(HMASTLOCKM[i]),                       /////////top output
  			  .HREADYMUXM(hreadymuxm[i]),                       /////////to decode stage
  			  .HREADYMUXOUT(HREADYM[i]),                        /////////top output 
  			  .HWDATAM(HWDATAM[((i*32)+32)-1:(i*32)])           /////////top output
		          );


    end
  endgenerate

  always@(*)
    begin
      for(a=0;a<N;a=a+1)
        begin
          for(b=0;b<N;b=b+1)
	    begin
	      sel_op[a][b]=sel_out[b][a];
	      active_dec[a][b]=active_op[b][a];
	      hready[a][b]=hreadymuxm[b][a];
	    end
        end
    end




  endmodule
  
  
  ////////////////////////////input_stage.v////////////////////////
    /********************************************************************************************

  Copyright 2024 - Maven Silicon Softech Pvt Ltd.  

  www.maven-silicon.com

  All Rights Reserved.

  This source code is an unpublished work belongs to Maven Silicon Softech Pvt Ltd.
  It is not to be shared with or used by any third parties who have not enrolled for our paid 
  training courses or received any written authorization from Maven Silicon.

  Filename                :       input_stage.v   

  module Name             :       input_stage

  Description             :       Register the master data upon the slave access and send to decode stage

  Author Name             :       K Sriguru

  Support e-mail          :       For any queries, reach out to us on "techsupport_vm@maven-silicon.com" 

  Version                 :       1.0

  *********************************************************************************************/   




  module input_stage (
                      input            HCLK,            	// System Clock
                      input            HRESETn,         	// System Reset
                      input            HSELS,           	// Slave Select from AHB
                      input      [31:0]HADDRS,          	// Address bus from AHB
                      input      [1:0] HTRANSS,         	// Transfer type from AHB
                      input            HWRITES,         	// Transfer direction from AHB
                      input      [2:0] HSIZES,          	// Transfer size from AHB
                      input      [2:0] HBURSTS,         	// Burst type from AHB
                      input      [3:0] HPROTS,          	// Protection control from AHB
                      input      [3:0] HMASTERS,        	// Master number from AHB
                      input            HMASTLOCKS,      	// Locked Sequence  from AHB
                      input            active_ip,          	// active_ip signal from decode stage
                      input            readyout_ip,        	// HREADYOUT input from decode stage
                      input      [1:0] resp_ip,            	// HRESP input from decode stage

                      output reg       HREADYOUTS,	        // HREADYOUT input
                      output reg [1:0] HRESPS,          	// Transfer response to AHB    
                      output reg       sel_ip,           	// HSEL output
                      output reg [31:0]addr_ip,                 // HADDR output
                      output reg [1:0] trans_ip,                // HTRANS output
                      output reg       write_ip,                // HWRITE output
                      output reg [2:0] size_ip,                 // HSIZE output
                      output reg [2:0] burst_ip,                // HBURST output
                      output reg [3:0] prot_ip,                 // HPROT output
                      output reg [3:0] master_ip,               // HMASTER output
                      output reg       mastlock_ip,             // HMASTLOCK output
		      output reg       HREADYM
                      );


  wire         load_reg;             	// Holding register load flag
  wire         pend_tran;            	// An active transfer cannot complete
  wire         addr_valid;           	// Indicates address phase of valid transfer
  reg 	       data_valid;
  reg   [1:0]  reg_trans;            	// Registered HTRANSS
  reg   [31:0] reg_addr;             	// Registered HADDRS
  reg          reg_write;            	// Registered HWRITES
  reg 	       reg_sel;		  	// Registered HSELS
  reg   [2:0]  reg_size;             	// Registered HSIZES
  reg   [2:0]  reg_burst;            	// Registered HBURSTS
  reg   [3:0]  reg_prot;             	// Registered HPROTS
  reg   [3:0]  reg_master;           	// Registerd HMASTERS
  reg          reg_mastlock;         	// Registered HMASTLOCKS





  always@(negedge HRESETn or posedge HCLK)
    begin
      if (~HRESETn)
        begin
          reg_trans    <= 2'b00;
          reg_addr     <= 32'b0;
          reg_write    <= 1'b0 ;
          reg_size     <= 3'b000;
          reg_burst    <= 3'b000;
          reg_prot     <= 4'b0;
          reg_master   <= 4'b0000;
          reg_mastlock <= 1'b0 ;
          reg_sel      <= 1'b0;
	  HREADYOUTS   <= 1'b0;
        end
	
      else
        begin
          if(load_reg)
            begin
              reg_trans    <= HTRANSS;
              reg_addr     <= HADDRS;
              reg_write    <= HWRITES;
              reg_size     <= HSIZES;
              reg_burst    <= HBURSTS;
              reg_prot     <= HPROTS;
              reg_master   <= HMASTERS;
              reg_mastlock <= HMASTLOCKS;
              reg_sel      <= HSELS;
            end
        end
  end


  // addr_valid indicates the address phase of an active (non-BUSY/IDLE)
  // transfer to this slave port
  assign addr_valid = (HSELS & HTRANSS[1]);

  // The holding register is loaded whenever there is a transfer on the input
  // port which is validated by active signal 
  assign load_reg = (addr_valid & active_ip);

  // data_valid register
  // addr_valid indicates the data phase of an active 
  // transfer to this slave port. A valid response (HREADY, HRESP) must be
  // generated
  always@(negedge HRESETn or posedge HCLK)
  begin
    if (~HRESETn)
      data_valid <= 1'b0;

    else
      if (readyout_ip)
        data_valid  <= addr_valid;
  end

  // pend_tran indicates that an active transfer presented to this
  // slave cannot complete immediately.  

  assign pend_tran = (load_reg & (~active_ip)) ? 1'b1 :(active_ip & readyout_ip) ? 1'b0 : pend_tran;


  always@(*)
  begin
    if(~pend_tran)
      begin
        sel_ip      = HSELS;
        trans_ip    = HTRANSS;
        addr_ip     = HADDRS;
        write_ip    = HWRITES;
        size_ip     = HSIZES;
        burst_ip    = HBURSTS;
        prot_ip     = HPROTS;
        master_ip   = HMASTERS;
        mastlock_ip = HMASTLOCKS;
        HREADYM	    = readyout_ip;
      end
	
    else
      begin
        sel_ip      = reg_sel;
        trans_ip    = reg_trans;
        addr_ip     = reg_addr;
        write_ip    = reg_write;
        size_ip     = reg_size;
        burst_ip    = reg_burst;
        prot_ip     = reg_prot;
        master_ip   = reg_master;
        mastlock_ip = reg_mastlock;
        HREADYM	    = readyout_ip;
      end
  end

  always@(data_valid or pend_tran or readyout_ip or resp_ip)
  begin
    if (~data_valid)
      begin
        HREADYOUTS = readyout_ip;
        HRESPS     = 2'b00;
      end

    else if (pend_tran)
      begin
        HREADYOUTS = 1'b0;
        HRESPS     = 2'b00;
      end
      
    else
      begin
        HREADYOUTS = readyout_ip;
        HRESPS     = resp_ip;
      end
  end

  endmodule
  
  
  
  /////////////////////////////default_slave.v/////////////////////
    /********************************************************************************************

  Copyright 2024 - Maven Silicon Softech Pvt Ltd.  

  www.maven-silicon.com

  All Rights Reserved.

  This source code is an unpublished work belongs to Maven Silicon Softech Pvt Ltd.
  It is not to be shared with or used by any third parties who have not enrolled for our paid 
  training courses or received any written authorization from Maven Silicon.

  Filename                :       default_slave.v   

  module Name             :       default_slave

  Description             :       Instantiated in decode stage to act as slave when address is not found in the mapped locations 

  Author Name             :       K Sriguru

  Support e-mail          :       For any queries, reach out to us on "techsupport_vm@maven-silicon.com" 

  Version                 :       1.0

  *********************************************************************************************/   




  module default_slave (
                        // Common AHB signals
                        input         HCLK,           // AHB System Clock
                        input         HRESETn,        // AHB System Reset

                        // AHB control input signals
                        input         HSEL,           // Slave Select
                        input         HTRANS,         // Transfer type
                        input         HREADY,         // Transfer done

                        // AHB control output signals
                        output reg    HREADYOUT,      // HREADY feedback
                        output reg [1:0] HRESP        // Transfer response
		        );         



  `define RSP_OKAY    2'b00         // OKAY response
  `define RSP_ERROR   2'b01         // ERROR response
  `define RSP_RETRY   2'b10         // RETRY response
  `define RSP_SPLIT   2'b11         // SPLIT response


  wire          invalid;    	   // Set during invalid transfer
  wire          iHREADYOUT;
  wire          iHRESP;

  always@(posedge HCLK or negedge HRESETn)
    begin
      if(!HRESETn)
        begin
          HREADYOUT <= 0;
	  HRESP     <= 0;
        end

      else
        begin
          HREADYOUT <= iHREADYOUT;
	  HRESP     <= iHRESP;
        end
    end

  assign invalid = (HREADY & HSEL & HTRANS);
  assign iHREADYOUT = HSEL ? 1'b1 : 1'b0;
  assign iHRESP = invalid ? `RSP_ERROR : `RSP_OKAY;


  endmodule
  
  
  
  ////////////////////////////decode_stage.v/////////////////////////
    /********************************************************************************************

  Copyright 2024 - Maven Silicon Softech Pvt Ltd.  

  www.maven-silicon.com

  All Rights Reserved.

  This source code is an unpublished work belongs to Maven Silicon Softech Pvt Ltd.
  It is not to be shared with or used by any third parties who have not enrolled for our paid 
  training courses or received any written authorization from Maven Silicon.

  Filename                :       decode_stage.v   

  module Name             :       decode_stage

  Description             :       Decodes the address from input stage and provides slave select signal

  Author Name             :       K Sriguru

  Support e-mail          :       For any queries, reach out to us on "techsupport_vm@maven-silicon.com" 

  Version                 :       1.0

  *********************************************************************************************/  




  module decode_stage #(parameter N=15)(
                                        // Common AHB signals
                                        input               HCLK,             // System Clock
                                        input               HRESETn,          // System Reset

                                        // Internal address remapping control
                                        input   [3:0]       remap,            // Internal remap signal

                                        // Signals from the Input stage from input stage
                                        input         	    HREADYS,          // Transfer done
					input  [3:0]        hmaster,          // Hmaster value
                                        input               sel_dec,          // HSEL input
                                        input  [31:0]       decode_addr_dec,  // HADDR decoder input
                                        input   [1:0]       trans_dec,        // Input port HTRANS signal
                                        input   	    hwrite,	      // Input port from ip stage

                                        // From output stage 0
                                        input   [N-1:0]     active_dec,       // Output stage MI0 active_dec signal
                                        input   [N-1:0]     readyout_dec,     // HREADYOUT input
                                        input   [(N*2)-1:0] resp_dec,         // HRESP input
                                        input   [(N*32)-1:0]rdata_dec,        // HRDATA input

                                        // Output port selection signals
                                        output reg  [N-1:0] sel_out,          // HSEL output to o/p stage 0

                                        // Selected Output port data and control signals
                                        output reg          active_decode,    // Combinatorial active_dec O/P
                                        output reg          HREADYOUTS,       // HREADY feedback output
                                        output reg [1:0]    HRESPS,           // Transfer response
                                        output reg [31:0]   HRDATAS,          // Slave output to master
                                        output 	            HREADYIN          // hready out for read data
                                        );


  reg     [3:0] addr_out_port;     	// Address output ports
  reg     [3:0] data_out_port;     	// Data output ports

  // Default slave signals
  reg           sel_dft_slv;       	// HSEL signal
  wire          readyout_dft_slv;  	// HREADYOUT signal
  wire    [1:0] resp_dft_slv;      	// Combinatorial HRESPS signal


  default_slave DUV(
                    // Common AHB signals
                    .HCLK        (HCLK),
                    .HRESETn     (HRESETn),

                    // AHB Control signals
                    .HSEL        (sel_dft_slv),
                    .HTRANS      (trans_dec[1]),
                    .HREADY      (HREADYS),
                    .HREADYOUT   (readyout_dft_slv),
                    .HRESP       (resp_dft_slv)
	            );


  always@(decode_addr_dec or remap)
    begin
      case (remap)  
      4'd0 : begin
               if (((decode_addr_dec > 32'h00000000) & (decode_addr_dec < 32'h00001000)))
                 addr_out_port = 4'd0;  // Select Output port 0

               else if (((decode_addr_dec > 32'h00001000) & (decode_addr_dec < 32'h00002000)))
                 addr_out_port = 4'd1;  // Select Output port 1

               else if (((decode_addr_dec > 32'h00002000) & (decode_addr_dec < 32'h00003000)))
                 addr_out_port = 4'd2;  // Select Output port 2

               else if (((decode_addr_dec > 32'h00003000) & (decode_addr_dec < 32'h00004000)))
                 addr_out_port = 4'd3;  // Select Output port 3

               else if (((decode_addr_dec > 32'h00004000) & (decode_addr_dec < 32'h00005000)))
                 addr_out_port = 4'd4;  // Select Output port 4

               else if (((decode_addr_dec > 32'h00006000) & (decode_addr_dec < 32'h00007000)))
                 addr_out_port = 4'd5;  // Select Output port 5

               else if (((decode_addr_dec > 32'h00007000) & (decode_addr_dec < 32'h00008000)))
                 addr_out_port = 4'd6;  // Select Output port 6

               else if (((decode_addr_dec > 32'h00008000) & (decode_addr_dec < 32'h00009000)))
                 addr_out_port = 4'd7;  // Select Output port 7

               else if (((decode_addr_dec > 32'h00009000) & (decode_addr_dec < 32'h00010000)))
                 addr_out_port = 4'd8;  // Select Output port 8

               else if (((decode_addr_dec > 32'h00010000) & (decode_addr_dec < 32'h00020000)))
                 addr_out_port = 4'd9;  // Select Output port 9

               else if (((decode_addr_dec > 32'h00020000) & (decode_addr_dec < 32'h00030000)))
                 addr_out_port = 4'd10;  // Select Output port 10

               else if (((decode_addr_dec > 32'h00030000) & (decode_addr_dec < 32'h00040000)))
                 addr_out_port = 4'd11;  // Select Output port 11

               else if (((decode_addr_dec > 32'h00040000) & (decode_addr_dec < 32'h00050000)))
                 addr_out_port = 4'd12;  // Select Output port 12

               else if (((decode_addr_dec > 32'h00060000) & (decode_addr_dec < 32'h00070000)))
                 addr_out_port = 4'd13;  // Select Output port 13

               else if (((decode_addr_dec > 32'h00070000) & (decode_addr_dec < 32'h00080000)))
                 addr_out_port = 4'd14;  // Select Output port 14

               //else if (((decode_addr_dec == 32'h0) & (decode_addr_dec > 32'h00080000)))
                 //addr_out_port = 4'd15;   // Select the default slave
	     
	       else
                 addr_out_port = 4'd15;
             end

      4'd1 : begin
               if (((decode_addr_dec > 32'hC0000000) & (decode_addr_dec < 32'hC0001000)))
                 addr_out_port = 4'd0;  // Select Output port 0

               else if (((decode_addr_dec > 32'hC0001000) & (decode_addr_dec < 32'hC0002000)))
                 addr_out_port = 4'd1;  // Select Output port 1

               else if (((decode_addr_dec > 32'hC0002000) & (decode_addr_dec < 32'hC0003000)))
                 addr_out_port = 4'd2;  // Select Output port 2

               else if (((decode_addr_dec > 32'hC0003000) & (decode_addr_dec < 32'hC0004000)))
                 addr_out_port = 4'd3;  // Select Output port 3

               else if (((decode_addr_dec > 32'hC0004000) & (decode_addr_dec < 32'hC0005000)))
                 addr_out_port = 4'd4;  // Select Output port 4

               else if (((decode_addr_dec > 32'hC0006000) & (decode_addr_dec < 32'hC0007000)))
                 addr_out_port = 4'd5;  // Select Output port 5

               else if (((decode_addr_dec > 32'hC0007000) & (decode_addr_dec < 32'hC0008000)))
                 addr_out_port = 4'd6;  // Select Output port 6

               else if (((decode_addr_dec > 32'hC0008000) & (decode_addr_dec < 32'hC0009000)))
                 addr_out_port = 4'd7;  // Select Output port 7

               else if (((decode_addr_dec > 32'hC0009000) & (decode_addr_dec < 32'hC0010000)))
                 addr_out_port = 4'd8;  // Select Output port 8

               else if (((decode_addr_dec > 32'hC0010000) & (decode_addr_dec < 32'hC0020000)))
                 addr_out_port = 4'd9;  // Select Output port 9

               else if (((decode_addr_dec > 32'hC0020000) & (decode_addr_dec < 32'hC0030000)))
                 addr_out_port = 4'd10;  // Select Output port 10

               else if (((decode_addr_dec > 32'hC0030000) & (decode_addr_dec < 32'hC0040000)))
                 addr_out_port = 4'd11;  // Select Output port 11

               else if (((decode_addr_dec > 32'hC0040000) & (decode_addr_dec < 32'hC0050000)))
                 addr_out_port = 4'd12;  // Select Output port 12

               else if (((decode_addr_dec > 32'hC0060000) & (decode_addr_dec < 32'hC0070000)))
                 addr_out_port = 4'd13;  // Select Output port 13

               else if (((decode_addr_dec > 32'hC0070000) & (decode_addr_dec < 32'hC0080000)))
                 addr_out_port = 4'd14;  // Select Output port 14

               //else if (((decode_addr_dec == 32'h0) & (decode_addr_dec > 32'hC0080000)))
                 //addr_out_port = 4'd15;   // Select the default slave

               else
                 addr_out_port = 4'd15;
             end

      4'd3 : begin
               if (((decode_addr_dec > 32'hC0000000) & (decode_addr_dec < 32'hC0001000)))
                 addr_out_port = 4'd0;  // Select Output port 0

               else if (((decode_addr_dec > 32'hC0001000) & (decode_addr_dec < 32'hC0002000)))
                 addr_out_port = 4'd1;  // Select Output port 1

               else if (((decode_addr_dec > 32'hC0002000) & (decode_addr_dec < 32'hC0003000)))
                 addr_out_port = 4'd2;  // Select Output port 2

               else if (((decode_addr_dec > 32'hC0003000) & (decode_addr_dec < 32'hC0004000)))
                 addr_out_port = 4'd3;  // Select Output port 3

               else if (((decode_addr_dec > 32'hC0004000) & (decode_addr_dec < 32'hC0005000)))
                 addr_out_port = 4'd4;  // Select Output port 4

               else if (((decode_addr_dec > 32'hC0006000) & (decode_addr_dec < 32'hC0007000)))
                 addr_out_port = 4'd5;  // Select Output port 5

               else if (((decode_addr_dec > 32'hC0007000) & (decode_addr_dec < 32'hC0008000)))
                 addr_out_port = 4'd6;  // Select Output port 6

               else if (((decode_addr_dec > 32'hC0008000) & (decode_addr_dec < 32'hC0009000)))
                 addr_out_port = 4'd7;  // Select Output port 7

               else if (((decode_addr_dec > 32'hC0009000) & (decode_addr_dec < 32'hC0010000)))
                 addr_out_port = 4'd8;  // Select Output port 8

               else if (((decode_addr_dec > 32'hC0010000) & (decode_addr_dec < 32'hC0020000)))
                 addr_out_port = 4'd9;  // Select Output port 9

               else if (((decode_addr_dec > 32'hC0020000) & (decode_addr_dec < 32'hC0030000)))
                 addr_out_port = 4'd10;  // Select Output port 10

               else if (((decode_addr_dec > 32'hC0030000) & (decode_addr_dec < 32'hC0040000)))
                 addr_out_port = 4'd11;  // Select Output port 11

               else if (((decode_addr_dec > 32'hC0040000) & (decode_addr_dec < 32'hC0050000)))
                 addr_out_port = 4'd12;  // Select Output port 12

               else if (((decode_addr_dec > 32'hC0060000) & (decode_addr_dec < 32'hC0070000)))
                 addr_out_port = 4'd13;  // Select Output port 13

               else if (((decode_addr_dec > 32'hC0070000) & (decode_addr_dec < 32'hC0080000)))
                 addr_out_port = 4'd14;  // Select Output port 14

               //else if (((decode_addr_dec == 32'h0) & (decode_addr_dec > 32'hC0080000)))
                 //addr_out_port = 4'd15;   // Select the default slave

               else
                 addr_out_port = 4'd15;
                 
             end

      default : addr_out_port = 4'bz;
      endcase
  end


  // Select signal decode
  always@(sel_dec or addr_out_port)
    begin
      sel_out = 'b0;
      sel_dft_slv = 1'b0;

      if (sel_dec)
        case (addr_out_port)
          4'd0  : sel_out[0]  = 1'b1;
          4'd1  : sel_out[1]  = 1'b1;
          4'd2  : sel_out[2]  = 1'b1;
          4'd3  : sel_out[3]  = 1'b1;
          4'd4  : sel_out[4]  = 1'b1;
          4'd5  : sel_out[5]  = 1'b1;
          4'd6  : sel_out[6]  = 1'b1;
          4'd7  : sel_out[7]  = 1'b1;
          4'd8  : sel_out[8]  = 1'b1;
          4'd9  : sel_out[9]  = 1'b1;
          4'd10 : sel_out[10] = 1'b1;
          4'd11 : sel_out[11] = 1'b1;
          4'd12 : sel_out[12] = 1'b1;
          4'd13 : sel_out[13] = 1'b1;
          4'd14 : sel_out[14] = 1'b1;
          4'd15 : sel_dft_slv = 1'b1;    // Select the default slave
          default : begin
                      sel_out = 'bz;
                      sel_dft_slv = 1'bz;
                    end
        endcase
    end


  // The decoder selects the appropriate active_dec signal depending on which
  // output stage is required for the transfer.
  always@(active_dec or addr_out_port)
    begin
      case (addr_out_port)
        4'd0   : active_decode = active_dec[0];
        4'd1   : active_decode = active_dec[1];
        4'd2   : active_decode = active_dec[2];
        4'd3   : active_decode = active_dec[3];
        4'd4   : active_decode = active_dec[4];
        4'd5   : active_decode = active_dec[5];
        4'd6   : active_decode = active_dec[6];
        4'd7   : active_decode = active_dec[7];
        4'd8   : active_decode = active_dec[8];
        4'd9   : active_decode = active_dec[9];
        4'd10  : active_decode = active_dec[10];
        4'd11  : active_decode = active_dec[11];
        4'd12  : active_decode = active_dec[12];
        4'd13  : active_decode = active_dec[13];
        4'd14  : active_decode = active_dec[14];
        4'd15  : active_decode = 1'b1;         // Select the default slave
        default: active_decode = 1'bz;
      endcase 
    end


  // The data_out_port needs to be updated when HREADY from the input stage is high
  always@(negedge HRESETn or posedge HCLK)
    begin : p_data_out_port_seq
      if (~HRESETn)
        begin
          data_out_port <= 4'b0;
	end
	
      else
        data_out_port <= addr_out_port;
    end 


  // HREADYOUTS output decode
  always@(readyout_dft_slv or readyout_dec or data_out_port)
    begin 
      case (data_out_port)
        4'd0    : HREADYOUTS = readyout_dec[0];
        4'd1    : HREADYOUTS = readyout_dec[1];
        4'd2    : HREADYOUTS = readyout_dec[2];
        4'd3    : HREADYOUTS = readyout_dec[3];
        4'd4    : HREADYOUTS = readyout_dec[4];
        4'd5    : HREADYOUTS = readyout_dec[5];
        4'd6    : HREADYOUTS = readyout_dec[6];
        4'd7    : HREADYOUTS = readyout_dec[7];
        4'd8    : HREADYOUTS = readyout_dec[8];
        4'd9    : HREADYOUTS = readyout_dec[9];
        4'd10   : HREADYOUTS = readyout_dec[10];
        4'd11   : HREADYOUTS = readyout_dec[11];
        4'd12   : HREADYOUTS = readyout_dec[12];
        4'd13   : HREADYOUTS = readyout_dec[13];
        4'd14   : HREADYOUTS = readyout_dec[14];
        4'd15   : HREADYOUTS = readyout_dft_slv;    // Select the default slave
        default : HREADYOUTS = 1'bz;
      endcase 
    end 


  // HRESPS output decode
  always@(resp_dft_slv or resp_dec or data_out_port)
    begin
      case (data_out_port)
        4'd0    : HRESPS = resp_dec[1:0];
        4'd1    : HRESPS = resp_dec[3:2];
        4'd2    : HRESPS = resp_dec[5:4];
        4'd3    : HRESPS = resp_dec[7:6];
        4'd4    : HRESPS = resp_dec[9:8];
        4'd5    : HRESPS = resp_dec[11:10];
        4'd6    : HRESPS = resp_dec[13:12];
        4'd7    : HRESPS = resp_dec[15:14];
        4'd8    : HRESPS = resp_dec[17:16];
        4'd9    : HRESPS = resp_dec[19:18];
        4'd10   : HRESPS = resp_dec[21:20];
        4'd11   : HRESPS = resp_dec[23:22];
        4'd12   : HRESPS = resp_dec[25:24];
        4'd13   : HRESPS = resp_dec[27:26];
        4'd14   : HRESPS = resp_dec[29:28];
        4'd15   : HRESPS = resp_dft_slv;     // Select the default slave
        default : HRESPS = 2'bz;
      endcase 
    end


  // HRDATAS output decode
  always@(*)//rdata_dec or  data_out_port or hwrite)
    begin
      if(!HRESETn)
        HRDATAS = 32'd0;
     
      else
        begin
          if(hwrite==0 && active_dec[data_out_port])
            begin
              case (data_out_port)
              4'd0    : HRDATAS = rdata_dec[31:0];
              4'd1    : HRDATAS = rdata_dec[63:32];
              4'd2    : HRDATAS = rdata_dec[95:64];
              4'd3    : HRDATAS = rdata_dec[127:96];
              4'd4    : HRDATAS = rdata_dec[159:128];
              4'd5    : HRDATAS = rdata_dec[191:160];
              4'd6    : HRDATAS = rdata_dec[223:192];
              4'd7    : HRDATAS = rdata_dec[255:224];
              4'd8    : HRDATAS = rdata_dec[287:256];
              4'd9    : HRDATAS = rdata_dec[319:288];
              4'd10   : HRDATAS = rdata_dec[351:320];
              4'd11   : HRDATAS = rdata_dec[383:352];
              4'd12   : HRDATAS = rdata_dec[415:384];
              4'd13   : HRDATAS = rdata_dec[447:416];
              4'd14   : HRDATAS = rdata_dec[479:448];
              4'd15   : HRDATAS = 32'b0;   // Select the default slave
              default : HRDATAS = 32'bz;
              endcase
          end
        end
    end

  assign HREADYIN = HREADYS;

  endmodule
  
  
  ///////////////////////////////cvw.sv/////////////////////////
    /********************************************************************************************

  Copyright 2024 - Maven Silicon Softech Pvt Ltd.  

  www.maven-silicon.com

  All Rights Reserved.

  This source code is an unpublished work belongs to Maven Silicon Softech Pvt Ltd.
  It is not to be shared with or used by any third parties who have not enrolled for our paid 
  training courses or received any written authorization from Maven Silicon.

  Filename                :       cvw.sv   

  module Name             :       cvw

  Description             :       Package file for number of masters and slaves

  Author Name             :       K Sriguru

  Support e-mail          :       For any queries, reach out to us on "techsupport_vm@maven-silicon.com" 

  Version                 :       1.0

  *********************************************************************************************/



  package cvw;

  typedef struct packed {

    int n;  
  
  } cvw_t;


  localparam n=15;

  localparam cvw_t P = '{ 
    n : n  
  
  };

  endpackage



////////////////////////////////////slv_interface.sv/////////////////////
  /********************************************************************************************

  Copyright 2024 - Maven Silicon Softech Pvt Ltd.  

  www.maven-silicon.com

  All Rights Reserved.

  This source code is an unpublished work belongs to Maven Silicon Softech Pvt Ltd.
  It is not to be shared with or used by any third parties who have not enrolled for our paid 
  training courses or received any written authorization from Maven Silicon.

  Filename                :       slv_interface.sv   

  module Name             :       slv_interface

  Description             :       Slave Interface for AHB Bus Matrix 

  Author Name             :       K Sriguru

  Support e-mail          :       For any queries, reach out to us on "techsupport_vm@maven-silicon.com" 

  Version                 :       1.0

  *********************************************************************************************/

 // import cvw::*;

  interface slv_interface(input bit HCLK);

    logic [1:0] HRESPM;
    logic [31:0]HRDATAM;
    logic       HREADYOUTM;

    logic       HSELM;
    logic [31:0]HADDRM;
    logic [1:0] HTRANSM;
    logic       HWRITEM;
    logic [2:0] HSIZEM;
    logic [2:0] HBURSTM;
    logic [3:0] HPROTM;
    logic [3:0] HMASTERM;
    logic       HMASTLOCKM;
    logic [31:0]HWDATAM;
    logic       HREADYM;
    logic [1:0] resp;

    clocking sdrv_cb@(posedge HCLK);
  //    default input #1 output #1;
      output HRESPM,HRDATAM,HREADYOUTM,resp;
      input  HWRITEM,HSELM,HADDRM,HTRANSM,HSIZEM,HBURSTM,HPROTM,HMASTERM,HMASTLOCKM,HWDATAM,HREADYM;
    endclocking

    clocking smon_cb@(posedge HCLK);
    //  default input #1 output #1;
      input HRESPM,HRDATAM,HREADYOUTM,HWRITEM,HSELM,HADDRM,HTRANSM,HSIZEM,HBURSTM,HPROTM,HMASTERM,HMASTLOCKM,HWDATAM,HREADYM,resp;
    endclocking


    modport SLV_DRV_MP(clocking sdrv_cb);

    modport SLV_MON_MP(clocking smon_cb);

  endinterface:slv_interface
  
  
  
  
  
  ///////////////////////////////output_stage.v//////////////////////
    /********************************************************************************************

  Copyright 2024 - Maven Silicon Softech Pvt Ltd.  

  www.maven-silicon.com

  All Rights Reserved.

  This source code is an unpublished work belongs to Maven Silicon Softech Pvt Ltd.
  It is not to be shared with or used by any third parties who have not enrolled for our paid 
  training courses or received any written authorization from Maven Silicon.

  Filename                :       output_stage.v   

  module Name             :       output_stage

  Description             :       Depending upon the arbiter address the master data are given to slave as output

  Author Name             :       K Sriguru

  Support e-mail          :       For any queries, reach out to us on "techsupport_vm@maven-silicon.com" 

  Version                 :       1.0

  *********************************************************************************************/   



  module output_stage #(parameter N=15)(
                                      // Common AHB signals
                                      input             HCLK,           // AHB system clock
                                      input             HRESETn,        // AHB system reset

                                      // Bus-switch input 0
                                      input      [N-1:0]     sel_op,     // Port  HSEL signal
                                      input      [(N*32)-1:0]addr_op,    // Port  HADDR signal
                                      input      [(N*2)-1:0] trans_op,   // Port  HTRANS signal
                                      input      [N-1:0]     write_op,   // Port  HWRITE signal
                                      input      [(N*3)-1:0] size_op,    // Port  HSIZE signal
                                      input      [(N*3)-1:0] burst_op,   // Port  HBURST signal
                                      input      [(N*4)-1:0] prot_op,    // Port  HPROT signal
                                      input      [(N*4)-1:0] master_op,  // Port  HMASTER signal
                                      input      [N-1:0]     mastlock_op,// Port  HMASTLOCK signal
                                      input      [(N*32)-1:0]wdata_op,   // Port  HWDATA signal
                                      input                  HREADYOUTM, // HREADY feedback from top
                                      input      [N-1:0]     hreadyout,  // hready from master to slave

                                      output reg [N-1:0]     active_op,  // Port  Active signal

                                      // Slave Address/Control Signals
                                      output reg        HSELM,      	 // Slave select line
                                      output reg [31:0] HADDRM,     	 // Address
                                      output reg [1:0]  HTRANSM,    	 // Transfer type
                                      output reg        HWRITEM,    	 // Transfer direction
                                      output reg [2:0]  HSIZEM,     	 // Transfer size
                                      output reg [2:0]  HBURSTM,    	 // Burst type
                                      output reg [3:0]  HPROTM,     	 // Protection control
                                      output reg [3:0]  HMASTERM,   	 // Master ID
                                      output reg        HMASTLOCKM, 	 // Locked transfer
                                      output reg [N-1:0]HREADYMUXM, 	 // Transfer done
                                      output reg [31:0] HWDATAM,     	 // Write data
                                      output reg        HREADYMUXOUT     // Ready out for slave
                                      );


  wire  [3:0]  addr_in_port;  	// Address input port
  reg   [3:0]  data_in_port;  	// Data input port
  wire         no_port;       	// No port selected signal
  reg          slave_sel;       // Slave select signal
  reg 	       i_hreadymuxm;
  reg   [N-1:0]sel_out;


  // Arbiter instance for resolving requests to this output stage
  arbiter #(N) DUV(
                   .HCLK(HCLK),
                   .HRESETn(HRESETn),
                   .req_port(sel_op),

                   .HREADYM(i_hreadymuxm),
                   .HTRANSM(HTRANSM),
                   .HMASTLOCKM(HMASTLOCKM),

                   .addr_in_port(addr_in_port),
                   .no_port(no_port)
                   );


  // Active signal combinatorial decode
  always@(addr_in_port or no_port)
    begin 
      // Default value(s)
      active_op = 'b0;

      // Decode selection when enabled
      if (~no_port)
        begin
          case (addr_in_port)
            4'd0  : active_op[0] = 1'b1;
            4'd1  : active_op[1] = 1'b1;
            4'd2  : active_op[2] = 1'b1;
            4'd3  : active_op[3] = 1'b1;
            4'd4  : active_op[4] = 1'b1;
            4'd5  : active_op[5] = 1'b1;
            4'd6  : active_op[6] = 1'b1;
            4'd7  : active_op[7] = 1'b1;
            4'd8  : active_op[8] = 1'b1;
            4'd9  : active_op[9] = 1'b1;
            4'd10 : active_op[10] = 1'b1;
            4'd11 : active_op[11] = 1'b1;
            4'd12 : active_op[12] = 1'b1;
            4'd13 : active_op[13] = 1'b1;
            4'd14 : active_op[14] = 1'b1;
            default : begin
                        active_op = 'bz;
                      end
          endcase 
       end
    end


  //  Address/control output decode
  always@(sel_op or addr_op or trans_op or write_op or
             size_op or burst_op or prot_op or
             master_op or mastlock_op or addr_in_port or no_port)
    begin
      // Default values
      HSELM       = 1'b0;
      HADDRM      = 32'b0;
      HTRANSM     = 2'b00;
      HWRITEM     = 1'b0;
      HSIZEM      = 3'b000;
      HBURSTM     = 3'b000;
      HPROTM      = 4'b0;
      HMASTERM    = 4'b0000;
      HMASTLOCKM  = 1'b0;
      HREADYMUXOUT= 1'b0;

      // Decode selection when enabled
      if (~no_port)
        case (addr_in_port)
        // Bus-switch input 0
          4'd0 :
            begin
              HSELM       = sel_op[0];
              HADDRM      = addr_op[31:0];
              HTRANSM     = trans_op[1:0];
              HWRITEM     = write_op[0];
              HSIZEM      = size_op[2:0];
              HBURSTM     = burst_op[2:0];
              HPROTM      = prot_op[3:0];
              HMASTERM    = master_op[3:0];
              HMASTLOCKM  = mastlock_op[0];
	      HREADYMUXOUT= hreadyout[0];
            end

          // Bus-switch input 1
          4'd1 :
            begin
              HSELM       = sel_op[1];
              HADDRM      = addr_op[63:32];
              HTRANSM     = trans_op[3:2];
              HWRITEM     = write_op[1];
              HSIZEM      = size_op[5:3];
              HBURSTM     = burst_op[5:3];
              HPROTM      = prot_op[7:4];
              HMASTERM    = master_op[7:4];
              HMASTLOCKM  = mastlock_op[1];
	      HREADYMUXOUT= hreadyout[1];
            end

	  // Bus-switch input 2
          4'd2 :
            begin
              HSELM       = sel_op[2];
              HADDRM      = addr_op[95:64];
              HTRANSM     = trans_op[5:4];
              HWRITEM     = write_op[2];
              HSIZEM      = size_op[8:6];
              HBURSTM     = burst_op[8:6];
              HPROTM      = prot_op[11:8];
              HMASTERM    = master_op[11:8];
              HMASTLOCKM  = mastlock_op[2];
	      HREADYMUXOUT= hreadyout[2];
            end

          // Bus-switch input 3
          4'd3 :
            begin
              HSELM       = sel_op[3];
              HADDRM      = addr_op[127:96];
              HTRANSM     = trans_op[7:6];
              HWRITEM     = write_op[3];
              HSIZEM      = size_op[11:9];
              HBURSTM     = burst_op[11:9];
              HPROTM      = prot_op[15:12];
              HMASTERM    = master_op[15:12];
              HMASTLOCKM  = mastlock_op[3];
	      HREADYMUXOUT= hreadyout[3];
            end

	  // Bus-switch input 4
          4'd4 :
            begin
              HSELM       = sel_op[4];
              HADDRM      = addr_op[159:128];
              HTRANSM     = trans_op[9:8];
              HWRITEM     = write_op[4];
              HSIZEM      = size_op[14:12];
              HBURSTM     = burst_op[14:12];
              HPROTM      = prot_op[19:16];
              HMASTERM    = master_op[19:16];
              HMASTLOCKM  = mastlock_op[4];
	      HREADYMUXOUT= hreadyout[4];
            end

          // Bus-switch input 5
          4'd5 :
            begin
              HSELM       = sel_op[5];
              HADDRM      = addr_op[191:160];
              HTRANSM     = trans_op[11:10];
              HWRITEM     = write_op[5];
              HSIZEM      = size_op[17:15];
              HBURSTM     = burst_op[17:15];
              HPROTM      = prot_op[23:20];
              HMASTERM    = master_op[23:20];
              HMASTLOCKM  = mastlock_op[5];
	      HREADYMUXOUT= hreadyout[5];
            end

	  // Bus-switch input 6
          4'd6 :
            begin
              HSELM       = sel_op[6];
              HADDRM      = addr_op[223:192];
              HTRANSM     = trans_op[13:12];
              HWRITEM     = write_op[6];
              HSIZEM      = size_op[20:18];
              HBURSTM     = burst_op[20:18];
              HPROTM      = prot_op[27:24];
              HMASTERM    = master_op[27:24];
              HMASTLOCKM  = mastlock_op[6];
	      HREADYMUXOUT= hreadyout[6];
            end

          // Bus-switch input 7
          4'd7 :
            begin
              HSELM       = sel_op[7];
              HADDRM      = addr_op[255:224];
              HTRANSM     = trans_op[15:14];
              HWRITEM     = write_op[7];
              HSIZEM      = size_op[23:21];
              HBURSTM     = burst_op[23:21];
              HPROTM      = prot_op[31:28];
              HMASTERM    = master_op[31:28];
              HMASTLOCKM  = mastlock_op[7];
	      HREADYMUXOUT= hreadyout[7];
            end

	  // Bus-switch input 8
          4'd8 :
            begin
              HSELM       = sel_op[8];
              HADDRM      = addr_op[287:256];
              HTRANSM     = trans_op[17:16];
              HWRITEM     = write_op[8];
              HSIZEM      = size_op[26:24];
              HBURSTM     = burst_op[26:24];
              HPROTM      = prot_op[35:32];
              HMASTERM    = master_op[35:32];
              HMASTLOCKM  = mastlock_op[8];
	      HREADYMUXOUT= hreadyout[8];
            end

          // Bus-switch input 9
          4'd9 :
            begin
              HSELM       = sel_op[9];
              HADDRM      = addr_op[319:288];
              HTRANSM     = trans_op[19:18];
              HWRITEM     = write_op[9];
              HSIZEM      = size_op[29:27];
              HBURSTM     = burst_op[29:27];
              HPROTM      = prot_op[39:36];
              HMASTERM    = master_op[39:36];
              HMASTLOCKM  = mastlock_op[9];
	      HREADYMUXOUT= hreadyout[9];
            end

	  // Bus-switch input 10
          4'd10 :
            begin
              HSELM       = sel_op[10];
              HADDRM      = addr_op[351:320];
              HTRANSM     = trans_op[21:20];
              HWRITEM     = write_op[10];
              HSIZEM      = size_op[32:30];
              HBURSTM     = burst_op[32:30];
              HPROTM      = prot_op[43:40];
              HMASTERM    = master_op[43:40];
              HMASTLOCKM  = mastlock_op[10];
	      HREADYMUXOUT= hreadyout[10];
            end

          // Bus-switch input 11
          4'd11 :
            begin
              HSELM       = sel_op[11];
              HADDRM      = addr_op[383:352];
              HTRANSM     = trans_op[23:22];
              HWRITEM     = write_op[11];
              HSIZEM      = size_op[35:33];
              HBURSTM     = burst_op[35:33];
              HPROTM      = prot_op[47:44];
              HMASTERM    = master_op[47:44];
              HMASTLOCKM  = mastlock_op[11];
	      HREADYMUXOUT= hreadyout[11];
            end

	  // Bus-switch input 12
          4'd12 :
            begin
              HSELM       = sel_op[12];
              HADDRM      = addr_op[415:384];
              HTRANSM     = trans_op[25:24];
              HWRITEM     = write_op[12];
              HSIZEM      = size_op[38:36];
              HBURSTM     = burst_op[38:36];
              HPROTM      = prot_op[51:48];
              HMASTERM    = master_op[51:48];
              HMASTLOCKM  = mastlock_op[12];
	      HREADYMUXOUT= hreadyout[12];
            end

          // Bus-switch input 13
          4'd13 :
            begin
              HSELM       = sel_op[13];
              HADDRM      = addr_op[447:416];
              HTRANSM     = trans_op[27:26];
              HWRITEM     = write_op[13];
              HSIZEM      = size_op[41:39];
              HBURSTM     = burst_op[41:39];
              HPROTM      = prot_op[55:52];
              HMASTERM    = master_op[55:52];
              HMASTLOCKM  = mastlock_op[13];
	      HREADYMUXOUT= hreadyout[13];
            end

	  // Bus-switch input 14
          4'd14 :
            begin
              HSELM       = sel_op[14];
              HADDRM      = addr_op[479:448];
              HTRANSM     = trans_op[29:28];
              HWRITEM     = write_op[14];
              HSIZEM      = size_op[44:42];
              HBURSTM     = burst_op[44:42];
              HPROTM      = prot_op[59:56];
              HMASTERM    = master_op[59:56];
              HMASTLOCKM  = mastlock_op[14];
	      HREADYMUXOUT= hreadyout[14];
            end

          default :
            begin
              HSELM       = 1'bz;
              HADDRM      = 32'bz;
              HTRANSM     = 2'bz;
              HWRITEM     = 1'bz;
              HSIZEM      = 3'bz;
              HBURSTM     = 3'bz;
              HPROTM      = 4'bz;
              HMASTERM    = 4'bz;
              HMASTLOCKM  = 1'bz;
	      HREADYMUXOUT= 1'bz;
            end
        endcase 
  end


  // Dataport register
  always@(negedge HRESETn or posedge HCLK)
    begin 
      if(~HRESETn)
        data_in_port <= 4'b0;

      else
        if(i_hreadymuxm)
          data_in_port <= addr_in_port;
    end


  // HWDATAM output decode
  always@(wdata_op or data_in_port or sel_op)
    begin
      // Default value
      HWDATAM = 32'b0;

    if(sel_op[data_in_port])
      // Decode selection
      if(write_op[data_in_port])
        case (data_in_port)
          4'd0    : HWDATAM = wdata_op[31:0];
          4'd1    : HWDATAM = wdata_op[63:32];
          4'd2    : HWDATAM = wdata_op[95:64];
          4'd3    : HWDATAM = wdata_op[127:96];
          4'd4    : HWDATAM = wdata_op[159:128];
          4'd5    : HWDATAM = wdata_op[191:160];
          4'd6    : HWDATAM = wdata_op[223:192];
          4'd7    : HWDATAM = wdata_op[255:224];
          4'd8    : HWDATAM = wdata_op[287:256];
          4'd9    : HWDATAM = wdata_op[319:288];
          4'd10   : HWDATAM = wdata_op[351:320];
          4'd11   : HWDATAM = wdata_op[383:352];
          4'd12   : HWDATAM = wdata_op[415:384];
          4'd13   : HWDATAM = wdata_op[447:416];
          4'd14   : HWDATAM = wdata_op[479:448];
          default : HWDATAM = 32'b0;
      	endcase 
    end


  // The HREADY signal on the shared slave is generated directly from
  //  the shared slave HREADYOUTS if the slave is selected, otherwise
  //  it mirrors the HREADY signal of the appropriate input port
  /*always@(negedge HRESETn or posedge HCLK)
    begin
      if (~HRESETn)
        slave_sel <= 1'b0;

      else
        begin
          //if(i_hreadymuxm)
            slave_sel  <= HSELM;
	  
	  // Drive output with internal version of the signal
	  HREADYMUXM[addr_in_port] = i_hreadymuxm;
	end
    end*/

  always@(*)//negedge HRESETn or posedge HCLK)
    begin

          //if(i_hreadymuxm)
            slave_sel  <= HSELM;

          i_hreadymuxm <= (slave_sel) ? HREADYOUTM : 1'b1;
          // Drive output with internal version of the signal
          HREADYMUXM[addr_in_port] <= i_hreadymuxm;
    end


  // HREADYMUXM output selection
  //assign i_hreadymuxm = (slave_sel) ? HREADYOUTM : 1'b1;

  // Drive output with internal version of the signal
  //assign HREADYMUXM[addr_in_port] = i_hreadymuxm;


  endmodule
  
  
  ///////////////////////////////mas_interface.sv//////////////////////
    /********************************************************************************************

  Copyright 2024 - Maven Silicon Softech Pvt Ltd.  

  www.maven-silicon.com

  All Rights Reserved.

  This source code is an unpublished work belongs to Maven Silicon Softech Pvt Ltd.
  It is not to be shared with or used by any third parties who have not enrolled for our paid 
  training courses or received any written authorization from Maven Silicon.

  Filename                :       mas_interface.sv   

  module Name             :       mas_interface

  Description             :       Master Interface for AHB Bus Matrix 

  Author Name             :       K Sriguru

  Support e-mail          :       For any queries, reach out to us on "techsupport_vm@maven-silicon.com" 

  Version                 :       1.0

  *********************************************************************************************/



  import cvw::*;

  interface mas_interface(input bit HCLK);


    logic       HRESETn;
    logic [3:0] REMAP;
    logic       HSELS;
    logic [31:0]HADDRS;
    logic [31:0]HWDATAS;
    logic [1:0] HTRANSS;
    logic       HWRITES;
    logic [2:0] HSIZES;
    logic [2:0] HBURSTS;
    logic [3:0] HPROTS;
    logic [3:0] HMASTERS;
    logic       HMASTLOCKS;
    logic       HREADYOUTS;
    logic [1:0] HRESPS;
    logic [31:0]HRDATAS;

    clocking mdrv_cb@(posedge HCLK);
  //    default input #1 output #1;
      input HREADYOUTS,HRESPS,HRDATAS;
      output HRESETn,REMAP,HSELS,HADDRS,HWDATAS,HTRANSS,HSIZES,HBURSTS,HPROTS,HMASTERS,HMASTLOCKS,
			HWRITES;
    endclocking

    clocking mmon_cb@(posedge HCLK);
    //  default input #1 output #1;
      input HRESETn,REMAP,HSELS,HADDRS,HWDATAS,HTRANSS,HSIZES,HBURSTS,HPROTS,HMASTERS,HMASTLOCKS,HWRITES,HREADYOUTS,HRESPS,HRDATAS;
    endclocking


    modport MAS_DRV_MP(clocking mdrv_cb);

    modport MAS_MON_MP(clocking mmon_cb);

  endinterface
		
		
		
		/////////////////////arbiter.v/////////////////////////
		  /********************************************************************************************

  Copyright 2024 - Maven Silicon Softech Pvt Ltd.  

  www.maven-silicon.com

  All Rights Reserved.

  This source code is an unpublished work belongs to Maven Silicon Softech Pvt Ltd.
  It is not to be shared with or used by any third parties who have not enrolled for our paid 
  training courses or received any written authorization from Maven Silicon.

  Filename                :       arbiter.v   

  module Name             :       arbiter

  Description             :       When master is accessing shared slave upon priority master is given access

  Author Name             :       K Sriguru

  Support e-mail          :       For any queries, reach out to us on "techsupport_vm@maven-silicon.com" 

  Version                 :       1.0

  *********************************************************************************************/




  module arbiter #(parameter N=15)(
                                  // Common AHB signals
                                  input        HCLK,            // AHB system clock
                                  input        HRESETn,         // AHB system reset

                                  input  [N-1:0]req_port,       // Port 0 request signal

                                  input        HREADYM,         // Transfer done
                                  input  [1:0] HTRANSM,         // Transfer type
                                  input        HMASTLOCKM,      // Locked transfer

                                  output reg [3:0]addr_in_port, // Port address input
                                  output reg      no_port       // No port selected signal
                                  );


  reg  [3:0]addr_in_port_next; // D-input of addr_in_port
  reg  no_port_next;           // D-input of no_port


  always@(req_port or HMASTLOCKM)
    begin
      // Default values are used for addr_in_port_next and no_port_next
      no_port_next     = 1'b0;
      addr_in_port_next = 1'bz;

      if (HMASTLOCKM)
        addr_in_port_next = 4'bz;

      else if (req_port[0] )
        addr_in_port_next = 4'd0;
      
      else if (req_port[1] )
        addr_in_port_next = 4'd1;

      else if (req_port[2] )
        addr_in_port_next = 4'd2;              
      
      else if (req_port[3] )
        addr_in_port_next = 4'd3;

      else if (req_port[4] )
        addr_in_port_next = 4'd4;
      
      else if (req_port[5] )
        addr_in_port_next = 4'd5;

      else if (req_port[6] )
        addr_in_port_next = 4'd6;
      
      else if (req_port[7] )
        addr_in_port_next = 4'd7;

      else if (req_port[8] )
        addr_in_port_next = 4'd8;
      
      else if (req_port[9] )
        addr_in_port_next = 4'd9;

      else if (req_port[10] )
        addr_in_port_next = 4'd10;
      
      else if (req_port[11] )
        addr_in_port_next = 4'd11;

      else if (req_port[12] )
        addr_in_port_next = 4'd12;
      
      else if (req_port[13])
        addr_in_port_next = 4'd13;

      else if (req_port[14])
        addr_in_port_next = 4'd14;

      else
        no_port_next = 1'b1;
    end


  always@(negedge HRESETn or posedge HCLK)
    begin
      if(~HRESETn)
        begin
          no_port<=1'b1;
          addr_in_port<=4'bz;
        end

      else
        begin
          no_port <= no_port_next;
          addr_in_port <= addr_in_port_next;
        end
    end

  endmodule