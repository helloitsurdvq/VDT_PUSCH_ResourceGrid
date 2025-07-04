bits = de2bi(0:15, 4, 'left-msb'); % 16x4, each row is [b0 b1 b2 b3]

I = (1 - 2*bits(:,1)) .* (1 + 2*bits(:,3));
Q = (1 - 2*bits(:,2)) .* (1 + 2*bits(:,4));
symbols = (I + 1j*Q) / sqrt(10);

figure;
plot(real(symbols), imag(symbols), 'bo', 'MarkerSize', 10, 'LineWidth', 2);
grid on; axis equal;
xlabel('In-phase (I)');
ylabel('Quadrature (Q)');
title('16-QAM Constellation');
xlim([-2 2]); ylim([-2 2]);

for k = 1:16
    text(real(symbols(k))+0.08, imag(symbols(k)), num2str(bits(k,:), '%d'), 'FontSize', 10);
end
