function symbols = qam16_gray(bits)
    % bits: (N_SC, N_SYM, 4)
    b = double(bits);
    I = (1 - 2*b(:,:,1)) .* (1 + 2*b(:,:,3));
    Q = (1 - 2*b(:,:,2)) .* (1 + 2*b(:,:,4));
    symbols = (I + 1j*Q) / sqrt(10);
end