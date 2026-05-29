// Module Name: block_delay
// Description: Inside real RTL #delay is not synthesizable. Hence, this counter block is used to mimic 
//              a delay of exec_cycle cycles of any particular state of the FSM. It asserts comp_result
//              after the specified delay.
// Exec Time  : exec_cycle.

module block_delay # (
    parameter BUS_WIDTH = 4
)(
    input  logic                        clk     ,
    input  logic                        rst_n   ,
    input  logic                        clear   ,
    input  logic [ BUS_WIDTH - 1 : 0 ]  exec_cycle,
    output logic                        error   ,
    output logic                        comp_result
);


    logic [BUS_WIDTH-1:0] count_cycle;
    logic                 overflow_sig;
    logic                 comp_sig;

    counter #(
        .BUS_WIDTH(BUS_WIDTH)
    ) u_counter (
        .clk      (clk),
        .rst_n    (rst_n),
        .clear    (clear),
        .count    (count_cycle),
        .overflow (overflow_sig)
    );

    comparator #(
        .BUS_WIDTH(BUS_WIDTH)
    ) u_comparator (
        .exec_cycle      (exec_cycle),
        .count_cycle     (count_cycle),
        .comparison_result(comp_sig)
    );


    assign comp_result = comp_sig;
    assign error       = overflow_sig;
    
endmodule

module counter # (
    parameter BUS_WIDTH = 4
)
(
    input  logic                        clk     ,
    input  logic                        rst_n   ,
    input  logic                        clear   ,
    output logic [ BUS_WIDTH - 1 : 0 ]  count   ,
    output logic                        overflow
);
           logic                        temp    ;

    always_ff @ ( posedge clk ) begin
        if (!rst_n) begin
            count    <= 'b0;
            overflow <= 'b0;
            temp     <= 'b0;
        end
        else begin
            temp     <= &count;
            count    <= clear ? 'b0 : (count + 1);
            overflow <= (temp & ~clear) ? 'b1 : 'b0;
        end
    end
endmodule

module comparator # (
    parameter BUS_WIDTH = 4
)
(
    input  logic [ BUS_WIDTH - 1 : 0 ]      exec_cycle ,
    input  logic [ BUS_WIDTH - 1 : 0 ]      count_cycle,
    output logic                       comparison_result
);

    always_comb begin
        comparison_result = ((count_cycle + 1) === exec_cycle)? 'b1 : 'b0;
    end

endmodule