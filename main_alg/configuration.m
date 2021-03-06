% Configuration parameter

% Kalman filter Settings
H=[[1, 0, 0, 0]',[0,1 0 0]', [0,0, 1, 0]',[0,0 0 1]', [0,0 0 0]',[0,0 0 0]']; % Expected measurement given the predicted state
P = 100*eye(6);
dt=1;
A=[[1,0,0,0 0 0 ]',[0,1,0,0 0 0]',[1,0,0,0 0 0]',[0,1,0,0 0 0]',[dt,0,1,0 0 0]',[0,dt,0,1 0 0]']; % State transiction matrix
g = 5; % pixels^2/time step % Acceleration magnitude
Bu = [0,0,0,0,0,g]'; % Effect of the acceleration on the state times the accelaration
% measurement noise 
R=[[0.2845,0.0045 ,0.0045 ,0.0045]',[0.0045,0.0455 ,0.0045 ,0.0045 ]', [ 0.0045 ,0.0045, 0.2845,0.0045]',[0.0045 ,0.0045 ,0.0045 ,0.0455]']; 
% Process noise
Q=0.01*eye(6);

% Star filter Settings
N_radii  = 50; % Number of radii for the star-kalman
step_edge_window = 10; % Used by the step edge detection function %From ultrasound 10 , framegrabber 5
window_search = 5;  %Window of search from the ellipse perimeter 30
automatic_detection = 0; % 0 for manual selection, 1 for automatic
display_res = 1; %Flag about visualizing results
th_collapse = 8; %9
motion_detection_flag = 1; %Flag telling whether to use the motion detection or not (1 = use motion detection)
slope_window  = 20; %Number of frames used for the slop analysis between pressure and area/radius

close_to_zero_slope_th = 0.15;
too_small_pressure_th = 3;
%degree_th = -0.12;%-0.45 ;  

  
