

module ALUControl (
    input  logic [9:0] Funct10,
    input  logic [2:0] ALUOp,
    output logic [4:0] ALUCtrl
);


localparam FUNADD = 10'b0000000_000;
localparam FUNSUB = 10'b0100000_000;
localparam FUNAND = 10'b0000000_111;
localparam FUNOR  = 10'b0000000_110;
localparam FUNSLT = 10'b0000000_010;

always @(*) begin

    
    ALUCtrl = OPADD; // add por default

    case (ALUOp)
        3'b000: ALUCtrl = OPADD; // lw/sw (rs1 + offset)
        3'b001: ALUCtrl = OPSUB; // beq (rs1 - rs2)
        
        3'b010: begin // Instruções Tipo-R
            case (Funct10)
                FUNADD: ALUCtrl = OPADD;
                FUNSUB: ALUCtrl = OPSUB;
                FUNAND: ALUCtrl = OPAND;
                FUNOR : ALUCtrl = OPOR;
                FUNSLT: ALUCtrl = OPSLT;
                default: ALUCtrl = OPADD; // Padrão seguro
            endcase
        end

        //addi e jalr
        3'b011: ALUCtrl = OPADD; // (rs1 + imediato)
		  3'b100: ALUCtrl = OPLUI; // LUI
        
        default: ALUCtrl = OPADD; // Padrão seguro
    endcase
end

endmodule