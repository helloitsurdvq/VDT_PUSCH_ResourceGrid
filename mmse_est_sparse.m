function [H_est, noise_var] = mmse_est_sparse(rx_grid, dmrs_tx, dmrs_col, delta_f, tau_rms)
% MMSE channel estimation using exponential correlation model
% rx_grid: (N_SC, N_SYM)
% dmrs_tx: (N_SC, 1)
% dmrs_col: DMRS column
% delta_f: subcarrier spacing (Hz)
% tau_rms: RMS delay spread (s)

    N_SC = size(rx_grid,1);
    pilot_idx = 1:2:N_SC; 
    Y_pilot = rx_grid(pilot_idx, dmrs_col);
    X_pilot = dmrs_tx(pilot_idx);
    H_pilot = Y_pilot ./ X_pilot;

    % Build exponential correlation matrices
    idx = (1:N_SC)';
    diff = idx - idx';
    Rhh = 1 ./ (1 + 1j*2*pi*delta_f*tau_rms*diff);
    Rhp = Rhh(:, pilot_idx);
    Rpp = Rhh(pilot_idx, pilot_idx);

    % Estimate noise variance
    noise_var = mean(abs(Y_pilot - H_pilot .* X_pilot).^2);

    % MMSE estimate for all subcarriers
    H_est = zeros(N_SC,1);
    reg = 1e-2; % regularization
    H_est = Rhp * ((Rpp + reg*eye(length(pilot_idx))) \ H_pilot);

end