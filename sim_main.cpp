#include "Vtestbench.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

vluint64_t main_time = 0;

double sc_time_stamp() {
    return main_time;
}

int main(int argc, char** argv) {

    Verilated::commandArgs(argc, argv);

    Verilated::traceEverOn(true);

    Vtestbench* top = new Vtestbench;

    VerilatedVcdC* tfp = new VerilatedVcdC;

    top->trace(tfp, 99);

    tfp->open("./output/attention_waveform.vcd");

    while (!Verilated::gotFinish()) {

        top->eval();

        tfp->dump(main_time);

        main_time++;
    }

    tfp->close();

    delete tfp;
    delete top;

    return 0;
}