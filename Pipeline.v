`ifndef PARAM
	`include "Parametros.v"
`endif

module Pipeline (
	input logic clockCPU, clockMem,
	input logic reset,
	output logic [31:0] PC,
	output logic [31:0] Instr,
	input  logic [4:0] regin,
	output logic [31:0] regout,
	output logic [3:0] estado
	);

	// ==============================================================================
	// 1. DEFINIÇÃO DOS REGISTRADORES DE PIPELINE
	// ==============================================================================
	
	reg [63:0] REG_IF_ID; 
	// WB(3) + MEM(4) + EX(5) + PC(32) + A(32) + B(32) + Imm(32) + Func(4) + Rd(5) = 149 bits
	reg [148:0] REG_ID_EX; 
	// WB(3) + MEM(4) + BranchTarget(32) + Zero(1) + ALURes(32) + WriteData(32) + Rd(5) = 109 bits
	reg [108:0] REG_EX_MEM; 
	// WB(3) + ReadData(32) + ALURes(32) + Rd(5) = 72 bits
	reg [71:0]  REG_MEM_WB; 

	// ==============================================================================
	// 2. FIOS (WIRES) GERAIS
	// ==============================================================================
	
	// --- Sinais do Estágio WB (Feedback) ---
	wire wRegWrite_WB;
	wire [4:0]  wRd_WB;
	wire [31:0] wWriteData_WB;

	// --- Estágio IF ---
	wire [31:0] wPC_Next, wPC_Plus4, wInstr_IF;
	// PCSrc agora será decidido pelo estágio MEM (onde validamos o Branch)
	// Mas no pipeline simples, algumas decisões voltam do EX ou MEM.
	// Vamos assumir decisão no MEM para evitar Hazard de controle complexo agora.
	wire PCSrc;         
	wire [31:0] wBranchTarget_MEM; // Vem do estágio MEM

	// --- Estágio ID ---
	wire [31:0] wPC_ID, wInstr_ID;
	wire wRegWrite_ID, wALUSrc_ID, wMemRead_ID, wMemWrite_ID, wBranch_ID, wJump_ID, wJumpReg_ID;
	wire [1:0] wMemToReg_ID;
	wire [2:0] wALUOp_ID;
	wire [31:0] wReadData1_ID, wReadData2_ID, wImm_ID;

	// --- Estágio EX ---
	// Sinais desempacotados do REG_ID_EX
	wire wRegWrite_EX, wMemRead_EX, wMemWrite_EX, wBranch_EX, wJump_EX, wALUSrc_EX, wJumpReg_EX;
	wire [1:0] wMemToReg_EX;
	wire [2:0] wALUOp_EX;
	wire [31:0] wPC_EX, wReadData1_EX, wReadData2_EX, wImm_EX;
	wire [4:0]  wRd_EX;
	wire [2:0]  wFunct3_EX;
	wire wFunct7_EX;

	// Sinais calculados no EX
	wire [4:0]  wALUCtrl;
	wire [31:0] wALUResult, wALUInputB;
	wire wZero_EX;
	wire [31:0] wBranchTarget_EX;

	// --- Estágio MEM ---
	wire wRegWrite_MEM, wMemRead_MEM, wMemWrite_MEM, wBranch_MEM, wJump_MEM, wZero_MEM;
	wire [1:0] wMemToReg_MEM;
	wire [31:0] wALUResult_MEM, wWriteDataMem_MEM;
	wire [4:0] wRd_MEM;
	wire [31:0] wMemReadData_MEM;

	// ==============================================================================
	// 3. ESTÁGIO IF (INSTRUCTION FETCH)
	// ==============================================================================
	
	assign wPC_Plus4 = PC + 4;
	
	// Se PCSrc (decidido no MEM) for 1, pula para o endereço calculado
	assign wPC_Next = (PCSrc) ? wBranchTarget_MEM : wPC_Plus4; 

	always @(posedge clockCPU or posedge reset) begin
		if (reset) PC <= 32'h0040_0000;
		else       PC <= wPC_Next;
	end

	ramI MemC (.address(PC[11:2]), .clock(clockMem), .data(32'b0), .wren(1'b0), .q(wInstr_IF));
	assign Instr = wInstr_IF; 

	always @(posedge clockCPU or posedge reset) begin
		if (reset) REG_IF_ID <= 64'b0;
		else       REG_IF_ID <= {PC, wInstr_IF}; 
	end

	assign wPC_ID    = REG_IF_ID[63:32];
	assign wInstr_ID = REG_IF_ID[31:0];

	// ==============================================================================
	// 4. ESTÁGIO ID (INSTRUCTION DECODE)
	// ==============================================================================

	Controle CtrlUnit (
		.iOpcode(wInstr_ID[6:0]),
		.oRegWrite(wRegWrite_ID), .oALUSrc(wALUSrc_ID), .oMemToReg(wMemToReg_ID),
		.oMemRead(wMemRead_ID), .oMemWrite(wMemWrite_ID), .oBranch(wBranch_ID),
		.oJump(wJump_ID), .oJumpReg(wJumpReg_ID), .oALUOp(wALUOp_ID)
	);

	Registers RegFile (
		.iCLK(clockCPU), .iRST(reset), .iRegWrite(wRegWrite_WB), 
		.iReadRegister1(wInstr_ID[19:15]), .iReadRegister2(wInstr_ID[24:20]), 
		.iWriteRegister(wRd_WB), .iWriteData(wWriteData_WB), 
		.oReadData1(wReadData1_ID), .oReadData2(wReadData2_ID),
		.iRegDispSelect(regin), .oRegDisp(regout)
	);

	ImmGen ImmediateGen (.iInstrucao(wInstr_ID), .oImm(wImm_ID));

	// Escrita no ID/EX
	always @(posedge clockCPU or posedge reset) begin
		if (reset) REG_ID_EX <= 149'b0;
		else REG_ID_EX <= {
			wRegWrite_ID, wMemToReg_ID, // WB (3 bits)
			wMemRead_ID, wMemWrite_ID, wBranch_ID, wJump_ID, // MEM (4 bits)
			wALUSrc_ID, wALUOp_ID, wJumpReg_ID, // EX (5 bits)
			wPC_ID, wReadData1_ID, wReadData2_ID, wImm_ID, // Dados (128 bits)
			wInstr_ID[30], wInstr_ID[14:12], wInstr_ID[11:7] // Funct e Rd (9 bits)
		};
	end

	// ==============================================================================
	// 5. ESTÁGIO EX (EXECUTE)
	// ==============================================================================
	
	// 5.1 Desempacotamento do ID/EX
	assign {wRegWrite_EX, wMemToReg_EX} = REG_ID_EX[148:146];
	assign {wMemRead_EX, wMemWrite_EX, wBranch_EX, wJump_EX} = REG_ID_EX[145:142];
	assign {wALUSrc_EX, wALUOp_EX, wJumpReg_EX} = REG_ID_EX[141:137];
	assign wPC_EX        = REG_ID_EX[136:105];
	assign wReadData1_EX = REG_ID_EX[104:73];
	assign wReadData2_EX = REG_ID_EX[72:41];
	assign wImm_EX       = REG_ID_EX[40:9];
	assign wFunct7_EX    = REG_ID_EX[8];
	assign wFunct3_EX    = REG_ID_EX[7:5];
	assign wRd_EX        = REG_ID_EX[4:0];

	// 5.2 Controlador da ULA
	// Precisamos concatenar funct7 e funct3 para o formato Funct10 

	
	//vetor de 10 bits fictício onde o bit mais alto é o funct7 e os 3 baixos sao funct3.
	wire [9:0] wFunct10_Combined = {wFunct7_EX, 6'b000000, wFunct3_EX}; 

	ALUControl AluCtrlUnit (
		.Funct10(wFunct10_Combined), 
		.ALUOp(wALUOp_EX), 
		.ALUCtrl(wALUCtrl)
	);

	// 5.3 MUX da entrada B da ULA
	assign wALUInputB = (wALUSrc_EX) ? wImm_EX : wReadData2_EX;

	// 5.4 ULA (ALU)
	ALU MainALU (
		.iControl(wALUCtrl),
		.iA(wReadData1_EX),
		.iB(wALUInputB),
		.oResult(wALUResult),
		.Zero(wZero_EX)
	);

	// 5.5 Cálculo do Branch Target (PC + Imm)
	assign wBranchTarget_EX = wPC_EX + wImm_EX;

	// Escrita no EX/MEM
	always @(posedge clockCPU or posedge reset) begin
		if (reset) REG_EX_MEM <= 109'b0;
		else REG_EX_MEM <= {
			wRegWrite_EX, wMemToReg_EX, // WB (3)
			wMemRead_EX, wMemWrite_EX, wBranch_EX, wJump_EX, // MEM (4)
			wBranchTarget_EX, // 32
			wZero_EX, // 1
			wALUResult, // 32
			wReadData2_EX, // 32 (Dado para Store)
			wRd_EX // 5
		};
	end

	// ==============================================================================
	// 6. ESTÁGIO MEM (MEMORY ACCESS)
	// ==============================================================================
	
	// 6.1 Desempacotamento do EX/MEM
	assign {wRegWrite_MEM, wMemToReg_MEM} = REG_EX_MEM[108:106];
	assign {wMemRead_MEM, wMemWrite_MEM, wBranch_MEM, wJump_MEM} = REG_EX_MEM[105:102];
	assign wBranchTarget_MEM = REG_EX_MEM[101:70];
	assign wZero_MEM         = REG_EX_MEM[69];
	assign wALUResult_MEM    = REG_EX_MEM[68:37];
	assign wWriteDataMem_MEM = REG_EX_MEM[36:5];
	assign wRd_MEM           = REG_EX_MEM[4:0];

	// 6.2 Lógica de Branch (AND entre Branch e Zero, ou Jumps)
	// Se for BEQ (Branch=1 e Zero=1) OU se for Jump (Jump=1), então PCSrc = 1
	assign PCSrc = (wBranch_MEM & wZero_MEM) | wJump_MEM;

	// 6.3 Acesso à Memória de Dados
	ramD MemD (
		.address(wALUResult_MEM[11:2]), 
		.clock(clockMem), 
		.data(wWriteDataMem_MEM), 
		.wren(wMemWrite_MEM), 
		.q(wMemReadData_MEM)
	);

	// Escrita no MEM/WB
	always @(posedge clockCPU or posedge reset) begin
		if (reset) REG_MEM_WB <= 72'b0;
		else REG_MEM_WB <= {
			wRegWrite_MEM, wMemToReg_MEM, // WB (3)
			wMemReadData_MEM, // 32 (Dado Lido)
			wALUResult_MEM, // 32 (Resultado ULA)
			wRd_MEM // 5
		};
	end

	// ==============================================================================
	// 7. ESTÁGIO WB (WRITE BACK)
	// ==============================================================================
	
	wire [1:0] wMemToReg_WB;
	wire [31:0] wMemReadData_WB, wALUResult_WB;

	// 7.1 Desempacotamento do MEM/WB
	assign {wRegWrite_WB, wMemToReg_WB} = REG_MEM_WB[71:69];
	assign wMemReadData_WB = REG_MEM_WB[68:37];
	assign wALUResult_WB   = REG_MEM_WB[36:5];
	assign wRd_WB          = REG_MEM_WB[4:0];

	// 7.2 MUX do Write Back (Seleciona o que vai ser escrito no registrador)
	// 00: Resultado ULA, 01: Memória, 10: PC+4 
	assign wWriteData_WB = (wMemToReg_WB == 2'b01) ? wMemReadData_WB : wALUResult_WB; 
	

endmodule