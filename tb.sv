class env_config extends uvm_object;

  `uvm_object_utils(env_config)

  bit has_sb=1;
  bit has_master=1;
  bit has_slave=1;
 int has_no_of_master=1;
 int has_no_of_slave=1;


 m_agent_config mcfgh[];
 s_agent_config scfgh[];

 extern function new(string name="env_config");

endclass

// -----------------------
function env_config::new(string name="env_config");
  super.new(name);
endfunction
////////////////////////////////////////////////
class env extends uvm_env;

  `uvm_component_utils(env)

  // Sub-environment handles
  master_agent_top  m_agnth;
  slave_agent_top   s_agnth;

  // Scoreboard handle
  scoreboard sb;

  // Environment config handle
  env_config cfgh;

  //------------------------------------------
  // Methods
  //------------------------------------------
  extern function new(string name="env", uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);

endclass

function env::new(string name="env", uvm_component parent);
  super.new(name,parent);
endfunction

function void env::build_phase(uvm_phase phase);
  super.build_phase(phase);

  // Get environment config from DB
  if(!uvm_config_db#(env_config)::get(this,"","env_config", cfgh))
    `uvm_fatal("CONFIG","Cannot get env_config from UVM config DB")


 if(cfgh.has_master)
   begin
        m_agnth=master_agent_top::type_id::create("m_agnth",this);
  end
if(cfgh.has_slave)
    begin
        s_agnth = slave_agent_top::type_id::create("s_agnth",this);
    end

  // ----------------------------
  // Scoreboard
  // ----------------------------
  if(cfgh.has_sb)
    sb = scoreboard::type_id::create("sb", this);
endfunction


function void env::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  m_agnth.agnth[0].monh.monitor_port_m.connect(sb.fifo_h_m.analysis_export);
  s_agnth.agnth[0].monh.monitor_port_s.connect(sb.fifo_h_s.analysis_export);
endfunction

///////////////////////////////////////////////////////////////////////////
class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)

   uvm_tlm_analysis_fifo #(master_xtn) fifo_h_m;
   uvm_tlm_analysis_fifo #(slave_xtn) fifo_h_s;

   master_xtn mh;
   master_xtn mcovh;

   slave_xtn sh;
   slave_xtn  scovh;

   covergroup master_cov;
        option.per_instance=1;

        ADDR:coverpoint mcovh.Haddr{
                        bins addr={[0:32'hffff_ffff]};}
        BURST:coverpoint mcovh.Hburst{
                        bins burst[]={[0:7]};}
        SIZE:coverpoint mcovh.Hsize{
                        bins size[]={0,1,2};}
        TRANS:coverpoint mcovh.Htrans{
                        bins trans[]={2,3};}
        WRITE: coverpoint mcovh.Hwrite{
                        bins write[]={0,1};}
  endgroup

   covergroup slave_cov;
        option.per_instance=1;

        RESP:coverpoint scovh.Hresp{
                        bins resp={0,1};}
   endgroup
 extern function new(string name="scoreboard", uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);


endclass

function scoreboard::new(string name="scoreboard", uvm_component parent);
  super.new(name,parent);
  master_cov=new();
  slave_cov=new();
endfunction



function void scoreboard::build_phase(uvm_phase phase);
  super.build_phase(phase);
  fifo_h_m=new("fifo_h_w",this);
  fifo_h_s=new("fifo_h_s",this);
endfunction


task scoreboard::run_phase(uvm_phase phase);
 super.run_phase(phase);
 forever
   begin
    fork
        fifo_h_m.get(mh);
        fifo_h_s.get(sh);
     join


        mh.print();
        sh.print();
         // Write Operation

    if (mh.Hwrite)
     begin
      if(mh.HWdata == sh.HWdata)
        `uvm_info("SB", "WRITE MATCH", UVM_LOW)
      else
        `uvm_info("SB", "WRITE MISMATCH", UVM_LOW)
    end


    // Read Operation

    else
     begin
      if(mh.HRdata == sh.HRdata)
        `uvm_info("SB", "READ MATCH", UVM_LOW)
      else
        `uvm_info("SB", "READ MISMATCH", UVM_LOW)
    end


    mcovh = mh;
    master_cov.sample();

    scovh = sh;
    slave_cov.sample();

  end
endtask

///////////////////////////////////////////////////////////////////////////
module top;

    import test_pkg::*;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    bit clock=0;

    always
        #10 clock = ~clock;

    //instantiate clock
    ahb_if ahbif(clock);

    initial
     begin
        `ifdef VCS
            $fsdbDumpvars(0, top);
        `endif

        uvm_config_db #(virtual ahb_if)::set(null, "*", "ahb_if", ahbif);
        run_test();
    end

endmodule

