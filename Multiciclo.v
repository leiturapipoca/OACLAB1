`ifndef PARAM
	`include "Parametros.v"
`endif

module Multiciclo (
	input  logic        clockCPU, 
	input  logic        clockMem, 
	input  logic        reset,
	output logic [31:0] PC, 
	output logic [31:0] Instr,
	input  logic [4:0]  regin,
	output logic [31:0] regout,
	output logic [4:0]  estado //pra visualização na forma de onda
);

	//sinais do controle
	wire 		 c_EscreveIR;
	wire 		 c_EscrevePC;
	wire 		 c_EscrevePCCond;
	wire 		 c_EscrevePCBack;
	wire [1:0] c_OrigAULA;
	wire [1:0] c_OrigBULA;
	wire [1:0] c_Mem2Reg;
	wire 		 c_OrigPC;
	wire 		 c_IouD;
	wire 		 c_RegWrite;
	wire 		 c_MemWrite;
	wire 		 c_MemRead;
	wire [1:0] c_ALUOp;
	
	
	reg [31:0] r_PC;			// Program Counter
	reg [31:0] r_IR;			// Instruction Register (Salva a instrução)
	reg [31:0] r_MDR;			// Memory Data Register (Salva dado lido da mem)
	reg [31:0] r_A;			// Salva rs1
	reg [31:0] r_B;			// Salva rs2
	reg [31:0] r_ALUOut;		// Salva resultado da ULA
	reg [31:0] r_PCBack;		// Salva PC+4

	// Visualização na forma de onda
	assign PC    = r_PC;
	assign Instr = r_IR;

	// Fioss de dados
	wire [31:0] w_MemAddress;		// Endereço efetivo da memória (Vem do MUX IouD)
	wire [31:0] w_MemReadData;		// Dado final lido (Selecionado entre ramI e ramD)
	wire [31:0] w_Instr_Q;			// Saída da ramI
	wire [31:0] w_Data_Q;			// Saída da ramD
	
	wire [31:0] w_RD1, w_RD2;		// Saídas do Banco de Regs
	wire [31:0] w_WD3;				// Dado para escrever no Banco
	wire [31:0] w_Imm;				// Imediato Gerado
	wire [31:0] w_SrcA, w_SrcB;	// Entradas da ULA
	wire [31:0] w_ALUResult;		// Saída da ULA
	wire 			w_Zero;				// Flag Zero
	wire [4:0]  w_ALUControl;		// Controle da ULA
	wire [31:0] w_PC_Next;			// Próximo PC

	// Tudo do codigo do Control_MULTI
	Control_MULTI UnidadeDeControle (
		.iCLK(clockCPU),
		.iRST(reset),
		.Opcode(r_IR[6:0]),		// Opcode vem do IR
		.oEscreveIR(c_EscreveIR),
		.oEscrevePC(c_EscrevePC),
		.oEscrevePCCond(c_EscrevePCCond),
		.oEscrevePCBack(c_EscrevePCBack),
		.oOrigAULA(c_OrigAULA),
		.oOrigBULA(c_OrigBULA),
		.oMem2Reg(c_Mem2Reg),
		.oOrigPC(c_OrigPC),
		.oIouD(c_IouD),
		.oRegWrite(c_RegWrite),
		.oMemWrite(c_MemWrite),
		.oMemRead(c_MemRead),
		.oALUOp(c_ALUOp),
		.oEstado(estado)
	);

	// Escolha do  acesso a memoria
	
	// MUX IouD: Seleciona o endereço (0=PC, 1=ALUOut)
	assign w_MemAddress = (c_IouD == 1'b0) ? r_PC : r_ALUOut;

	// Lógica de Seleção (Bit 28): 1 = Dados, 0 = Instrução
	wire sel_ram_d = w_MemAddress[28];

	// Instância da Memória de Instruções (ramI)
	ramI MemInstr (
		.address(w_MemAddress[11:2]), // Converte Byte Address -> Word Address
		.clock(clockMem),
		.data(r_B), 				  // Write Data (Sempre vem de B)
		.wren(c_MemWrite & ~sel_ram_d), // Escreve SÓ se for pra Instrução (raro)
		.rden(c_MemRead & ~sel_ram_d),  // Lê SÓ se for da Instrução
		.q(w_Instr_Q)
	);

	// Instância da Memória de Dados (ramD)
	ramD MemData (
		.address(w_MemAddress[11:2]), 
		.clock(clockMem),
		.data(r_B), 
		.wren(c_MemWrite & sel_ram_d),  // Escreve SÓ se for pra Dados
		.rden(c_MemRead & sel_ram_d),   // Lê SÓ se for de Dados
		.q(w_Data_Q)
	);

	// MUX de Saída da Memória (Escolhe qual dado entregar pro processador)
	assign w_MemReadData = (sel_ram_d) ? w_Data_Q : w_Instr_Q;


	// MUX OrigAULA (00=PCBack, 01=A, 10=PC)
	assign w_SrcA = (c_OrigAULA == 2'b10) ? r_PC :
						 (c_OrigAULA == 2'b01) ? r_A :
						 r_PCBack;

	// MUX OrigBULA (00=B, 01=4, 10=Imm)
	assign w_SrcB = (c_OrigBULA == 2'b10) ? w_Imm :
						 (c_OrigBULA == 2'b01) ? 32'd4 :
						 r_B;

	// MUX Mem2Reg (00=ALUOut, 01=PCBack, 10=MDR)
	assign w_WD3 = (c_Mem2Reg == 2'b10) ? r_MDR :
						(c_Mem2Reg == 2'b01) ? r_PCBack :
						r_ALUOut;

	// MUX OrigPC (0=ULA Normal, 1=ALUOut Salvo)
	assign w_PC_Next = (c_OrigPC == 1'b1) ? r_ALUOut : w_ALUResult;


	// Banco de Registradores
	Registers BancoRegs (
		.iCLK(clockCPU),
		.iRST(reset),
		.iRegWrite(c_RegWrite),
		.iReadRegister1(r_IR[19:15]),
		.iReadRegister2(r_IR[24:20]),
		.iWriteRegister(r_IR[11:7]),
		.iWriteData(w_WD3),
		.oReadData1(w_RD1),
		.oReadData2(w_RD2),
		
		// Visuallização na forma de onda, colocar regin em 5
		.iRegDispSelect(regin),
		.oRegDisp(regout)
	);

	ImmGen GeradorImm (
		.iInstrucao(r_IR),
		.oImm(w_Imm)
	);

	ALUControl CtrlULA (
		.Funct10({r_IR[31:25], r_IR[14:12]}),
		.ALUOp(c_ALUOp),
		.ALUCtrl(w_ALUControl)
	);

	ALU ULA (
		.iControl(w_ALUControl),
		.iA(w_SrcA),
		.iB(w_SrcB),
		.oResult(w_ALUResult),
		.Zero(w_Zero)
	);

	// Ciclos de clock
	
	wire w_PC_Enable = c_EscrevePC | (c_EscrevePCCond & w_Zero);

	always @(posedge clockCPU or posedge reset) begin
		if (reset) begin
			r_PC 		<= TEXT_ADDRESS; 
			r_PCBack    <= TEXT_ADDRESS;
			r_IR 		<= 32'd0;
			r_MDR 	    <= 32'd0;
			r_A 		<= 32'd0;
			r_B 		<= 32'd0;
			r_ALUOut    <= 32'd0;
		end
		else begin
			if (w_PC_Enable)
				r_PC <= w_PC_Next;

			if (c_EscrevePCBack)
				r_PCBack <= w_ALUResult; 

			if (c_EscreveIR)
				r_IR <= w_MemReadData;

			r_MDR <= w_MemReadData; 
			
			r_A <= w_RD1;
			r_B <= w_RD2;
			
			r_ALUOut <= w_ALUResult;
		end
	end

endmodule