## Nexys A7-100T RMII (Digilent master XDC excerpt)

## Included from constraints/nexys_a7_100t.xdc when USE_ETH=1



set_property -dict { PACKAGE_PIN C9   IOSTANDARD LVCMOS33 } [get_ports { eth_mdc }];

set_property -dict { PACKAGE_PIN A9   IOSTANDARD LVCMOS33 } [get_ports { eth_mdio }];

set_property -dict { PACKAGE_PIN B3   IOSTANDARD LVCMOS33 } [get_ports { eth_rstn }];

set_property -dict { PACKAGE_PIN D9   IOSTANDARD LVCMOS33 } [get_ports { eth_crs_dv }];

set_property -dict { PACKAGE_PIN C11  IOSTANDARD LVCMOS33 } [get_ports { eth_rxd[0] }];

set_property -dict { PACKAGE_PIN D10  IOSTANDARD LVCMOS33 } [get_ports { eth_rxd[1] }];

set_property -dict { PACKAGE_PIN B9   IOSTANDARD LVCMOS33 } [get_ports { eth_txen }];

set_property -dict { PACKAGE_PIN A10  IOSTANDARD LVCMOS33 } [get_ports { eth_txd[0] }];

set_property -dict { PACKAGE_PIN A8   IOSTANDARD LVCMOS33 } [get_ports { eth_txd[1] }];

set_property -dict { PACKAGE_PIN D5   IOSTANDARD LVCMOS33 } [get_ports { eth_refclk }];



create_clock -add -name eth_refclk -period 20.000 -waveform {0 10} [get_ports { eth_refclk }];

set_clock_groups -asynchronous -group [get_clocks sys_clk_pin] -group [get_clocks eth_refclk]

