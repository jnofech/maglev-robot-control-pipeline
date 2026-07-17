%% Xiaodong magnet

h = 0.010;
d = 0.010;
% m_g = 10.86;

z_above_platform = 0.000;
z_xiaodong_frame = 0.079; % center

%% Custom magnet 1
clc
h_xiaodong = 0.010;
d_xiaodong = 0.010;
% m_g_xiaodong = 10.86;
Br_xiaodong = 1.29;

h = 0.010;
d = 0.010;
% m_g = 10.86;
Br = 1.45;
z_above_platform = 0.002;

z_xiaodong_frame = (0.079 - (z_above_platform + h/2 - h_xiaodong/2)) % CEN of magnet

%% Custom magnet 2 (mine)
clc
h_xiaodong = 0.010;
d_xiaodong = 0.010;
% m_g_xiaodong = 10.86;

h = 0.00635;
d = 0.00635;
% m_g = 1.5876;
Br = 1.45;
z_above_platform = 0.003825;

z_xiaodong_frame = (0.079 - (z_above_platform + h/2 - h_xiaodong/2)) % CEN of magnet

%% Feedforward component


r = d/2;
m_kg = m_g / 1000;
g = -9.81;

a_zc = 2.8141;
b_zc = -0.3556;

% dipolemoment_scaling = (pi*(d_xiaodong/2)^2*h_xiaodong)*Br_xiaodong ...
%                       / ((pi*(d/2)^2*h)*Br)
dipolemoment_scaling = (pi*(d_xiaodong/2)^2*h_xiaodong)*Br_xiaodong ...
                      / ((pi*(d/2)^2*h)*Br)

I_ff = m_kg * g / (a_zc * z_xiaodong_frame + b_zc) * dipolemoment_scaling