
// f ′(x) = 2ax + b
module calcula_y_linha (
	input  [10:0] x,
   input  [7:0] a,
   input  [7:0] b,
	output [26:0] y_linha
);

	wire [15:0] produto1;
	wire [26:0] produto2;
	wire [26:0] b_ext;
	wire ovf1;
	
	//2a
   multiplicador_8x8_sinalizado multp_1 (
       .A(a),
       .B(2'b10),
       .S(produto1)
    );
	 
	 //2ax
	 multiplicador_16x11_sinalizado multp_2(
		 .A(produto1), 
		 .B(x),
		 .S(produto2)  
	 );
	 
	 // Extensão de sinal da variável 'b' (8 bits -> 27 bits)
	 buf (b_ext[0], b[0]);
    buf (b_ext[1], b[1]);
    buf (b_ext[2], b[2]);
    buf (b_ext[3], b[3]);
    buf (b_ext[4], b[4]);
    buf (b_ext[5], b[5]);
    buf (b_ext[6], b[6]);
    buf (b_ext[7], b[7]);
    buf (b_ext[8],  b[7]);
    buf (b_ext[9],  b[7]);
    buf (b_ext[10], b[7]);
    buf (b_ext[11], b[7]);
    buf (b_ext[12], b[7]);
    buf (b_ext[13], b[7]);
    buf (b_ext[14], b[7]);
    buf (b_ext[15], b[7]);
    buf (b_ext[16], b[7]);
    buf (b_ext[17], b[7]);
    buf (b_ext[18], b[7]);
    buf (b_ext[19], b[7]);
    buf (b_ext[20], b[7]);
    buf (b_ext[21], b[7]);
    buf (b_ext[22], b[7]);
    buf (b_ext[23], b[7]);
    buf (b_ext[24], b[7]);
    buf (b_ext[25], b[7]);
    buf (b_ext[26], b[7]);
	 
	 // 2ax + b
    somador_27b soma24 (
        .A(produto2),
        .B(b_ext),
        .cin(1'b0),
        .S(y_linha),
        .cout(),
        .overflow(ovf1)
    );
	 	
endmodule



module somador_27b (
    input  [26:0] A,
    input  [26:0] B,
    input         cin,
    output [26:0] S,
    output        cout,
    output        overflow
);
    
    wire [25:0] c;

    somador_completo fa0  (.A(A[0]),  .B(B[0]),  .cin(cin),   .S(S[0]),  .cout(c[0]));
    somador_completo fa1  (.A(A[1]),  .B(B[1]),  .cin(c[0]),  .S(S[1]),  .cout(c[1]));
    somador_completo fa2  (.A(A[2]),  .B(B[2]),  .cin(c[1]),  .S(S[2]),  .cout(c[2]));
    somador_completo fa3  (.A(A[3]),  .B(B[3]),  .cin(c[2]),  .S(S[3]),  .cout(c[3]));
    somador_completo fa4  (.A(A[4]),  .B(B[4]),  .cin(c[3]),  .S(S[4]),  .cout(c[4]));
    somador_completo fa5  (.A(A[5]),  .B(B[5]),  .cin(c[4]),  .S(S[5]),  .cout(c[5]));
    somador_completo fa6  (.A(A[6]),  .B(B[6]),  .cin(c[5]),  .S(S[6]),  .cout(c[6]));
    somador_completo fa7  (.A(A[7]),  .B(B[7]),  .cin(c[6]),  .S(S[7]),  .cout(c[7]));
    somador_completo fa8  (.A(A[8]),  .B(B[8]),  .cin(c[7]),  .S(S[8]),  .cout(c[8]));
    somador_completo fa9  (.A(A[9]),  .B(B[9]),  .cin(c[8]),  .S(S[9]),  .cout(c[9]));
    somador_completo fa10 (.A(A[10]), .B(B[10]), .cin(c[9]),  .S(S[10]), .cout(c[10]));
    somador_completo fa11 (.A(A[11]), .B(B[11]), .cin(c[10]), .S(S[11]), .cout(c[11]));
    somador_completo fa12 (.A(A[12]), .B(B[12]), .cin(c[11]), .S(S[12]), .cout(c[12]));
    somador_completo fa13 (.A(A[13]), .B(B[13]), .cin(c[12]), .S(S[13]), .cout(c[13]));
    somador_completo fa14 (.A(A[14]), .B(B[14]), .cin(c[13]), .S(S[14]), .cout(c[14]));
    somador_completo fa15 (.A(A[15]), .B(B[15]), .cin(c[14]), .S(S[15]), .cout(c[15]));
    somador_completo fa16 (.A(A[16]), .B(B[16]), .cin(c[15]), .S(S[16]), .cout(c[16]));
    somador_completo fa17 (.A(A[17]), .B(B[17]), .cin(c[16]), .S(S[17]), .cout(c[17]));
    somador_completo fa18 (.A(A[18]), .B(B[18]), .cin(c[17]), .S(S[18]), .cout(c[18]));
    somador_completo fa19 (.A(A[19]), .B(B[19]), .cin(c[18]), .S(S[19]), .cout(c[19]));
    somador_completo fa20 (.A(A[20]), .B(B[20]), .cin(c[19]), .S(S[20]), .cout(c[20]));
    somador_completo fa21 (.A(A[21]), .B(B[21]), .cin(c[20]), .S(S[21]), .cout(c[21]));
    somador_completo fa22 (.A(A[22]), .B(B[22]), .cin(c[21]), .S(S[22]), .cout(c[22]));
    somador_completo fa23 (.A(A[23]), .B(B[23]), .cin(c[22]), .S(S[23]), .cout(c[23]));
    somador_completo fa24 (.A(A[24]), .B(B[24]), .cin(c[23]), .S(S[24]), .cout(c[24]));
    somador_completo fa25 (.A(A[25]), .B(B[25]), .cin(c[24]), .S(S[25]), .cout(c[25]));
    somador_completo fa26 (.A(A[26]), .B(B[26]), .cin(c[25]), .S(S[26]), .cout(cout));
    
    // O overflow em complemento de dois ocorre pelo XOR entre o carry de entrada (c[25]) e o carry de saída (cout) do bit mais significativo
    xor (overflow, c[25], cout);
     
endmodule
