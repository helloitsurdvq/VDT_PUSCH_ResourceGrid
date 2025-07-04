function [H_est, No] = ls_est_sparse(rx_grid, dmrs_tx, dmrs_col, method)
% rx_grid: (N_SC, N_SYM)
% dmrs_tx: (N_SC, 1)
% dmrs_col: DMRS column 
    if nargin < 4, method = 'linear'; end
    N_SC = size(rx_grid,1);
    pilot_idx = 1:2:N_SC; % even subcarriers 
    Y_pilot = rx_grid(pilot_idx, dmrs_col);
    X_pilot = dmrs_tx(pilot_idx);
    H_pilot = Y_pilot ./ X_pilot;
    H_est = zeros(N_SC,1);
    No = [];
    if strcmp(method, 'linear')
        x = (1:N_SC)';
        H_est_real = interp1(pilot_idx', real(H_pilot), x, 'linear', 'extrap');
        H_est_imag = interp1(pilot_idx', imag(H_pilot), x, 'linear', 'extrap');
        H_est = H_est_real + 1j*H_est_imag;
    elseif strcmp(method, 'spline')
        H_est(pilot_idx) = H_pilot;
        H_est(2:2:end) = H_est(1:2:end-1); 
    end
end