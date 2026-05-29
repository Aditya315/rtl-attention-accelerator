#! /bin/bash

verilator -sv -Irtl --cc tb/testbench.sv --exe sim_main.cpp --build --timing --Wno-fatal --Wno-UNOPTFLAT --Wno-WIDTH --trace

./obj_dir/Vtestbench