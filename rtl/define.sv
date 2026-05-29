/*-------------------------------------
   Data Size and Matrices dimensions
--------------------------------------*/
`define BUS_WIDTH    4                  // exec_cycle counter BUS width, max count = 2^BUS_WIDTH - 1
`define DATA_WIDTH  32                  // Data BUS width (size of each element in matrices)

`define ROW_XQ       3                  // XQ matrix rows
`define COL_XQ       4                  // XQ matrix columns

`define ROW_WQ       4                  // WQ matrix rows
`define COL_WQ       5                  // WQ matrix columns

`define ROW_XK       4                  // XK matrix rows
`define COL_XK       3                  // XK matrix columns

`define ROW_WK       3                  // WK matrix rows
`define COL_WK       5                  // WK matrix columns

`define ROW_XV       4                  // XV matrix rows
`define COL_XV       4                  // XV matrix columns

`define ROW_WV       4                  // WV matrix rows
`define COL_WV       2                  // WV matrix columns

/*-------------------------------------
            User defines
-------------------------------------*/
`define CLK_HALF_PERIOD           5     //  10 unit clock period
`define FRAC_POINT                8     //  Fixed point scaling to Qm.n, where m is integer bits and n is frac bits
`define SCALE_NR_STEPS            8     //  Newton-Raphson approximation steps to calculate S = QK^T/sqrt(dk)
`define EXP_SERIES_LN            26     //  Taylor's series for e^r = sum of N (r^n / n!) length
`define EXP_SERIES_LN2          177     //  ln(2) approx value in Q8.8 format (≈ 0.693 * 2^8 = 177)        

/*------------------------------------
        FSM State Exec Cycle
------------------------------------*/
`define EXEC_IDLE                 1
`define EXEC_DATA_FETCH           1
`define EXEC_MATRIX_MULT          1
`define EXEC_SCALED_ATTEN_SCORE   1
`define EXEC_OUTPUT_MAC           1

/*-------------------------------------
            FSM States
-------------------------------------*/
`define IDLE                      0
`define DATA_FETCH                1
`define MATRIX_MULT               2
`define SCALED_ATTEN_SCORE        3
`define OUTPUT_MAC                4
`define RESULT_READY              5
`define ERROR                     6