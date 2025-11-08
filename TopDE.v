`include "Parametros.v"

module TopDE (
	input logic CLOCK, Reset,
	input logic [4:0] Regin,
	output logic ClockDIV,
	output logic [31:0] PC,Instr,Regout,
	output logic [3:0] Estado
	);
	logic [1:0] counter;
		
	assign ClockDIV = counter[1]; 

    always @(posedge CLOCK or posedge Reset)
    begin
        if (Reset)
            counter <= 2'b0;
        else
            counter <= counter + 1;
    end
	 
	
	Uniciclo UNI1 (.clockCPU(ClockDIV), .clockMem(CLOCK), .reset(Reset), 
						.PC(PC), .Instr(Instr), .regin(Regin), .regout(Regout)); 

					
/*	Multiciclo MULT1 (.clockCPU(ClockDIV), .clockMem(CLOCK), .reset(Reset), 
						.PC(PC), .Instr(Instr), .regin(Regin), .regout(Regout), .estado(Estado);	*/
						
/* Pipeline PIP1 (.clockCPU(ClockDIV), .clockMem(CLOCK), .reset(Reset), 
						.PC(PC), .Instr(Instr), .regin(Regin), .regout(Regout)); */
		
	
endmodule
