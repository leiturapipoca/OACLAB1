

module Uniciclo (
	input logic clockCPU, clockMem,
	input logic reset,
	output logic [31:0] PC,
	output logic [31:0] Instr,
	input  logic [4:0] regin,
	output logic [31:0] regout
	);
	
	
	initial
		begin
			PC<=32'h0040_0000;
			Instr<=32'b0;
			regout<=32'b0;
		end
		
		//wire [31:0] SaidaULA, Leitura2, MemData;
		//wire EscreveMem;
		
//******************************************
// Aqui vai o seu código do seu processador



// Sinais de Dados
    wire [31:0] wImm;//Saída do ImmGen
    wire [31:0] wReadData1;//Saída rs1 do registers
    wire [31:0] wReadData2;//Saída rs2 do registers
    wire [31:0] wALU_B_In;//Entrada B da ULA (ALUSrc)
    wire [31:0] wWriteData;//Dado a ser escrito no registers (MemToReg)
    wire [31:0] wPC_plus_4;//PC + 4
    wire [31:0] wPC_plus_Imm;//PC + Imediato (beq/jal)
    wire [31:0] wNextPC;//MUX do PC
    wire [31:0] SaidaULA;//Saída da ULA (oResult)
    wire [31:0] MemData;//Saída da memória
	 
	 
	 
	 // Sinais de Controle
    wire wRegWrite;
    wire wALUSrc;
    wire [1:0] wMemToReg;
    wire wMemRead;
    wire wMemWrite;
    wire wBranch;
    wire wJump;
    wire wJumpReg;
    wire [1:0] wALUOp;
    wire [4:0] wALUControl;//Saída do ALUControl
    wire wZero;//Flag 'Zero' da ULA
	 
//Controle	 
Controle U_Controle (
    .iOpcode    (Instr[6:0]),//Opcode 
    .oRegWrite  (wRegWrite),
    .oALUSrc    (wALUSrc),
    .oMemToReg  (wMemToReg),
    .oMemRead   (wMemRead),
    .oMemWrite  (wMemWrite),
    .oBranch    (wBranch),
    .oJump      (wJump),
    .oJumpReg   (wJumpReg),
    .oALUOp     (wALUOp)
);

//Gerador de Imediato
ImmGen U_ImmGen (
    .iInstrucao (Instr),
    .oImm       (wImm)
);

//Registers
Registers U_Registers (
    .iCLK           (clockCPU),
    .iRST           (reset),
    .iRegWrite      (wRegWrite),
    .iReadRegister1 (Instr[19:15]),//rs1
    .iReadRegister2 (Instr[24:20]),//rs2
    .iWriteRegister (Instr[11:7]),//rd
    .iWriteData     (wWriteData),//MemToReg
    .oReadData1     (wReadData1),
    .oReadData2     (wReadData2),
    .iRegDispSelect (regin),//'regout' para visualização
    .oRegDisp       (regout)//Conecta direto na saída do módulo
);

//ALU_Cintroller

ALUControl U_ALUControl (
    .Funct10    ({Instr[31:25], Instr[14:12]}), //Funct10 (7 + 3)
    .ALUOp      (wALUOp),
    .ALUCtrl    (wALUControl)
);

//ULA

ALU U_ALU (
    .iControl   (wALUControl),
    .iA         (wReadData1),//Entrada A é sempre rs1
    .iB         (wALU_B_In),//ALUSrc
    .oResult    (SaidaULA),
    .Zero       (wZero)
);


//ALUSrc
//Se ALUSrc=0, pega rs2. Se ALUSrc=1, pega o Imediato.
assign wALU_B_In = (wALUSrc) ? wImm : wReadData2;

//MemToReg
// Decide o que será escrito de volta no Registrador
assign wWriteData = (wMemToReg == 2'b01) ? MemData ://01:Memória (lw)
                    (wMemToReg == 2'b10) ? wPC_plus_4 ://10:PC+4 (jal/jalr)
                                           SaidaULA;// 00:ULA (Tipo-R/I)
														 
														 
//PC
assign wPC_plus_4   = PC + 32'd4;
assign wPC_plus_Imm = PC + wImm; // Para BEQ e JAL
//AND do beq
wire wTakeBranch = wBranch & wZero;

//PRÓXIMO PC
always @(*)
begin
    if (wJump) // JAL
        wNextPC = wPC_plus_Imm;
    else if (wJumpReg) // JALR
        wNextPC = SaidaULA; // A ULA calcula rs1 + imm
    else if (wTakeBranch) // BEQ
        wNextPC = wPC_plus_Imm;
    else // Padrão
        wNextPC = wPC_plus_4;
end

//Registrador do PC 
//Atualiza o PC na borda do clock com o valor que o MUX decidiu

always @(posedge clockCPU or posedge reset)
begin
    if(reset)
        PC <= TEXT_ADDRESS; 
    else
        PC <= wNextPC;
end



//always @(posedge clockCPU  or posedge reset)
	//if(reset)
		//PC <= 32'h0040_0000;
	//else
		//PC <= PC + 32'd4;

		
		
//assign EscreveMem = 1'b0;
//assign SaidaULA = 32'b0;



ramI MemC (.address(PC[11:2]), .clock(clockMem), .data(), .wren(1'b0), .q(Instr));
ramD MemD (.address(SaidaULA[11:2]), .clock(clockMem), .data(wReadData2), .wren(wMemWrite), .q(MemData));
		

	
		
//*****************************************	
			
endmodule
