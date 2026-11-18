module multiplicador_9x11_sinalizado (
    input  signed [8:0]  A,
    input  signed [10:0] B,
    output signed [19:0] S
);
    assign S = A * B;
endmodule