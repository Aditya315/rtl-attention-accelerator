// Module Name: matrix_qkt
// Description: Fetches two matrices from Q and K buffer and calculates Qk^T.
// Exec Time  : Combinational Logic.

module matrix_qkt # (
    parameter DATA_WIDTH    = 32,
    parameter ROW_Q         =  2,
    parameter ROW_K         =  2,
    parameter COL_Q         =  2,
    parameter COL_K         =  2
)(
    input  logic                         reset_n                 ,  // Active low reset pin
    input  logic signed [DATA_WIDTH-1:0] mat_Q    [ROW_Q] [COL_Q],  // Input matrix Q
    input  logic signed [DATA_WIDTH-1:0] mat_K    [ROW_K] [COL_K],  // Input matrix K
    input  logic                         exec_start              ,  // Start executing this block if HIGH
    output logic signed [DATA_WIDTH-1:0] mat_QKT  [ROW_Q] [ROW_K],  // Output matrix QK^T
    output logic                         error                      // Errors out if any dimension mismatch  
); 
           logic signed [DATA_WIDTH-1:0] mat_qkt  [ROW_Q] [ROW_K];

    assign mat_QKT = mat_qkt;
    // Matrix valid dimension checker
    assign error = (COL_Q != COL_K)? 'b1 : 'b0;

    // Matrix dot logic Implementation
    always_comb begin

        if (!reset_n) begin
            foreach (mat_qkt[i,k]) mat_qkt[i][k] = 'd0;
        end

        else if (reset_n & !error & exec_start) begin : matrix_qkt  
            foreach (mat_qkt[i,k]) mat_qkt[i][k] = 'd0;

            // QK^T Calculation: Q2m.2n sum [i][k] prior to assigning to mat_QKT [i][k] which is Qm.n
            for (int i = 0; i < ROW_Q; i ++) begin : mat_Q_row
                for (int j = 0; j < COL_Q; j ++) begin : mat_Q_col
                    for (int k = 0; k < ROW_K; k ++) begin: mat_K_col
                        mat_qkt [i][k] = mat_qkt [i][k] + ((mat_Q [i][j] * mat_K [k][j]) >>> `FRAC_POINT);
                    end // mat_K_col
                end // mat_Q_col
            end // mat_Q_row
        end // matrix_qkt

        else foreach (mat_qkt[i,k]) mat_qkt [i][k] = 'bx;
    end
endmodule