function bits = qpsk_demod(symbols)
    I = real(symbols);
    Q = imag(symbols);
    b0 = uint8(I < 0);
    b1 = uint8(Q < 0);
    bits = cat(3, b0, b1);
end