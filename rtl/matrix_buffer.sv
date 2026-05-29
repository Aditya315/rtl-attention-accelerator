// Module Name: matrix_buffer
// Description: Stores matrix elements.
// Exec Time  : One clk cycle.

module matrix_buffer #(
    parameter DATA_WIDTH = 32,
    parameter ROW        =  2,
    parameter COL        =  2
)(
    input  logic                         clk               ,
    input  logic                         store             ,
    input  logic signed [DATA_WIDTH-1:0] mat_in  [ROW][COL],
    output logic signed [DATA_WIDTH-1:0] mat_buf [ROW][COL]
);

    always_ff @(posedge clk) begin
        if (store) begin
            foreach (mat_buf[i,j]) mat_buf[i][j] <= mat_in[i][j];
        end
        else foreach (mat_buf[i,j]) mat_buf[i][j] <= 'bx;
    end
endmodule