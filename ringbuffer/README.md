
![image](https://github.com/user-attachments/assets/ecb06ab8-192d-4c60-8882-061f4e31d6ee)

![image](https://github.com/user-attachments/assets/932cdbc0-c9dd-4ee7-8d08-643a0ecc2b9e)

Still in-progress... 
- Need to optimize IP sizes: ringbuffers with controls (174 LUTs, 24 FFs), axilite master (155 LUTs, 211 FFs) after submodule synthesis [would improve after running implementation in vivado]

Idea of project:
---------------

-> "ringbuffer_ctl.sv" has 2 ringbuffers, one for CMD (command) and another for RESP (response). 
- A command is pushed to the command buffer by a CPU. A command is popped out of the command buffer by the AXI-LITE IP.
- A response is pushed to the response buffer by the AXI-LITE IP. A response is popped out of the response buffer by a CPU.

-> "parameter NUM_ENTRIES=6," in "ringbuffer_v_to_sv.v" indicates the number of packets that the ringbuffers can have stored at one time.

Files:
------
- ringbuffer.sv : general ringbuffer IP (this IP does not clean up data on it's own; it will leave dirty data inside unless overwritten)
- req_pulse_ack.sv : takes an input request from a cpu or IP and produces an ACK (if ACK isn't fast enough then produces a req pulse which is what the AXI-LITE IP uses)
- ringbuffer_ctl.sv : bundles the request-acknowledgement and ringbuffer IP's for command and response
- ringbuffer_v_to_sv.v : houses the *.sv internals so it can be used in the vivado schematic (vivado inherently doesn't allow *.sv modules into the schematic system)
- axilite_master.v : pipelined axi-lite master

This system:
------------

CPU (simulation) W/R command -> CMD REQ PUSH -> CMD ringbuffer -> CMD REQ POP -> AXI-LITE IP (does commands)
AXI-LITE IP (sends back response) -> RESP REQ PUSH -> RESP ringbuffer -> RESP REQ POP -> CPU (simulation)
