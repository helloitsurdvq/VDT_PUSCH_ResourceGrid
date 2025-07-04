function dmrs_data = load_dmrs(filename, num_subcarriers)
        if exist(filename, 'file')
            fprintf('Loading DMRS data from %s...\n', filename);
            
            try
                [~, ~, raw_data] = xlsread(filename);
                fprintf('Successfully loaded raw data using xlsread.\n');
                
                % Parse complex numbers from strings
                dmrs_data = parse_complex_data(raw_data, num_subcarriers);
                fprintf('Successfully parsed complex DMRS data.\n');
                
            catch ME
                fprintf('Error reading Excel file: %s\n', ME.message);
                error('Could not read DMRS data from file');
            end
            
            if size(dmrs_data, 1) ~= num_subcarriers
                if size(dmrs_data, 2) == num_subcarriers
                    dmrs_data = dmrs_data';
                    fprintf('Transposed DMRS data to match required dimensions.\n');
                else
                    error('DMRS data size mismatch: expected %d rows, got %d', num_subcarriers, size(dmrs_data, 1));
                end
            end
            
            fprintf('Successfully loaded DMRS data from file.\n');
            
        else
            error('DMRS file not found: %s', filename);
        end
    
    if isreal(dmrs_data)
        dmrs_data = complex(dmrs_data);
    end
    
    if size(dmrs_data, 1) ~= num_subcarriers
        error('DMRS data must have %d rows', num_subcarriers);
    end
    
    fprintf('DMRS data loaded: %d x %d complex values\n', size(dmrs_data, 1), size(dmrs_data, 2));
end

function dmrs_data = parse_complex_data(raw_data, num_subcarriers)
    if iscell(raw_data)
        data_column = raw_data(:, 1);
        dmrs_data = zeros(num_subcarriers, 1);
        
        for i = 1:min(length(data_column), num_subcarriers)
            value = data_column{i};
            dmrs_data(i) = parse_single_complex(value);
        end
        
        if length(data_column) < num_subcarriers
            dmrs_data(length(data_column)+1:num_subcarriers) = 0;
        end
        
    else
        % Handle numeric array
        dmrs_data = raw_data(1:num_subcarriers, 1);
        if isreal(dmrs_data)
            dmrs_data = complex(dmrs_data);
        end
    end
    
    fprintf('Parsed %d complex values from Excel data\n', length(dmrs_data));
end

function complex_val = parse_single_complex(value)
    if isnumeric(value)
        % Direct numeric value
        complex_val = complex(value);
    elseif ischar(value) || isstring(value)
        % String value - need to parse
        str_val = char(value);
        
        % Remove any whitespace
        str_val = strtrim(str_val);
        
        % Check if it's a pure real number
        if isempty(regexp(str_val, '[ij]', 'once'))
            complex_val = complex(str2double(str_val));
        else
            % Handle complex number in string format
            complex_val = parse_complex_string(str_val);
        end
    else
        % Unknown format, default to 0
        complex_val = 0;
    end
end

function complex_val = parse_complex_string(str_val)
    str_val = strrep(str_val, 'i', 'j');
  
    if strcmp(str_val, 'j') || strcmp(str_val, '+j')
        complex_val = 1j;
    elseif strcmp(str_val, '-j')
        complex_val = -1j;
    elseif strcmp(str_val(1), 'j')
        complex_val = 1j * str2double(str_val(2:end));
    elseif strcmp(str_val(1:2), '+j')
        complex_val = 1j * str2double(str_val(3:end));
    elseif strcmp(str_val(1:2), '-j')
        % -j followed by number
        complex_val = -1j * str2double(str_val(3:end));
    else
        try
            complex_val = eval(str_val);
        catch
            % If evaluation fails, try to parse manually
            complex_val = parse_manual_complex(str_val);
        end
    end
end

function complex_val = parse_manual_complex(str_val)
    if contains(str_val, '+')
        parts = strsplit(str_val, '+');
        if length(parts) == 2
            real_part = str2double(parts{1});
            imag_part_str = parts{2};
            if contains(imag_part_str, 'j')
                imag_part = str2double(strrep(imag_part_str, 'j', ''));
                complex_val = real_part + 1j * imag_part;
            else
                complex_val = real_part;
            end
        else
            complex_val = 0;
        end
    elseif contains(str_val, '-')
        % Handle negative imaginary part
        if str_val(1) == '-'
            % Starts with negative
            if contains(str_val(2:end), '-')
                parts = strsplit(str_val(2:end), '-');
                if length(parts) == 2
                    real_part = -str2double(parts{1});
                    imag_part_str = parts{2};
                    if contains(imag_part_str, 'j')
                        imag_part = str2double(strrep(imag_part_str, 'j', ''));
                        complex_val = real_part - 1j * imag_part;
                    else
                        complex_val = real_part;
                    end
                else
                    complex_val = 0;
                end
            else
                complex_val = str2double(str_val);
            end
        else
            % Has negative in middle
            parts = strsplit(str_val, '-');
            if length(parts) == 2
                real_part = str2double(parts{1});
                imag_part_str = parts{2};
                if contains(imag_part_str, 'j')
                    imag_part = str2double(strrep(imag_part_str, 'j', ''));
                    complex_val = real_part - 1j * imag_part;
                else
                    complex_val = real_part;
                end
            else
                complex_val = 0;
            end
        end
    else
        % No + or -, might be pure real or pure imaginary
        if contains(str_val, 'j')
            complex_val = 1j * str2double(strrep(str_val, 'j', ''));
        else
            complex_val = str2double(str_val);
        end
    end
    
    % Handle NaN or invalid results
    if isnan(complex_val)
        complex_val = 0;
    end
end