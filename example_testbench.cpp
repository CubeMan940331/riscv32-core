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
#include "VComputer_DataMemory.h"
#include "VComputer_PipelineCPU.h"
#include "verilated.h"

#define MAX_CYCLE 20000
void load_data_mem(VComputer_DataMemory *ptr, ifstream in){
    constexpr size_t INST_SIZE = 65536;
    sizeof(ptr->mem.m_storage);
    if(INST_SIZE%4){
        // expect size of DataMemory is align
        throw runtime_error("size of DataMemory is misalign");
    }
    unsigned long long i=0;
    string str;
    CData byte_to_wr;
    while(in>>str){
        if(i>=INST_SIZE){
            throw runtime_error("DataMemory not big enough");
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
        ptr->mem[i++]=byte_to_wr;
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
    
    bool is_set_tohost_addr=false;
    uint32_t tohost_addr;
    if(argc>2){
        try{
            tohost_addr=stoul(argv[2]);
            is_set_tohost_addr=true;
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

    if(mem_file.size()){
        load_data_mem(top->Computer->m_DataMemory, ifstream(mem_file));
    }
    do_cycle(contextp, m_trace, top);

    IData mem_data;
    top->rst_n = 1;
    for(int i=0; i<MAX_CYCLE; ++i){
        if(is_set_tohost_addr){
            if(
                top->Computer->d_mem_addr==tohost_addr &&
                top->Computer->d_mem_wr_en
            ){
                mem_data = top->Computer->d_mem_wr_data;
                break;
            }
        }
        do_cycle(contextp, m_trace, top);
    }

    m_trace->dump(contextp->time());
    top->final();
    m_trace->close();

    if(is_set_tohost_addr){
        if(mem_data==1) cout<<"Yes\n";
        else cout<<"No\n";
    }
    else cout<<"Done\n";

    return 0;
}
