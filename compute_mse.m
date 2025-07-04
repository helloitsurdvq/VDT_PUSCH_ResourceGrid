function mse = compute_mse(symbols_tx, symbols_rx)
    diff = symbols_tx - symbols_rx;
    mse = mean(abs(diff(:)).^2);
end