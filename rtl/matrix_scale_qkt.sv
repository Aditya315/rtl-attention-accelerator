// Module Name: matrix_scale_qkt
// Description: Scales QK^T output by 1/sqrt(dk)
//              S = QK^T / sqrt(dk)
// Exec Time  : Combinational Logic

module matrix_scale_qkt #(
    parameter DATA_WIDTH = 32,
    parameter ROW        =  2,
    parameter COL        =  2,
    parameter DK         =  2   // DK = COL_Q = COL_K
)(
    input  logic signed [DATA_WIDTH-1:0] mat_QKT [ROW][COL],
    output logic signed [DATA_WIDTH-1:0] mat_S   [ROW][COL]
);
           logic signed [DATA_WIDTH-1:0] scale_factor;
           logic signed [DATA_WIDTH-1:0] dk;
           logic signed [DATA_WIDTH-1:0] mat_sc  [ROW][COL];

    assign mat_S = mat_sc;

    always_comb begin

        // Assigning default value to the mat_S
        foreach (mat_sc[i,j]) begin
            mat_sc[i][j] = '0;
        end
    
        dk = DK <<< `FRAC_POINT; // dk = DK * (2^FRAC_POINT), converting DK to fixed-point
        for (int i = 1 ; i <= `SCALE_NR_STEPS ; i ++ ) begin
            if (i == 1) scale_factor = (1 <<< (`FRAC_POINT-3)); // Initiating iteration with value from very small number since sqrt dk is in the denominator
            else scale_factor = scale_NewtonRaphson( dk, scale_factor);
        end

        // Scaling S = QK^T / sqrt(dk)
        foreach (mat_sc[i,j]) begin
            mat_sc[i][j] = signed'((2*DATA_WIDTH)'(mat_QKT[i][j] * scale_factor)) >>> `FRAC_POINT;
        end
    end

    // Newton-Raphson : S = 1/sqrt(dk)
    //                  S(n+1) = S(n) - [ f(S(n)) / f'(S(n)) ]
    //                  S(n+1) = S(n) * (1.5 - 0.5 * dk * S(n) * S(n))
    function automatic logic signed [DATA_WIDTH-1:0] scale_NewtonRaphson ( input logic signed [DATA_WIDTH-1:0] dk, input logic signed [DATA_WIDTH-1:0] scale );
        
        // 1.5 is represented by 3 <<< (`FRAC_POINT - 1 )

        // S(n) * S(n) is Q2m.2n. convert it to Qm.n
        logic signed [DATA_WIDTH-1:0] scale_sq;
        scale_sq = ( scale * scale ) >>> `FRAC_POINT;

        //                 <------- 1.5 -------->     <------- Q2m.2n to Qm.n---- +1 for 0.5---->
        return ( scale * ( (3 <<< (`FRAC_POINT-1))  - ( ( dk * scale_sq ) >>> (`FRAC_POINT + 1) )  )) >>> `FRAC_POINT;
    endfunction
endmodule
