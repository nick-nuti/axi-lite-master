# axi-lite-master
Generic AXI-LITE Master IP

- Small : Small and more-combinational implementation of AXI-LITE master
- Regular : AXI-LITE master with flopped ports and one-stage pipelining implemented
- Ringbuffer : Implements a Command ringbuffer and a Response ringbuffer connect to my "Regular" version of AXI-LITE master; minimal latency between operations

Tutorials:
- https://zipcpu.com/formal/2018/12/28/axilite.html
- https://www.realdigital.org/doc/a9fee931f7a172423e1ba73f66ca4081

In-Progress:
---
- considering adding conditional ports for read and write stall...
