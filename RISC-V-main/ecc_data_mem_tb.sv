module ecc_data_mem_tb;
    logic        clk, reset, memwrite;
    logic [31:0] addr, wd;
    logic [31:0] rd;
    logic        fault_en, fault_en2;
    logic [5:0]  fbit0, fbit1;
    logic        single_err, double_err;
    logic [31:0] error_addr;

    int pass_cnt = 0, fail_cnt = 0;

    ecc_data_mem DUT (
        .clk(clk), .reset(reset), .memwrite(memwrite),
        .addr(addr), .wd(wd), .rd(rd),
        .fault_inject_en(fault_en),   .fault_bit_pos(fbit0),
        .fault_inject_en2(fault_en2), .fault_bit_pos2(fbit1),
        .single_err_corrected(single_err),
        .double_err_detected(double_err),
        .error_addr(error_addr)
    );

    always #5 clk = ~clk;

    task automatic check(string name, bit cond);
        if (cond) begin pass_cnt++; $display("[PASS] %s", name); end
        else      begin fail_cnt++; $display("[FAIL] %s", name); end
    endtask

    initial begin
        clk = 0; reset = 1; memwrite = 0; addr = '0; wd = '0;
        fault_en = 0; fault_en2 = 0; fbit0 = '0; fbit1 = '0;
        @(negedge clk); reset = 0;

        // ---- 1. Reset test ----
        addr = 0;
        #1 check("Reset clears memory",
                 rd === 32'h0 && single_err === 1'b0 && double_err === 1'b0);

        // ---- 2. Normal write/read (no fault) ----
        addr = 0; wd = 32'hDEADBEEF; memwrite = 1; @(posedge clk); memwrite = 0;
        fault_en = 0; fault_en2 = 0;
        #1 check("Normal R/W no-error",
                 rd === 32'hDEADBEEF && single_err === 1'b0 && double_err === 1'b0);

        // ---- 3. Second word ----
        addr = 4; wd = 32'h12345678; memwrite = 1; @(posedge clk); memwrite = 0;
        #1 check("Second word R/W", rd === 32'h12345678);

        // ---- 4. Single-bit fault injection & correction ----
        addr = 0; fault_en = 1; fbit0 = 6'd10;   // flip codeword bit 10
        #1 check("Single-bit corrected data",
                 rd === 32'hDEADBEEF && single_err === 1'b1);
        fault_en = 0;

        // ---- 5. Double-bit fault injection & detection ----
        addr = 0; fault_en = 1; fbit0 = 6'd2; fault_en2 = 1; fbit1 = 6'd9;
        #1 check("Double-bit error detected", double_err === 1'b1);
        fault_en = 0; fault_en2 = 0;

        // ---- 6. Error address captured ----
        @(posedge clk);
        #1 check("Error address logged", error_addr === 32'h0);

        $display("\n==== RESULT: %0d PASSED / %0d FAILED ====", pass_cnt, fail_cnt);
        $stop;
    end
endmodule
