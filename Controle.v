

module Controle(

	//recebe qual e a insstrucao (add,sub etc)
	input logic [6:0] iOpcode,
	 
	// Sinais de Controle de Saída
    output logic       oRegWrite, // Habilita escrita no Banco de Registradores
    output logic       oALUSrc, // MUX da ULA B (0: Reg[rs2], 1: Imediato)
    output logic [1:0] oMemToReg, // MUX de Write-Back (00: ULA, 01: Mem, 10: PC+4)
    output logic       oMemRead, // Habilita leitura da memória
    output logic       oMemWrite, // Habilita escrita na memória
    output logic       oBranch, // 'beq' (usado com 'Zero' da ULA)
    output logic       oJump, // 'jal'
    output logic       oJumpReg, // 'jalr'
    output logic [2:0] oALUOp// 'Controlador_ULA' (000:Load/Store, 01:Beq, 10:R, 11:I)

);

always @(*)
    begin
        //default p n bugar 
        oRegWrite = 1'b0;//nao registra
        oALUSrc   = 1'b0;//pega a saida do banco de registradores ao inves do gerador de imeediatos
        oMemToReg = 2'b00; //pega o resultado da ULA (01 e load e 10 e PC + 4)
        oMemRead  = 1'b0; //nao le
        oMemWrite = 1'b0; //nao escreve
        oBranch   = 1'b0; //nao e desvio
        oJump     = 1'b0; //nao e jump
        oJumpReg  = 1'b0; // nao e jalr
        oALUOp    = 3'b000; // Padrão
       
		 //leitura do opcode
        case (iOpcode)
            
            // Tipo R (add, sub, and, or, slt)
          OPC_RTYPE:
          begin
                oRegWrite = 1'b1; // Escreve no registrador 'rd'
                oALUSrc   = 1'b0; // ULA B recebe Reg[rs2]
                oMemToReg = 2'b00; // Escreve o resultado da ULA
                oALUOp    = 3'b010; // ALU_control recebe tipo R
            end

            // Tipo I - Imediato (addi)
          OPC_OPIMM:
          begin
                oRegWrite = 1'b1; // Escreve no registrador 'rd'
                oALUSrc   = 1'b1; // ULA B recebe Imediato
                oMemToReg = 2'b00; // Escreve o resultado da ULA
                oALUOp    = 3'b011; // ALU_control recebe tipo I
            end

            // Tipo I - Load (lw)
          OPC_LOAD:
          begin
                oRegWrite = 1'b1; // Escreve no registrador 'rd'
                oALUSrc   = 1'b1; // ULA B recebe imediato (offset)
                oMemToReg = 2'b01; // Escreve o dado vindo da memória
                oMemRead  = 1'b1; // Lê da memória
                oALUOp    = 3'b000; //ALU_control recebe lw/sw
            end

            // Tipo S - Store (sw)
          OPC_STORE:
          begin
                oALUSrc   = 1'b1; // ULA B recebe imediato (offset)
                oMemWrite = 1'b1; // Escreve na memória
                oALUOp    = 3'b000; // ALU_control recebe lw/sw
            end

            // Tipo B - Branch (beq)
          OPC_BRANCH:
          begin
              
                oALUSrc   = 1'b0; // ULA B recebe Reg[rs2] (compara rs1)
                oBranch   = 1'b1; // Habilita beq
                oALUOp    = 3'b001; // ALU_control recebe beq
            end

            // Tipo J - Jump and Link (jal)
          OPC_JAL:
          begin
                oRegWrite = 1'b1; // Escreve no registrador 'rd' 
                oMemToReg = 2'b10; // Escreve o valor de PC+4
                oJump     = 1'b1; // ALU_control recebe jal  pelo mux do PC
                
            end

            // Tipo I - Jump and Link Register (jalr)
          OPC_JALR:
			 begin
                oRegWrite = 1'b1; // Escreve no registrador 'rd'
                oALUSrc   = 1'b1; // ULA B recebe imediato
                oMemToReg = 2'b10; // Escreve o valor de PC+4
                oJumpReg  = 1'b1; // ALU_control recebe jal  pelo mux do PC
                oALUOp    = 1'b011; // Diz ao Controlador_ULA que é Tipo-I (para ULA fazer rs1 + imm)
            end
				
			 OPC_LUI:
          begin
                oRegWrite = 1'b1;     // Escreve em 'rd'
                oALUSrc   = 1'b1;     // ULA B recebe imediato
                oMemToReg = 2'b00;    // Escreve o resultado da ULA
                oALUOp    = 3'b100;   // Diz ao Controlador_ULA que é Tipo-U
            end
            
        endcase
    end
endmodule