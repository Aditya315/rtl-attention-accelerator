`timescale 1ns/1ns
`include "../rtl/rtl_top.sv"

module tb_rtl_top;


    localparam BUS_WIDTH  = `BUS_WIDTH ;
    localparam DATA_WIDTH = `DATA_WIDTH;

    localparam ROW_XQ     = `ROW_XQ    ;
    localparam COL_XQ     = `COL_XQ    ;

    localparam ROW_WQ     = `ROW_WQ    ;
    localparam COL_WQ     = `COL_WQ    ;

    localparam ROW_XK     = `ROW_XK    ;
    localparam COL_XK     = `COL_XK    ;

    localparam ROW_WK     = `ROW_WK    ;
    localparam COL_WK     = `COL_WK    ;

    localparam ROW_XV     = `ROW_XV    ;
    localparam COL_XV     = `COL_XV    ;

    localparam ROW_WV     = `ROW_WV    ;
    localparam COL_WV     = `COL_WV    ;

    logic clk;
    logic reset_n;
    logic start;

    logic signed [DATA_WIDTH-1:0] X_Q [ROW_XQ][COL_XQ];
    logic signed [DATA_WIDTH-1:0] X_K [ROW_XK][COL_XK];
    logic signed [DATA_WIDTH-1:0] X_V [ROW_XV][COL_XV];

    logic signed [DATA_WIDTH-1:0] W_Q [ROW_WQ][COL_WQ];
    logic signed [DATA_WIDTH-1:0] W_K [ROW_WK][COL_WK];
    logic signed [DATA_WIDTH-1:0] W_V [ROW_WV][COL_WV];

    logic signed [DATA_WIDTH-1:0] mat_O [ROW_XQ][COL_WV];

    logic fsm_done;
    logic error;

    rtl_top #(
        .BUS_WIDTH(BUS_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),

        .ROW_XQ(ROW_XQ),
        .COL_XQ(COL_XQ),
        .ROW_XK(ROW_XK),
        .COL_XK(COL_XK),
        .ROW_XV(ROW_XV),
        .COL_XV(COL_XV),

        .ROW_WQ(ROW_WQ),
        .COL_WQ(COL_WQ),
        .ROW_WK(ROW_WK),
        .COL_WK(COL_WK),
        .ROW_WV(ROW_WV),
        .COL_WV(COL_WV)
    ) dut (
        .clk(clk),
        .reset_n(reset_n),
        .start(start),

        .X_Q(X_Q),
        .X_K(X_K),
        .X_V(X_V),

        .W_Q(W_Q),
        .W_K(W_K),
        .W_V(W_V),

        .mat_O(mat_O),
        .fsm_done(fsm_done),
        .error(error)
    );

    // -------------------------
    // CLOCK GENERATION BLOCK
    // -------------------------
    initial clk = 0;
    always #`CLK_HALF_PERIOD clk = ~clk;

    int  fd ; // File descriptor for reading/writing files
    real tmp; // Temporary variable for reading values from files

    initial begin

        //---------------------------
        //  LOADS THE INITIAL VALUES
        //---------------------------
        reset_n = 0;
        start   = 0;
        load_initial_MatVal();
        @(negedge clk);


        //---------------------------
        //  LOADS THE FINAL VALUES
        //---------------------------
        reset_n = 1;
        start   = 1;
        load_final_MatVal();
        @(negedge clk);


        //---------------------------
        // WAIT FOR fsm_done or error
        //---------------------------
        do begin
            @(negedge clk);
        end while ( (fsm_done === 0) && (error === 0) );


        //---------------------------
        //  DISPLAY AND WRITE OUTPUT
        //---------------------------
        write_attention_output();

        $display("\n----------- ATTENTION (Q,K,V) ------------");
        for (int i = 0; i < ROW_XQ; i++)
            for (int j = 0; j < COL_WV; j++) //                         <--- type casted ----> Since (Int / real) returns real
                $display("mat_O[%0d][%0d] = %0.4f", i, j, mat_O[i][j] / real'(2 ** `FRAC_POINT) );

        if (error) $display("------------------ ERROR -----------------\n");
        else       $display("------------------ DONE ------------------\n");



        @(negedge clk);
        $finish;
    end

    initial begin
        $dumpfile("./output/attention_waveform.vcd");
        $dumpvars(0, tb_rtl_top);
    end

    task automatic load_XQ;
        fd = $fopen("./inputs/XQ.txt", "r");
        if (fd == 0) $fatal("Cannot open inputs/XQ.txt");

        for (int i = 0; i < ROW_XQ; i++)
            for (int j = 0; j < COL_XQ; j++) begin
                $fscanf(fd, "%f", tmp);
                X_Q[i][j] =  tmp * (2 ** `FRAC_POINT);
            end

        $fclose(fd);
    endtask

    task automatic load_WQ;
        fd = $fopen("inputs/WQ.txt", "r");
        if (fd == 0) $fatal("Cannot open inputs/WQ.txt");

        for (int i = 0; i < ROW_WQ; i++)
            for (int j = 0; j < COL_WQ; j++) begin
                $fscanf(fd, "%f", tmp);
                W_Q[i][j] =  tmp * (2 ** `FRAC_POINT);
            end

        $fclose(fd);
    endtask

    task automatic load_XK;
        fd = $fopen("inputs/XK.txt", "r");
        if (fd == 0) $fatal("Cannot open inputs/XK.txt");

        for (int i = 0; i < ROW_XK; i++)
            for (int j = 0; j < COL_XK; j++) begin
                $fscanf(fd, "%f", tmp);
                X_K[i][j] =  tmp * (2 ** `FRAC_POINT);
            end

        $fclose(fd);
    endtask

    task automatic load_WK;
        fd = $fopen("inputs/WK.txt", "r");
        if (fd == 0) $fatal("Cannot open inputs/WK.txt");

        for (int i = 0; i < ROW_WK; i++)
            for (int j = 0; j < COL_WK; j++) begin
                $fscanf(fd, "%f", tmp);
                W_K[i][j] =  tmp * (2 ** `FRAC_POINT);
            end

        $fclose(fd);
    endtask

    task automatic load_XV;
        fd = $fopen("inputs/XV.txt", "r");
        if (fd == 0) $fatal("Cannot open inputs/XV.txt");

        for (int i = 0; i < ROW_XV; i++)
            for (int j = 0; j < COL_XV; j++) begin
                $fscanf(fd, "%f", tmp);
                X_V[i][j] =  tmp * (2 ** `FRAC_POINT);
            end

        $fclose(fd);
    endtask

    task automatic load_WV;
        fd = $fopen("inputs/WV.txt", "r");
        if (fd == 0) $fatal("Cannot open inputs/WV.txt");

        for (int i = 0; i < ROW_WV; i++)
            for (int j = 0; j < COL_WV; j++) begin
                $fscanf(fd, "%f", tmp);
                W_V[i][j] =  tmp * (2 ** `FRAC_POINT);
            end

        $fclose(fd);
    endtask

    task automatic load_initial_MatVal;
        foreach (X_Q[i,j]) X_Q[i][j] = 0;
        foreach (X_K[i,j]) X_K[i][j] = 0;
        foreach (X_V[i,j]) X_V[i][j] = 0;
        foreach (W_Q[i,j]) W_Q[i][j] = 0;
        foreach (W_K[i,j]) W_K[i][j] = 0;
        foreach (W_V[i,j]) W_V[i][j] = 0;
    endtask

    task automatic load_final_MatVal;
        load_XQ();
        load_WQ();
        load_XK();
        load_WK();
        load_XV();
        load_WV();
    endtask

    task automatic write_attention_output;

        $display("\n//------------------------------------------------------------//"  );
        $display(  "  Writing attention output to ./output/attention_testbench.txt"    );
        $display(  "//------------------------------------------------------------//\n");

        fd = $fopen("./output/attention_testbench.txt", "w");

        if (fd == 0) begin
            $display("ERROR: Cannot open ./output/attention_testbench.txt");
        end

        else begin
            for (int i = 0; i < ROW_XQ; i++) begin
                for (int j = 0; j < COL_WV; j++) begin
                    $fwrite(fd, "%0.4f", mat_O[i][j] / real'(2 ** `FRAC_POINT));
                    if (j != (COL_WV-1)) $fwrite(fd, " "); // Add space between values, except after the last value in the row
                end
                $fwrite(fd, "\n"); // Add newline after each row
            end
            $fclose(fd);
            $display("Output written to ./output/attention_testbench.txt");
        end
    endtask
endmodule