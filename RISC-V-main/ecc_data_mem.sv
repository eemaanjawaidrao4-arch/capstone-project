module ecc_data_mem (
    input  logic        clk,
    input  logic        reset,
    input  logic        memwrite,
    input  logic [31:0] addr,
    input  logic [31:0] wd,
    output logic [31:0] rd,
    // ---- fault injection ----
    input  logic        fault_inject_en,
    input  logic [5:0]  fault_bit_pos,
    input  logic        fault_inject_en2,
    input  logic [5:0]  fault_bit_pos2,
    // ---- status ----
    output logic        single_err_corrected,
    output logic        double_err_detected,
    output logic [31:0] error_addr
);
    localparam int MEM_WORDS = 16;

    logic [38:0] mem [0:MEM_WORDS-1];

    logic [3:0]  word_addr;
    logic [38:0] enc_codeword;
    logic [38:0] raw_codeword;
    logic [38:0] fault_mask;
    logic [38:0] faulty_codeword;
    logic        dec_single, dec_double;
    logic [31:0] dec_data;

    assign word_addr = addr[5:2];

    ecc_encoder ENC (
        .data_in  (wd),
        .codeword (enc_codeword)
    );

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < MEM_WORDS; i++)
                mem[i] <= '0;
        end
        else if (memwrite) begin
            mem[word_addr] <= enc_codeword;
        end
    end

    assign raw_codeword = mem[word_addr];
    assign fault_mask   = (fault_inject_en  ? (39'b1 << fault_bit_pos)  : 39'b0) |
                          (fault_inject_en2 ? (39'b1 << fault_bit_pos2) : 39'b0);
    assign faulty_codeword = raw_codeword ^ fault_mask;

    ecc_decoder DEC (
        .codeword_in          (faulty_codeword),
        .data_out             (dec_data),
        .single_err_corrected (dec_single),
        .double_err_detected  (dec_double)
    );

    assign rd = dec_data;

    error_status_reg ESR (
        .clk                  (clk),
        .reset                (reset),
        .single_err_in        (dec_single),
        .double_err_in        (dec_double),
        .addr_in              (addr),
        .single_err_corrected (single_err_corrected),
        .double_err_detected  (double_err_detected),
        .error_addr           (error_addr)
    );
endmodule
