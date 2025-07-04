function ber = compute_ber(bits_tx, bits_rx)
    errors = bits_tx ~= bits_rx;
    ber = mean(errors(:));
end