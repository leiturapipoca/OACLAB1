

module ALUControl (
    input  logic [9:0] Funct10,
    input  logic [1:0] ALUOp,
    output logic [4:0] ALUCtrl
);

`include "Parametros.v"
localparam FUNADD = 10'b0000000_000;
localparam FUNSUB = 10'b0100000_000;
localparam FUNAND = 10'b0000000_111;
localparam FUNOR  = 10'b0000000_110;
localparam FUNSLT = 10'b0000000_010;

always @(*) begin

    
    ALUCtrl = OPADD; // add por default

    case (ALUOp)
        2'b00: ALUCtrl = OPADD; // lw/sw (rs1 + offset)
        2'b01: ALUCtrl = OPSUB; // beq (rs1 - rs2)
        
        2'b10: begin // Instruções Tipo-R
            case (Funct10)
                FUNADD: ALUCtrl = OPADD;
                FUNSUB: ALUCtrl = OPSUB;
                FUNAND: ALUCtrl = OPAND;
                FUNOR : ALUCtrl = OPOR;
                FUNSLT: ALUCtrl = OPSLT;
                default: ALUCtrl = OPADD; // Padrão seguro
            endcase
        end

        //lui
		  2'b11: ALUCtrl = OPLUI; // LUI e um caso a parte e deve ser melhor avaliado no gerador de imediatos
        
        default: ALUCtrl = OPADD; // Padrão seguro
    endcase
end

endmodule