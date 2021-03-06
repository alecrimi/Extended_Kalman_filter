function test_star_kalman(root_filename)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Star-Kalman Matlab implementation as described in the paper:
%   Crimi, Alessandro, et al. "Vessel tracking for ultrasound-based venous pressure measurement." 
%   2014 IEEE 11th International Symposium on Biomedical Imaging (ISBI). IEEE, 2014.
% 
%   This is the test script which prepare the data and call the main algorithm function which is the script star_kalman.m
%
%   A.Crimi ETH 08/12/2012
%   version 0.1
%
%   Input:
%   - root_filename: filename to run the experiments, two files are expected:
%   A VPR file comprising the pressure values streming.
%   An SXI file with the ultrasound streaming or the manual annotation  
%
%   Output:
%   There is no direct output of this function, but the results of the tracking, segmentation and detected peripheral venous pressure are saved on a mat file
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INITIALIZATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%clear,
warning off
clc
close all
% Import main algorithm and external libraries
addpath('main_alg');
addpath('lib');

kfinit = 0; %Flag about the init image, 0 = init, 1 = the other frames
   % Load the data vpr for ultrasound and pressure streaming and sxi for the manual segmentation
   [ header, ~, ~] = vpReader( [root_filename '.vpr'], [root_filename  '.sxi'], 1 );
   % count the number of frames of the streaming and decompose the streaming into ultrasound video and pressure
   n_frames =  double(header.nFrames );  
   interval = [1 n_frames];  
   interval = [50 750]; %We have to skip some meaningless frames in the  given example, remove this line in other realworld applications.
   [ header, images, pressures ] = vpReader( [root_filename '.vpr'], [root_filename '.sxi'], interval );

% Configure initial variables
x = zeros(1,6); % initial empty state
dummyvar = 40; % Show this latest values
preassure_graph = zeros(dummyvar,1); %Plot the pressure value of the latest 40 frames  P = 100*eye(6);
shift_calibration = 0;  % Possible delay between video straming and pressure streaming 
[row,col,n_frames] = size(images);
seg_res = zeros(col,row,n_frames -1);
%Structure containing data for the PVP  prediction
pressure_stc.PVP_last = 0;
pressure_stc.PVP_seq = 0;
pressure_stc.shapeinfo_seq = 0;
pressure_stc.collapse_flag = 1;
pressure_stc.pressure_decreasing = 0;
pressure_stc.b_axis_init = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
% Loop over all images, but not the last frame and in case of delay skip also the last window frame
for ii =   1 : n_frames -1 - shift_calibration
 
    % Load single image from the streaming, it has to be transposed
    Im = images(:,:,ii)'; 

    % Take into account possible delay between ultrasound and pressure reads within the window
    jj = max(1,ii-dummyvar);
    pressure_data = pressures(jj+shift_calibration:ii+shift_calibration);
    PVP = pressure_data(end);
  
    % Run the star-kalman filter
    [x preassure_graph mask pressure_stc] = star_kalman(Im, kfinit, x, preassure_graph, pressure_data, PVP, pressure_stc );

    kfinit = 1; % This change the flag telling the initialization is over
    seg_res(:,:,ii) = mask;
    
        if( pressure_stc.PPVP )
            disp(['The detected PVP is '  num2str(pressure_stc.PPVP) ])
            plot(x(2), x(1),'*b','Markersize',5);
        end
    
    total_PVP(ii) = pressure_stc.PPVP;   
    total_flag(ii) = pressure_stc.pressure_decreasing;
end

save([root_filename  ],'seg_res', 'pressures','total_PVP','pressure_stc','total_flag' );
%save([root_filename '_auto_nocon'],'seg_res', 'pressures' );
%save(['../' root_filename '_autobad'],'seg_res','area','pressures'); %, 'confidence'
