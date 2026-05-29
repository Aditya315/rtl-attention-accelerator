// Module Name: matrix_mul
// Description: Fetches two matrices from data fetch and does matrix multiplication.
// Exec Time  : Combinational Logic.

module matrix_mul # (
    parameter DATA_WIDTH    = 32,
    parameter ROW_A         =  2,
    parameter ROW_B         =  2,
    parameter COL_A         =  2,
    parameter COL_B         =  2
)(
    input  logic                         reset_n                 ,  // Active low reset pin
    input  logic signed [DATA_WIDTH-1:0] mat_A    [ROW_A] [COL_A],  // Input matrix A
    input  logic signed [DATA_WIDTH-1:0] mat_B    [ROW_B] [COL_B],  // Input matrix B
    input  logic                         exec_start              ,  // Start executing this block if HIGH
    output logic signed [DATA_WIDTH-1:0] mat_MUL  [ROW_A] [COL_B],  // Output matrix MUL
    output logic                         error                      // Errors out if any dimension mismatch
);
           logic signed [DATA_WIDTH-1:0] mat_AxB  [ROW_A] [COL_B];
    
    assign mat_MUL = mat_AxB;
    // Matrix valid dimension checker
    assign error = (COL_A != ROW_B)? 'b1 : 'b0;

    // Matrix multiplication logic Implementation
    always_comb begin

        if (!reset_n) begin
            foreach (mat_AxB[i,k]) begin
                mat_AxB[i][k] = 'd0;
            end
        end

        else if (reset_n & !error & exec_start) begin : matrix_mul
            // initiates value = 0 each time::
            foreach (mat_AxB[i,k]) mat_AxB[i][k] = 'd0;

            // Calculate Q2m.2n and right shift it by `FRAC_POINT prior to assigning to mat_MUL [i][k] which is Qm.n
            for (int i = 0; i < ROW_A; i ++) begin : mat_A_row
                for (int j = 0; j < COL_A; j ++) begin : mat_A_col
                    for (int k = 0; k < COL_B; k ++) begin: mat_B_col
                        mat_AxB [i][k] = mat_AxB [i][k] + ((mat_A [i][j] * mat_B [j][k]) >>> `FRAC_POINT);
                    end // mat_B_col
                end // mat_A_col
            end // mat_A_row
        end // matrix_mul

        else foreach (mat_AxB[i,k]) mat_AxB[i][k] = 'bx;
    end
endmodule