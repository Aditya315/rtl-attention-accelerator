// Module Name: matrix_softmax
// Description: Calculates softmax(QK^T / sqrt(dk) )
// Exec Time  : Combinational Logic and latency depends on size of Taylor's series of e^x.

module matrix_softmax # (
    parameter DATA_WIDTH    = 32,
    parameter ROW_SM        =  2,
    parameter COL_SM        =  2
)(
    input  logic                         reset_n                   ,  // Active low reset pin
    input  logic                         exec_start                ,  // Start executing this block if HIGH
    input  logic signed [DATA_WIDTH-1:0] mat_S    [ROW_SM] [COL_SM],  // Scaled QK^T/sqrt(dk) matrix
    output logic signed [DATA_WIDTH-1:0] mat_SM   [ROW_SM] [COL_SM]   // softmax( QK^T/sqrt(dk) ) matrix
);
           
           logic signed [DATA_WIDTH-1:0] mat_soft [ROW_SM] [COL_SM];  // mat_soft = softmaxx(mat_S)
    
    assign mat_SM = mat_soft;

    always_comb begin

        logic signed [DATA_WIDTH-1:0]   mat_exp  [ROW_SM] [COL_SM]; // mat_exp [i][j] = e ^ mat_S[i][j]
        logic signed [DATA_WIDTH-1:0]   row_max                   ; // Used for subtracting row max x' = x - max(X_row)
        logic signed [DATA_WIDTH-1:0]   norm_x                    ; // Used for storing subtracted element
        logic signed [DATA_WIDTH-1:0]   dnom                      ; // Used to calculate dnominator = e11 + e12 + e13
        logic signed [DATA_WIDTH-1:0]   temp                      ;

        if (!reset_n) begin
            foreach ( mat_soft[i,j]) begin
                mat_soft[i][j] = 'd0;
                mat_exp [i][j] = 'd0;
            end
        end

        else if ( reset_n & exec_start) begin
            
            // Each time initiate with default value 0.
            foreach ( mat_soft[i,j]) begin
                mat_soft[i][j] = 'd0;
                mat_exp [i][j] = 'd0;
            end

            for (int i = 0; i < ROW_SM; i++) begin

                // Find row_max (for numerical stability)
                // Initiating row_max with first element of every row
                row_max = mat_S[i][0];
                for (int j = 1; j < COL_SM; j++) begin
                    if (mat_S[i][j] > row_max)
                        row_max = mat_S[i][j];
                end

                // Calculating the denominator first
                dnom = 'd0;
                for ( int j = 0; j < COL_SM; j++) begin
                    // Subtracting the row maximum is for numerical stability
                    norm_x = mat_S[i][j] - row_max;
                    mat_exp[i][j] = exp_approx(norm_x);
                    dnom = dnom + mat_exp[i][j];
                end

                // Calculating the softmax matrix
                temp = 'b0;
                for ( int k = 0; k < COL_SM; k++) begin
                    if (dnom != 0) begin
                        temp           = mat_exp[i][k] <<< `FRAC_POINT;
                        mat_soft[i][k] = temp / dnom;
                    end
                    else mat_soft[i][k] = 'd0;
                end
            end
        end

        else foreach ( mat_soft[i,j]) mat_soft[i][j] = 'dx;
    end


    // Function to calculate e^x using Taylor's series expansion
    function automatic logic signed [DATA_WIDTH-1:0] exp_approx(input logic signed [DATA_WIDTH-1:0] x);

        logic signed [  DATA_WIDTH-1:0]   sum  ;
        logic signed [2*DATA_WIDTH-1:0]   power;
        logic signed [  DATA_WIDTH-1:0]   term ;

        logic signed [  DATA_WIDTH-1:0]    r   ;
        logic signed [  DATA_WIDTH-1:0]    n   ;

   
        // e^x = 2^n * e^r, where n = x/ln(2) and r = x - n*ln(2)
        // ------------------------------------------------------
       
        // Integer part/  quotient : n = x / ln(2)
        n = x / `EXP_SERIES_LN2;

        // Leftover part/ remainder r = x - n*ln(2)
        r = x - (n * `EXP_SERIES_LN2);

        // PART_2 : Taylor series for e^r = 1+ r + r^2/2! + ...
        //-------------------------------------------------------
        sum   = (1 <<< `FRAC_POINT);    // first term = 1
        power = (1 <<< `FRAC_POINT);    // e^0        = 1

        for (int i = 1; i < `EXP_SERIES_LN; i++) begin
            // power = r^i
            power = (power * r) >>> `FRAC_POINT;
            term  = (power <<< `FRAC_POINT) / factorial(i);
            term  = term >>> `FRAC_POINT;
            sum   = sum + term;
        end

        // PART_1 : Scale result by 2^n (just bit shift)
        //-------------------------------------------------------
        if (n >= 0) return sum <<< n   ; // Multiplying by 2^n
        else        return sum >>> (-n); // Dividing by 2^(-n) = Multiplying by 2^n
    endfunction
    

    // Find factorial of numbers
    function automatic logic signed [DATA_WIDTH-1:0] factorial(input logic signed [DATA_WIDTH-1:0] n);
        logic signed [DATA_WIDTH-1:0] fact;
        fact = 'd0;
        for (int i = 0; i <= n; i++) begin
            if (i == 0) fact = 1;
            else fact = fact * i;
        end
        return fact;
    endfunction

endmodule