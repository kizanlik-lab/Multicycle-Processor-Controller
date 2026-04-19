module controller (input  logic 		  clk, reset,
						 input  logic [6:0] op,
						 input  logic [2:0] funct3,
						 input  logic 		  funct7b5,
						 input  logic       Zero,
						 output logic [1:0] ImmSrc,
						 output logic [1:0] ALUSrcA, ALUSrcB,
						 output logic [1:0] ResultSrc,
						 output logic		  AdrSrc,
						 output logic [2:0] ALUControl,
						 output logic		  IRWrite, PCWrite,
						 output logic 		  RegWrite, MemWrite); 

	logic [1:0] ALUOp;
	logic       Branch, PCUpdate;

	mainfsm m1  (.clk(clk), 
					 .reset(reset), 
					 .op(op), 
					 .ALUSrcA(ALUSrcA), 
					 .ALUSrcB(ALUSrcB), 
					 .ResultSrc(ResultSrc),
				    .ALUOp(ALUOp), 
					 .AdrSrc(AdrSrc), 
					 .IRWrite(IRWrite),
					 .RegWrite(RegWrite), 
					 .MemWrite(MemWrite),
				    .PCUpdate(PCUpdate), 
					 .Branch(Branch));

	aludec a1   (.opb5(op[5]), 
					 .funct3(funct3), 
					 .funct7b5(funct7b5), 
					 .ALUOp(ALUOp), 
					 .ALUControl(ALUControl));

	instrdec i1 (.op(op), 
					 .ImmSrc(ImmSrc));

	assign PCWrite = (Branch & Zero) | PCUpdate;

endmodule

module mainfsm (input  logic 		  clk, reset,
					 input  logic [6:0] op,
					 output logic [1:0] ALUSrcA, ALUSrcB,
					 output logic [1:0] ResultSrc,
					 output logic [1:0] ALUOp,
					 output logic		  AdrSrc,
					 output logic		  IRWrite, RegWrite, MemWrite,
					 output logic		  PCUpdate, Branch);

	logic [3:0] state_reg, state_next;

	always_ff @(posedge clk, posedge reset)
		begin
			if(reset)
				state_reg <= 4'b0000;
			else
				state_reg <= state_next;
		end

	always_comb
		begin
			AdrSrc     = 1'b0;
			IRWrite    = 1'b0;
			PCUpdate   = 1'b0;
			RegWrite   = 1'b0;
			MemWrite   = 1'b0;
			Branch     = 1'b0;
			ResultSrc  = 2'b00;
			ALUSrcA    = 2'b00;
			ALUSrcB    = 2'b00;
			ALUOp      = 2'b00;
			state_next = state_reg;
			
			case(state_reg)
				4'b0000: begin
						AdrSrc 	  = 1'b0;
						IRWrite 	  = 1'b1;
						PCUpdate   = 1'b1;
						ALUSrcA 	  = 2'b00;
						ALUSrcB 	  = 2'b10;
						ALUOp 	  = 2'b00;
						ResultSrc  = 2'b10;
						state_next = 4'b0001;
					 end
				
				4'b0001: begin
						ALUSrcA = 2'b01;
						ALUSrcB = 2'b01;
						ALUOp   = 2'b00;
						
						case(op)
							7'b0000011,
							7'b0100011:	state_next = 4'b0010;
							7'b0110011: state_next = 4'b0110;
							7'b0010011: state_next = 4'b1000;
							7'b1101111: state_next = 4'b1001;
							7'b1100011: state_next = 4'b1010;
							default:    state_next = 4'bxxxx;
						endcase
					 end
				
				4'b0010: begin
						ALUSrcA = 2'b10;
						ALUSrcB = 2'b01;
						ALUOp   = 2'b00;
						
						case(op)
							7'b0000011: state_next = 4'b0011;
							7'b0100011: state_next = 4'b0101;
							default:		state_next = 4'bxxxx;
						endcase
					end
				
				4'b0011: begin
						AdrSrc     = 1'b1;
						ResultSrc  = 2'b00;
						state_next = 4'b0100;
					end
				
				4'b0100: begin
						RegWrite   = 1'b1;
						ResultSrc  = 2'b01;
						state_next = 4'b0000;
					end
				
				4'b0101: begin
						AdrSrc     = 1'b1;
						MemWrite   = 1'b1;
						ResultSrc  = 2'b00;
						state_next = 4'b0000;
					end
				
				4'b0110: begin
						ALUSrcA    = 2'b10;
						ALUSrcB    = 2'b00;
						ALUOp      = 2'b10;
						state_next = 4'b0111;
					end
				
				4'b0111: begin
						RegWrite   = 1'b1;
						ResultSrc  = 2'b00;
						state_next = 4'b0000;
					end
				
				4'b1000: begin
						ALUSrcA    = 2'b10;
						ALUSrcB    = 2'b01;
						ALUOp 	  = 2'b10;
						state_next = 4'b0111;
					end
				
				4'b1001: begin
						PCUpdate	  = 1'b1;
						ALUSrcA    = 2'b01;
						ALUSrcB    = 2'b10;
						ALUOp 	  = 2'b00;
						ResultSrc  = 2'b00;
						state_next = 4'b0111;
					end
				
				4'b1010: begin
						Branch     = 1'b1;
						ALUSrcA    = 2'b10;
						ALUSrcB    = 2'b00;
						ALUOp      = 2'b01;
						ResultSrc  = 2'b00;
						state_next = 4'b0000;
					end
					
				default: begin
						AdrSrc 	  = 1'b0;
						Branch     = 1'b0;
						IRWrite 	  = 1'b0;
						RegWrite   = 1'b0;
						MemWrite   = 1'b0;
						PCUpdate   = 1'b0;
						ALUSrcA 	  = 2'b00;
						ALUSrcB 	  = 2'b00;
						ALUOp 	  = 2'b00;
						ResultSrc  = 2'b00;
						state_next = 4'b0000;
					 end
			endcase	
		end
endmodule

module aludec(input  logic       opb5,
              input  logic [2:0] funct3,
              input  logic       funct7b5,
              input  logic [1:0] ALUOp,
              output logic [2:0] ALUControl);
              
    logic  RtypeSub;
    assign RtypeSub = funct7b5 & opb5; 
              
    always_comb
        case(ALUOp)
            2'b00:  ALUControl = 3'b010; // add  (Testbench'in beklediği)
            2'b01:  ALUControl = 3'b110; // sub, beq (Testbench'in beklediği)
            default: case(funct3) 
                        3'b000: if (RtypeSub)
                                    ALUControl = 3'b110; // sub
                                else
                                    ALUControl = 3'b010; // add, addi
                        3'b010: ALUControl = 3'b111; // slt, slti
                        3'b110: ALUControl = 3'b001; // or, ori
                        3'b111: ALUControl = 3'b000; // and, andi
                        default: ALUControl = 3'b000;
                    endcase
        endcase
endmodule

module instrdec (input  logic [6:0] op,
					  output logic [1:0] ImmSrc
);

	always_comb
		case(op)
			7'b0110011: ImmSrc = 2'bxx; // R-type
			7'b0010011: ImmSrc = 2'b00; // I-type ALU
			7'b0000011: ImmSrc = 2'b00; // lw
			7'b0100011: ImmSrc = 2'b01; // sw
			7'b1100011: ImmSrc = 2'b10; // beq
			7'b1101111: ImmSrc = 2'b11; // jal
			default:    ImmSrc = 2'bxx; // ???
		endcase
endmodule