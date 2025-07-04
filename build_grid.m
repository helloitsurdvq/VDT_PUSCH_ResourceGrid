function grid = build_grid(symbols, dmrs_vec, dmrs_col)
    [N_SC, N_SYM] = size(symbols);
    grid = zeros(N_SC, N_SYM+1);
    data_cols = setdiff(1:N_SYM+1, dmrs_col);
    grid(:, data_cols) = symbols;
    grid(:, dmrs_col) = dmrs_vec;
end