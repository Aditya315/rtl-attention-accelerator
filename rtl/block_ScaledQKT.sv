// Module Name: block_ScaledQKT
// Description: Computes Scaled QK^T/sqrt(dk).
// Exec Time  : Combinational Logic.


module block_ScaledQKT # (
    parameter DATA_WIDTH    = 32,
    parameter ROW_Q         =  2,
    parameter ROW_K         =  2,
    parameter COL_Q         =  2,
    parameter COL_K         =  2
)(
    input  logic                         rst_n                   ,  // Active low reset pin
    input  logic                         exec_start              ,  // Start executing this block if HIGH
    input  logic signed [DATA_WIDTH-1:0] mat_Q    [ROW_Q] [COL_Q],  // Input matrix Q
    input  logic signed [DATA_WIDTH-1:0] mat_K    [ROW_K] [COL_K],  // Input matrix K
    output logic signed [DATA_WIDTH-1:0] mat_S    [ROW_Q] [ROW_K],  // Scaled QK^T/sqrt(dk) matrix
    output logic                         error                      // Errors out if any dimension mismatch
);

    logic signed [DATA_WIDTH-1:0] mat_QKT  [ROW_Q] [ROW_K];

    matrix_qkt #(
                .DATA_WIDTH (DATA_WIDTH),
                .ROW_Q      (ROW_Q)     ,
                .ROW_K      (ROW_K)     ,
                .COL_Q      (COL_Q)     ,
                .COL_K      (COL_K)     ) unscaled_qkt (
                .reset_n    (rst_n)     ,
                .mat_Q      (mat_Q)     ,
                .mat_K      (mat_K)     ,
                .exec_start (exec_start),
                .mat_QKT    (mat_QKT)   ,
                .error      (error)
    );


    matrix_scale_qkt #(
                .DATA_WIDTH (DATA_WIDTH),
                .ROW        (ROW_Q)     ,
                .COL        (ROW_K)     ,
                .DK         (COL_Q)     ) scaled_qkt (
                .mat_QKT    (mat_QKT)   ,
                .mat_S      (mat_S)
    );
endmodule