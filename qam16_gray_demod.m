function bits = qam16_gray_demod(symbols)
    scale = sqrt(10);
    I = real(symbols) * scale;
    Q = imag(symbols) * scale;
    b0 = uint8(I < 0);
    b1 = uint8(Q < 0);
    b2 = uint8(abs(I) > 2);
    b3 = uint8(abs(Q) > 2);
    bits = cat(3, b0, b1, b2, b3);
end