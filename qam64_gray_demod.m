function bits = qam64_gray_demod(symbols)
    scale = sqrt(42);
    I = real(symbols) * scale;
    Q = imag(symbols) * scale;
    absI = abs(I);
    absQ = abs(Q);
    b0 = uint8(I < 0);
    b1 = uint8(Q < 0);
    b2 = uint8(absI > 3);
    b3 = uint8(absQ > 3);
    b4 = uint8((b2==0 & absI==1) | (b2==1 & absI==7));
    b5 = uint8((b3==0 & absQ==1) | (b3==1 & absQ==7));
    bits = cat(3, b0, b1, b2, b3, b4, b5);
end