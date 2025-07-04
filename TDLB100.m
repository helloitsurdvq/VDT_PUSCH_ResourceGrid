classdef TDLB100 < handle
    % TDL-B (100ns - 25Hz) fading channe;
    properties (Constant)
        POW_DB = [0.0, -2.2, -0.6, -0.6, -0.3, -1.2, -5.9, -2.2, -0.8, -6.3, -7.5, -7.1];
        DEL_NS = [0.0, 10.0, 20.0, 30.0, 35.0, 45.0, 55.0, 120.0, 170.0, 245.0, 330.0, 480.0];
    end
    properties
        fs      % Sample rate (Hz)
        fd      % Doppler (Hz)
        rng     % Random stream
        p_lin   % Linear tap powers
        del_samp% Tap delays (samples)
        ntaps   % Number of taps
        tau_max % Max delay (samples)
        faders  % Jakes fader params: {omega, phi, scale2}
    end
    methods
        function obj = TDLB100(fs, fd, seed, M)
            if nargin < 2, fd = 25.0; end
            if nargin < 3, seed = 'shuffle'; end
            if nargin < 4, M = 16; end
            obj.fs = fs;
            obj.fd = fd;
            obj.rng = RandStream('mt19937ar','Seed',seed);
            obj.p_lin = 10.^(obj.POW_DB/10);
            obj.del_samp = round(obj.DEL_NS * 1e-9 * obj.fs);
            obj.ntaps = numel(obj.p_lin);
            obj.tau_max = max(obj.del_samp);
            k = 1:M;
            alpha = pi*(k-0.5)/M;
            omega = 2*pi*obj.fd*cos(alpha);
            phi = 2*pi*rand(obj.rng, obj.ntaps, M);
            scale2 = 2.0/M;
            obj.faders = {omega, phi, scale2};
        end
        function h = cir(obj, num, start)
            % Generate CIR matrix shape (ntaps, num) complex
            if nargin < 3, start = 0; end
            omega = obj.faders{1};
            phi = obj.faders{2};
            scale2 = obj.faders{3};
            t = (start + (0:num-1)) / obj.fs;
            i = zeros(obj.ntaps, num);
            q = zeros(obj.ntaps, num);
            for tap = 1:obj.ntaps
                pha = omega(:) * t + phi(tap, :)'; % (M x num)
                i(tap,:) = sqrt(scale2) * sum(cos(pha),1);
                q(tap,:) = sqrt(scale2) * sum(sin(pha),1);
            end
            h = complex(i, q);
            h = h .* sqrt(obj.p_lin(:));
        end
        function y = apply_channel(obj, x)
            % Filter x through channel, return y same shape
            if ~isvector(x) || ~isnumeric(x)
                error('x must be 1-D numeric array');
            end
            x = x(:).';
            N = numel(x);
            y = zeros(1, N + obj.tau_max);
            h = obj.cir(N);
            for k = 1:obj.ntaps
                d = obj.del_samp(k);
                y(d+1:d+N) = y(d+1:d+N) + h(k,:) .* x;
            end
            y = y(1:N);
            % Normalize
            y = y / sqrt(mean(abs(y).^2)) * sqrt(mean(abs(x).^2));
            y = y.'; % Return as column
        end
        function noise = get_noise(obj, x, snr_db)
            N = numel(x);
            snr_lin = 10^(snr_db/10);
            noise_var = mean(abs(x).^2) / snr_lin;
            noise = sqrt(noise_var/2) * ...
                (randn(obj.rng, N, 1) + 1j*randn(obj.rng, N, 1));
        end
    end
end 