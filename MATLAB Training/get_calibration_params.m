function get_calibration_params(fname)
% Assuming that a day's worth of training data uses the same set of
% calibration parameters: Reads these parameters from a .csv file for later
% use in data analysis and/or training.
 
 % Open csv
 A = readtable('D:\Maglev_Project\00_WORKSTATION\dSPACE_Simulink\Project_00X\00_PythonScripts\calibration_params\calibrations_2024-04-08.csv');

 % Send params to workspace
 assignin('base','mag_height_m' , A.mag_height_m)
 assignin('base','mag_diameter_m' , A.mag_diameter_m)
 assignin('base','z_rest' , A.z_rest)
 assignin('base','x_cen' , A.x_cen)
 assignin('base','y_cen' , A.y_cen)
 assignin('base','zyokem' , A.zyokem)
 assignin('base','zlaserm' , A.zlaserm)
 assignin('base','dstandm' , A.dstandm)
 assignin('base','dstand0m' , A.dstand0m)

end