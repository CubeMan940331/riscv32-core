#include <verilated.h>
#include <verilated_vcd_c.h>
#include <stdio.h>
#include <vector>
#include <time.h>
#include <cmath>
#include <iostream>

using namespace std;

#include "VComputer.h"

#define MAX_CYCLE 5000

int main(int argc, char **argv){
    VerilatedContext *contextp = new VerilatedContext;
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    VComputer *top = new VComputer{contextp};

    contextp->traceEverOn(true);
    contextp->commandArgs(argc, argv);

    top->trace(m_trace, 0);
    m_trace->open("waveform.vcd");

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

    for(int i=0; i<MAX_CYCLE; ++i){
        top->clk = !top->clk;
        top->eval();

        m_trace->dump(contextp->time());
        contextp->timeInc(1);
    }

    m_trace->dump(contextp->time());
    top->final();
    m_trace->close();
    
    cout<<endl;
    cout<<"============================"<<endl;
    cout<<"\e[32m\e[1mPASS\e[0m\n"; //can be executed

    return 0;
}
