// Module Name: block_outputMAC
// Description: Does Calculate Attention (Q,K,V) = softmax( QK^T / sqrt(dk) ) x V
//              Stores Attention score to an output buffer
// Exec Time  : Combinational Logic and latency depends on size of Taylor's series of e^x.
//              One CLk cycle to store output Attention score to matrix buffer.


module block_outputMAC #(
    parameter DATA_WIDTH    = 32,
    parameter ROW_S         =  2,
    parameter ROW_V         =  2,
    parameter COL_S         =  2,
    parameter COL_V         =  2

)(
    input  logic                         rst_n                   ,  // Active low reset pin
    input  logic                         clk                     ,  // Clock signal
    input  logic                         exec_start              ,  // Start executing this block if HIGH
    input  logic signed [DATA_WIDTH-1:0] mat_V    [ROW_V] [COL_V],  // Input matrix V from buffer
    input  logic signed [DATA_WIDTH-1:0] mat_S    [ROW_S] [COL_S],  // Input matrix Scaled =  (QK^T/sqrt(dk))
    output logic signed [DATA_WIDTH-1:0] mat_O    [ROW_S] [COL_V],  // Output matrix Attention(Q,K,V) buffer
    output logic                         error                      // Errors out if dimension mismatch
);


           logic signed [DATA_WIDTH-1:0] mat_soft [ROW_S] [COL_S];
           logic signed [DATA_WIDTH-1:0] mat_attn [ROW_S] [COL_V];
           logic                         store;


    assign store = !error & exec_start;

    // Calculate softmax(mat_S) where mat_S = ( QK^T / sqrt(dk) )
    matrix_softmax  #(
                      .DATA_WIDTH(DATA_WIDTH),
                      .ROW_SM    (ROW_S)     ,
                      .COL_SM    (COL_S)     ) softmax_approx (
                      .reset_n   (rst_n)     ,
                      .exec_start(exec_start),
                      .mat_S     (mat_S)     ,
                      .mat_SM    (mat_soft)
    );

    // Output MAC unit:: Calculates Attention(Q,K,V) =  softmax( QK^T / sqrt(dk) ) x V
    matrix_mul      #(
                      .DATA_WIDTH(DATA_WIDTH),
                      .ROW_A     (ROW_S)     ,
                      .ROW_B     (ROW_V)     ,
                      .COL_A     (COL_S)     ,
                      .COL_B     (COL_V)     ) output_MAC_unit (
                      .reset_n   (rst_n)     ,
                      .mat_A     (mat_soft)  ,
                      .mat_B     (mat_V)     ,
                      .exec_start(exec_start),
                      .mat_MUL   (mat_attn)  ,
                      .error     (error)
    );

    
    // Stores Attention(Q,K,V) to a buffer
    matrix_buffer  #(
                      .DATA_WIDTH(DATA_WIDTH),
                      .ROW       (ROW_S)     ,
                      .COL       (COL_V)     ) store_attention (
                      .clk       (clk)       ,
                      .store     (store)     ,
                      .mat_in    (mat_attn)  ,
                      .mat_buf   (mat_O)
    );


endmodule