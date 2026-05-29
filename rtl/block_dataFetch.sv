// Module Name: block_dataFetch
// Description: Fetches and stores weight matrix W_{Q,K,V} and tokens X_{Q,K,V}.
// Exec Time  : One Clk Cycle

module block_dataFetch #(
    parameter DATA_WIDTH = 32,

    parameter ROW_XQ     =  2,
    parameter ROW_XK     =  2,
    parameter ROW_XV     =  2,

    parameter COL_XQ     =  2,
    parameter COL_XK     =  2,
    parameter COL_XV     =  2,

    parameter ROW_WQ     =  2,
    parameter ROW_WK     =  2,
    parameter ROW_WV     =  2,

    parameter COL_WQ     =  2,
    parameter COL_WK     =  2,
    parameter COL_WV     =  2
)(
    input  logic                         clk                    ,
    input  logic                         fetch                  ,

    input  logic signed [DATA_WIDTH-1:0] X_Q    [ROW_XQ][COL_XQ],
    input  logic signed [DATA_WIDTH-1:0] X_K    [ROW_XK][COL_XK],
    input  logic signed [DATA_WIDTH-1:0] X_V    [ROW_XV][COL_XV],

    input  logic signed [DATA_WIDTH-1:0] W_Q    [ROW_WQ][COL_WQ],
    input  logic signed [DATA_WIDTH-1:0] W_K    [ROW_WK][COL_WK],
    input  logic signed [DATA_WIDTH-1:0] W_V    [ROW_WV][COL_WV],

    output logic signed [DATA_WIDTH-1:0] XQ     [ROW_XQ][COL_XQ],
    output logic signed [DATA_WIDTH-1:0] XK     [ROW_XK][COL_XK],
    output logic signed [DATA_WIDTH-1:0] XV     [ROW_XV][COL_XV],

    output logic signed [DATA_WIDTH-1:0] WQ     [ROW_WQ][COL_WQ],
    output logic signed [DATA_WIDTH-1:0] WK     [ROW_WK][COL_WK],
    output logic signed [DATA_WIDTH-1:0] WV     [ROW_WV][COL_WV]
);

           logic signed [DATA_WIDTH-1:0] xq_buf [ROW_XQ][COL_XQ];
           logic signed [DATA_WIDTH-1:0] xk_buf [ROW_XK][COL_XK];
           logic signed [DATA_WIDTH-1:0] xv_buf [ROW_XV][COL_XV];

           logic signed [DATA_WIDTH-1:0] wq_buf [ROW_WQ][COL_WQ];
           logic signed [DATA_WIDTH-1:0] wk_buf [ROW_WK][COL_WK];
           logic signed [DATA_WIDTH-1:0] wv_buf [ROW_WV][COL_WV];
  

    matrix_buffer #(
                      .DATA_WIDTH(DATA_WIDTH),
                      .ROW       (ROW_XQ)     ,
                      .COL       (COL_XQ) )
    store_XQ (
                      .clk       (clk)        ,
                      .store     (fetch)      ,
                      .mat_in    (X_Q)        ,
                      .mat_buf   (xq_buf)
    );

    matrix_buffer #(
                      .DATA_WIDTH(DATA_WIDTH),
                      .ROW       (ROW_XK)     ,
                      .COL       (COL_XK) )
    store_XK (
                      .clk       (clk)        ,
                      .store     (fetch)      ,
                      .mat_in    (X_K)        ,
                      .mat_buf   (xk_buf)
    );

    matrix_buffer #(
                      .DATA_WIDTH(DATA_WIDTH),
                      .ROW       (ROW_XV)     ,
                      .COL       (COL_XV) )
    store_XV (
                      .clk       (clk)        ,
                      .store     (fetch)      ,
                      .mat_in    (X_V)        ,
                      .mat_buf   (xv_buf)
    );

    matrix_buffer #(
                      .DATA_WIDTH(DATA_WIDTH),
                      .ROW       (ROW_WQ)     ,
                      .COL       (COL_WQ) )
    store_WQ (
                      .clk       (clk)        ,
                      .store     (fetch)      ,
                      .mat_in    (W_Q)        ,
                      .mat_buf   (wq_buf)
    );

    matrix_buffer #(
                      .DATA_WIDTH(DATA_WIDTH),
                      .ROW       (ROW_WK)     ,
                      .COL       (COL_WK) )
    store_WK (
                      .clk       (clk)        ,
                      .store     (fetch)      ,
                      .mat_in    (W_K)        ,
                      .mat_buf   (wk_buf)
    );

    matrix_buffer #(
                      .DATA_WIDTH(DATA_WIDTH),
                      .ROW       (ROW_WV)     ,
                      .COL       (COL_WV) )
    store_WV (
                      .clk       (clk)        ,
                      .store     (fetch)      ,
                      .mat_in    (W_V)        ,
                      .mat_buf   (wv_buf)
    );

    assign XQ = xq_buf;
    assign XK = xk_buf;
    assign XV = xv_buf;

    assign WQ = wq_buf;
    assign WK = wk_buf;
    assign WV = wv_buf;

endmodule