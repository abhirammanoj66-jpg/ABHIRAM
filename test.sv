package test_pkg;


        import uvm_pkg::*;
        `include "uvm_macros.svh"
//      `include "tb_defs.sv"
        `include "master_xtn.sv"
        `include "master_agent_config.sv"
        `include "slave_agent_config.sv"
        `include "env_config.sv"

        `include "master_seqs.sv"
        `include "master_driver.sv"
        `include "master_monitor.sv"
        `include "master_sequencer.sv"
        `include "master_agent.sv"
        `include "master_agent_top.sv"
        `include "slave_xtn.sv"
        `include "slave_seqs.sv"
        `include "slave_driver.sv"
        `include "slave_monitor.sv"
        `include "slave_sequencer.sv"
        `include "slave_agent.sv"
        `include "slave_agent_top.sv"
//      `include "uart_virtual_sequencer.sv"
//      `include "uart_virtual_seqs.sv"
        `include "scoreboard.sv"
        `include "env.sv"
        `include "test.sv"
endpackage

///////////////////////////////////////////////
class test extends uvm_test;
  `uvm_component_utils(test)

  // Environment handle
  env      envh;

  // Environment and agent configs
  env_config    cfgh;
  m_agent_config   mcfgh[];
  s_agent_config  scfgh[];

  int has_sb=1;
  int has_master=1;
  int has_slave=1;
  int has_no_of_master=1;
  int has_no_of_slave=1;


  extern function new(string name="test",uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern function void config_test();
  extern function void end_of_elaboration_phase(uvm_phase phase);
endclass

//----------------- Constructor -----------------//
function test::new(string name="test", uvm_component parent);
  super.new(name,parent);
endfunction



function void test::config_test();
        if(has_master)
         begin
                mcfgh=new[has_no_of_master];

                foreach(mcfgh[i])
                 begin
                                mcfgh[i]=m_agent_config::type_id::create($sformatf("mcfgh[%0d]",i));
                                if(!uvm_config_db #(virtual ahb_if)::get(this,"","ahb_if",mcfgh[i].vif))
                                `uvm_fatal("config","cannot get vif")

                                mcfgh[i].is_active=UVM_ACTIVE;
                                cfgh.mcfgh[i]=mcfgh[i];
                 end
         end

 if(has_slave)
         begin
                scfgh=new[has_no_of_slave];

                foreach(scfgh[i])
                 begin
                                scfgh[i]=s_agent_config::type_id::create($sformatf("scfgh[%0d]",i));
                                if(!uvm_config_db #(virtual ahb_if)::get(this,"","ahb_if",scfgh[i].vif))
                                `uvm_fatal("config","cannot get vif")

                                scfgh[i].is_active=UVM_ACTIVE;
                                cfgh.scfgh[i]=scfgh[i];
                 end
         end
        cfgh.has_sb=has_sb;
        cfgh.has_master=has_master;
        cfgh.has_slave=has_slave;
        cfgh.has_no_of_master=has_no_of_master;
        cfgh.has_no_of_slave=has_no_of_slave;

endfunction

//----------------- Build Phase -----------------//
function void test::build_phase(uvm_phase phase);
  super.build_phase(phase);


  cfgh =env_config::type_id::create("cfgh");

   cfgh.mcfgh=new[has_no_of_master];
   cfgh.scfgh=new[has_no_of_slave];
  config_test();

  uvm_config_db#(env_config)::set(this,"*","env_config",cfgh);
  envh =env::type_id::create("envh", this);

endfunction

//----------------- end of elaboration phase -----------------//
function void test::end_of_elaboration_phase(uvm_phase phase);
  uvm_top.print_topology();
endfunction




class single_test extends test;
        `uvm_component_utils(single_test)

        single_seqs seqh;
        sresp_seqs seqh1;
        extern function new(string name="single_test",uvm_component parent);
        extern function void build_phase(uvm_phase phase);
        extern task run_phase(uvm_phase phase);

endclass
 function single_test::new(string name="single_test",uvm_component parent);
                super.new(name,parent);
        endfunction


        function void single_test::build_phase(uvm_phase phase);
                super.build_phase(phase);
        endfunction

        task single_test::run_phase(uvm_phase phase);
                super.run_phase(phase);
                phase.raise_objection(this);
                seqh=single_seqs::type_id::create("seqh");
                seqh1=sresp_seqs::type_id::create("seqh1");
         fork
                seqh.start(envh.m_agnth.agnth[0].seqrh);
                seqh1.start(envh.s_agnth.agnth[0].seqrh);
        join
//      #100;
                phase.drop_objection(this);

        endtask




class incr_test extends test;
        `uvm_component_utils(incr_test)

        incr_seqs seqh;
        sresp_seqs seqh2;
        extern function new(string name="incr_test",uvm_component parent);
        extern function void build_phase(uvm_phase phase);
        extern task run_phase(uvm_phase phase);

endclass

        function incr_test::new(string name="incr_test",uvm_component parent);
                super.new(name,parent);
        endfunction


        function void incr_test::build_phase(uvm_phase phase);
                super.build_phase(phase);
        endfunction

        task incr_test::run_phase(uvm_phase phase);
                super.run_phase(phase);
                phase.raise_objection(this);
                seqh=incr_seqs::type_id::create("seqh");
                seqh2=sresp_seqs::type_id::create("seqh2");
            fork
                seqh.start(envh.m_agnth.agnth[0].seqrh);
                seqh2.start(envh.s_agnth.agnth[0].seqrh);
   join
//              #100;
                phase.drop_objection(this);
        endtask







class wrap_test extends test;
        `uvm_component_utils(wrap_test)

        wrap_seqs seqh;
        sresp_seqs seqh3;
        extern function new(string name="wrap_test",uvm_component parent);
        extern function void build_phase(uvm_phase phase);
        extern task run_phase(uvm_phase phase);

endclass

        function wrap_test::new(string name="wrap_test",uvm_component parent);
                super.new(name,parent);
        endfunction


        function void wrap_test::build_phase(uvm_phase phase);
                super.build_phase(phase);
        endfunction

        task wrap_test::run_phase(uvm_phase phase);
                super.run_phase(phase);
                phase.raise_objection(this);
                seqh=wrap_seqs::type_id::create("seqh");
                seqh3=sresp_seqs::type_id::create("seqh3");
                fork
                seqh.start(envh.m_agnth.agnth[0].seqrh);
                seqh3.start(envh.s_agnth.agnth[0].seqrh);
                join
//#100;
                phase.drop_objection(this);

        endtask
