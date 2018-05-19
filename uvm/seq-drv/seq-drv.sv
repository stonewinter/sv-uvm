/************************************
signle sequencer shared by
multiple sequencer
running in parallel 
************************************/


import uvm_pkg::*;
`include "uvm_macros.svh"


class Packet extends uvm_sequence_item;
   `uvm_object_utils(Packet)
   int a;
   int b;
   string msg;
   
   function new(string name="Packet");
      super.new(name);
   endfunction

   function void do_copy(uvm_object rhs);
      Packet RHS;
      if(!$cast(RHS, rhs)) begin
	 `uvm_fatal("Packet", "copy fail");
      end
      super.do_copy(RHS);
      this.a = RHS.a;
      this.b = RHS.b;
      this.msg = RHS.msg;
   endfunction // do_copy


   function bit do_compare(uvm_object rhs, uvm_comparer comparer);
      Packet RHS;
      if(!$cast(RHS, rhs)) begin
	 `uvm_fatal("Packet", "copy compare fail");
      end
      return (super.do_compare(rhs, comparer)
	      && a == RHS.a
	      && b == RHS.b
	      //&& msg == RHS.msg
	      );
   endfunction
   
   function string info();
      return $sformatf("a = %0d, b=%0d, msg = %s", this.a, this.b, this.msg);
   endfunction
endclass // Packet










class SequenceA extends uvm_sequence#(Packet);
   
   `uvm_object_utils_begin(SequenceA)
   `uvm_object_utils_end

   Packet req;

   function new(string name="SequenceA");
      super.new(name);
   endfunction

   task body();
      req = Packet::type_id::create("req packet");
      for(int i=0; i<5; i++) begin
        start_item(req);
        // packet filling up
        req.a = i;
        req.b = i+1;
        req.msg = $sformatf("here is the No.%0d msg in SequenceA", i);
        finish_item(req);
      end
      `uvm_info("SequenceaA", $sformatf("SequenceA has done"), UVM_LOW);
   endtask

endclass // SequenceA






class SequenceB extends uvm_sequence#(Packet);
   
   `uvm_object_utils_begin(SequenceB)
   `uvm_object_utils_end

   Packet req;
   
   function new(string name="SequenceB");
      super.new(name);
   endfunction // new

   task body();
      req = Packet::type_id::create("req packet");
      for(int i=0; i<3; i++) begin
	 start_item(req);
	 req.a = i+10;
	 req.b = i+11;
	 req.msg = $sformatf("here is the No.%0d msg in SequenceB", i);
	 finish_item(req);
      end
      `uvm_info("SequenceB", $sformatf("SequenceB has done"), UVM_LOW);
   endtask
   
endclass // SequenceB









class Driver extends uvm_driver#(Packet);
   
   `uvm_component_utils_begin(Driver)
   `uvm_component_utils_end

   Packet req;
   
   function new(string name="", uvm_component parent);
      super.new(name, parent);
   endfunction // new

   task main_phase(uvm_phase phase);
      forever begin
	 seq_item_port.get_next_item(req);
	 // drive this packet
	 $display("time = %0t, %s", $time, req.info());
	 seq_item_port.item_done();
      end
   endtask

   
endclass // Driver









class Test extends uvm_test;
   
   `uvm_component_utils_begin(Test)
   `uvm_component_utils_end

   SequenceA seqa;
   SequenceB seqb;
   Driver drv;
   uvm_sequencer#(Packet) sqcr;
   
   function new(string name="Test", uvm_component parent);
      super.new(name, parent);
   endfunction // new

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      drv = Driver::type_id::create("drv", this);
      sqcr = new("sqcr", this);
      seqa = SequenceA::type_id::create("seqa", this);
      seqb = SequenceB::type_id::create("seqb", this);
   endfunction

   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      drv.seq_item_port.connect(sqcr.seq_item_export);
   endfunction // connect_phase

   task main_phase(uvm_phase phase);
     phase.raise_objection(this);
      fork
	 seqa.start(sqcr);
	 seqb.start(sqcr);
      join
     phase.drop_objection(this);
   endtask

endclass // Test



module top();
    initial begin
      run_test("Test");
    end

endmodule 

