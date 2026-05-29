// Module Name: block_MultMatStore
// Description: Fetches two matrices from data fetch and does matrix multiplication.
//              After getting Multiplied matrix, it stores into a buffer/ memory location.
// Exec Time  : One clk cycle.

module block_MultMatStore #(
    parameter DATA_WIDTH    = 32,   
    parameter ROW_1         =  2,
    parameter ROW_2         =  2,
    parameter COL_1         =  2,
    parameter COL_2         =  2
)(
    input  logic                         rst_n                   ,  // Active low reset pin
    input  logic                         clk                     ,  // Clock signal
    input  logic signed [DATA_WIDTH-1:0] mat_1    [ROW_1] [COL_1],  // Input matrix 1
    input  logic signed [DATA_WIDTH-1:0] mat_2    [ROW_2] [COL_2],  // Input matrix 2
    input  logic                         exec_start              ,  // Start executing this block if HIGH
    output logic signed [DATA_WIDTH-1:0] mat_buf  [ROW_1] [COL_2],  // Multiplied matrix buffer
    output logic                         error                      // Errors out if dimension mismatch
);

           logic signed [DATA_WIDTH-1:0] mat_mul  [ROW_1] [COL_2];
           logic                         store                   ;

           assign store = !error & exec_start;

    matrix_mul      #(.DATA_WIDTH(DATA_WIDTH),
                      .ROW_A     (ROW_1)     ,
                      .ROW_B     (ROW_2)     ,
                      .COL_A     (COL_1)     ,
                      .COL_B     (COL_2) ) multiplication (
                      .reset_n   (rst_n)     ,
                      .mat_A     (mat_1)     ,
                      .mat_B     (mat_2)     ,
                      .exec_start(exec_start),
                      .mat_MUL   (mat_mul)   ,
                      .error     (error)
    );

    matrix_buffer  #(
                      .DATA_WIDTH(DATA_WIDTH),
                      .ROW       (ROW_1)     ,
                      .COL       (COL_2) ) store_mat (
                      .clk       (clk)       ,
                      .store     (store)     ,
                      .mat_in    (mat_mul)   ,
                      .mat_buf   (mat_buf)
    );
endmodule