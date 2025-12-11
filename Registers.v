

module Registers (
    input wire 			iCLK, iRST, iRegWrite, // clock, reset e EscreveReg
    input wire  [4:0] 	iReadRegister1, iReadRegister2, iWriteRegister, //rs1,rs2 e rd de 32 
    input wire  [31:0] 	iWriteData, //dado a ser escrito
    output wire [31:0] 	oReadData1, oReadData2, //dados do rs1 e rs2

    input wire  [4:0] 	iRegDispSelect,
    output reg  [31:0] 	oRegDisp
    );

/* Register file */
reg [31:0] registers[31:0]; //"array de registradores"

parameter  SPR=5'd2, GPR=5'd3;                  // SP e GP conforme especificações

reg [5:0] i;

initial //seta todos os regs pra 0
	begin
		for (i = 0; i <= 31; i = i + 1'b1) 
			registers[i] = 32'd0;
		registers[SPR] <= STACK_ADDRESS;
		registers[GPR] <=DATA_ADDRESS;
	end

//logica combinacional, ou seja, permite a leitura dos 3 regs ao mesmo tempo
assign oReadData1 =	registers[iReadRegister1];
assign oReadData2 =	registers[iReadRegister2];

assign oRegDisp 	=	registers[iRegDispSelect];

//parte síncrona, sensível ao clock e ao reset
always @(posedge iCLK or posedge iRST)
begin
    if (iRST)
    begin // reseta o banco de registradores e pilha
        for (i = 0; i <= 31; i = i + 1'b1)
            registers[i] = 32'b0;
		  registers[SPR] <= STACK_ADDRESS; 
		  registers[GPR] <=DATA_ADDRESS;
    end
    else
	 begin
		i<=6'b0; // para não dar warning
		if(iRegWrite && (iWriteRegister != 5'b0))//se o EscreveReg for um e o rd nao for x0
				registers[iWriteRegister] <= iWriteData; //coloca o dado no rd
	 end
end

endmodule