//master agent  configuration

class m_agent_config extends uvm_object;

  `uvm_object_utils(m_agent_config)

  // Virtual interface for AHB
  virtual ahb_if vif;

  // Active or passive agent
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  static int mon_rcvd_xtn_cnt = 0;
  static int drv_data_sent_cnt  = 0;

  extern function new(string name="m_agent_config");

endclass

// -----------------------
function m_agent_config::new(string name="m_agent_config");
  super.new(name);
endfunction


///////////////////////////////////////////////////////////////////////////////

class master_agent extends uvm_agent;
  `uvm_component_utils(master_agent)

  master_driver    drvh;
  master_monitor   monh;
  master_sequencer seqrh;
  m_agent_config mcfgh;

  extern function new(string name="master_agent", uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
endclass

function master_agent::new(string name="master_agent", uvm_component parent);
  super.new(name,parent);
endfunction

function void master_agent::build_phase(uvm_phase phase);
  super.build_phase(phase);

  // Get agent config
  if (!uvm_config_db #(m_agent_config)::get(this,"","m_agent_config", mcfgh))
    `uvm_fatal("AGT_CFG","m_agent_config missing!")

  // Monitor always created
  monh = master_monitor::type_id::create("monh", this);

  // Driver & sequencer only if active
  if (mcfgh.is_active == UVM_ACTIVE)
    begin
    seqrh = master_sequencer::type_id::create("seqrh", this);
    drvh  = master_driver::type_id::create("drvh", this);
    end
endfunction

function void master_agent::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  if (mcfgh.is_active == UVM_ACTIVE)
    drvh.seq_item_port.connect(seqrh.seq_item_export);
endfunction

////////////////////////////////////////////////////////////////////////////////

class master_agent_top extends uvm_env;

  `uvm_component_utils(master_agent_top)

  // Agent handle
  master_agent agnth[];
  env_config cfgh;

  //------------------------------------------
  // METHODS
  //------------------------------------------

  // Constructor
  extern function new(string name="master_agent_top", uvm_component parent);

  // Build phase
  extern function void build_phase(uvm_phase phase);


endclass

// ----------------- Implementation -----------------------

function master_agent_top::new(string name="master_agent_top", uvm_component parent);
  super.new(name,parent);
endfunction

function void master_agent_top::build_phase(uvm_phase phase);
  super.build_phase(phase);

  if(!uvm_config_db #(env_config)::get(this,"","env_config",cfgh))
        `uvm_fatal("ENV_CFG","cannot get env config")

        agnth=new[cfgh.has_no_of_master];
        foreach(agnth[i])
        begin
                uvm_config_db #(m_agent_config)::set(this,$sformatf("agnth[%0d]*",i),"m_agent_config",cfgh.mcfgh[i]);
                agnth[i]=master_agent::type_id::create($sformatf("agnth[%0d]",i),this);
        end

endfunction

///////////////////////////////////////////////////////////////////////////////////////

class master_driver extends uvm_driver #(master_xtn);

  `uvm_component_utils(master_driver)

  m_agent_config mcfgh;

  virtual ahb_if.M_DRV vif;

  extern function new(string name="master_driver", uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern task send_to_dut(master_xtn xtn);
endclass

// implementation
function master_driver::new(string name="master_driver", uvm_component parent);
  super.new(name,parent);
endfunction


//build phase
function void master_driver::build_phase(uvm_phase phase);
  super.build_phase(phase);

  if(!uvm_config_db #(m_agent_config)::get(this,"","m_agent_config",mcfgh))
  `uvm_fatal("config","cannot get config");
endfunction


//connect phase
function void master_driver::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
        vif=mcfgh.vif;
endfunction
task master_driver::send_to_dut(master_xtn xtn);

        `uvm_info("driver",$sformatf("from master_driver %s",xtn.sprint()),UVM_LOW)

        `uvm_info("MASTER_DRV",$sformatf("Time=%0t HREADY=%0b",$time, vif.master_drv_cb.Hready),UVM_LOW)
        wait(vif.master_drv_cb.Hready==1)

                vif.master_drv_cb.Hwrite<=xtn.Hwrite;
                vif.master_drv_cb.Htrans<=xtn.Htrans;
                vif.master_drv_cb.Hsize<=xtn.Hsize;
                vif.master_drv_cb.Haddr<=xtn.Haddr;
                vif.master_drv_cb.Hburst<=xtn.Hburst;
                vif.master_drv_cb.length<=xtn.length;

        @(vif.master_drv_cb);

        wait(vif.master_drv_cb.Hready==1)
        if(xtn.Hwrite)

                vif.master_drv_cb.HWdata<=xtn.HWdata;
        else

                vif.master_drv_cb.HWdata<=0;
endtask

//run_phase
task master_driver::run_phase(uvm_phase phase);
        @(vif.master_drv_cb);
                vif.master_drv_cb.Hresetn<=1'b0;
        @(vif.master_drv_cb);
                vif.master_drv_cb.Hresetn<=1'b1;

        forever
          begin
                seq_item_port.get_next_item(req);
                send_to_dut(req);
                seq_item_port.item_done();
         end
endtask

//////////////////////////////////////////////////////////////////////////////


class master_monitor extends uvm_monitor;

`uvm_component_utils(master_monitor)

m_agent_config mcfgh;

virtual ahb_if.M_MON vif;
master_xtn xtn;

uvm_analysis_port#(master_xtn) monitor_port_m;


extern function new(string name="master_monitor", uvm_component parent);
extern function void build_phase (uvm_phase phase);
extern function void connect_phase (uvm_phase phase);
extern task run_phase(uvm_phase phase);
extern task collect_data();
endclass



function master_monitor::new(string name="master_monitor", uvm_component parent);
super.new(name,parent);
monitor_port_m=new("monitor_port_m",this);
endfunction



function void master_monitor::build_phase (uvm_phase phase);
super.build_phase(phase);
if(!uvm_config_db #(m_agent_config)::get(this, "", "m_agent_config",mcfgh))
`uvm_fatal("config", "cannot get config")
endfunction



function void master_monitor::connect_phase (uvm_phase phase);
super.connect_phase (phase);
vif= mcfgh.vif;
endfunction
task master_monitor::run_phase(uvm_phase phase);
        forever
         begin
                collect_data();
        end
endtask




task master_monitor::collect_data();

    xtn = master_xtn::type_id::create("xtn");

    @(vif.master_mon_cb);
    wait(vif.master_mon_cb.Hready == 1);

    xtn.Haddr  = vif.master_mon_cb.Haddr;
    xtn.Hwrite = vif.master_mon_cb.Hwrite;
    xtn.Hsize  = vif.master_mon_cb.Hsize;
    xtn.Hburst = vif.master_mon_cb.Hburst;
    xtn.Htrans = vif.master_mon_cb.Htrans;
    xtn.length = vif.master_mon_cb.length;
    @(vif.master_mon_cb);
    wait(vif.master_mon_cb.Hready == 1);

    if(xtn.Hwrite)
      xtn.HWdata = vif.master_mon_cb.HWdata;
    else
      xtn.HRdata = vif.master_mon_cb.HRdata;

    `uvm_info("MONITOR",$sformatf("from master monitor %s", xtn.sprint()),UVM_LOW)

        monitor_port_m.write(xtn);

  endtask
//////////////////////////////////////////////////////////////////

class master_seqs extends uvm_sequence #(master_xtn);
        `uvm_object_utils(master_seqs)
        bit [2:0]hsize;
        bit [1:0]htrans;
        bit [31:0]hrdata;
        bit [31:0]hwdata;
        bit [31:0]haddr;
        bit hwrite;
        int len;
        bit [1:0]hresp;
        bit hready;
        bit [2:0]hburst;
        bit [31:0]s_addr;
        bit [31:0]b_addr;
        bit [9:0]length;
        extern function new(string name ="master_seqs");

endclass
        function master_seqs::new(string name ="master_seqs");
                super.new(name);
        endfunction

//single
class single_seqs extends master_seqs;
        `uvm_object_utils(single_seqs)

        extern function new(string name ="single_seqs");
        extern task body();
endclass
        function single_seqs::new(string name ="single_seqs");
                super.new(name);
        endfunction

        task single_seqs::body();
        repeat(1)
        begin
                req=master_xtn::type_id::create("req");
                start_item(req);
                assert(req.randomize() with {Htrans==2'b10;Hburst==3'b000;});
                 uvm_config_db#(bit[9:0])::set(null,"*","length",req.length);

    finish_item(req);
        end
        endtask





//incr-4
class incr_seqs extends master_seqs;
        `uvm_object_utils(incr_seqs)

        extern function new(string name ="incr_seqs");
        extern task body();
endclass
        function incr_seqs::new(string name ="incr_seqs");
                super.new(name);
        endfunction

        task incr_seqs::body();
        repeat(5)
        begin
                req=master_xtn::type_id::create("req");
                start_item(req);
                assert(req.randomize() with {Hwrite==1;Htrans==2'b10;Hburst inside {3,5,7};});
                uvm_config_db #(bit[9:0])::set(null,"*","length",req.length);
                finish_item(req);

                haddr=req.Haddr;
                hwrite=req.Hwrite;
                hsize=req.Hsize;
                hburst=req.Hburst;
                len=req.length;
for(int i=0;i<len-1;i++)
                begin
                        start_item(req);
                        assert(req.randomize() with {Hwrite==hwrite;
                                                        Hsize==hsize;
                                                        Hburst==hburst;
                                                        Htrans==2'b11;
                                                        Haddr==(haddr+(2**hsize));});
                         uvm_config_db#(bit[9:0])::set(null,"*","length",req.length);

                        finish_item(req);
                        haddr=req.Haddr;

                end
        end
        endtask




//wrap-4
class wrap_seqs extends master_seqs;
        `uvm_object_utils(wrap_seqs)

        extern function new(string name ="wrap_seqs");
        extern task body();
endclass
        function wrap_seqs::new(string name ="wrap_seqs");
                super.new(name);
        endfunction

        task wrap_seqs::body();
        repeat(5)
        begin
                req=master_xtn::type_id::create("req");
                start_item(req);
                assert(req.randomize() with {Htrans==2'b10;Hburst inside {2,4,6};});
                 uvm_config_db #(bit[9:0])::set(null,"*","length",req.length);

                finish_item(req);
  haddr=req.Haddr;
                hwrite=req.Hwrite;
                hsize=req.Hsize;
                hburst=req.Hburst;
                len=req.length;


                s_addr=int'((req.Haddr)/((2**req.Hsize)*req.length))*((2**req.Hsize)*req.length);
                $display("starting_addr=%0h",s_addr);
                b_addr=s_addr+(2**req.Hsize)*req.length;
                $display("Boundary_addr=%0h",b_addr);
                haddr=req.Haddr+(2**hsize);

                for(int i=0;i<len-1;i++)
                begin
                        if(haddr==b_addr)
                                haddr=s_addr;
                        start_item(req);
                        assert(req.randomize() with {Hwrite==hwrite;
                                                        Hsize==hsize;
                                                        Hburst==hburst;
                                                        Htrans==2'b11;
                                                        Haddr==haddr;});
                         uvm_config_db#(bit[9:0])::set(null,"*","length",req.length);

                        finish_item(req);
                        haddr=req.Haddr+(2**hsize);

                end
        end
        endtask



//////////////////////////////////////////////////

class master_sequencer extends uvm_sequencer #(master_xtn);

  `uvm_component_utils(master_sequencer)

  extern function new(string name="master_sequencer", uvm_component parent);

endclass

function master_sequencer::new(string name="master_sequencer", uvm_component parent);
  super.new(name,parent);
endfunction

///////////////////////////////////////////////////////////////////
class master_xtn extends uvm_sequence_item;
  `uvm_object_utils(master_xtn)

        rand bit [1:0]Htrans;
        rand bit [2:0]Hsize;
        rand bit [2:0]Hburst;
        rand bit [31:0]HWdata;
        rand bit [31:0]Haddr;
        rand bit Hwrite;
        rand bit [9:0]length;
        bit Hready;
        bit [31:0]HRdata;
        rand bit Hresetn;

        constraint valid_size{Hsize inside{[0:2]};}
        constraint valid_addr{(Hsize==1)->Haddr%2==0;
                                (Hsize==2)->Haddr%4==0;}
        constraint valid_Hburst{if(Hburst==0)
                                        length==1;
                                else if(Hburst==2|Hburst==3)
                                        length==4;
                                else if(Hburst==4|Hburst==5)
                                        length==8;
                                else if(Hburst==6|Hburst==7)
                                        length==16;
                                else if(Hburst==1)
                                        (Haddr%1024)+(length*(2**Hsize))<=1023;}

  extern function new(string name="master_xtn");
  extern function void do_print(uvm_printer printer);
endclass

 function master_xtn::new(string name="master_xtn");
        super.new(name);
 endfunction

 function void master_xtn::do_print(uvm_printer printer);
        super.do_print(printer);

        printer.print_field("Hresetn",this.Hresetn,1,UVM_DEC);
        printer.print_field("Hready",this.Hready,1,UVM_DEC);
        printer.print_field("Htrans",this.Htrans,2,UVM_DEC);
        printer.print_field("Hwrite",this.Hwrite,1,UVM_DEC);
        printer.print_field("Hsize",this.Hsize,8,UVM_DEC);
        printer.print_field("Hburst",this.Hburst,8,UVM_DEC);
        printer.print_field("Haddr",this.Haddr,32,UVM_HEX);
        printer.print_field("HWdata",this.HWdata,32,UVM_HEX);
        printer.print_field("HRdata",this.HRdata,32,UVM_HEX);
        printer.print_field("length",this.length,10,UVM_DEC);

  endfunction

///////////////////////////////////////////////////////
