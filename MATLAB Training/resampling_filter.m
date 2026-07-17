function [sigReResamp] = resampling_filter(times_s,signal,fn)
% Given a signal with sampling frequency `fs` (in Hz) and noise of
% precisely-known frequency `fn` (in Hz), eliminates that noise with a
% moving average filter.
% Because the filter width (in samples) must be an odd integer, resampling
% is necessary. The signal will be "re-resampled" back to its original
% sampling frequency afterwards.
%
% Params:
% -------
%   times_s : double(array)
%       Time axis of the signal, in seconds
%   signal : double (array)
%       The "y-axis" of the input signal, assuming constant sample
%       frequency.
%   fn : double
%       Precisely-known noise frequency, in Hz. (Integers would be ideal.)
    
    % Calculate sampling frequency
    timesteps = times_s - circshift(times_s,1);
    fs_raw = 1/mean(timesteps(2:end-2));  % Calculated sampling frequency (e.g. 999.96 Hz)
    fs = round(fs_raw); % Rounded sampling frequency (e.g. 1000 Hz)
    
    % Calculate ideal filter width, in samples, and the nearest usable
    % equivalent
    filterwidth_ideal = fs/fn;
    filterwidth_rounded = round(filterwidth_ideal) + 1*(mod(round(filterwidth_ideal),2)==0);  % Smallest odd integer above ideal filterwidth

    % Resample
    fsResamp = fn*filterwidth_rounded;    % Resampling frequency (Hz); divisible by noise frequency and odd-integer filterwidth
    sigResamp = resample(signal, fsResamp, fs);
    tResamp = (0:numel(sigResamp)-1)/fsResamp;
    sigResamp_mean = sgolayfilt(sigResamp,1,filterwidth_rounded);
    sigReResamp = makima(tResamp,sigResamp_mean, times_s);
end