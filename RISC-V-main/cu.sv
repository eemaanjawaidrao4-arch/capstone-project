module cu (
    output logic       alu_src,
    output logic       result_src,
    output logic       regwrite,
    output logic       memwrite,
    output logic       pc_src,
    output logic [1:0] imm_src,
    output logic [2:0] alu_control,
    input  logic [6:0] opcode,
    input  logic [2:0] fun3,
    input  logic       fun7,
    input  logic       zero,
    input  logic       sign
);
    logic       branch;
    logic [1:0] aluop;

    control_unit C1 (
        .branch     (branch),
        .regwrite   (regwrite),
        .memwrite   (memwrite),
        .alu_src    (alu_src),
        .result_src (result_src),
        .imm_src    (imm_src),
        .aluop      (aluop),
        .opcode     (opcode)
    );

    alu_control C2 (
        .alu_control (alu_control),
        .aluop       (aluop),
        .fun3        (fun3),
        .fun7        (fun7)
    );

    always_comb begin
        if (branch) begin
            case (fun3)
                3'b000:  pc_src = zero;   // BEQ
                3'b001:  pc_src = ~zero;  // BNE
                3'b100:  pc_src = sign;   // BLT
                3'b101:  pc_src = ~sign;  // BGE
                default: pc_src = 1'b0;
            endcase
        end else begin
            pc_src = 1'b0;
        end
    end
endmodule
