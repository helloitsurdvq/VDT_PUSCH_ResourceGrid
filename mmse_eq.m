function data_mmse = mmse_eq(rx_grid, H_est, noise_var, dmrs_col)
% MMSE equalization: Y = H X + N -> estimate X from Y and H
    data_cols = setdiff(1:size(rx_grid,2), dmrs_col);
    Y_data = rx_grid(:, data_cols);
    W = conj(H_est) ./ (abs(H_est).^2 + noise_var);
    data_mmse = W .* Y_data;
end