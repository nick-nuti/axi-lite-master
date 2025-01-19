Small AXI-LITE master IP design (almost everything is combinational; typically would be driven by other logic; timing @ 100MHz can be tight)

![image](https://github.com/user-attachments/assets/f8d0709c-54a5-42de-836b-10a0bca1a561)

Regarding input parameters:
-----
- FLOP_READ_DATA : allows the developer to choose whether or not to flop READ data out and READ data out enable
- USER_START_HAS_PULSE_CONTROL : addresses whether or not the hardware driving this IP has synchronous control of "user_start". If this value is 0 then the state machine has a state after WRITE_RESPONSE and READ_RESPONSE to catch and hold the system from progressing further and starting another operation. Deactivation of user_start will allow the state machine to go back to idle. If this input parameter is set to 1 then it's recommended to only pulse "user_start" for one clock cycle.

Hardware sizes:
-----
- if FLOP_READ_DATA=0 and USER_START_HAS_PULSE_CONTROL=0 then pre-optimization synthesis in vivado shows LUT: 144 and FF: 7
- if FLOP_READ_DATA=0 and USER_START_HAS_PULSE_CONTROL=1 then pre-optimization synthesis in vivado shows LUT: 142 and FF: 4
- if FLOP_READ_DATA=1 and USER_START_HAS_PULSE_CONTROL=0 then pre-optimization synthesis in vivado shows LUT: 112 and FF: 72
- if FLOP_READ_DATA=1 and USER_START_HAS_PULSE_CONTROL=1 then pre-optimization synthesis in vivado shows LUT: 112 and FF: 69
