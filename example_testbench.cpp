#include <verilated.h>
#include <verilated_vcd_c.h>
#include <stdio.h>
#include <vector>
#include <time.h>
#include <cmath>
#include <iostream>
#include <filesystem>
#include <fstream>
#include <stdexcept>

using namespace std;

#include "VComputer.h"
#include "VComputer_Computer.h"
#include "VComputer_InstructionMemory.h"
#include "VComputer_PipelineCPU.h"
#include "verilated.h"

#define MAX_CYCLE 1000

void load_inst_mem(VComputer_InstructionMemory *ptr, ifstream in){
    constexpr size_t INST_SIZE = 8192;
    if(INST_SIZE%4){
        // expect size of InstructionMemory is align
        throw runtime_error("size of InstructionMemory is misalign");
    }
    unsigned long long i=0;
    string str;
    CData byte_to_wr;
    while(in>>str){
        if(i>=INST_SIZE){
            throw runtime_error("InstructionMemory not big enough");
        }
        // expect `str` to be a byte in 0/1 string
        if(str.size()!=8){
            throw runtime_error(".mem file format error");
        }
        byte_to_wr=0;
        for(auto &a:str){
            if(a!='0' && a!='1'){
                throw runtime_error(".mem file format error");
            }
            byte_to_wr<<=1;
            byte_to_wr|=(a=='1');
        }
        ptr->insts[i++]=byte_to_wr;
    }
    for(;i<INST_SIZE;i+=4){
        // set to nop
        ptr->insts[i+3] = 0x00;
        ptr->insts[i+2] = 0x00;
        ptr->insts[i+1] = 0x00;
        ptr->insts[i+0] = 0x13;
    }
}

void do_cycle(VerilatedContext *contextp, VerilatedVcdC *m_trace, VComputer *top){
    // flick clk to 1, then flick clk to 0
    top->clk = 1;
    top->eval();
    m_trace->dump(contextp->time());
    contextp->timeInc(1);

    top->clk = 0;
    top->eval();
    m_trace->dump(contextp->time());
    contextp->timeInc(1);
}

int main(int argc, char **argv){
    string mem_file;
    string dump_file="waveform.vcd";
    if(argc>1){
        mem_file=argv[1];
        
        auto sep_pos=mem_file.find_last_of('.');
        if(mem_file.substr(sep_pos+1)!="mem"){
            throw runtime_error("wrong file extension");
        }

        if(!filesystem::exists(mem_file)){
            throw runtime_error(".mem file not found");
        }

        dump_file=mem_file.substr(0,sep_pos)+".vcd";
    }
    bool is_set_end_pc=false;
    bool is_reach_end_pc=false;
    int end_pc;
    if(argc>2){
        try{
            end_pc=stoi(argv[2]);
            is_set_end_pc=true;
        }
        catch(...){}
    }
    
    VerilatedContext *contextp = new VerilatedContext;
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    VComputer *top = new VComputer{contextp};

    contextp->traceEverOn(true);
    contextp->commandArgs(argc, argv);
    
    top->trace(m_trace, 0);
    m_trace->open(dump_file.c_str());

    // reset
    top->rst_n = 0;
    do_cycle(contextp, m_trace, top);

    if(mem_file.size()) load_inst_mem(top->Computer->m_InstMem, ifstream(mem_file));
    do_cycle(contextp, m_trace, top);

    top->rst_n = 1;
    for(int i=0; i<MAX_CYCLE; ++i){
        if(
            is_set_end_pc &&
            top->Computer->m_core0->WB_pc_valid_out &&
            top->Computer->m_core0->WB_pc_out==end_pc
        ){
            is_reach_end_pc=true;
            break;
        }
        do_cycle(contextp, m_trace, top);
    }

    m_trace->dump(contextp->time());
    top->final();
    m_trace->close();

    if(is_set_end_pc){
        if(is_reach_end_pc) cout<<"Yes"<<endl;
        else cout<<"No"<<endl;
    }
    else cout<<"Done\n";

    return 0;
}
