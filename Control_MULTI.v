
// Bloco de Controle do Multiciclo

module Control_MULTI(



	input 				iCLK,iRST, 			//clock e reset
	input		[6:0]		Opcode, 				//identifica quall tipo de instrução
	output				oEscreveIR, 		//habillita o registrador de instruções
	output				oEscrevePC, 		//habilita escrita no PC
	output				oEscrevePCCond,	//identifica se o beq e verdaadeiro
	output				oEscrevePCBack,	//salva o endereço caso necesssite de retorno (jal ou jalr), se n att
	output	[1:0]		oOrigAULA,			//1 operando da ULA (00 = Vem do PCBack // 01 = Vem do Banco de Registradores(rs1) // 010 = Vem do PC)
	output	[1:0]		oOrigBULA,			//2 operando da ULA (00 = Vem do Banco de Registradores(rs2) // 001 = 4 (Pra fazer PC+ 4) // 010 = Vem do Gerador de Imediatos)
	output	[1:0]		oMem2Reg,			//De onde vem o dado a ser escrito no banco de registradores (00 = saida da ULA (tipo I e tipo R) // 01  = PCBack[retorno do jal jalr] // 10 = Registrador de Dado da Memória). Ele segura a instrução ate o momento da escrita.
	output				oOrigPC,				//De onde vem PC (0 = PC + 4 // 1 = SaídaULA (jal ou jjalr))
	output				oIouD,				//Indica o motivo da consulta na memória, se busca uma instrução ou um dado (0 = instrução (procura a instrução na posição de PC) // 1 = dado(saida da ula pra pegar o offset))
	output				oRegWrite,			//Habilita escrita no  banco de registradores (tipo-r, load e jal jalr)
	output				oMemWrite,			//Habilita escrita na memoria (sw)
	output				oMemRead,			//Habilita leitura da memória (lw e na leitura da instrução)
	output	[1:0]		oALUOp,				//Le o Funct3 e Funct7 da instrução, pra ver se e add,sub etc (00 = adicao // 01 = subtração // 10 = analisar funct // 11 = lui).
	output	[4:0]		oEstado				//Facilitar visualização dos estados na forma de onda
	

);

`include "Parametros.v"
reg	[4:0]	pr_state; // present state
wire	[4:0] nx_state;  //next_state

	localparam ST_FETCH       = 5'd0;
	localparam ST_FETCH1      = 5'd1;
	localparam ST_DECODE      = 5'd2;
	localparam ST_LWSW        = 5'd3;
	localparam ST_LW          = 5'd4;
	localparam ST_LW1         = 5'd5;
	localparam ST_LW2         = 5'd6;
	localparam ST_SW          = 5'd7;
	localparam ST_SW1         = 5'd8;
	localparam ST_RTYPE       = 5'd9;
	localparam ST_ULAREGWRITE = 5'd10;
	localparam ST_BRANCH      = 5'd11;
	localparam ST_LUI         = 5'd12;
	localparam ST_ADDI        = 5'd13;
	localparam ST_ADDI1       = 5'd14;
	localparam ST_JAL         = 5'd15;
	localparam ST_JALR        = 5'd16;
	
assign oEstado = pr_state; //facilitar a visualização na forma de onda

//a cada ciclo de Clock
always @ (posedge iCLK or posedge iRST)
	begin
		if (iRST)
			pr_state <= ST_FETCH; //se resetou, volta pro estado inicial
		else
			pr_state <= nx_state; // próximo estado
	end
	
	
always @(*)

	case (pr_state)
		//estado somente para accesso de memoria
		ST_FETCH:	//0
			begin
				oEscreveIR		<= 1'b0;
				oEscrevePC		<= 1'b0; 	
				oEscrevePCCond	<= 1'b0; 	
				oEscrevePCBack <= 1'b0; 	
				oOrigAULA		<= 2'b00;	//Se tiver dando errado, mudar pra ficar igual ao fetch1
				oOrigBULA		<= 2'b00;	// Se tiver dando errado, mudar para ficar igual ao fetch1
				oMem2Reg			<= 2'b00;
				oOrigPC			<= 1'b0;
				oIouD				<= 1'b0;	
				oRegWrite		<= 1'b0;
				oMemWrite		<= 1'b0;
				oMemRead			<= 1'b1; 	// Só acessa a memória e não faz mais nada
				oALUOp			<= 2'b00;
				nx_state			<= ST_FETCH1;
			end
		
		ST_FETCH1:	//1
			begin
				oEscreveIR		<= 1'b1; 	// escreve a instrução lida da memória
				oEscrevePC		<= 1'b1; 	// o PC sempre deve ser atualizado após um estado, seja por PC + 4 ou PC imm, n fica na mesma instrucao
				oEscrevePCCond	<= 1'b0; 	// nao e beq,nao ha necessidade de verificar
				oEscrevePCBack	<= 1'b1; 	// n e desvio, salva PC + 4
				oOrigAULA		<= 2'b10; 	// Poe PC na entrada da ULA
				oOrigBULA		<= 2'b01; 	// Poe 4 na entrada da ULA
				oMem2Reg			<= 2'b00;	// Poe a saída da ULA (PC + 4) pra salvar no Banco de Registradores
				oOrigPC			<= 1'b0; 	// Fala pro controle que e PC + 4
				oIouD				<= 1'b0;		// Indica que está buscando uma instrução
				oRegWrite		<= 1'b0;		// Nao tem rd
				oMemWrite		<= 1'b0;		// Nao e sw
				oMemRead			<=	1'b1;		// Garante os 2 cicclos
				oALUOp			<= 2'b00;		// Indica soma pra ULA (PC + 4)
				nx_state			<= ST_DECODE;
			end
		
		ST_DECODE:	// 2
			begin
				oEscreveIR		<= 1'b0;		// Nao escreve nada na memoria de instrucao, vai apenas identificala
				oEscrevePC		<= 1'b0;		// Nao atualiza o PC
				oEscrevePCCond <= 1'b0;		// Nao atualiza o PC
				oEscrevePCBack	<= 1'b0;		// Nao atualiza o PC
				oOrigAULA		<= 2'b00;	// Pega a instrução atual (talvez precise mudar???)
				oOrigBULA		<= 2'b10;		// Gerador de imediatos, pega os OPCodes?? Não tenho ctz
				oMem2Reg			<= 2'b00;	// Não tá trabalhando com escrita
				oOrigPC			<= 1'b0;		// Nao e jal
				oIouD				<= 1'b0;		// Tanto Faz
				oRegWrite		<= 1'b0;		// Na decodificcação não escreve
				oMemWrite		<= 1'b0;		// Na decodificcação não escreve
				oMemRead			<= 1'b0;		// Ja leu da memória na etapa anterior
				oALUOp			<= 2'b00;		// Nao sei pq e soma
				// Durante a analise do opcode
				case (Opcode)
						OPC_LOAD:	nx_state 	<= ST_LWSW;
						OPC_STORE:	nx_state		<= ST_LWSW;
						OPC_RTYPE:	nx_state		<= ST_RTYPE;
						OPC_BRANCH:	nx_state		<= ST_BRANCH;
						OPC_JAL:		nx_state		<= ST_JAL;
						OPC_LUI:		nx_state		<= ST_LUI;
						OPC_OPIMM:	nx_state		<= ST_ADDI;
						default:		nx_state		<= ST_FETCH;
				endcase
			end
		
		ST_LWSW:	//3
			begin
				oEscreveIR		<= 1'b0; 	// Nao escreve nada na memoria de instrucao
				oEscrevePC		<= 1'b0;		// Nao escreve nada no PC
				oEscrevePCCond	<= 1'b0;		// Nao e branch
				oEscrevePCBack <= 1'b0;		// Nao muda endereço de retorno
				oOrigAULA		<= 2'b01;	// Pega o registrador para pegar ou escrever o valor
				oOrigBULA		<= 2'b10;	// Calcula o offset
				oMem2Reg			<= 2'b00;	// Segura a instrucao que tava na saida da ULA pra identificar o opcode
				oOrigPC			<= 1'b0;		// Nao mexe com o PC
				oIouD				<= 1'b0;		// Esse estado e somente a distincao do sw/lw, entao analisa a instrucao para pegar o opcode
				oRegWrite		<= 1'b0;		// Nao sabe se e load ainda
				oMemWrite		<= 1'b0;		// Nao sabe se e store ainda
				oMemRead			<= 1'b0;		// Ainda nao sabe qual e a instrucao
				oALUOp			<= 2'b00;	// Pega a saida da ULA que é o rs1 + offset do immgen
				// Analisaa o opcode
				case (Opcode)
					OPC_LOAD:		nx_state		<= ST_LW;
					OPC_STORE:		nx_state		<= ST_SW;
					default:			nx_state		<= ST_FETCH;
				endcase
			end
			
		ST_LW:	// 4
			begin
				oEscreveIR		<= 1'b0;		// Nao escreve na memoria de instruca
				oEscrevePC		<= 1'b0;		// Nao escreve no PC
				oEscrevePCCond <= 1'b0;		// Nao e branch
				oEscrevePCBack <= 1'b0;		// Nao escreve no PC
				oOrigAULA		<= 2'b01;	// Tanto faz, já sabemos o registrador a ser operado, repetindo o outro esstado
				oOrigBULA		<= 2'b10;	// Tanto faz, já sabemos o offset, repetindo o outro esstado
				oMem2Reg			<= 2'b00;	// Ainda nao escreve nada, primmeiro deve acessar
				oOrigPC			<= 1'b0;		// Nao importa o PC agora
				oIouD				<= 1'b1;		// A consulta a memmoria esta sendo feita para buscar um dado
				oRegWrite		<= 1'b0;		// Ainda nao escreve pois nao pegamos o dado ainda
				oMemWrite		<= 1'b0;		// Nao precisa escrever nada na memoria
				oMemRead			<= 1'b1;		// Load le da memoria
				oALUOp			<= 2'b00;	// Tanto faz, ja tinhamos pego o rs1 + offset,repetindo o outro esstado
				nx_state			<= ST_LW1;	// Garante os 2 ciclos pra mexer na memoria exigido pelo quartus
			end
			
		ST_LW1:	// 5
			begin
				oEscreveIR		<= 1'b0;		// Nao escreve na memoria de instruca
				oEscrevePC		<= 1'b0;		// Nao escreve no PC
				oEscrevePCCond <= 1'b0;		// Nao e branch
				oEscrevePCBack <= 1'b0;		// Nao escreve no PC
				oOrigAULA		<= 2'b01;	// Tanto faz, já sabemos o registrador a ser operado, repetindo o outro esstado (tlvz mudar p 0)
				oOrigBULA		<= 2'b10;	// Tanto faz, já sabemos o offset, repetindo o outro esstado (tlvz mudar p 0)
				oMem2Reg			<= 2'b00;	// Ainda nao escreve nada, primmeiro deve acessar
				oOrigPC			<= 1'b0;		// Nao importa o PC agora
				oIouD				<= 1'b1;		// A consulta a memmoria esta sendo feita para buscar um dado
				oRegWrite		<= 1'b0;		// Ainda nao escreve pois nao pegamos o dado ainda
				oMemWrite		<= 1'b0;		// Nao precisa escrever nada na memoria
				oMemRead			<= 1'b1;		// Load le da memoria
				oALUOp			<= 2'b00;	// Tanto faz, ja tinhamos pego o rs1 + offset,repetindo o outro esstado
				nx_state			<= ST_LW2;	// load word e o mais demorado, pois acessa a memoria depois escreve no banco de regs, entao ncessita de outro estado
			end
			
		// Esse estado escreve no Banco de Registradores
		ST_LW2:	// 6
			begin
				oEscreveIR		<= 1'b0;		// Nao escreve na memoria de instruc
				oEscrevePC		<= 1'b0;		// Nao escreve nada no PC
				oEscrevePCCond <= 1'b0;		// Nao e branch
				oEscrevePCBack	<= 1'b0;		// Nao mexe com PC
				oOrigAULA		<= 2'b01;	// Tanto faz, repetindo (tlvz mudar p 0)
				oOrigBULA		<= 2'b10;	// Tanto faz, repetindo (tlvz mudar p 0)
				oMem2Reg			<= 2'b10;	// Indica que o que vai ser escrito no banco de registradores veio da memoria
				oOrigPC			<= 1'b0;		// Nao mexemos com PC
				oIouD				<= 1'b0;		// Tanto faz, já pegamos o dado da memoria
				oRegWrite		<= 1'b1;		// Habilita a escrita do dado no Banco de Registradores
				oMemWrite		<= 1'b0;		// Nao le nada
				oMemRead			<= 1'b0;		// A leitura foi no passo anterior
				oALUOp			<= 2'b00;	// Tanto faz, ja tinhamos pego o rs1 + offset,repetindo o outro esstado
				nx_state			<= ST_FETCH;// Volta ao estado inicial
			end
		
		ST_SW:	// 7
			begin
				oEscreveIR		<= 1'b0;		// Nao esrceve na memoria de instrucao, so no de dados
				oEscrevePC		<= 1'b0;		// Nao escreve no PC
				oEscrevePCCond	<= 1'b0;		// Nao e beq
				oEscrevePCBack	<= 1'b0;		// Nao mexe com PC
				oOrigAULA		<= 2'b01;	// Tanto faz, no swlw já fez o rs1 + offset, mantendo (tlvz mudar p 0)
				oOrigBULA		<= 2'b10;	// Tanto faz, no swlw já fez o rs1 + offset, mantendo (tlvz mudar p 0)
				oMem2Reg			<= 2'b00;	// Nao faz escrita no banco de registradores, tanto faz
				oOrigPC			<= 1'b0;		// Nao mexe com o PC
				oIouD				<= 1'b1;		// A consulta na memoria esta procurando um dado
				oRegWrite		<= 1'b0;		// Nao vamos escrever no Bando de Registradores
				oMemWrite		<=	1'b1;		// Vamos escrever na memoria
				oMemRead			<= 1'b0;		// Nao vamos ler nada da memoria
				oALUOp			<= 2'b00;	// Tanto faz, já sabemos o endereco de rs1 + imm que veio do lwsw
				nx_state			<= ST_SW1;
			end
			
		ST_SW1:	// 8
			begin
				oEscreveIR		<= 1'b0;		// Nao esrceve na memoria de instrucao, so no de dados
				oEscrevePC		<= 1'b0;		// Nao escreve no PC
				oEscrevePCCond	<= 1'b0;		// Nao e beq
				oEscrevePCBack	<= 1'b0;		// Nao mexe com PC
				oOrigAULA		<= 2'b01;	// Tanto faz, no swlw já fez o rs1 + offset, mantendo (tlvz mudar p 0)
				oOrigBULA		<= 2'b10;	// Tanto faz, no swlw já fez o rs1 + offset, mantendo (tlvz mudar p 0)
				oMem2Reg			<= 2'b00;	// Nao faz escrita no banco de registradores, tanto faz
				oOrigPC			<= 1'b0;		// Nao mexe com o PC
				oIouD				<= 1'b1;		// A consulta na memoria esta procurando um dado
				oRegWrite		<= 1'b0;		// Nao vamos escrever no Bando de Registradores
				oMemWrite		<=	1'b1;		// Vamos escrever na memoria
				oMemRead			<= 1'b0;		// Nao vamos ler nada da memoria
				oALUOp			<= 2'b00;	// Tanto faz, já sabemos o endereco de rs1 + imm que veio do lwsw
				nx_state			<= ST_FETCH;
			end
			
		ST_RTYPE:	// 9
			begin
				oEscreveIR		<= 1'b0;		// Nao escreve na memoria de instrucao, so no de dados
				oEscrevePC		<= 1'b0;		// Nao escreve no PC
				oEscrevePCCond <= 1'b0;		// Nao e branch
				oEscrevePCBack	<= 1'b0;		// Nao mexe no PC
				oOrigAULA		<= 2'b01;	// Coloca o rs1 para o calculo 
				oOrigBULA		<= 2'b00;	// Coloca o rs2 para o calculo
				oMem2Reg			<= 2'b00;	// Indica que o dado a ser escrito vem da ULA
				oOrigPC			<= 1'b0;		// Nao mexe com PC
				oIouD				<= 1'b0;		// Tanto faz, nao estamos consultando com memoria
				oRegWrite		<= 1'b0;		// Ainda nao escreve
				oMemWrite		<= 1'b0;		// Nao acessamos a memoria
				oMemRead			<= 1'b0;		// Nao acessamos a memoria
				oALUOp			<= 2'b10;	// Indicamos que deve analisar o funct3 e funct 7 pra saber se e add, sub etc
				nx_state			<= ST_ULAREGWRITE;
			end
			
		ST_ULAREGWRITE:// 10
			begin
				oEscreveIR		<= 1'b0;		// Nao escreve na memoria de instrucao, so dados
				oEscrevePC		<= 1'b0;		// Nao mexe com PC
				oEscrevePCCond	<= 1'b0;		// Nao mexe com PC
				oEscrevePCBack	<= 1'b0;		// Nao mexe com PC
				oOrigAULA		<= 2'b01;	// Indica que usaremos rs1 (tanto faz, ja pegamos no ultimo)
				oOrigBULA		<= 2'b00;	// Indica que usaremos rs2 (tanto faz, ja pegamos no ultimo)
				oMem2Reg			<= 2'b00;	// O dado a ser escrito vem da ula
				oOrigPC			<= 1'b0;		// Nao mexxe com PC
				oIouD				<= 1'b0;		// Nao estamos consultando a memoria
				oRegWrite		<= 1'b1;		// Vaamos escrever no banco de registradores
				oMemWrite		<= 1'b0;		// Nao acessamos a memoria
				oMemRead			<= 1'b0;		// Nao acessamos a memoria
				oALUOp			<= 2'b10;	// se der ruim mude pra 00
				nx_state			<= ST_FETCH;
			end
		
		ST_BRANCH:	//11
			begin
				oEscreveIR		<= 1'b0;		// Nao escreve na memoria de instrucao
				oEscrevePC		<= 1'b0;		// nao e no estagio de branch q o pc e rreesccrito
				oEscrevePCCond	<= 1'b1;		// analisa a condicao
				oEscrevePCBack	<= 1'b0;		// nao e nesse estaagio que o pc e atualizado
				oOrigAULA		<= 2'b01;	// usa o rs1 pra verificar igualdade
				oOrigBULA		<= 2'b00;	// ussa o rs2 pra verificar a igualdade
				oMem2Reg			<= 2'b00;	// vai escrever  a saida da ula
				oOrigPC			<= 1'b1;		// indica que o pc  vai sair da ula
				oIouD				<= 1'b0;		// Nao ha consulta na memoria
				oRegWrite		<= 1'b0;		// Nao escreve no registrador
				oMemWrite		<= 1'b0; 	// Nao escreve nada na memoria
				oMemRead			<= 1'b0;		// Nao faz leitura da memoria
				oALUOp			<= 2'b01;		// Indica que deve ser feito uma subtacao
				nx_state			<= ST_FETCH;
			end
			
		ST_LUI:	// 12
			begin
				oEscreveIR		<= 1'b0;		//	Nao escreve na memoria de instrucao
				oEscrevePC		<= 1'b0;		// Nao mexe no PC
				oEscrevePCCond <= 1'b0;		// Nao e beq
				oEscrevePCBack	<= 1'b0;		// Nao mexe cocm pc
				oOrigAULA		<= 2'b00;	// Tanto faz, so precisa do imediato
				oOrigBULA		<= 2'b10;	// Qual numero vai ser usado
				oMem2Reg			<= 2'b00;	// Escreve a saida da ULA no rd
				oOrigPC			<= 1'b0;		// Nao mexe com PC
				oIouD				<= 1'b0;		// Nao mexe na memoria
				oRegWrite		<= 1'b1; 	// Habilita a escrita no Banco de registradores
				oMemWrite		<= 1'b0;		// Nao acessa a memoria
				oMemRead			<= 1'b0;		// Nao le nada da memoria
				oALUOp			<=	2'b11;		// faz o lui
				nx_state			<= ST_FETCH;
		end
			
		ST_ADDI:	// 13
			begin
				oEscreveIR		<= 1'b0;		// Nao escreve na memoria de instrucao
				oEscrevePC		<= 1'b0;		// Nao escreve no PC
				oEscrevePCCond	<= 1'b0;		// Não e beq
				oEscrevePCBack	<=	1'b0;		// nao mexe compc
				oOrigAULA		<=	2'b01;	// Rs1 pra somar o imediato
				oOrigBULA		<= 2'b10;	// Soma o imediato do addi
				oMem2Reg			<= 2'b00;	// Pega a saida da ULA
				oOrigPC			<= 1'b0;		// Nao mexe no pc
				oIouD				<= 1'b0;		// Nao mexe na memoria
				oRegWrite		<= 1'b0;		// Ainda nao escreve como no rtype
				oMemWrite		<= 1'b0;		// Nao acessa a memoria
				oMemRead			<= 1'b0;		// Nao acessa a memoria
				oALUOp			<= 2'b00;		// realiza uma soma
				nx_state			<= ST_ADDI1;
			end
		
		ST_ADDI1:	// 14
			begin
				oEscreveIR		<= 1'b0;		// Nao mexe pc
				oEscrevePC		<= 1'b0;		// Nao escreve no PC
				oEscrevePCCond	<= 1'b0;		// Nao mexe no pc
				oEscrevePCBack	<= 1'b0;		// Nao mexe no ppcc
				oOrigAULA		<= 2'b01;	// Mantem por estabilidade
				oOrigBULA		<= 2'b10;	// Mantem por estabilidade
				oMem2Reg			<= 2'b00;	// Pega a saida da ULA
				oOrigPC			<= 1'b0;		// Nao mexe no pc
				oIouD				<= 1'b0;		// Nao mexe na memoria
				oRegWrite		<= 1'b1;		// Agora ativa a escrita
				oMemWrite		<= 1'b0;		// Nao acessa a memoria
				oMemRead			<= 1'b0;		// Nao acessa a memoria
				oALUOp			<= 2'b00;	// mantem
				nx_state			<= ST_FETCH;
			end
			
		ST_JAL:	// 15
			begin
				oEscreveIR		<= 1'b0;		// Nao atualiza a instrucao lida
				oEscrevePC		<= 1'b1;		// Muda o PC para a nova posicao
				oEscrevePCCond	<= 1'b0;		// Nao e beq
				oEscrevePCBack	<=	1'b0;		// Nao muda o endereco de retorno, apenas de ida
				oOrigAULA		<= 2'b00;	// Ja foi pre calculado no decode (tlvz mudar pra 0)
				oOrigBULA		<=	2'b10;	// Ja foi pre calculado no decode (tlvz mudar pra 0)
				oMem2Reg			<=	2'b01;	// Vai salvar o retorno no Banco de Registradoress
				oOrigPC			<= 1'b1;		// O PC  vai pegar a saidad a ULA
				oIouD				<= 1'b0;		// Nao mexe na memoria
				oRegWrite		<= 1'b1;		// Vai salvar o endereço de retorno
				oMemWrite		<= 1'b0;		// Nao mexe na memoria
				oMemRead			<=	1'b0;		// Nao acessa a memoria
				oALUOp			<= 2'b00;	// Mantem a soma
				nx_state			<= ST_FETCH;	
			end
			
		ST_JALR:	//16
			begin
				oEscreveIR		<= 1'b0;		// Nao atualiza instrucao lida
				oEscrevePC		<= 1'b1;		// Escreve no PC
				oEscrevePCCond	<=	1'b0;		// Nao e beq
				oEscrevePCBack	<=	1'b0;		// Nao muda o endereco de rettorno
				oOrigAULA		<=	2'b01;	// usa o rs1 pra registrar argumento
				oOrigBULA		<= 2'b10;	// Imediato pra onde vai pular
				oMem2Reg			<= 2'b01;	// Vai salvar o retorno no banco de registradores
				oOrigPC			<= 1'b1;		// PC vem da ULA
				oIouD				<= 1'b0;		// Nao acessa a memoria
				oRegWrite		<= 1'b1;		// Salva o retorno
				oMemWrite		<=	1'b0;		// nao mexe na memoria
				oMemRead			<=	1'b0;		// nao mexe na memoria
				oALUOp			<= 2'b00;	// indica soma do endereco
				nx_state			<= ST_FETCH;
			end
		endcase
		
endmodule
			
		
					
				
		
		
				
						