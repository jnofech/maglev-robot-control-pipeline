function [rgb_scaled] = rgb(r,g,b)
% Scales an RGB colour from 0-255 to 0-1.
% Designed for easy copy-pasting from website:
%       https://redketchup.io/color-picker

    rgb_scaled = [r,g,b]/255;
end