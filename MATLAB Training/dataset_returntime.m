function [maxtime] = dataset_returntime(fname,mode_rawdata)
% Given an input MF4 file with path+name `fname`, reads its contents +
% returns the duration of the MF4 file in milliseconds.

    % ~~~~~~~~~~~~~~~~~~~~~~~
    % ~~~~ READ RAW DATA ~~~~ 
    % ~~~~~~~~~~~~~~~~~~~~~~~
    
    % Track .mf4 file number (if any)
    % mf4_filename_index = parse_mf4_number(fname);

    % (Hyperparameter: XYZ data may be "raw" or "buttered")   
    mdfObj = mdf(fname);
    data = read(mdfObj);
    ttable = data{1};       % 'ttable' stands for "timetable"
    times = ttable.Time;                    % Times, as time vector (Realtime?)
    
    % Position data & diagnostics 
    if contains(fname,"2024-04-")
        % Old ver (pre-May2024)
        x_pos = ttable.("ModelRoot_plant_PositionDetermination1_X_m_");
        y_pos = ttable.("ModelRoot_plant_PositionDetermination1_Y_m_");
        z_pos = ttable.("ModelRoot_plant_PositionDetermination1_Z_m_");
        diagnostics_head1_empty             = ttable.("ModelRoot_Monitoring_diagnostics_h1_empty");
        diagnostics_head2_or_head3_empty    = ttable.("ModelRoot_Monitoring_diagnostics_h2_or_h3_empty");
        diagnostics_head1_off       = ttable.("ModelRoot_Monitoring_diagnostics_h1_off");
        diagnostics_head2_off       = ttable.("ModelRoot_Monitoring_diagnostics_h2_off");
        diagnostics_head3_off       = ttable.("ModelRoot_Monitoring_diagnostics_h3_off");
        diagnostics_z_resting           = ttable.("ModelRoot_Monitoring_diagnostics_z_resting");
        diagnostics_z_resting_toolow    = ttable.("ModelRoot_Monitoring_diagnostics_z_resting_too_low");
        delet = ttable.("ModelRoot_get_plant_input_Z_1dctrl_Current2Vol1_Gain2_Out1");          % redundant; identical to V_coil0
    else
        % New ver (post-May2024)
        if lower(mode_rawdata)=="buttered"
            x_pos = ttable.("ModelRoot_plant_PositionDetermination1_x_pos_fil");    % Unneeded? (Only used for identifying "convergence" during data-gen)
            y_pos = ttable.("ModelRoot_plant_PositionDetermination1_y_pos_fil");    % Unneeded? (Only used for identifying "convergence" during data-gen)
            z_pos = ttable.("ModelRoot_plant_PositionDetermination1_z_pos_fil");    % Unneeded? (Only used for "D" gain + identifying "convergence" during data-gen)
        elseif lower(mode_rawdata)=="raw"
            x_pos = ttable.("ModelRoot_plant_PositionDetermination1_x_pos_raw");
            y_pos = ttable.("ModelRoot_plant_PositionDetermination1_y_pos_raw");
            z_pos = ttable.("ModelRoot_plant_PositionDetermination1_z_pos_raw");
        else
            error('Invalid `mode_rawdata`')
        end
        if contains(fname,"2024-05-06")
            diagnostics_head1_empty             = ttable.("ModelRoot_Monitoring_diagnostics_h1_empty");
            diagnostics_head2_or_head3_empty    = ttable.("ModelRoot_Monitoring_diagnostics_h2_or_h3_empty");
            diagnostics_is_in_workspace         = ~diagnostics_head1_empty | ~diagnostics_head2_or_head3_empty;
            diagnostics_is_ready_to_run         = ~(diagnostics_head1_empty | diagnostics_head2_or_head3_empty);
            % diagnostics_z_resting               = ttable.("ModelRoot_Monitoring_diagnostics_z_resting");
            % diagnostics_z_resting_toolow        = ttable.("ModelRoot_Monitoring_diagnostics_z_resting_too_low");
            % diagnostics_recording_safe          = ttable.("ModelRoot_Monitoring_recording_safe_Out1");
        else
            diagnostics_quickreport             = ttable.("ModelRoot_Monitoring_diagnostics_summary_quickreport");
            diagnostics_is_in_workspace         = get_digits(diagnostics_quickreport,12);
            diagnostics_is_ready_to_run         = get_digits(diagnostics_quickreport,11);
            % diagnostics_z_resting               = diagnostics_quickreport;
            % diagnostics_z_resting_toolow        = diagnostics_quickreport;
            % diagnostics_recording_safe          = diagnostics_quickreport;
            % h1_V                                = ttable.("ModelRoot_plant_outputSignal_HeadZ_V__Out1");
            % h2_V                                = ttable.("ModelRoot_plant_outputSignal_HeadII_V__Out1");
            % h3_V                                = ttable.("ModelRoot_plant_outputSignal_HeadIII_V__Out1");
                % Original python code, for comparison:
                % is_in_workspace         = get_digits(quickreport,12)
                % is_ready_to_run         = get_digits(quickreport,11)
                % diagnostics_stability   = get_digits(quickreport,10)
                % is_close                = get_digits(quickreport,9)
                % is_converged            = get_digits(quickreport,8)
                % is_xy_dangerzone        = get_digits(quickreport,7)
                % diagnostics_resting     = get_digits(quickreport,6)
                % is_converged_x          = get_digits(quickreport,5)
                % is_converged_y          = get_digits(quickreport,4)
                % is_saturated            = get_digits(quickreport,3)
        end
    end
    
    % Unit conversions
    times_ms = milliseconds(times);  % Time, in ms
    % times_s = seconds(times);  % Time, in s
    % x_pos = x_pos*1000;     % x_pos, in mm
    % y_pos = y_pos*1000;     % mm
    % z_pos = z_pos*1000;     % mm
    
    % Return empty table if max time is unusably short
    maxtime = times_ms(end);
    if maxtime < 500
        % error(fname+" has a maximum time value of "+num2str(maxtime)+", which is too short.")
        disp(fname+" has a maximum time value of "+num2str(maxtime)+", which is too short.")
        % file_data = [];
        return
    end
    return


end

function [val] = get_digit(number, n)
% Returns value of digit `n` of a number, counting from right (e.g.
% get_digit(67890, 2) would return 9).
    number_str = num2str(number);
    [~,n_digits] = size(number_str);
    val = str2num(number_str(n_digits+1-n));
end
function [val] = get_digits(arr, n)
% Returns a vector of the nth digit of some number array, counting from the
% right (e.g. get_digit([67890; 12345], 2) would return [9; 4]).
% Note that there are 12 digits per reading, which is where the 
    arr_str = num2str(arr,'%012.f');
    [~,n_digits] = size(arr_str);
    val = str2num(arr_str(:,n_digits+1-n));
end

