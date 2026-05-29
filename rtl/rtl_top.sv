`include "define.sv"
`include "matrix_buffer.sv"
`include "block_dataFetch.sv"
`include "matrix_mul.sv"
`include "matrix_qkt.sv"
`include "matrix_scale_qkt.sv"
`include "block_MultMatStore.sv"
`include "block_ScaledQKT.sv"
`include "matrix_softmax.sv"
`include "block_outputMAC.sv"
`include "block_delay.sv"
`include "block_fsm.sv"


module rtl_top # (
    parameter BUS_WIDTH =   4,
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
    input logic clk                                             ,
    input logic reset_n                                         ,
    input logic start                                           ,

    input  logic signed [DATA_WIDTH-1:0] X_Q    [ROW_XQ][COL_XQ],
    input  logic signed [DATA_WIDTH-1:0] X_K    [ROW_XK][COL_XK],
    input  logic signed [DATA_WIDTH-1:0] X_V    [ROW_XV][COL_XV],

    input  logic signed [DATA_WIDTH-1:0] W_Q    [ROW_WQ][COL_WQ],
    input  logic signed [DATA_WIDTH-1:0] W_K    [ROW_WK][COL_WK],
    input  logic signed [DATA_WIDTH-1:0] W_V    [ROW_WV][COL_WV],

    output logic signed [DATA_WIDTH-1:0] mat_O  [ROW_XQ][COL_WV],
    output logic                         fsm_done               ,
    output logic                         error
);


    //--------------------------------------------
    //                 FSM BLOCK
    //--------------------------------------------

    logic                 clear_cntr ;
    logic [BUS_WIDTH-1:0] exec_cycle ;
    logic                 comp_result;
    logic                 error_cntr ;
    logic                 fetch      ;

    logic                 exec_mult  ;
    logic                 exec_scale ;
    logic                 exec_mac   ;

    logic                 error_mult ;
    logic                 error_scale;
    logic                 error_mac  ;

    block_fsm #(
        .BUS_WIDTH      (BUS_WIDTH)
    ) u_fsm (
        .clk            (clk)        ,
        .reset_n        (reset_n)    ,
        .start          (start)      ,
        .error1         (error_mult) ,
        .error2         (error_scale),
        .error3         (error_mac)  ,
        .error4         (error_cntr) ,
        .comp_result    (comp_result),
        .fetch          (fetch)      ,
        .exec_start1    (exec_mult)  ,
        .exec_start2    (exec_scale) ,
        .exec_start3    (exec_mac)   ,
        .clr_cntr       (clear_cntr) ,
        .fsm_done       (fsm_done)   ,
        .error          (error)      ,
        .exec_cycle     (exec_cycle)
    );

    //--------------------------------------------
    //                 DELAY BLOCK
    //--------------------------------------------
    block_delay #(
        .BUS_WIDTH      (BUS_WIDTH)
    ) u_delay (
        .clk            (clk)       ,
        .rst_n          (reset_n)   ,
        .clear          (clear_cntr),
        .exec_cycle     (exec_cycle),
        .error          (error_cntr),
        .comp_result    (comp_result)
    );


    //--------------------------------------------
    //             DATA FETCH BLOCK
    //--------------------------------------------

    logic signed [DATA_WIDTH-1:0] XQ [ROW_XQ][COL_XQ];
    logic signed [DATA_WIDTH-1:0] XK [ROW_XK][COL_XK];
    logic signed [DATA_WIDTH-1:0] XV [ROW_XV][COL_XV];

    logic signed [DATA_WIDTH-1:0] WQ [ROW_WQ][COL_WQ];
    logic signed [DATA_WIDTH-1:0] WK [ROW_WK][COL_WK];
    logic signed [DATA_WIDTH-1:0] WV [ROW_WV][COL_WV];

    block_dataFetch #(
        .DATA_WIDTH(DATA_WIDTH),
        .ROW_XQ        (ROW_XQ),
        .ROW_XK        (ROW_XK),
        .ROW_XV        (ROW_XV),
        .COL_XQ        (COL_XQ),
        .COL_XK        (COL_XK),
        .COL_XV        (COL_XV),
        .ROW_WQ        (ROW_WQ),
        .ROW_WK        (ROW_WK),
        .ROW_WV        (ROW_WV),
        .COL_WQ        (COL_WQ),
        .COL_WK        (COL_WK),
        .COL_WV        (COL_WV)
    ) u_dataFetch (
        .clk           (clk)   ,
        .fetch         (fetch) ,
        .X_Q           (X_Q)   ,
        .X_K           (X_K)   ,
        .X_V           (X_V)   ,
        .W_Q           (W_Q)   ,
        .W_K           (W_K)   ,
        .W_V           (W_V)   ,

        .XQ            (XQ)    ,
        .XK            (XK)    ,
        .XV            (XV)    ,
        .WQ            (WQ)    ,
        .WK            (WK)    ,
        .WV            (WV)
    );

  
    //--------------------------------------------
    //      MATRIX MULTIPLICATION ENGINE
    //--------------------------------------------
    
    logic error1_q;
    logic error1_k;
    logic error1_v;

    assign error_mult = error1_q | error1_k | error1_v;


    // MATRIX_MULT ENGINE Q = XQ x WQ
    // ==============================
    logic signed [DATA_WIDTH-1:0] mat_Q [ROW_XQ][COL_WQ];

    block_MultMatStore #(
        .DATA_WIDTH(DATA_WIDTH),
        .ROW_1     (ROW_XQ)    ,
        .ROW_2     (ROW_WQ)    ,
        .COL_1     (COL_XQ)    ,
        .COL_2     (COL_WQ)
    ) store_Q (
        .rst_n     (reset_n)   ,
        .clk       (clk)       ,
        .mat_1     (XQ)        ,
        .mat_2     (WQ)        ,
        .exec_start(exec_mult) ,
        .mat_buf   (mat_Q)     ,
        .error     (error1_q)
    );


    // MATRIX_MULT ENGINE K = XK x WK
    // ============================== 
    logic signed [DATA_WIDTH-1:0] mat_K [ROW_XK][COL_WK];

    block_MultMatStore #(
        .DATA_WIDTH(DATA_WIDTH),
        .ROW_1     (ROW_XK)    ,
        .ROW_2     (ROW_WK)    ,
        .COL_1     (COL_XK)    ,
        .COL_2     (COL_WK)   
    ) store_K (
        .rst_n     (reset_n)   ,
        .clk       (clk)       ,
        .mat_1     (XK)        ,
        .mat_2     (WK)        ,
        .exec_start(exec_mult) ,
        .mat_buf   (mat_K)     ,
        .error     (error1_k)
    );


    // MATRIX_MULT ENGINE V = XV x WV
    // ==============================
    logic signed [DATA_WIDTH-1:0] mat_V [ROW_XV][COL_WV];

    block_MultMatStore #(
        .DATA_WIDTH(DATA_WIDTH),
        .ROW_1     (ROW_XV)    ,
        .ROW_2     (ROW_WV)    ,
        .COL_1     (COL_XV)    ,
        .COL_2     (COL_WV)
    ) store_V (
        .rst_n     (reset_n)   ,
        .clk       (clk)       ,
        .mat_1     (XV)        ,
        .mat_2     (WV)        ,
        .exec_start(exec_mult) ,
        .mat_buf   (mat_V)     ,
        .error     (error1_v)
    );



    //--------------------------------------------
    //              SCALING UNIT
    //--------------------------------------------
    logic signed [DATA_WIDTH-1:0] mat_SCALED [ROW_XQ][ROW_XK];

    block_ScaledQKT # (
        .DATA_WIDTH(DATA_WIDTH),
        .ROW_Q     (ROW_XQ)    ,
        .ROW_K     (ROW_XK)    ,
        .COL_Q     (COL_WQ)    ,
        .COL_K     (COL_WK)
    ) u_ScaledQKT (
        .rst_n     (reset_n)   ,
        .exec_start(exec_scale),
        .mat_Q     (mat_Q)     ,
        .mat_K     (mat_K)     ,
        .mat_S     (mat_SCALED),
        .error     (error_scale)
    );
 


    //--------------------------------------------
    //          OUTPUT MAC UNIT
    //--------------------------------------------
    block_outputMAC #(
        .DATA_WIDTH(DATA_WIDTH),
        .ROW_S     (ROW_XQ)    ,
        .ROW_V     (ROW_XV)    ,
        .COL_S     (ROW_XK)    ,
        .COL_V     (COL_WV)
    ) u_outputMAC (
        .rst_n     (reset_n)   ,
        .clk       (clk)       ,
        .exec_start(exec_mac)  ,
        .mat_V     (mat_V)     ,
        .mat_S     (mat_SCALED),
        .mat_O     (mat_O)     ,
        .error     (error_mac)
    );


endmodule