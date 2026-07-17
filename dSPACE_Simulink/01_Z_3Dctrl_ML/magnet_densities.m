%% Actual neodymium magnet density
diameter_m = convlength(3/8, 'in','m');
height_m = convlength(3/8, 'in','m');
mass_g = 5.09;

% DENSITY: 7499.5 KG/M3


%% Xiaodong magnet density
diameter_m = 0.01;
height_m = 0.01;
mass_g = 10.86;

% DENSITY: 13827 KG/M3 (IMPOSSIBLE-- IT'S TWICE AS DENSE AS THE ACTUAL
% METAL???


%% My magnet
diameter_m = convlength(1/4, 'in','m');
height_m = convlength(1/4, 'in','m');
% mass_g = 1.5876;
mass_g = 1.5081;    % 0.0532oz, according to K&J 

% ~DENSITY: 7894.6 KG/M3~ (W R O N G)
% DENSITY: 7499.3 KG/M3

%%
radius_m = diameter_m/2;
volume = pi * radius_m^2 * height_m;
density_kgm3 = (mass_g / 1000) / volume
