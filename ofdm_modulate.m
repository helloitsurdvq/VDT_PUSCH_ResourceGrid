function tx = ofdm_modulate(grid)
    N_FFT = 4096;
    CP_LENGTHS = [320, repmat(288,1,6), 320, repmat(288,1,6)];
    TOTAL_SAMPLES = 61440;
    [N_SC, N_SYM] = size(grid);
    symbols_td = [];
    for s = 1:N_SYM
        vec = map_subcarriers(grid(:,s), N_FFT);
        time_sym = ifft(vec);
        cp = time_sym(end-CP_LENGTHS(s)+1:end);
        symbols_td = [symbols_td; cp; time_sym];
    end
    tx = N_FFT * symbols_td;
    if length(tx) ~= TOTAL_SAMPLES
        error('Sample count mismatch');
    end
end

function vec_shift = map_subcarriers(sym_freq, n_fft)
    k = length(sym_freq);
    half = k/2;
    vec_shift = zeros(n_fft,1);
    center = n_fft/2;
    start = center - half + 1;
    vec_shift(start:start+k-1) = sym_freq;
    vec_shift = ifftshift(vec_shift);
end