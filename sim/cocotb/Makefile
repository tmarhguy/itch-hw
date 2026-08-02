SIM_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
RTL_ROOT := $(abspath $(SIM_ROOT)/../rtl)

TOPLEVEL_LANG = verilog
TOPLEVEL = itch_hw_tb
MODULE = test_itch_hw

VERILOG_SOURCES += $(SIM_ROOT)/hdl/itch_hw_tb.sv
VERILOG_SOURCES += $(RTL_ROOT)/itch/itch_types.sv
VERILOG_SOURCES += $(RTL_ROOT)/itch/itch_byte_fsm.sv
VERILOG_SOURCES += $(RTL_ROOT)/itch/itch_pipeline.sv
VERILOG_SOURCES += $(RTL_ROOT)/book/lut3_price_cmp.sv
VERILOG_SOURCES += $(RTL_ROOT)/book/order_book.sv
VERILOG_SOURCES += $(RTL_ROOT)/top/itch_hw_core.sv

COMPILE_ARGS += -sv

include $(shell cocotb-config --makefiles)/Makefile.sim

# Resume-scale replay (10M+ messages; use Verilator for speed):
#   make stress SIM=verilator STRESS_MSGS=10000000
stress:
	$(MAKE) SIM=$(SIM) STRESS_MSGS=10000000 MODULE=test_itch_hw TESTCASE=test_stress_replay
