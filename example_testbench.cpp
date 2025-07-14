#include <verilated.h>
#include <verilated_vcd_c.h>
#include <stdio.h>
#include <vector>
#include <time.h>
#include <cmath>
#include <iostream>

using namespace std;

#include "VPipelineCPU.h"

#define max_cycles 5000

VerilatedContext *contextp = new VerilatedContext;
VerilatedVcdC *m_trace = new VerilatedVcdC;
VPipelineCPU *top = new VPipelineCPU{contextp};

void PipelineCPUTest(int cycle){
    // reset
    top->clk = 0;
    top->rst_n = 1;
    top->eval();
    m_trace->dump(contextp->time());
    contextp->timeInc(1);

    top->clk = 1;
    top->rst_n = 0;
    top->eval();
    m_trace->dump(contextp->time());
    contextp->timeInc(1);

    // rst_n clocking
    top->clk = 0;
    top->rst_n = 1;
    top->eval();
    m_trace->dump(contextp->time());
    contextp->timeInc(1);

    top->clk = 1;
    top->rst_n = 1;
    top->eval();
    m_trace->dump(contextp->time());
    contextp->timeInc(1);

    for(int i=0; i<cycle; ++i){
        top->clk = !top->clk;
        top->eval();

        m_trace->dump(contextp->time());
        contextp->timeInc(1);
    }

}

int main(int argc, char **argv){
    contextp->traceEverOn(true);
    contextp->commandArgs(argc, argv);

    top->trace(m_trace, 0);
    m_trace->open("waveform.vcd");


    PipelineCPUTest(max_cycles);

    m_trace->dump(contextp->time());
    top->final();
    m_trace->close();
    delete top;
    delete contextp;

    cout<<endl;
    cout<<"============================"<<endl;
    cout<<"\e[32m\e[1mPASS\e[0m\n"; //can be executed
    for (int i = 0; i < 32; ++i)
        printf("x%02d = 0x%08x\n", i, top->r[i]);

    return 0;
}
