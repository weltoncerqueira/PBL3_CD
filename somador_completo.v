
// Somador completo
module somador_completo (
    input  wire A,
    input  wire B,
    input  wire cin,
    output wire S,
    output wire cout
);
    // Fios internos para interconectar as portas lógicas
    wire axorb;
    wire aandb;
    wire cin_and_axorb;

    xor u1 (axorb, A, B);

    xor u2 (S, axorb, cin);

    and u3 (aandb, A, B);


    and u4 (cin_and_axorb, cin, axorb);
    or  u5 (cout, aandb, cin_and_axorb);
	 
endmodule

// Meio somador
module meio_somador (

	input wire A,
	input wire B,
	output wire cout,
	output wire sum
	
);

	xor (sum, A, B);
	and (cout, A, B);

endmodule 