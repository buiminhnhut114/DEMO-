##################################################################################################
# Makefile – UART TB runner (include "run_test.v")
# Works even when PATH doesn't include ModelSim (vlog/vsim) & folders have spaces.
# Updated: 2025-10-23
##################################################################################################

# ========= User vars =========
TESTNAME      ?= run_test          # ../testcases/<TESTNAME>.v
TB_NAME       ?= test_bench
RADIX         ?= decimal
REGRESS_LIST  ?= pat.list

# ---- ModelSim (Intel) tool paths (CHANGE if your install is elsewhere) ----
VSIM_BIN ?= C:/intelFPGA/20.1/modelsim_ase/win32aloem
VLIB := "$(VSIM_BIN)/vlib.exe"
VMAP := "$(VSIM_BIN)/vmap.exe"
VLOG := "$(VSIM_BIN)/vlog.exe"
VSIM := "$(VSIM_BIN)/vsim.exe"

# Always use local modelsim.ini in current dir (avoid spaces in path)
MODELSIM_INI := modelsim.ini
MI           := -modelsimini $(MODELSIM_INI)

.PHONY: all all_wave all_cov build build_cov run run_cov wave regress gen_cov gen_html clean help

all: build run
all_wave: build run wave
all_cov: build_cov run_cov

# ========= Build =========
# Note: tb/test_bench.v MUST contain:  `include "run_test.v"`
build:
	@mkdir -p log
	@cp -f ../testcases/$(TESTNAME).v run_test.v
	@echo "[INFO] VSIM_BIN = $(VSIM_BIN)"
	@echo "[INFO] Tools: VLIB=$(VLIB) VLOG=$(VLOG) VSIM=$(VSIM)"
	@if [ ! -f "$(MODELSIM_INI)" ]; then \
		echo "[INIT] Creating local modelsim.ini"; \
		$(VMAP) -c >/dev/null; \
	fi
	@$(VLIB) work 2>/dev/null || true
	@$(VMAP) $(MI) work work >/dev/null 2>&1 || true
	@echo "[BUILD] Compiling with local ini: $(MODELSIM_INI)"
	@$(VLOG) $(MI) -sv +incdir+. -f compile.f | tee compile.log

build_cov:
	@mkdir -p log
	@cp -f ../testcases/$(TESTNAME).v run_test.v
	@if [ ! -f "$(MODELSIM_INI)" ]; then \
		echo "[INIT] Creating local modelsim.ini"; \
		$(VMAP) -c >/dev/null; \
	fi
	@$(VLIB) work 2>/dev/null || true
	@$(VMAP) $(MI) work work >/dev/null 2>&1 || true
	@echo "[BUILD] Compiling (coverage) with local ini: $(MODELSIM_INI)"
	@$(VLOG) $(MI) -sv +cover=bcesft +incdir+. -f compile.f | tee compile.log

# ========= Run =========
run:
	@$(VSIM) $(MI) -debugDB -l $(TESTNAME).log -voptargs=+access -assertdebug \
	    -c $(TB_NAME) -do "log -r /*; run -all;"
	@cp -f $(TESTNAME).log ./log/ 2>/dev/null || true
	@mv -f $(TESTNAME).log sim.log

run_cov:
	@$(VSIM) $(MI) -coverage -l $(TESTNAME).log -c $(TB_NAME) -voptargs="+cover=bcesft" \
	    -assertdebug -do "coverage save -onexit $(TESTNAME).ucdb; log -r /*; run -all"
	@cp -f $(TESTNAME).log ./log/ 2>/dev/null || true
	@mv -f $(TESTNAME).log sim.log

wave:
	@$(VSIM) $(MI) -i -view vsim.wlf -do "add wave vsim:/$(TB_NAME)/*; radix -$(RADIX)" &

# ========= Regression (optional) =========
regress:
	@echo "[Make] Running regression from $(REGRESS_LIST)"
	@rc=0; \
	while IFS= read -r t || [ -n "$$t" ]; do \
		[ -z "$$t" ] && continue; \
		echo "=================== $$t : BUILD ==================="; \
		$(MAKE) --no-print-directory TESTNAME=$$t build || rc=1; \
		echo "=================== $$t : RUN   ==================="; \
		$(MAKE) --no-print-directory TESTNAME=$$t run   || rc=1; \
	done < $(REGRESS_LIST); \
	exit $$rc

# ========= Coverage utils =========
gen_cov:
	@mkdir -p coverage
	@"$(VSIM_BIN)/vcover.exe" merge IP.ucdb *.ucdb
	@"$(VSIM_BIN)/vcover.exe" report IP.ucdb -output coverage/summary_report.txt
	@"$(VSIM_BIN)/vcover.exe" report -zeros -details -code bcesft -annotate -All -codeAll IP.ucdb \
	    -output coverage/detail_report.txt

gen_html:
	@mkdir -p coverage
	@"$(VSIM_BIN)/vcover.exe" merge IP.ucdb *.ucdb
	@"$(VSIM_BIN)/vcover.exe" report -zeros -details -code bcesft -annotate -testhitdataAll -html IP.ucdb

# ========= Housekeeping =========
clean:
	- rm -rf work
	- rm -rf vsim.dbg
	- rm -rf *.ini
	- rm -rf *.log log/*.log
	- rm -rf *.wlf
	- rm -rf transcript
	- rm -rf *.ucdb
	- rm -rf run_test.v

help:
	@echo ""
	@echo "****************************************"
	@echo "** make clean       : clean all compiled data"
	@echo "** make build       : build the design (+incdir+.)"
	@echo "** make build_cov   : build the design in coverage mode"
	@echo "** make run         : run simulation"
	@echo "** make run_cov     : run simulation in coverage mode"
	@echo "** make all         : build and run simulation"
	@echo "** make all_cov     : build and run simulation in coverage mode"
	@echo "** make wave        : open waveform"
	@echo "** make regress     : run all tests listed in $(REGRESS_LIST)"
	@echo "** make gen_cov     : merge & generate text coverage report"
	@echo "** make gen_html    : merge & generate HTML coverage report"
	@echo "****************************************"
	@echo ""
