//slave agent configuration
class s_agent_config extends uvm_object;

  `uvm_object_utils(s_agent_config)

  // Virtual interface for AHB
  virtual ahb_if vif;

  // Active or passive agent
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  static int mon_rcvd_xtn_cnt = 0;
  static int drv_data_sent_cnt  = 0;

  extern function new(string name="s_agent_config");

endclass

// -----------------------
function s_agent_config::new(string name="s_agent_config");
  super.new(name);
endfunction

//////////////////////////////////////////////////////////////////
class slave_agent extends uvm_agent;
  `uvm_component_utils(slave_agent)

  slave_driver    drvh;
  slave_monitor   monh;
  slave_sequencer seqrh;
  s_agent_config scfgh;

  extern function new(string name="slave_agent", uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
endclass

function slave_agent::new(string name="slave_agent", uvm_component parent);
  super.new(name,parent);
endfunction

function void slave_agent::build_phase(uvm_phase phase);
  super.build_phase(phase);

  // Get agent config
  if (!uvm_config_db #(s_agent_config)::get(this,"","s_agent_config", scfgh))
    `uvm_fatal("AGT_CFG","s_agent_config missing!")

  // Monitor always created
  monh = slave_monitor::type_id::create("monh", this);

  // Driver & sequencer only if active
  if (scfgh.is_active == UVM_ACTIVE)
    begin
    seqrh = slave_sequencer::type_id::create("seqrh", this);
    drvh  = slave_driver::type_id::create("drvh", this);
    end
endfunction

function void slave_agent::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  if (scfgh.is_active == UVM_ACTIVE)
    drvh.seq_item_port.connect(seqrh.seq_item_export);
endfunction

///////////////////////////////////////////////////////////////////////////

class slave_agent_top extends uvm_env;

  `uvm_component_utils(slave_agent_top)

  // Agent handle
  slave_agent agnth[];
  env_config cfgh;

  //------------------------------------------
  // METHODS
  //------------------------------------------

  // Constructor
  extern function new(string name="slave_agent_top", uvm_component parent);

  // Build phase
  extern function void build_phase(uvm_phase phase);


endclass

// ----------------- Implementation -----------------------

function slave_agent_top::new(string name="slave_agent_top", uvm_component parent);
  super.new(name,parent);
endfunction

function void slave_agent_top::build_phase(uvm_phase phase);
  super.build_phase(phase);

  if(!uvm_config_db #(env_config)::get(this,"","env_config",cfgh))
        `uvm_fatal("ENV_CFG","cannot get env config")

        agnth=new[cfgh.has_no_of_slave];
        foreach(agnth[i])
        begin
                uvm_config_db #(s_agent_config)::set(this,$sformatf("agnth[%0d]*",i),"s_agent_config",cfgh.scfgh[i]);
                agnth[i]=slave_agent::type_id::create($sformatf("agnth[%0d]",i),this);
        end

endfunction

//////////////////////////////////////////////////////////////////////////////
class slave_driver extends uvm_driver #(slave_xtn);

  `uvm_component_utils(slave_driver)

  s_agent_config scfgh;
  virtual ahb_if.S_DRV vif;
//  int i;

  extern function new(string name="slave_driver", uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern task send_to_dut(slave_xtn xtn);
endclass

// implementation
function slave_driver::new(string name="slave_driver", uvm_component parent);
  super.new(name,parent);
endfunction


//build phase
function void slave_driver::build_phase(uvm_phase phase);
  super.build_phase(phase);

  if(!uvm_config_db #(s_agent_config)::get(this,"","s_agent_config",scfgh))
  `uvm_fatal("config","cannot get config");
endfunction


//connect phase
function void slave_driver::connect_phase(uvm_phase phase);
        vif=scfgh.vif;
$display("I am in slave driver %p",vif);
endfunction
//run_phase
task slave_driver::run_phase(uvm_phase phase);
 forever
  begin
      seq_item_port.get_next_item(req);
        `uvm_info(get_type_name(),$sformatf("in ahb driver %0d",req.resp),UVM_LOW)
      send_to_dut(req);
      seq_item_port.item_done();
    end
  endtask
task slave_driver:: send_to_dut(slave_xtn xtn);


 `uvm_info("SLAVE DRIVER",$sformatf("Sending transaction: %s", xtn.sprint()), UVM_LOW)

//OKAY resp
   if(xtn.resp == 0)
     begin

        if(vif.slave_drv_cb.Hwrite == 1) //write operation
          begin
            vif.slave_drv_cb.Hready <= 1'b1;
            vif.slave_drv_cb.Hresp <= 2'b00;
            @(vif.slave_drv_cb);
//          vif.slave_drv_cb.Hready <= 1'b1;
  //          vif.slave_drv_cb.Hresp <= 2'b0;

          end

        else if(vif.slave_drv_cb.Hwrite == 0) //Read operation
          begin
            vif.slave_drv_cb.Hready <= 1'b1;
            vif.slave_drv_cb.Hresp <= 2'b0;
            vif.slave_drv_cb.HRdata <= xtn.HRdata;
            @(vif.slave_drv_cb);

          end

     end
  //OKAY WITH WAIT STATE resp
   else if(xtn.resp == 1)
    begin

      if(vif.slave_drv_cb.Hwrite == 1'b1) //write operation
         begin
           vif.slave_drv_cb.Hready <= 1'b0;
           vif.slave_drv_cb.Hresp  <= 1'b0;
          repeat(xtn.delay_cycles)  //to be in wait state for few cycles
          // @(vif.s_drv_cb);  //extra cycle incase delay cycle =0
           @(vif.slave_drv_cb);
             vif.slave_drv_cb.Hready <= 1'b1;
             vif.slave_drv_cb.Hresp  <= 1'b0;
           @(vif.slave_drv_cb);
           @(vif.slave_drv_cb);
             vif.slave_drv_cb.Hready <= 1'b0;

         end

      else if(vif.slave_drv_cb.Hwrite == 1'b0) //Read operation
         begin
           vif.slave_drv_cb.Hready <= 1'b0;
           vif.slave_drv_cb.Hresp  <= 1'b0;
          repeat(xtn.delay_cycles)
         //  @(vif.s_drv_cb);  //extra cycle incase delay cycle =0
           @(vif.slave_drv_cb);
             vif.slave_drv_cb.Hready <= 1'b1;
             vif.slave_drv_cb.Hresp  <= 1'b0;
             vif.slave_drv_cb.HRdata <= xtn.HRdata;
           @(vif.slave_drv_cb);
           @(vif.slave_drv_cb);
           vif.slave_drv_cb.Hready <= 1'b0;
           vif.slave_drv_cb.Hresp  <= 1'b0;

         end
    end


  //ERROR resp
    else if(xtn.resp == 2)
      begin

      if(vif.slave_drv_cb.Hwrite == 1'b1)  //WRITE operation
       begin
            if(vif.slave_drv_cb.Htrans == 2'b10) //Non sequential transfer
begin
              vif.slave_drv_cb.Hready <= 1'b0;
              vif.slave_drv_cb.Hresp <= 2'b01;  //error cycle1
              @(vif.slave_drv_cb);
               vif.slave_drv_cb.Hready <= 1'b1;
               vif.slave_drv_cb.Hresp  <= 2'b01; //error cycle2
               @(vif.slave_drv_cb);
             end


            else if(vif.slave_drv_cb.Htrans == 2'b11)  //SEQ transfer
              begin
              @(vif.slave_drv_cb);
              @(vif.slave_drv_cb);
               vif.slave_drv_cb.Hready  <=  1'b1;
               vif.slave_drv_cb.Hresp  <= 2'b0; //okay
              @(vif.slave_drv_cb);
               vif.slave_drv_cb.Hready  <= 1'b0;
               vif.slave_drv_cb.Hresp  <= 2'b0; //okay
              end

        end
 else if(vif.slave_drv_cb.Hwrite == 1'b0)  //Read operation
        begin


            if(vif.slave_drv_cb.Htrans == 2'b10) //Non sequential transfer
             begin
              vif.slave_drv_cb.Hready <= 1'b0;
              vif.slave_drv_cb.Hresp <= 2'b01;  //error cycle1
              vif.slave_drv_cb.HRdata <= 0;
              @(vif.slave_drv_cb);
               vif.slave_drv_cb.Hready <= 1'b1;
               vif.slave_drv_cb.Hresp  <= 2'b01; //error cycle2
               @(vif.slave_drv_cb);
              vif.slave_drv_cb.Hready <= 1'b0;
                 vif.slave_drv_cb.Hresp  <= 2'b0; //okay
                vif.slave_drv_cb.HRdata <= xtn.HRdata;
             end


            else if(vif.slave_drv_cb.Htrans == 2'b11)  //SEQ transfer
              begin
              @(vif.slave_drv_cb);
              @(vif.slave_drv_cb);
               vif.slave_drv_cb.Hready  <=  1'b1;
               vif.slave_drv_cb.Hresp  <= 2'b0; //okay
             vif.slave_drv_cb.HRdata <= xtn.HRdata;
              @(vif.slave_drv_cb);
              @(vif.slave_drv_cb);
               vif.slave_drv_cb.Hready  <= 1'b0;
              end

       end

    end

 endtask

//////////////////////////////////////////////////////////////////////////

class slave_monitor extends uvm_monitor;

`uvm_component_utils(slave_monitor)

s_agent_config scfgh;

// Virtual interface handle
virtual ahb_if.S_MON vif;
slave_xtn xtn;

uvm_analysis_port#(slave_xtn) monitor_port_s;

// Constructor
extern function new(string name="slave_monitor", uvm_component parent);

// Build phase
extern function void build_phase (uvm_phase phase);

// Connect phase
extern function void connect_phase (uvm_phase phase);
extern task run_phase(uvm_phase phase);
extern task collect_data();
endclass



function slave_monitor::new(string name="slave_monitor", uvm_component parent);
super.new(name,parent);
monitor_port_s=new("monitor_port_s",this);
endfunction



function void slave_monitor::build_phase (uvm_phase phase);
super.build_phase(phase);
if(!uvm_config_db #(s_agent_config)::get(this, "", "s_agent_config",scfgh))
`uvm_fatal("config", "cannot get config")
endfunction
function void slave_monitor::connect_phase (uvm_phase phase);
super.connect_phase (phase);
vif= scfgh.vif;
endfunction


task slave_monitor::run_phase(uvm_phase phase);
        forever
         begin
                collect_data();
        end
endtask




task slave_monitor::collect_data();

    xtn = slave_xtn::type_id::create("xtn");

    @(vif.slave_mon_cb);
    wait(vif.slave_mon_cb.Hready == 1);

    xtn.Haddr  = vif.slave_mon_cb.Haddr;
    xtn.Hwrite = vif.slave_mon_cb.Hwrite;
    xtn.Hsize  = vif.slave_mon_cb.Hsize;
    xtn.Hburst = vif.slave_mon_cb.Hburst;
    xtn.Htrans = vif.slave_mon_cb.Htrans;
    xtn.length = vif.slave_mon_cb.length;
    @(vif.slave_mon_cb);
    wait(vif.slave_mon_cb.Hready == 1);

    if(xtn.Hwrite)
      xtn.HWdata = vif.slave_mon_cb.HWdata;
    else
      xtn.HRdata = vif.slave_mon_cb.HRdata;

    `uvm_info("MONITOR",$sformatf("from slave monitor %s", xtn.sprint()),UVM_LOW)

        monitor_port_s.write(xtn);
endtask
////////////////////////////////////////////////////////////////
class slave_seqs extends uvm_sequence #(slave_xtn);
        `uvm_object_utils(slave_seqs)
         bit [9:0]length;
        extern function new(string name ="slave_seqs");

endclass
        function slave_seqs::new(string name ="slave_seqs");
                super.new(name);
        endfunction




class sresp_seqs extends slave_seqs;
         `uvm_object_utils(sresp_seqs)

         extern function new(string name ="sresp_seqs");
         extern task body();
 endclass
         function sresp_seqs::new(string name ="sresp_seqs");
                 super.new(name);
         endfunction

         task sresp_seqs::body();
        #100;
                 if(!uvm_config_db#(bit[9:0])::get(null,"","length",length))
                 `uvm_fatal("config","cannot get length")

         repeat(length)
         begin
                 req=slave_xtn::type_id::create("req");
//               #100;
//               if(!uvm_config_db#(bit[9:0])::get(null,"","length",length))
//               `uvm_fatal("config","cannot get length")

                 start_item(req);
                 assert(req.randomize());
                 finish_item(req);
         end
        endtask
/////////////////////////////////////////////////////////////////////////
class slave_sequencer extends uvm_sequencer #(slave_xtn);

  `uvm_component_utils(slave_sequencer)

  extern function new(string name="slave_sequencer", uvm_component parent);

endclass

function slave_sequencer::new(string name="slave_sequencer", uvm_component parent);
  super.new(name,parent);
endfunction
///////////////////////////////////////////////////////////
class slave_xtn extends uvm_sequence_item;
  `uvm_object_utils(slave_xtn)

  bit        Hresetn;
  bit [1:0]  Htrans;
  bit [2:0]  Hsize;
  bit [2:0]  Hburst;
  bit [31:0] Haddr;
  bit [31:0] HWdata;
  bit        Hwrite;
  bit [9:0]  length;
  rand bit Hready;
  rand bit [1:0] Hresp;
  rand bit [31:0] HRdata;

 rand enum{okay,okay_with_wait_state,error}resp;
 rand bit [2:0]delay_cycles;

 constraint dc{delay_cycles inside {[1:7]};}


  extern function new(string name="slave_xtn");
  extern function void do_print(uvm_printer printer);
endclass

 function slave_xtn::new(string name="slave_xtn");
        super.new(name);
 endfunction



 function void slave_xtn::do_print(uvm_printer printer);
  super.do_print(printer);

  printer.print_field("Htrans", this.Htrans, 2, UVM_DEC);
  printer.print_field("Hwrite", this.Hwrite, 1, UVM_DEC);
  printer.print_field("Hsize", this.Hsize, 3, UVM_DEC);
  printer.print_field("Hburst", this.Hburst, 3, UVM_DEC);
  printer.print_field("Haddr", this.Haddr, 32, UVM_HEX);
  printer.print_field("length", this.length, 10, UVM_DEC);

  printer.print_field("Hready", this.Hready, 1, UVM_DEC);
  printer.print_field("Hresp", this.Hresp, 2, UVM_DEC);
  printer.print_field("HRdata", this.HRdata, 32, UVM_HEX);
//  printer.print_generic( "respt","resp", $bits(resp),resp.name());

endfunction




