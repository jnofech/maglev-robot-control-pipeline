function [file_data] = dataset_generator(fname,mode_rawdata,mode_accel_method,mode_accel_filtering,lowpass_cutoff_hz,data_keep_ratio)
% Given an input MF4 file with path+name `fname`, reads its contents +
% returns a timetable of relevant data for use in ML training.
%
% INPUTS:
% ~~~~~~~
%   fname : str
%       Name of the file being processed
%   mode_rawdata : str
%       'buttered' (default) - Uses butter(6,0.6)-filtered position data
%                              (smooth, but has a ~5ms delay)
%       'raw'                - Uses unfiltered position data (no delay to 
%                              worry about, but requires additional
%                              filtering)
%   mode_accel_method : str
%       (!!TO BE IMPLEMENTED, as a hyperparameter!!)
%       High-level methodology by which accelerations are calculated.
%       'steps' (default) - accel. is measured throughout each v1x6 ratio
%       'continuous'      - accel. is continuous throughout entire file
%                           (simplest implementation, but does not account
%                           for discontinuous changes in V1x6)
%       'steps-simple'    - accel. is calculated only at the start of each
%                           new v1x6 ratio; the magnet is assumed to move
%                           in a straight line
%                           (lightweight dataset, but the magnet never
%                           changing directions is an oversimplifying
%                           assumption)
%   mode_accel_filtering : str
%       (!!TO BE IMPLEMENTED, as a hyperparameter!!)
%
%
    %   !! TEMPORARY INPUTS !!
    %   lowpass_cutoff_hz : double
    %       Cutoff frequency of the low-pass filter applied to the XY data
    %       (Lower = smoother position-vs-time data, but less rapid
    %       acceleration is captured)
    %   normalize_v1x6 : logical
    %       0 - (units: Volts) filters the voltages so that PID fluctuations 
    %           are eliminated, but V1x6 varies smoothly 
    %       1 - (unitless) only considers "normalized" voltages, so V1x6
    %           curve is basically a bunch of step functions
    %   data_keep_ratio : double
    %       Fraction of data that is kept for training, to speed up the process
%
% OUTPUTS:
% ~~~~~~~~
%   file_data : timetable(times, ...
%           V_coil1, V_coil2, V_coil3, V_coil4, V_coil5, V_coil6, ...
%           V_fil1, V_fil2, V_fil3, V_fil4, V_fil5, V_fil6, ...
%           x_pos, y_pos, z_pos, ...
%           x_fil, y_fil, z_fil, ...
%           x_vel, y_vel, z_vel, ...
%           x_acc, y_acc, z_acc, ...
%           );
%   
%
    %% ~~~~~~~~~~~~~~~~~~~~~~~
    % ~~~~ READ RAW DATA ~~~~
    % ~~~~~~~~~~~~~~~~~~~~~~~
    
    % Track .mf4 file number (if any)
    mf4_filename_index = parse_mf4_number(fname);

    % (Hyperparameter: XYZ data may be "raw" or "buttered")   
    mdfObj = mdf(fname);
    data = read(mdfObj);
    ttable = data{1};       % 'ttable' stands for "timetable"
    times = ttable.Time;                    % Times, as time vector (Realtime?)
    hostserv = ttable.("HostService");      % Times, as time vector (Controller time?)
    % NOTE: Coils are labeled on device. Orientations updated as of 2024-04-08.
    V_coil1 = ttable.("ModelRoot_get_plant_input_Z_1dctrl_Current2Vol1_Gain2_Out1_0_");     % -X, +Y
    V_coil2 = ttable.("ModelRoot_get_plant_input_Z_1dctrl_Current2Vol1_Gain2_Out1_1_");     % -X
    V_coil3 = ttable.("ModelRoot_get_plant_input_Z_1dctrl_Current2Vol1_Gain2_Out1_2_");     % -X, -Y
    V_coil4 = ttable.("ModelRoot_get_plant_input_Z_1dctrl_Current2Vol1_Gain2_Out1_3_");     % +X, -Y
    V_coil5 = ttable.("ModelRoot_get_plant_input_Z_1dctrl_Current2Vol1_Gain2_Out1_4_");     % +X
    V_coil6 = ttable.("ModelRoot_get_plant_input_Z_1dctrl_Current2Vol1_Gain2_Out1_5_");     % +X, +Y
    
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

    % Mark rows with .mf4 filename index
    mf4_filename_indices = x_pos*0 + mf4_filename_index;
    
    % Unit conversions
    times_ms = milliseconds(times);  % Time, in ms
    times_s = seconds(times);  % Time, in s
    x_pos = x_pos*1000;     % x_pos, in mm
    y_pos = y_pos*1000;     % mm
    z_pos = z_pos*1000;     % mm
    
    % Return empty table if max time is unusably short
    maxtime = times_ms(end);
    if maxtime < 500
        % error(fname+" has a maximum time value of "+num2str(maxtime)+", which is too short.")
        disp(fname+" has a maximum time value of "+num2str(maxtime)+", which is too short.")
        file_data = [];
        return
    end
    
    
    
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    % ~~~~ ENSURING CONSISTENCY ~~~~
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    %%disp("Reminder: Make sure the files use a consistent set of calibrations across different recordings when looping!")



    
    % ~~~~~~~~~~~~~~~~~~~~~~~
    % ~~~~ SPIKE REMOVAL ~~~~
    % ~~~~~~~~~~~~~~~~~~~~~~~
    % %disp("Reminder: `mode_rawdata` is used to determine xyz speed thresholds")
    drawplot = false;
    [x_pos,y_pos,z_pos, markfordeletion, mark_spikes_xy, mark_spikes_z] = clean_spikes(times_ms,x_pos,y_pos,z_pos, mode_rawdata, drawplot);
    
     




    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    % ~~~~ NORMALIZE COIL VOLTAGES? ~~~~
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    % Process coil voltages so that we have:
    %   - V_coilX   (raw voltages, from file)
    %   - V_normX   (voltage ratio, which appears as a normalized step function)
    %   - V_filX    (filtered voltages, which show overall scale without
    %                PID fluctuations getting in the way)
    %   - i_newratio    (1 where coil ratio changes, 0 otherwise)
    %   - PID_scaling   (V_coilX/V_normX, in VOLTS, including rapid fluctuations
    
    % V_normX : Normalized V1x6 ratio
    V_coils = [V_coil1, V_coil2, V_coil3, V_coil4, V_coil5, V_coil6];
    V_coils_mean = sum(V_coils, 2) / 6;
    V_norm1 = V_coil1 ./ V_coils_mean;
    V_norm2 = V_coil2 ./ V_coils_mean;
    V_norm3 = V_coil3 ./ V_coils_mean;
    V_norm4 = V_coil4 ./ V_coils_mean;
    V_norm5 = V_coil5 ./ V_coils_mean;
    V_norm6 = V_coil6 ./ V_coils_mean;
    
    % V_filX : Filtered voltages (V)
    filtershape   = 5;        % Lower = more Gaussian, higher = more rectangular
    lowpass_cutoff_V_hz = 0.016;
    [V_fil1,~] = filter_lowpass(times_ms,V_coil1,0,lowpass_cutoff_V_hz,filtershape,1,'Low-pass');
    [V_fil2,~] = filter_lowpass(times_ms,V_coil2,0,lowpass_cutoff_V_hz,filtershape,1,'Low-pass');
    [V_fil3,~] = filter_lowpass(times_ms,V_coil3,0,lowpass_cutoff_V_hz,filtershape,1,'Low-pass');
    [V_fil4,~] = filter_lowpass(times_ms,V_coil4,0,lowpass_cutoff_V_hz,filtershape,1,'Low-pass');
    [V_fil5,~] = filter_lowpass(times_ms,V_coil5,0,lowpass_cutoff_V_hz,filtershape,1,'Low-pass');
    [V_fil6,~] = filter_lowpass(times_ms,V_coil6,0,lowpass_cutoff_V_hz,filtershape,1,'Low-pass');
    
    % i_newratio : Row indices where new coil ratio is introduced
    V_norms = [V_norm1, V_norm2, V_norm3, V_norm4, V_norm5, V_norm6];
    V_norms_shifted = circshift(V_norms,1,1);
    i_newratio     = sum(abs(V_norms - V_norms_shifted) > 1e-10,2) ~= 0;         % "1" where the coil ratio changes, "0" otherwise
    i_newratio_nan = double(i_newratio);
    i_newratio_nan(~i_newratio) = NaN;                                           % "1" where the coil ratio changes, "NaN" otherwise
    i_newratio_nan(1) = 1;
    
    % PID scalings
    % PID_scaling = V_coil1 ./ V_norm1;    % In VOLTS; includes rapid fluctuations
    PID_scaling = mean([V_coil1 ./ V_norm1,V_coil2 ./ V_norm2,V_coil3 ./ V_norm3,V_coil4 ./ V_norm4,V_coil5 ./ V_norm5,V_coil6 ./ V_norm6],2);
    



    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    % ~~~~ CALCULATE ACCELERATIONS? ~~~~
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    %disp("Reminder: Loop through 'segments'. For each segment, find a way to calculate 'consensus' accelerations among numerous filters!")
    %disp("Reminder: The main objective is to get accelerations, NOT the filtered XYZ velocities and such.")
    %disp("Reminder: Accel should either be [a continuous curve across all times], [a DIScontinuous curve across all times], or [an individual value for the start of EACH V1x6 ratio].")
    % if ismember(lower(mode_accel_method),["steps","chunks","segments"])
    %     % do a thing
    % elseif lower(mode_accel_method)=="continuous"
    %     % simplest behaviour (copypaste)
    % elseif ismember(lower(mode_accel_method),["steps-simple","simple"])
    %     % do the other thingy
    % elseif lower(mode_accel_method)=="legacy"
    %     % Pre-May2024 behaviour of just filtering the whole thing at once      
    % else
    %     error("Invalid `mode_accel_calculation`");
    % end
    % [x_acc, y_acc, z_acc] = get_accelerations(x_pos,y_pos,z_pos,i_newratio,);  
    
    
    % ~~~~~~~~~~~~~~~~~~~~~~~
    % ~~~~ ACCELERATIONS ~~~~
    % ~~~~~~~~~~~~~~~~~~~~~~~
    % Filter signals.
    % NOTE: When using Fourier filters (`ifilter_noplot`), the filtered signal
    %   be inaccurate towards the start & ends, with these inaccurate regions
    %   widening _inversely_ to filter width (i.e. lower filter width = wider
    %   inaccurate region), and apparently NOT being affected by total signal
    %   duration (i.e. a ~1.5s inaccurate region will be 1.5s on all
    %   recordings!).
    % Smooth tapering, signal padding, or _signal "cropping"_ is needed.
    
                % % ~~ (UNUSED; less robust) POSITION FILTER ~~
                % % ALT FILTER 1 : Butterworth
                % fc = 3.1;    % Cutoff frequency (Hz)
                % fs = 1000;  % Sampling frequency (Hz)
                % n_order = 4; % Filter order (higher = steeper filter roll-off, but higher risk of phase distortion)
                % [bee,aye] = butter(n_order,fc/(fs/2));
                % x_fil2 = filtfilt(bee,aye,x_pos);   % Filters the data forward and then back, which prevents the phase shifting
    
    % ~~ POSITION FILTER 0 ~~
    % FILTER 1 : Low-pass, to get rid of the most extreme data spikes
    filterwidth   = 0.002;    % in Hz, I think (initial run, pre-3/12/24)
    filtershape   = 5;        % Lower = more Gaussian, higher = more rectangular
    [x_fil,~] = filter_lowpass(times_ms,x_pos,0,filterwidth,filtershape,1,'Low-pass');
    [y_fil,~] = filter_lowpass(times_ms,y_pos,0,filterwidth,filtershape,1,'Low-pass');
    [z_fil,~] = filter_lowpass(times_ms,z_pos,0,filterwidth,filtershape,1,'Low-pass');
    
    % ~~ POSITION FILTER 1 : S-G to remove noise, then filter out oscillations
    % with Fourier filter
    % FILTER 1 : S-G -> moving average
    noise_period_ms = 135;
    % x_mavge = sgolayfilt(x_pos,1,noise_period_ms);
    x_sgfilt = sgolayfilt(x_pos,3,noise_period_ms);
    x_sgfilt2 = sgolayfilt(x_sgfilt,1,noise_period_ms);
    y_sgfilt = sgolayfilt(y_pos,3,noise_period_ms);
    y_sgfilt2 = sgolayfilt(y_sgfilt,1,noise_period_ms);
    
    % FILTER 2 : Low-pass
    lowpass_cutoff_hz_001 = 0.001;
    lowpass_cutoff_hz_002 = 0.002;  % REPLACE WITH `lowpass_cutoff_hz` IN ACTUAL FUNCTION
    filtershape   = 5;        % Lower = more Gaussian, higher = more rectangular
    % [x_fil_001,~] = filter_lowpass(times_ms,x_sgfilt2,0,lowpass_cutoff_hz_001,filtershape,1,'Low-pass');
    [x_fil_002,~] = filter_lowpass(times_ms,x_sgfilt2,0,lowpass_cutoff_hz_002,filtershape,1,'Low-pass');
    [y_fil_002,~] = filter_lowpass(times_ms,y_sgfilt2,0,lowpass_cutoff_hz_002,filtershape,1,'Low-pass');
    
    % FINAL FILTER:
    % Calculate accelerations real quicky-like (in mm/s/s)
    % x_vfil_001 = gradient(x_fil_001, times_s);
    % x_afil_001 = gradient(x_vfil_001, times_s);
    x_vel = gradient(x_fil_002, times_s);
    x_afil_002 = gradient(x_vel, times_s);
    y_vel = gradient(y_fil_002, times_s);
    y_afil_002 = gradient(y_vel, times_s);
    % ^ !!! 3/18/24 - DECIDE HOW TO COMBINE THE ABOVE FILTERS (INCLUDING
    % "ORIGINAL") INTO THEIR FINAL FORM! (IF NECESSARY)
    
    % ~~ some placeholder for z i guess ~~
    % FILTER 1
    z_sgfilt = sgolayfilt(z_pos,1,noise_period_ms);
    % FILTER 2 : Low-pass (GENTLE, for actual movement)
    filterwidth   = 0.02;    % in Hz, I think
    filtershape   = 5;        % Lower = more Gaussian, higher = more rectangular
    [z_fil,~] = ifilter_noplot(times_ms,z_sgfilt,0,filterwidth,filtershape,1,'Low-pass');
    z_fil = z_fil';
    z_vel = gradient(z_fil, times_s);
    z_afil = gradient(z_vel, times_s);
    

    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    % ~~~~ FINALIZE VELS+ACCELS ~~~~
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    x_acc = x_afil_002;
    y_acc = y_afil_002;
    z_acc = z_afil;
    
    % (6-05-24 MISC ADDITIONS)
    movingwindow_threshold_ms = 100;
    PIDjitter_threshold_V = 0.02;
    movingmax = movmax(PID_scaling,[movingwindow_threshold_ms, 20]);
    movingmin = movmin(PID_scaling,[movingwindow_threshold_ms, 20]);
    mark_PIDjitter = abs(movingmax - movingmin) > PIDjitter_threshold_V;
    
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    % ~~~~ CREATE MORE ORGANIZED TABLE ~~~~
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    %disp("Reminder: The lightweight-accel version should insta-delete the overwhelming majority of the rows in the table!")
    %disp("Reminder: The lightweight-accel version should also have corresponding indicators of power requirements and heat generation (see Trello), so that each entry can be weighted.")
    
    data = timetable(times, V_coil1, V_coil2, V_coil3, V_coil4, V_coil5, V_coil6, ...
    V_fil1, V_fil2, V_fil3, V_fil4, V_fil5, V_fil6, ...
    PID_scaling, ...
    x_pos, y_pos, z_pos, ...
    x_fil, y_fil, z_fil, ...
    x_vel, y_vel, z_vel, ...
    x_acc, y_acc, z_acc, ...
    mark_PIDjitter, mf4_filename_indices);
    
    % ~~~~~~~~~~~~~~~~~~~~~~~
    % ~~~~ FINAL TOUCHES ~~~~
    % ~~~~~~~~~~~~~~~~~~~~~~~
    % disp("Reminder: Here, track power cost and heat generation throughout. Remove lowest-weight data for the non-lightweight-accel versions, to improve training speeds.")
    % disp("Reminder: CHANGES TO MAKE: Only use the `markfordeletion` bit for completely unsalvageable data; we want to properly weight the data instead!")
        % ^ ("Completely unsalvageable data" includes data where at least 1 sensor is empty, erroneous PID_scaling==0/NaN cases, coil saturation reached, etc)
    
    
    
    
    % DELETE ALL ROWS WITH INVALID DATA
    
    % delete data close to where the spikes were
    markfordeletion = markfordeletion;
    
    % % |dz| > threshold
    % % (Temporary, until I can account for height!)
    % z_target_mm = 2.00;             % ensure same units as z_pos
    % dz = abs(z_target_mm - z_pos);
    % markfordeletion = markfordeletion | (dz > 0.1);
    
    % Problematic diagnostics
    % markfordeletion = markfordeletion | diagnostics_z_resting_toolow | ...
    %     diagnostics_head1_empty | diagnostics_head2_or_head3_empty | ...
    %     diagnostics_head1_off | diagnostics_head2_off | diagnostics_head3_off;
    markfordeletion = markfordeletion | ~diagnostics_is_ready_to_run | ...
        (abs(x_pos) > 5.0) | (z_pos < -1) | isnan(PID_scaling);
    
    % Apply deletion
    data(markfordeletion,:) = [];
    
    
    % RANDOMLY SELECT ~5% OF DATASET, AND KEEP IT!
    idx_keep = randperm(height(data));
    file_data = data(idx_keep(1:round(height(data)*data_keep_ratio)),:);
    % ^ Final set of data from this file. Append onto the main table, and move
    % on to the next file!

end

%%
function [x_filled,y_filled,z_filled, markfordeletion, mark_spikes_xy, mark_spikes_z] = clean_spikes(times_ms,x_pos,y_pos,z_pos, mode_rawdata, drawplot)
% Detects unwanted "spikes" in X, Y, and/or Z measurements due to erroneous
% laser sensor readings (e.g. lasers being reflected into the wrong sensor
% by a glossy magnet).
% Data with unwanted "XY" spikes will be deleted, and these gaps will be
% filled using autoregressive modelling (`fillgaps()`). These filled gaps
% will be marked so that they are not actually used in ML training.

    % Find "raw" velocities, purely for initial analysis
    x_vraw = gradient(x_pos, times_ms);
    y_vraw = gradient(y_pos, times_ms);
    z_vraw = gradient(z_pos, times_ms);
    
    % Mark where v > some threshold, in mm/ms (spikes)
        % % Old ver (pre-May2024)
        % threshold_vel = 2.5e-3;
        % mark_spikes = (abs(x_vraw) > threshold_vel) | (abs(y_vraw) > threshold_vel);
        
        % New ver (post-May2024)
        if lower(mode_rawdata)=="raw"
            threshold_vel_z = 0.04;     % for "raw" z data
            threshold_vel_xy = 0.5;     % for "raw" xy data (Intentionally obscenely high)
        elseif lower(mode_rawdata)=="buttered"
            threshold_vel_z = 0.005;     % for "buttered" z data
            threshold_vel_xy = 0.5;     % for "raw" xy data (Intentionally obscenely high)
        else
            error("clean_spikes() - Invalid `mode_rawdata`.")
        end
        mark_spikes_xy = (abs(x_vraw) > threshold_vel_xy) | (abs(y_vraw) > threshold_vel_xy);
        mark_spikes_z = abs(z_vraw) > threshold_vel_z;

        % Create "continuous" marked regions
        % (Note: The spikes typically last about ~100ms each)
        % (Note: This is done using image dilation, and assumes that the data was
        %    recorded periodically-- and if it wasn't, then something has already
        %    gone horribly wrong)
        nearspikes_threshold = 100;                 % closeness threshold, ms (approx)
        strel = ones(1+2*nearspikes_threshold,1);   % 1D structuring element
        strel_erode = ones(1+2*(nearspikes_threshold-5),1);   % 1D structuring element
        mark_spikes_xy = imerode( imdilate(mark_spikes_xy,strel) ,strel_erode);
        mark_spikes_z  = imerode( imdilate(mark_spikes_z ,strel) ,strel_erode);


        % Choose which marked regions will be deleted+filled
        % mark_spikes = mark_spikes_xy | mark_spikes_z;
        mark_spikes = mark_spikes_xy;
        % disp("(2024-05-07) The z-spikes don't affect XY data too much, so we can safely ignore them until the feature engineering stage!")
        % disp("(2024-05-09) Also, note that the erroneous z-spikes are smaller in magnitude than the jitter that actually happens from randomly fluctuating CCR." + ...
        %     " Accounting for them explicitly might be neither necessary nor possible!")
    
    
    % For visualization
    mark_spikes_nan = double(mark_spikes);
    mark_spikes_nan(~mark_spikes) = NaN;
    mark_spikes_nan_z = double(mark_spikes_z);
    mark_spikes_nan_z(~mark_spikes_nan_z) = NaN;
    
    % Remove spikes, and fill in gaps!
    mark_good_nan = double(~mark_spikes);
    mark_good_nan(mark_spikes) = NaN;
    x_gap = x_pos.*mark_good_nan;
    y_gap = y_pos.*mark_good_nan;
    z_gap = z_pos.*mark_good_nan;
    filler_max_samples = 2000;      % Higher is better, but slower
    x_filled = fillgaps(x_gap,filler_max_samples);
    y_filled = fillgaps(y_gap,filler_max_samples);
    z_filled = fillgaps(z_gap,filler_max_samples);
    
    % % Establish new "raw" data
    % x_pos = x_filled;
    % y_pos = y_filled;
    % z_pos = z_filled;

    % Mark data that should not be used in training
    % markfordeletion = mark_spikes | mark_spikes_z;
    markfordeletion = mark_spikes;

    if drawplot==true
        % VISUALIZE spike cleaning!
        % Window range
        % xmin = 24660;
        % xmax = 24700;

        % Plot x/y velocities
        figure;
        hold on
        plot(times_ms, abs(x_vraw).*mark_good_nan,'b--','DisplayName','raw x-velocity')
        plot(times_ms, abs(y_vraw).*mark_good_nan,'b-','DisplayName','raw y-velocity')
        plot(times_ms, times_ms*0 + threshold_vel_xy, 'k--','DisplayName','spike detection threshold')
        plot(times_ms, abs(x_vraw).*mark_spikes_nan,'r--','DisplayName','x-spikes')
        plot(times_ms, abs(y_vraw).*mark_spikes_nan,'r-','DisplayName','y-spikes')
        hold off
        ylim([0,threshold_vel_xy*1.5])
        title("Spike detection (xy)")
        xlabel("Time (ms)")
        ylabel("Unfiltered horizontal velocity (mm/ms)")
        legend()

        % Plot z velocities
        figure;
        hold on
        plot(times_ms, abs(z_vraw),'DisplayName','raw z-velocity')
        plot(times_ms, times_ms*0 + threshold_vel_z, 'k--','DisplayName','spike detection threshold')
        plot(times_ms, abs(z_vraw).*mark_spikes_nan_z,'r-','DisplayName','spikes')
        ylim([0,threshold_vel_z*1.5])
        hold off
        title("Spike detection (z)")
        xlabel("Time (ms)")
        ylabel("Unfiltered vertical velocity (mm/ms)")
        legend()
        % xlim([xmin,xmax])


        % Plot positions
        figure;
        hold on
        plot(times_ms,x_gap*1000, 'Color',[0, 0, 1, 0.5],'LineStyle','--','LineWidth',1,'DisplayName','raw x-signal');
        plot(times_ms,x_pos*1000.*mark_spikes_nan, 'Color',[1, 0, 0, 0.5],'LineStyle','--','LineWidth',1,'DisplayName','x-spikes');
        plot(times_ms,x_filled*1000.*mark_spikes_nan, 'Color',[0, 1, 0, 0.5],'LineStyle','--','LineWidth',2,'DisplayName','x-spike filler');

        plot(times_ms,y_gap*1000, 'Color',[0, 0, 1, 0.5],'LineWidth',1,'DisplayName','raw y-signal');
        plot(times_ms,y_pos*1000.*mark_spikes_nan, 'Color',[1, 0, 0, 0.5],'LineWidth',1,'DisplayName','y-spikes');
        plot(times_ms,y_filled*1000.*mark_spikes_nan, 'Color',[0, 1, 0, 0.5],'LineWidth',2,'DisplayName','y-spike filler');
        hold off
        % xlim([xmin,xmax]);
        xlabel("Time (ms)")
        ylabel("X-Position (\mum)")
        legend();
    end
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