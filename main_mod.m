%% 5G PUSCH Resource Grid 
clear; clc; close all;
%%

rng(42);
N_SC = 3276;
N_SYM = 13;
DMRS_COL = 4; % 1-based index
bits = randi([0 1], N_SC, N_SYM, 4, 'uint8');
symbols = qam16_gray(bits);
dmrs_vec = load_dmrs('dmrs.xlsx', N_SC);
grid = build_grid(symbols, dmrs_vec, DMRS_COL);

fprintf('=== 5G PUSCH Resource Grid Implementation ===\n');
fprintf('Grid Size: %d subcarriers × %d symbols\n', N_SC, N_SYM+1);

data_cols = setdiff(1:N_SYM+1, DMRS_COL);
num_data_columns = numel(data_cols);

fprintf('Data Columns: %d (excluding DMRS column %d)\n', num_data_columns, DMRS_COL);
fprintf('Total Bits: %d\n', N_SC * N_SYM * 4);
fprintf('Total Data Symbols: %d\n', N_SC * N_SYM);
fprintf('Modulation: 16QAM (%d bits per symbol)\n', 4);

fprintf('Verification Results:\n');
fprintf('- Grid dimensions: (%d × %d)\n', size(grid,1), size(grid,2));
fprintf('- Data columns filled: %d/%d\n', num_data_columns, N_SYM+1);

tx_slot = ofdm_modulate(grid);
fprintf('OFDM output length: %d samples\n', length(tx_slot));
fs = 61.44e6;
ch = TDLB100(fs, 25.0, 123);
y = ch.apply_channel(tx_slot);
n = ch.get_noise(y, 0);

rx = y + n;
grid_est = ofdm_demodulate(rx);

data_grid = grid_est;
data_grid(:, DMRS_COL) = [];
bits_rx = qam16_gray_demod(data_grid);
%%
ber = compute_ber(bits, bits_rx);
fprintf('BER = %.2f%%\n', ber*100);

mse = compute_mse(symbols, data_grid);
fprintf('MSE = %.6e\n', mse);
%%
snr_vals = 0:2:30;
n_runs = 14;
delta_f = 15e3;
tau_rms = 100e-9;
DMRS_COL = 4; % matlab 1-based

mod_types = {'QPSK', '16QAM', '64QAM'};
bits_per_sym = [2, 4, 6];
mod_fns = {@qpsk, @qam16_gray, @qam64_gray};
demod_fns = {@qpsk_demod, @qam16_gray_demod, @qam64_gray_demod};

mse_zf = zeros(numel(mod_types), length(snr_vals));
ber_zf = zeros(numel(mod_types), length(snr_vals));
mse_mmse = zeros(numel(mod_types), length(snr_vals));
ber_mmse = zeros(numel(mod_types), length(snr_vals));

for mtype = 1:numel(mod_types)
    fprintf('\n=== %s Simulation ===\n', mod_types{mtype});
    for run = 1:n_runs
        for i = 1:length(snr_vals)
            snr = snr_vals(i);
            % --- Generate bits and symbols ---
            bits_tx = randi([0 1], N_SC, N_SYM, bits_per_sym(mtype), 'uint8');
            symbols_tx = mod_fns{mtype}(bits_tx);
            grid_tx = build_grid(symbols_tx, dmrs_vec, DMRS_COL);
            tx_slot = ofdm_modulate(grid_tx);

            % --- Channel and noise ---
            ch = TDLB100(fs, 25.0, 42+run);
            y = ch.apply_channel(tx_slot);
            n = ch.get_noise(y, snr);
            grid_rx = ofdm_demodulate(y+n);

            % --- LS (linear) estimation and ZF equalization ---
            [H_est_ls, ~] = ls_est_sparse(grid_rx, dmrs_vec, DMRS_COL, 'linear');
            data_zf = zf_eq(grid_rx, H_est_ls, DMRS_COL);
            mse_zf(mtype,i) = mse_zf(mtype,i) + compute_mse(symbols_tx, data_zf);
            bits_zf = demod_fns{mtype}(data_zf);
            ber_zf(mtype,i) = ber_zf(mtype,i) + compute_ber(bits_tx, bits_zf);

            % --- MMSE estimation and MMSE equalization ---
            [H_est_mmse, noise_var] = mmse_est_sparse(grid_rx, dmrs_vec, DMRS_COL, delta_f, tau_rms);
            data_mmse = mmse_eq(grid_rx, H_est_mmse, noise_var, DMRS_COL);
            mse_mmse(mtype,i) = mse_mmse(mtype,i) + compute_mse(symbols_tx, data_mmse);
            bits_mmse = demod_fns{mtype}(data_mmse);
            ber_mmse(mtype,i) = ber_mmse(mtype,i) + compute_ber(bits_tx, bits_mmse);
        end
    end
end

mse_zf = mse_zf / n_runs;
ber_zf = ber_zf / n_runs;
mse_mmse = mse_mmse / n_runs;
ber_mmse = ber_mmse / n_runs;

fprintf('SNR (dB) |   MSE (LS+ZF)   |   MSE (MMSE)   |  BER (LS+ZF)  |  BER (MMSE)\n');
fprintf('-----------------------------------------------------------------------------\n');
for i = 1:length(snr_vals)
    fprintf('%8d | %14.6e | %14.6e | %12.4e | %12.4e\n', ...
        snr_vals(i), mse_zf(i), mse_mmse(i), ber_zf(i), ber_mmse(i));
end

% Plot
figure;
for mtype = 1:numel(mod_types)
    semilogy(snr_vals, mse_zf(mtype,:), 'o-', 'LineWidth', 1.5, 'DisplayName', [mod_types{mtype} ' LS+ZF']); hold on;
    semilogy(snr_vals, mse_mmse(mtype,:), 's-', 'LineWidth', 1.5, 'DisplayName', [mod_types{mtype} ' MMSE']);
end
xlabel('SNR (dB)'); ylabel('Average MSE');
title('Average MSE vs SNR');
legend; grid on;

figure;
for mtype = 1:numel(mod_types)
    semilogy(snr_vals, ber_zf(mtype,:), 'o-', 'LineWidth', 1.5, 'DisplayName', [mod_types{mtype} ' LS+ZF']); hold on;
    semilogy(snr_vals, ber_mmse(mtype,:), 's-', 'LineWidth', 1.5, 'DisplayName', [mod_types{mtype} ' MMSE']);
end
xlabel('SNR (dB)'); ylabel('Average BER');
title('Average BER vs SNR');
legend; grid on;