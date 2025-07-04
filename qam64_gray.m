function symbols = qam64_gray(bits)
    % bits: (N_SC, N_SYM, 6)
    b = double(bits);
    I = (1 - 2*b(:,:,1)) .* (4 - (1 - 2*b(:,:,3)) .* (2 - (1 - 2*b(:,:,5))));
    Q = (1 - 2*b(:,:,2)) .* (4 - (1 - 2*b(:,:,4)) .* (2 - (1 - 2*b(:,:,6))));
    symbols = (I + 1j*Q) / sqrt(42);
end