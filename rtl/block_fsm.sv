// Module Name: block_fsm
// Description: Finite State Machine for controlling the execution flow of the attention mechanism.
// Exec Time  : Each state has a pre-determined execution time (in clock cycles) after which it transitions to the next state.

module block_fsm # (
    parameter BUS_WIDTH = 4                    // Bus width of counter
)
(
    input  logic                 clk         ,
    input  logic                 reset_n     , // Active low synchronous reset
    input  logic                 start       , // Stats the fsm when goes high
    input  logic                 comp_result , // Goes high when the current state completes its pre-determined execution time

    input  logic                 error1      , // Error from block_MultMatStore (Q | K | V)
    input  logic                 error2      , // Error from block_ScaledQKT
    input  logic                 error3      , // Error from block_outputMAC
    input  logic                 error4      , // error from block_delay 

    output logic                 fetch       , // Fetches and stores at block_dataFetch
    output logic                 exec_start1 , // Starts block_MultMatStore (Q | K | V)
    output logic                 exec_start2 , // Starts block_ScaledQKT
    output logic                 exec_start3 , // Starts block_outputMAC

    output logic                 fsm_done    , // Goes high if fsm completes it's execution
    output logic                 error       , // Errors out if fsm encounters any error
    
    output logic                 clr_cntr    , // Clears the counter prior to trasition to next state if count == exec_cycle
    output logic [BUS_WIDTH-1:0] exec_cycle    // Individual state execution time clock cycle


);

    logic [2:0] pstate; // Current or present state of fsm
    logic [2:0] nstate; // Next state of the fsm 



    /*
        Next state output logic (NSOL)
        Next state logic         (NSL)
        Output logic              (OL)
        NSOL = NSL + OL

        FSM_STATES        VALUES        MIN EXEC CYCLE        CONTROL-ed by                     ERRORs If                                   EXECUTES BLOCK
        -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
        IDLE                0               1 Clk             start       = 1      Counter overflow                                 block_delay
        DATA_FETCH          1               1 Clk             fetch       = 1      Counter overflow                                 block_delay and block_dataFetch
        MATRIX_MULT         2               1 Clk             exec_start1 = 1      Counter overflow or dimension mismatch           block_delay and block_MultMatStore
        SCALED_ATTEN_SCORE  3               1 Clk             exec_start2 = 1      Counter overflow or dimension mismatch           block_delay and block_ScaledQKT
        OUTPUT_MAC          4               1 Clk             exec_start3 = 1      Counter overflow or dimension mismatch           block_delay and block_outputMAC
        RESULT_READY        5               -                                                     N/A
        ERROR               6               -           error in previous states
    */

    always_comb begin : NSOL
    
        begin : NSL
            case(pstate)
                `IDLE               : nstate = (comp_result &start     & !error4)? `DATA_FETCH         : `IDLE      ;             
                `DATA_FETCH         : nstate = (comp_result            & !error4)? `MATRIX_MULT        : `DATA_FETCH;
                `MATRIX_MULT        : nstate = (comp_result & !error1  & !error4)? `SCALED_ATTEN_SCORE : `ERROR     ;
                `SCALED_ATTEN_SCORE : nstate = (comp_result & !error2  & !error4)? `OUTPUT_MAC         : `ERROR     ;
                `OUTPUT_MAC         : nstate = (comp_result & !error3  & !error4)? `RESULT_READY       : `ERROR     ;
                `RESULT_READY       : nstate = `RESULT_READY;
                `ERROR              : nstate = `ERROR;
                default             : nstate = 'bx;
            endcase
        end // NSL


        begin : OL
            case(pstate)

                `IDLE : begin
                    fetch      = 'b0;
                    exec_start1= 'b0;
                    exec_start2= 'b0;
                    exec_start3= 'b0;
                    clr_cntr   = 'b0;
                    fsm_done   = 'b0;
                    error      = 'b0;
                    exec_cycle = `EXEC_IDLE;
                    clr_cntr   = (comp_result) ? 'b1 : 'b0;
                end
                
                `DATA_FETCH : begin
                    exec_cycle = `EXEC_DATA_FETCH;
                    fetch      = 'b1;
                    error      = 'b0;
                    clr_cntr   = (comp_result) ? 'b1 : 'b0;
                end

                `MATRIX_MULT : begin
                    exec_start1= 'b1;
                    exec_cycle = `EXEC_MATRIX_MULT;
                    error      = 'b0;
                    clr_cntr   = (comp_result) ? 'b1 : 'b0;
                end

                `SCALED_ATTEN_SCORE : begin
                    exec_start2= 'b1;
                    exec_cycle = `EXEC_SCALED_ATTEN_SCORE;
                    error      = 'b0;
                    clr_cntr   = (comp_result) ? 'b1 : 'b0;
                end

                `OUTPUT_MAC : begin
                    exec_start3= 'b1;
                    exec_cycle = `EXEC_OUTPUT_MAC;
                    error      = 'b0;
                    clr_cntr   = (comp_result) ? 'b1 : 'b0;
                end

                `RESULT_READY : begin
                    fsm_done   = 'b1;
                    error      = 'b0;
                end

                `ERROR : begin
                    error      = 'b1;
                    fsm_done   = 'b1;
                end

                default : begin
                    error      = 'bx;
                    exec_cycle = 'bx;
                    clr_cntr   = 'bx;
                    exec_start1= 'bx;
                    exec_start2= 'bx;
                    exec_start3= 'bx;
                    fsm_done   = 'bx;
                end
            endcase

        end // OL

    end // NSOL



    always_ff @ (posedge clk ) begin
        pstate <= (~reset_n)? `IDLE : nstate;
    end

endmodule