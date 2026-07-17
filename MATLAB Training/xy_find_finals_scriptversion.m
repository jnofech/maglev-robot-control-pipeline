clc

% Sample data: position (y) vs time (t)
% t = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]'*100000 + 111100 % Time data
% y = -[1, 2, 3, 4, 4.5, 4.8, 5, 5.2, 5.3, 5.35, 5.4]'*10000 - 32710 % Position data
t = times_ms(indices);
y = x_fil(indices);
% t = t';
% y = y';

% Configurable parameters
barelychanges_threshold_micron = 200;    % Threshold for indicating relatively stationary magnet
score_diff_threshold = 0.1;             % Threshold for clear differences in adjusted R-Squared score (additive)
score_quot_threshold = 4;               % Threshold for clear differences in adjusted R-Squared score (multiplicative)
straightline_threshold = 0.3;           % Threshold for (max speed - min speed) for norm. curves, below which the segment is considered straight

% Any immediate time-saving checks to make?
if (abs(max(y) - min(y)) < barelychanges_threshold_micron / 1000) && t(end)<200
    disp("FINAL SELECTION REPORT: Segment too short (space AND time-wise); aborting")
    final_selection = y(end);
    return
end

    % Preprocessing: Normalization
    %   (For consistency, the functions should try to be monotonically
    %   increasing!)
    % t_norm = (t - t(1)) / (max(t) - min(t)) * 10
    % y_norm = (y - y(1)) / (max(y) - min(y)) * 10
    t_initial = t(1);
    t_scale = (max(t) - min(t)) * 1;
    y_initial = y(1);
    y_scale = (max(y) - min(y)) * 1 * sign(y(end)-y(1));    % incl. sign change
    t = (t - t_initial) / t_scale;
    y = (y - y_initial) / y_scale;
    
    % % Subsample the data (e.g., every 2nd point)
    % subsample_factor = 15;
    % t = t(1:subsample_factor:end);
    % y = y(1:subsample_factor:end);
    
    % Subsample the data (adaptably)
    n_points       = 50;    % BASE number of points in segment
    
    % ~~~~~~ LOOP ~~~~~~~~
    tic
    for n_points_extra = 0:10     % Additional, if needed due to GOF errors (!!!!INCREMENT AUTOMATICALLY IF NEEDED!!!!)
        % SUBSAMPLE DATA
        subsample_factor = max(floor(length(t)/(n_points+n_points_extra)), 1);  % Will not subsample if there are too few points!
        t_sub = flipud(t(end:-subsample_factor:1));
        y_sub = flipud(y(end:-subsample_factor:1));
        
        % WEIGHTS
        % Create a weight vector that gives more weight to the latter half of
        % the signal, and less weight for the first ~20% of the signal.
        % (Disabled if many GOF errors appear)
        weights = ones(size(t_sub));
        if n_points_extra < 4
            weights(round(length(weights)*0.50):end) = 3;
            % weights(1:round(length(weights)*0.20)) = 0.5;
        end
        
        % % Create a weight vector that gives more weight to the very end of the signal
        % weights = ones(size(t));
        % weights(round(length(weights)*60/100):end) = 500; % Increase weight for the latter half
        
        % % Create a weight vector that increases monotonically
        % weights = (1:length(t))' .^10 ;
        % weights = weights + mean(weights)*0.;  % Higher multiplier = more balanced weight
        
        % INITIAL GUESSES
        % Initial guesses for the parameters
        initial_guess_exp =              [max(y_sub)-min(y_sub), 1, min(y_sub)];
        initial_guess_sine = [max(y_sub)-min(y_sub), 1, 1, 0, min(y_sub)];
    
    
        % FINALIZE FIT PARAMS
        % Define fit options with initial guesses and robust fitting
        exp_fit_options = fitoptions('Method', 'NonlinearLeastSquares', ...
                                     'StartPoint', initial_guess_exp, ...
                                     'Robust', 'LAR', ...
                                     'Lower',[-Inf,   0,  -Inf], ...
                                     'Upper',[   0, Inf,  Inf], ...
                                     'TolFun',1e-6, ...
                                     'TolX',1e-6, ...
                                     'Weights', weights, ...
                                     'Display','off');
        sine_fit_options = fitoptions('Method', 'NonlinearLeastSquares', ...
                                                  'StartPoint', initial_guess_sine, ...
                                                  'Robust', 'LAR',...
                                                  'Lower',[-Inf,   0,   0,    0, -Inf], ...
                                                  'Upper',[   0, Inf, Inf, 2*pi, Inf], ...
                                                  'TolFun',1e-6, ...
                                                  'TolX',1e-6, ...
                                                  'Weights', weights, ...
                                                  'Display','off');
    
        % PERFORM (EXPO+SINE) FITS
        % Exponential approach model: y = A * exp(-B * t) + C
        exp_model = fittype('A * exp(-B * x) + C', 'independent', 'x', 'dependent', 'y', ...
                            'options', exp_fit_options);
        [exp_fit, exp_gof] = fit(t_sub, y_sub, exp_model);
        % Decaying sinusoidal wave model: y = A * exp(-B * t) * cos(C * t + D) + E
        sine_model = fittype('A * exp(-B * x) * cos(C * x + D) + E', ...
                                         'independent', 'x', 'dependent', 'y', ...
                                         'options', sine_fit_options);
        [sine_fit, sine_gof] = fit(t_sub, y_sub, sine_model);
    
        % CHECK IF FITS WERE SUCCESSFUL
        if abs(exp_gof.adjrsquare)+abs(sine_gof.adjrsquare) > 1e10   % If adjusted RSquare indicates an error:
            % retry the loop with incremented number of points
            disp("Error detected; retrying.")
            failed_to_generate_GOF = true;
            continue
        else
            % No error; continue the function!
            failed_to_generate_GOF = false;
        end
    
        
        if n_points_extra~=0 && failed_to_generate_GOF==false
            disp("Successfully completed fits after "+string(n_points_extra)+" attempts")
        elseif failed_to_generate_GOF==true
            disp("Failed to resolve erroneous GOF statistics within "+string(n_points_extra)+" attempts")
        end
    
        break    
    end
    toc
    % Display goodness-of-fit statistics
        % Final fit parameters
        % exp_fit
        % sine_fit
    
        % % Display confidence intervals
        % ci_exp = confint(exp_fit)
    
        % GOF stats (full)
        disp('Exponential Fit Goodness of Fit:');
        disp(exp_gof);
        disp('Decaying Sinusoidal Fit Goodness of Fit:');
        disp(sine_gof);
    
        % % GOF stats (Adjusted RSquare only)
        % disp('Exponential Fit AdjRSquare (weighted):         '+string(exp_gof.adjrsquare));
        % disp('Decaying Sinusoidal Fit AdjRSquare (weighted): '+string(sine_gof.adjrsquare));
    
        % % GOF stats (RMSE only)
        % disp('Exponential Fit RMSE (weighted):         '+string(exp_gof.rmse));
        % disp('Decaying Sinusoidal Fit RMSE (weighted): '+string(sine_gof.rmse));
    
    % Check for obvious oscillations
    % "Oscillation detection" condition:
    sine_always_increasing = all(diff(sine_fit(t)) > 0);                    % If sine fit monotonically increases (where false => obvious curvature)
    
    if (~sine_always_increasing && sine_gof.adjrsquare > 0.8)
        disp("OBVIOUS OSCILLATION DETECTED")
        strong_oscillation = true;
        endpoint_direction = sign(sine_fit(t(end)) - sine_fit(t(end-1)));   % travel direction for "normalized" data
    else
        strong_oscillation = false;
        endpoint_direction = 1;
    end
    
    
        
    
    % CALCULATE POSSIBLE FINAL RESTING POSITIONS FROM FITTED MODELS
    % Final resting positions according to the fits
    final_resting_position_exp = exp_fit.C;
    final_resting_position_sine = sine_fit.E;
        % ^ useful if "obvious oscillation" happens
        % ^ useful if "obvious oscillation" happens but the recording ends too early to detect it here
        %                                           ^ ~ALSO COULD BE AUTOMATICALLY SELECTED IF THE FILE IS KNOWN TO BE PRONE TO OBVIOUS OSCILLATIONS~ 
        %                                             actually no, it might only act like this in certain regions of the workspace (e.g. tiny platform > workspace size)
        %                                           ^ (DISREGARD FOR NOW; that's for another dataset that i dont have time to generate!)
    % Final point in input signal
    final_resting_position_finalpoint = y(end);
        % ^ useful for extremely short/slow segments
        % ^ useful if v≈0 for a relatively long period of time (in ms, NOT relative to segment length) at the end
    % First instance of v=0 after the signal ends (for sine fit only); assuming
    % the sine fit is of y = A * exp(-B * t) * cos(C * t + D) + E form
    % (i.e. velocity's zeroes are (atan(-B/C)-D+n*pi)/C) for n∈integers)
    n=0:1:100; t_zero_velocity = (atan(-sine_fit.B/sine_fit.C) - sine_fit.D + n*pi)/sine_fit.C;
    t_first_zero_velocity = min(t_zero_velocity(t_zero_velocity > t(end)));
    final_resting_position_sine_firststop = sine_fit(t_first_zero_velocity);
    dt = mean(diff(t));
    t_extrap = [t;(t(end)+dt:dt:min(2,t_first_zero_velocity))'];   % For visualizing the extrapolated curve! (Capped at 2x the segment's duration)
        % ^ useful if expo and sine fits both look good, but there isn't any
        % obvious oscillation happening
        % ^ Note that if this point is WAY BEYOND the end of the curve, that's
        % a sign that the sine fit is unlikely to be much better than expo fit!

    % % Plot the original data and the fitted curves BEFORE undoing norm.
    % close; figure;
    % plot(t, y, 'bo'); hold on;
    % plot(t_extrap, exp_fit(t_extrap), 'r-', 'DisplayName','Expo fit'); 
    % plot(t_extrap, sine_fit(t_extrap), 'g-', 'DisplayName','Decaying sinusoidal fit'); 
    % % yline(final_resting_position_exp, 'r--', 'DisplayName','Expo fit inf. limit'); 
    % yline(final_resting_position_sine, 'g--', 'DisplayName','Sine fit inf. limit'); 
    % yline(final_resting_position_sine_firststop, 'g:', 'DisplayName','Sine fit first v=0'); 
    % legend_position = "best"; legend("Location",legend_position);
    % xlabel('Time');
    % ylabel('Position');
    % title('Position vs Time with Fitted Curves');
    
    % "Undo" normalization!
    t_norm = t;
    t = t * t_scale + t_initial; t_extrap_ms = t_extrap * t_scale + t_initial;
    y = y * y_scale + y_initial;
    final_resting_position_exp = final_resting_position_exp * y_scale + y_initial;
    final_resting_position_sine = final_resting_position_sine * y_scale + y_initial;
    final_resting_position_finalpoint = final_resting_position_finalpoint * y_scale + y_initial;
    final_resting_position_sine_firststop = final_resting_position_sine_firststop * y_scale + y_initial;
    endpoint_direction = endpoint_direction * sign(y_scale);    % Positive = increasing y-value, negative = decreasing y-value
    
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    % ~~~ SELECT POSSIBLE FINAL RESTING CONDITIONS FROM THOSE CALCULATED ~~~
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    % Disregard straight lines:
    relative_accel_expo = max(gradient(exp_fit(t_norm),t_norm)) - min(gradient(exp_fit(t_norm),t_norm));    % Max - min speed, for normalized curve. Lower => straighter.
    relative_accel_sine = max(gradient(sine_fit(t_norm),t_norm)) - min(gradient(sine_fit(t_norm),t_norm));  % Max - min speed, for normalized curve. Lower => straighter.
    % Check curvature at the end of sine fit:
    accel_sine = gradient(gradient((sine_fit(t_norm) * y_scale + y_initial),t_norm),t_norm);    % Accel curve. Ends where input data ends
    if relative_accel_expo < straightline_threshold && relative_accel_sine < straightline_threshold
        disp("FINAL SELECTION PRE-REPORT: Looks like a straight line")
        exp_gof.adjrsquare = 0;
        sine_gof.adjrsquare = 0;
    elseif relative_accel_expo < straightline_threshold
        disp("FINAL SELECTION PRE-REPORT: Expo fit is a straight line")
        exp_gof.adjrsquare = 0;

        % "Strict" mode
        disp("WARNING                   : Expo fit being a straight line probably means the sine fit doesn't show decelerating!")
        sine_gof.adjrsquare = 0;
        % % "Generous" mode (may lead to unreliable data)
        % if sign(accel_sine(end)) ~= -endpoint_direction
        %     disp("                  ADDENDUM: Sine fit is accelerating the wrong way")
        %     sine_gof.adjrsquare = 0;
        % end
    elseif relative_accel_sine < straightline_threshold
        disp("FINAL SELECTION PRE-REPORT: Sine fit is a straight line")
        sine_gof.adjrsquare = 0;
    end
    % Conditionals:
    compare_score_diff = (sine_gof.adjrsquare - exp_gof.adjrsquare);            % Positive => sine fit is better; negative => exp fit is better
    compare_score_quot = (1 - min(exp_gof.adjrsquare,sine_gof.adjrsquare)) / ...
                         (1 - max(exp_gof.adjrsquare,sine_gof.adjrsquare));     % Higher => more drastic difference in quality between fits
    
    % Final resting position chosen by checking the following, in sequence:
    %   1. If position barely changes (max(y)-min(y) < 20micron), just take
    %   final position as endpoint
    if abs(max(y) - min(y)) < barelychanges_threshold_micron / 1000
        disp("FINAL SELECTION REPORT: Signal barely changes")
        final_selection = final_resting_position_finalpoint;
    %   1.5. If speed barely changes, it's basically a straight line. Either
    %   return endpoint as the final resting spot, or disregard the whole
    %   segment. (If the CCR responsible gives very smooth motion, then it's
    %   better to disregard the segment and let later ones be a clearer
    %   indicator of such motion!)
    % elseif relative_accel_expo < 0.3 && relative_accel_sine < 0.3
    %     disp("FINAL SELECTION REPORT: Looks like a straight line")
    %     final_selection = nan;
    % %   1.6. If either fit has relative accel. that's too small, disregard
    % %   it and see what we can make of the leftovers
    % elseif relative_accel_expo < 0.3 || relative_accel_sine < 0.3
    %     if relative_accel_expo < 0.3
    %         disp("FINAL SELECTION REPORT: Only sine fit doesn't look like a straight line!")
    %         % Sine fit wins! If sine fit looks okay, pick from its results
    %         % if sine_fit.
    %         final_selection_options = [final_resting_position_sine, final_resting_position_sine_firststop];
    %         final_selection = choose_from(final_selection_options, y(end), endpoint_direction);
    %     elseif relative_accel_sine < 0.3
    %         disp("FINAL SELECTION REPORT: Only expo fit doesn't look like a straight line!")
    %         % Expo fit wins! Pick from expo fit results
    %         final_selection = final_resting_position_exp;
    %     end

    %   2. If obvious oscillation was detected, disregard expo fit and choose
    %   from sine-fit's options
    elseif strong_oscillation==true
        disp("FINAL SELECTION REPORT: Obvious oscillation detected")
        final_selection_options = [final_resting_position_sine, final_resting_position_sine_firststop];
        final_selection = choose_from(final_selection_options, y(end), endpoint_direction);
    %   3. If velocity of last ~100ms is close to 0, just take final position
    %   as endpoint
    elseif max(t) > 110 && 1000*(max(y(max(1,end-100):end))-min(y(max(1,end-100):end))) < barelychanges_threshold_micron/2
        disp("FINAL SELECTION REPORT: Velocity near end is close to 0")
        final_selection = final_resting_position_finalpoint;
    %   4. If at least one fit failed to generate GOF stats: disregard GOF
    %   statistics; pick nearest option past the end of the signal
    elseif failed_to_generate_GOF
        disp("FINAL SELECTION REPORT: At least one GOF failed to generate")
        final_selection_options = [final_resting_position_exp, final_resting_position_sine, final_resting_position_sine_firststop];
        final_selection = choose_from(final_selection_options, y(end), endpoint_direction);
    
        
    %   5. If one fit is significantly better than the other: disregard the
    %   other; pick from remaining options
    elseif abs(compare_score_diff) > score_diff_threshold || (compare_score_quot > score_quot_threshold)
        if compare_score_diff > 0
            disp("FINAL SELECTION REPORT: Sine fit is significantly better!")
            % Sine fit wins! Pick from sine fit results
            final_selection_options = [final_resting_position_sine, final_resting_position_sine_firststop];
            final_selection = choose_from(final_selection_options, y(end), endpoint_direction);
        else
            disp("FINAL SELECTION REPORT: Expo fit is significantly better!")
            % Expo fit wins! Pick from expo fit results
            final_selection = final_resting_position_exp;
        end
    
    %   6. If expo fit and sine fit are BOTH HELLA GOOD: oscillation is out of
    %   the question, so disregard sine fit's inf. limit and select from the
    %   rest
    elseif exp_gof.adjrsquare > 0.99 && sine_gof.adjrsquare > 0.99
        disp("FINAL SELECTION REPORT: Both fits are excellent!")
        final_selection_options = [final_resting_position_exp, final_resting_position_sine_firststop];
        final_selection = choose_from(final_selection_options, y(end), endpoint_direction);
    %   7. If at least one fit is HELLA GOOD: Pick it, and disregard the other
    elseif exp_gof.adjrsquare > 0.99 || sine_gof.adjrsquare > 0.99
        if exp_gof.adjrsquare > 0.99
            disp("FINAL SELECTION REPORT: Expo fit is excellent!")
            final_selection = final_resting_position_expo;
        else
            disp("FINAL SELECTION REPORT: Sine fit is excellent!")
            final_selection_options = [final_resting_position_sine, final_resting_position_sine_firststop];
            final_selection = choose_from(final_selection_options, y(end), endpoint_direction);
        end
        
    %   9. If expo fit and sine fit are both reasonably good: Pick from all
    %   options I guess? Adjust later
    elseif exp_gof.adjrsquare > 0.75 && sine_gof.adjrsquare > 0.75
        disp("FINAL SELECTION REPORT: Both fits are... reasonably good i guess?")
        final_selection_options = [final_resting_position_exp, final_resting_position_sine_firststop];
        final_selection = choose_from(final_selection_options, y(end), endpoint_direction);
    %  99. else, the segment is probably a straight line and thus unusable. Discard! 
    else
        disp("FINAL SELECTION REPORT: Fits failed; disregard this segment")
        final_selection = nan;
    % (MISC)
    %   9. If expo fit and sine fit are both reasonably good: starting with the
    %   better option, check if "([expo's "C" /or/ sine's first v=0 point] - fil(end) < (fil(end) -
    %   fil(1))  *0.5)" [SLIGHT CALIBRATION NEEDED]. If so, great, pick it;
    %   otherwise, make this same check for the latter fit. If BOTH OF THESE
    %   fail, proceed to:
    %       8a) This may indicate that the recording only began to resemble an
    %       expo/sine curve before ending, which is still useful! Pick
    %       whichever [expo's "C" /or/ sine's first v=0 point] is closer (but
    %       still "past") the segment's end.
    %   otherwise do this same check for the other one. If both checks failed, 
    %   expofit's "C" / sinefit's first v=0 point accordingly!
    end

    % Final check: Is the selection reasonably close?
    if abs(final_selection - y(end)) > abs(y(end) - y(1))*2
        disp("FINAL SELECTION REPORT ADDENDUM: Best option is still too far; disregard this segment")
        final_selection = nan;
    end

% If no obvious oscillations: Find first instance of speed=0 for "sine"
% fit, since it may be an option!

% 
% % Display the final resting positions
% disp(['Final resting position (Exponential Model): ', num2str(final_resting_position_exp)]);
% disp(['Final resting position (Decaying Sinusoidal Model): ', num2str(final_resting_position_sine)]);
% 
% 



% Plot the original data and the fitted curves AFTER undoing norm.
close; figure;
plot(t, 1000*(y), 'bo'); hold on;
plot(t_extrap_ms, 1000*(exp_fit(t_extrap) * y_scale + y_initial), 'r-','DisplayName','Expo fit'); 
plot(t_extrap_ms, 1000*(sine_fit(t_extrap) * y_scale + y_initial), 'g-','DisplayName','Decaying sinusoidal fit'); 
% yline(1000*final_resting_position_exp, 'r--', 'DisplayName','Expo fit inf. limit'); 
yline(1000*final_resting_position_sine, 'g--', 'DisplayName','Sine fit inf. limit'); 
yline(1000*final_resting_position_sine_firststop, 'g:', 'DisplayName','Sine fit first v=0'); 
legend_position = "best"; legend("Location",legend_position);
xlabel('Time');
ylabel('Position');
title('Position vs Time with Fitted Curves');

function choice = choose_from(choices_array,y_end,endpoint_direction)
    if endpoint_direction==1
        choices_array = choices_array(choices_array > y_end);    % Remove options that aren't "past" the end
        choice = min(choices_array);                             % Choose the nearer remaining option
    else
        choices_array = choices_array(choices_array < y_end);    % Remove options that aren't "past" the end
        choice = max(choices_array);                             % Choose the nearer remaining option
    end
    if isempty(choice)
        choice = nan;
    end
end