function symbols = qpsk(bits)
    % bits: (N_SC, N_SYM, 2)
    b = double(bits);
    I = (1 - 2*b(:,:,1));
    Q = (1 - 2*b(:,:,2));
    symbols = (I + 1j*Q) / sqrt(2);
end