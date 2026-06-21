Bit Movement Engine

A hardware block that copies an arbitrary-length bitfield between two memory
locations at the bit level — source and destination can each start at any
bit offset within a 32-bit word, not just on word boundaries.

The engine has a simple slave register interface for configuration and a
pipelined master memory interface for the actual transfer. An AHB bridge is
included to connect the engine onto a standard AMBA AHB bus.

bitmove.sv          core engine: FSM, datapath, register file
bitmove_intf.svh   engine-side interface (slave + master modports)
ahb_bridge.sv        protocol bridge: bitmove interface <-> AHB
ahb_if.sv          AHB-side interfaces (master + slave

ahb_bridge.sv        protocol bridge: bitmove interface ↔ AHB

Design summary
- 32-bit word-addressed master interface, 2-cycle pipelined (address phase / data phase split)
- Bit-level transfers: both source and destination offsets are independent and arbitrary (0–31)
- Read-modify-write only on the first and last destination words; middle words are full overwrites
- 64-bit funnel shift register with carry-forward (preserved) to handle payload bits that straddle a word boundary
- mHold backpressure freezes the entire FSM combinationally — no counters or addresses advance until the slave is ready
- AHB bridge translates the engine's native interface to/from HADDR, HWDATA, HTRANS, HBUSREQ, HREADYin, etc.
