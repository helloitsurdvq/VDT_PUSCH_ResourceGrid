function grid_rx = ofdm_demodulate(rx_slot)
    N_FFT = 4096;
    CP_LENGTHS = [320, repmat(288,1,6), 320, repmat(288,1,6)];
    TOTAL_SAMPLES = 61440;
    N_SC = 3276;
    if length(rx_slot) ~= TOTAL_SAMPLES
        error('rx_slot length mismatch');
    end
    grid_rx = zeros(N_SC, 14);
    idx = 1;
    for s = 1:14
        idx = idx + CP_LENGTHS(s);
        sym_td = rx_slot(idx:idx+N_FFT-1);
        idx = idx + N_FFT;
        bins = fft(sym_td) / N_FFT;
        bins_shifted = fftshift(bins);
        half = N_SC/2;
        center = N_FFT/2;
        start = center - half + 1;
        grid_rx(:,s) = bins_shifted(start:start+N_SC-1);
    end
end