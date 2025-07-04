%% 5G PUSCH Resource Grid 
clear; clc; close all;
%%

rng(42);
N_SC = 3276;
N_SYM = 13;
DMRS_COL = 4; % matlab is 1-based
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
methods = {'none', 'nearest'};
labels = {'No EQ', 'LS+ZF'};

mse_avg = zeros(length(methods), length(snr_vals));
ber_avg = zeros(length(methods), length(snr_vals));

for run = 1:n_runs
    fprintf('Run %d/%d\n', run, n_runs);
    for i = 1:length(snr_vals)
        snr = snr_vals(i);

        % --- Generate new random bits and symbols for each run ---
        bits_tx = randi([0 1], N_SC, N_SYM, 4, 'uint8');
        symbols_tx = qam16_gray(bits_tx);
        grid_tx = build_grid(symbols_tx, dmrs_vec, DMRS_COL);
        tx_slot = ofdm_modulate(grid_tx);

        % --- Channel and noise ---
        ch = TDLB100(fs, 25.0, 42+run);
        y = ch.apply_channel(tx_slot);
        n = ch.get_noise(y, snr);
        grid_rx = ofdm_demodulate(y+n);

        data_raw = grid_rx;
        data_raw(:, DMRS_COL) = [];

        for m = 1:length(methods)
            if strcmp(methods{m}, 'none')
                data_proc = data_raw;
            else
                [H_est, ~] = ls_est_sparse(grid_rx, dmrs_vec, DMRS_COL, 'linear');
                data_proc = zf_eq(grid_rx, H_est, DMRS_COL);
            end
            mse_avg(m,i) = mse_avg(m,i) + compute_mse(symbols_tx, data_proc);
            bits_rx = qam16_gray_demod(data_proc);
            ber_avg(m,i) = ber_avg(m,i) + compute_ber(bits_tx, bits_rx);
        end
    end
end

mse_avg = mse_avg / n_runs;
ber_avg = ber_avg / n_runs;

fprintf('SNR (dB) |   MSE (No EQ)   |   MSE (LS+ZF)   |  BER (No EQ)  |  BER (LS+ZF)\n');
fprintf('-----------------------------------------------------------------------------\n');
for i = 1:length(snr_vals)
    fprintf('%8d | %14.6e | %14.6e | %12.4e | %12.4e\n', ...
        snr_vals(i), mse_avg(1,i), mse_avg(2,i), ber_avg(1,i), ber_avg(2,i));
end

%% 
figure;
for m = 1:length(methods)
    plot(snr_vals, mse_avg(m,:), 'o-', 'MarkerSize', 6, 'LineWidth', 1.5, 'DisplayName', labels{m}); hold on;
end
xlabel('SNR (dB)'); ylabel('Average MSE');
title('Average MSE vs SNR');
ylim([0 15]); yticks([0 1 2 3 4 5 6 7 8 9 10 15]);
legend; grid on;

figure;
for m = 1:length(methods)
    semilogy(snr_vals, ber_avg(m,:), 's-', 'MarkerSize', 6, 'LineWidth', 1.5, 'DisplayName', labels{m}); hold on;
end
xlabel('SNR (dB)'); ylabel('Average BER');
title('Average BER vs SNR');
ylim([0 1]); yticks([0 0.2 0.4 0.6 0.8 1]);
legend; grid on;