create_clock -name CLOCK_24 -period 42 -waveform {0 21} [get_ports {CLOCK_24}]
derive_pll_clocks -gen_basic_clock
