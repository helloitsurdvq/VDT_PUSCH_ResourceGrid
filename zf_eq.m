function data_eq = zf_eq(rx_grid, H_est, dmrs_col)
% ZF equalization: Y_data / H_est
    data_cols = setdiff(1:size(rx_grid,2), dmrs_col);
    Y_data = rx_grid(:, data_cols);
    data_eq = Y_data ./ H_est;
end