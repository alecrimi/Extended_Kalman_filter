function  [x preassure_graph mask new_PVP PVP_seq] = star_kalman(Im, kfinit, x, preassure_graph, pressure_data, PVP, pressure_stc )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Star-Kalman Matlab implementation as described in the paper:
%   Crimi, Alessandro, et al. "Vessel tracking for ultrasound-based venous pressure measurement." 
%   2014 IEEE 11th International Symposium on Biomedical Imaging (ISBI). IEEE, 2014.
%
%   A.Crimi ETH 08/12/2012
%   version 0.1
%
%   Input:
%   - Im: an image where to run the star-kalman tracking filter, according to the previous frame 
%   - kfinit: flag which discriminates the init frame from the others
%   - x....: the state vector of the system, in this version is [c_x,c_y, a_axis, b_axis, 0,0] 
%     This is the main variable representing the ellipse to be tracked
%   - pressure_graph: the vector containing the last 40 values of detection confidence 
%   - pressure_data: Data containing the whole story of the pressure values
%   - PVP: current value of venous compression value
%   - pressure_stc: Structure comprising several variables about the whole story of the venous compression value
%
%   Output:
%   - x: the state vector of the system after an entire cicle of the Kalman filter
%   - pressure_graph: the vector containing the last 40 values of detection confidence (updated)
%   - mask: binary mask with 1s the detected vessel and 0s background
%   - new_PVP: new value of venous compression value
%   - pressure_stc: Updated story of the venous compression value
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Load parameter of the kalman filter
    configuration; % This parameters can also be passed as an object to the function

    if kfinit==0
       if (automatic_detection)
          %[c_y,c_x] = find_vessel_threshold(Im); 
          state = find_vessel(Im);
          c_x = state(1);
          c_y = state(2);
          a_axis = state(3);
          b_axis  = state(4);
          %pause
       else
          disp('Select seed point'); 
          imshow(Im); % hold on
          [c_y,c_x] = ginput(1);
          a_axis = 40; %TODO: In the next version this will be automatic.
          b_axis = 10; %TODO: In the next version this will be automatic.
       end
       disp('Let s go'); 
       xp = [c_x,c_y, a_axis, b_axis, 0,0]';
    else
       % Prediction of the state according to the Kalman filter
       c_y = x(1);
       c_x = x(2);
       a_axis = x(3); 
       b_axis = x(4);
       xp = A*x' + Bu;  
    end %End initialization IF
    % Prediction of the covariance matrix of the Kalman filter
    PP = A*P*A' + Q; 

    % Check whether the predicted vessel is still matching a vessel or the vessel has collapsed
    [flag_ellipse ratio  mask ]= is_ellipse( Im, c_x, c_y, a_axis, b_axis); 
    % if it is not a vessel reduce the windowsearch
    if (flag_ellipse) 
        t_window_search = window_search;   
       % disp('I flagged')
    else
        t_window_search = window_search;
        % disp('no flag');
    end
    
    % Kalman update 
    % Measurement vector z      
    state = [round(c_x), round(c_y), a_axis, b_axis];
    [c_y  c_x a_axis b_axis  ] = update_ellipse(Im ,state,N_radii, step_edge_window, t_window_search, display_res );
    %mask = roipoly(zeros(size(Im)),  final_edge_x, final_edge_y ); %Mask given by points no ellipse
 
    K = PP*H'*pinv(H*PP*H'+R); % Kalman gain including the innovation or residual covariance 
    x = (xp + K*([c_y c_x a_axis b_axis ]' - H*xp))'; %Update the state   %[cc(i),cr(i)]
    P = (eye(6)-K*H)*PP; %Update the covariance
    if(display_res)
        pause(0.01); %Imshow of matlab needs this! DO NOT REMOVE IT! 
        g = subplot(2,2,2);
        p = get(g,'position');
        p(4) = p(4)*0.5;  % scale
        set(g, 'position', p);
        hold on
         % plot(preassure_graph);
         plot(ones(40,1)*1.5,'r');
        hold off
        xlabel('Frames');
        ylabel('v'); 
        title('Uncompressed vein confidence');
        axis([0 40 0 5]);
        
        subplot(2,2,4);
        % plot(pressure_data); 
        xlabel('Frames');
        ylabel('mbar'); 
        title('Pressure')
        axis([0 40 0 25])
    end %End visualization

    % This part is the trivial version of the PVP detection TODO: make it as detection-by-tracking
    if(b_axis < th_collapse)
       % fprintf('Local pressure value at the collapse time is %f \n', pressure_data(end));
       new_PVP = PVP;
    end
    
    if(~exist('new_PVP'))
       new_PVP = 0;
    end

    if( pressure_stc.PVP_seq(end)>0 && new_PVP==0)
       fprintf('The Mean Local pressure value is %f \n',mean(PVP_seq));
       pressure_stc.PVP_seq=0;
    end
    
    if(new_PVP>0)
        if (sum(pressure_stc.PVP_seq)==0)
            pressure_stc.PVP_seq(1) = new_PVP;
        else
            pressure_stc.PVP_seq(end+1) = new_PVP; %TODO: ORRIBLE!!!!! when converted to C++ this has to be cleaner!!!
        end
    end
 
end %End function

 
