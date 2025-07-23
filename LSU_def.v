// -----------------------------------------
//  Integer Load & Store
// -----------------------------------------
`define INST_LB  32'h00000003
`define INST_LB_MASK 32'h707f

`define INST_LH  32'h00001003
`define INST_LH_MASK 32'h707f

`define INST_LW  32'h00002003
`define INST_LW_MASK 32'h707f

`define INST_LBU 32'h00004003
`define INST_LBU_MASK 32'h707f

`define INST_LHU 32'h00005003
`define INST_LHU_MASK 32'h707f 

`define INST_LWU 32'h00006003
`define INST_LWU_MASK 32'h707f

`define INST_SB  32'h00000023
`define INST_SB_MASK 32'h707f

`define INST_SH  32'h00001023
`define INST_SH_MASK 32'h707f

`define INST_SW  32'h00002023
`define INST_SW_MASK 32'h707f

// -----------------------------------------
//  Floating Point Load & Store 
// -----------------------------------------
`define INST_FLW 32'h00007003
`define INST_FLW_MASK 32'h707f

`define INST_FSW 32'h00003023
`define INST_FSW_MASK 32'h707f

// `define INST_FLD 
// `define INST_FLD_MASK 

// `define INST_FSD
// `define INST_FSD_MASK

// -----------------------------------------
//  Exception
// -----------------------------------------
`define EXCEPTION_MISALIGNED_LOAD          6'h14
`define EXCEPTION_FAULT_LOAD               6'h15
`define EXCEPTION_MISALIGNED_STORE         6'h16
`define EXCEPTION_FAULT_STORE              6'h17