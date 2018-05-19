/***********************************
virtual sequence
in fact, virtual is just a sequence collection wrapper
which orgrainzes all sub-sequences and assign them with their 
own sequencer.
 
this virtual sequence is useful only when you have
several individual sub-envs that need their own sequencer to run separately.
in this case, virtual sequence is the very top sequence wrapper for the very
top test
************************************/
import uvm_pkg::*;
`include "uvm_macros.svh"


class Packet extends uvm_sequence_item;
   
   `uvm_object_utils_begin(Packet)
   `uvm_object_utils_end

   int a;
   int b;
   string msg;

   function new(string name="Packet");
      super.new(name);
   endfunction

   function void do_copy(uvm_object rhs);
      Packet RHS;
      if(!$cast(RHS, rhs)) begin
	 `uvm_fatal("Packet", "can not do copy");
      end

      super.do_copy(RHS);
      this.a = RHS.a;
      this.b = RHS.b;
      this.msg = RHS.msg;
   endfunction // do_copy

  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
      Packet RHS;
      if(!$cast(RHS, rhs)) begin
	 `uvm_fatal("Packet", "can not do compare");
      end
    
      return (super.do_compare(RHS, comparer)
              && this.a == RHS.a
	      	  && this.b == RHS.b);
   endfunction

   function string info();
      return $sformatf("a = %0d, b = %0d", this.a, this.b);
   endfunction

endclass // Packet







class SequenceA extends uvm_sequence#(Packet);
   
   `uvm_object_utils_begin(SequenceA)
   `uvm_object_utils_end

   Packet req;

   function new(string name="SequenceA");
      super.new(name);
      req = Packet::type_id::create("req packet");
   endfunction // new

   task body();
     for(int i=0;i<10;i++) begin
        #1;
	 start_item(req);
	 req.a = i;
	 req.b = i+1;
	 req.msg = $sformatf("here is NO.%0d msg from SequenceA, %s", i, req.info());
	 finish_item(req);
      end
      `uvm_info("SequenceA", $sformatf("SequenceA has done"), UVM_LOW);
   endtask // body

endclass // SequenceA






class SequenceB extends uvm_sequence#(Packet);
   
   `uvm_object_utils_begin(SequenceB)
   `uvm_object_utils_end

   Packet req;

   function new(string name="SequenceB");
      super.new(name);
      req = Packet::type_id::create("req packet");
   endfunction // new

   task body();
     for(int i=0;i<8;i++) begin
        #3;
	 start_item(req);
	 req.a = i+1;
	 req.b = i+2;
	 req.msg = $sformatf("here is NO.%0d msg from SequenceB, %s", i, req.info());
	 finish_item(req);
      end
   endtask
   
endclass // SequenceB







class DriverA extends uvm_driver#(Packet);
   
   `uvm_component_utils_begin(DriverA)
   `uvm_component_utils_end

   Packet req;

   function new(string name="", uvm_component parent);
      super.new(name, parent);
   endfunction

   task main_phase(uvm_phase phase);
      forever begin
	 seq_item_port.get_next_item(req);
	 `uvm_info("DriverA", req.msg, UVM_LOW);
	 seq_item_port.item_done();
      end
   endtask

endclass // DriverA







class DriverB extends uvm_driver#(Packet);
   
   `uvm_component_utils_begin(DriverB)
   `uvm_component_utils_end

   Packet req;

   function new(string name="", uvm_component parent);
      super.new(name, parent);
   endfunction

   task main_phase(uvm_phase phase);
      forever begin
	 seq_item_port.get_next_item(req);
	 `uvm_info("DriverB", req.msg, UVM_LOW);
	 seq_item_port.item_done();
      end
   endtask

endclass // DriverA






class Vseq extends uvm_sequence;
   
   `uvm_object_utils_begin(Vseq)
   `uvm_object_utils_end

   SequenceA seqa;
   SequenceB seqb;
   uvm_sequencer#(Packet) sqcrA;
   uvm_sequencer#(Packet) sqcrB;

   function new(string name="Vseq");
      super.new(name);
   endfunction // new


  function void get_sequencers(uvm_sequencer#(Packet) sqcrA,  uvm_sequencer#(Packet) sqcrB);
      this.sqcrA = sqcrA;
      this.sqcrB = sqcrB;
   endfunction


   task pre_body();
      seqa = SequenceA::type_id::create("seqa");
      seqb = SequenceB::type_id::create("seqb");
   endtask // pre_body
   

   task body();
      fork
      	seqa.start(sqcrA, this);
      	seqb.start(sqcrB, this);
      join
   endtask
   
endclass // Vseq








class Test extends uvm_test;
   
   `uvm_component_utils_begin(Test)
   `uvm_component_utils_end

   Vseq vseq;
   uvm_sequencer#(Packet) sqcrA;
   uvm_sequencer#(Packet) sqcrB;
   DriverA drvA;
   DriverB drvB;
   
   function new(string name="", uvm_component parent);
      super.new(name, parent);
   endfunction // new


   function void build_phase(uvm_phase phase);
      vseq = Vseq::type_id::create("vseq");
      sqcrA = new("seqr A", this);
      sqcrB = new("seqr B", this);
      drvA = DriverA::type_id::create("drvA", this);
      drvB = DriverB::type_id::create("drvB", this);
   endfunction // build_phase


   function void connect_phase(uvm_phase phase);
      vseq.get_sequencers(sqcrA, sqcrB);
      drvA.seq_item_port.connect(sqcrA.seq_item_export);
      drvB.seq_item_port.connect(sqcrB.seq_item_export);
   endfunction // connect_phase


   task main_phase(uvm_phase phase);
      phase.raise_objection(this);
      vseq.start(null);
      phase.drop_objection(this);
   endtask // main_phase

endclass // Test




module top();
   initial begin
      run_test("Test");
   end
endmodule



