function [c_x_new c_y_new a_axis b_axis   ] = update_ellipse(Imwork, state, N_radii, step_edge_window, t_window_search, display_res)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Star algorithm updating the ellipse
%
%   A.Crimi ETH 08/12/2012
%
%   Input:
%   - Imwork: an image where to run the star algorithm
%   - state: the state vector defining the initial ellipse as [c_x,c_y, a_axis, b_axis] 
%   - N_radii: number of radial sections to be used in the star
%   - step_edge_window: windows of displacement near the starting centroid
%   - t_window_search: length in pixels, how far you should look for edges along each ray of the star
%   - display_res: flag indicating whether to plot the results or not
%
%   Output:
%   - x: the state vector of the system after an entire cicle of the Kalman filter
%   - pressure_graph: the vector containing the last 40 values of detection confidence (updated)
%   - mask: binary mask with 1s the detected vessel and 0s background
%   - new_PVP: new value of venous compression value
%   - PVP_seq: updated story of the venous compression value
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Decompose the state
c_x = state(1);
c_y = state(2);
a_axis = state(3);
b_axis = state(4);
 
%Star algorithm settings
filter_size = 3; %Size of the filter for smoothing, In the Guerrero thesis this value is 5
n_best_values =  5; % N of best radius to be kept for each angle , In the Guerrero thesis this value is either 3 or 5
max_values = zeros(N_radii, n_best_values);
max_indices = zeros(N_radii, n_best_values);
%final_edge_x = zeros(N_radii,1); %Vector containing the final edge.
%final_edge_y = zeros(N_radii,1); %Vector containing the final edge.
radii_index = 1; % Dum variable to go through the edge vectors

%Smooth image
%imSmoothed = medfilt2(  Imwork , [filter_size filter_size]);
%non_polar = uint8(zeros( max_length_radii, N_radii ));
%imSmoothed =  rgb2gray(Imwork); 
%imSmoothed = imadjust(imSmoothed);
imcorr =  imadjust(Imwork); %
H = fspecial('disk',filter_size);
imSmoothed  = imfilter(imcorr,H,'replicate'); % imfilter(rgb2gray(Imwork),H,'replicate'); %rgb2gray(Imwork);%
 %  imcorr; %

%Verify if starting area is an ellipse
if(display_res)
   subplot(2,2,[1 3]);
   imshow(imSmoothed); 
   hold on
end
   
% For N radii compute step-edge detection 
for  ang = 0: 2*pi / N_radii : 2*pi - ( 2*pi / N_radii); %Do not compute twice the same angle
    
    r_pior = round ( (a_axis * b_axis ) / sqrt(  a_axis^2 * sin(ang)^2 + b_axis^2 * cos(ang)^2  ) );
    min_length_radii = r_pior - t_window_search;
    max_length_radii = r_pior + t_window_search; 
    temp_func = zeros( max_length_radii - min_length_radii ,1);
      
     for r = min_length_radii : max_length_radii
             % Use the equation from Friedland and Adam IEEE TMI 1989
             % F(r) = 1/3 ( x(r+2) + x(r+1) + x(r) - x(r-1) - x(r-2) - x(r-3) ) 
             % and remember the polar coordinates :
             % xp = r*cos(ang);
             % yp = r*sin(ang);
             % and the displacement given by the starting centroid
             if( round( (r:r+step_edge_window)*sin(ang) + c_x) > 0 )
                idx = sub2ind(size(imSmoothed),  [round( (r:r+step_edge_window)*sin(ang) + c_x)], [round((r:r+step_edge_window)*cos(ang) + c_y)]);
                idx2 = sub2ind(size(imSmoothed), [round( (r-step_edge_window-1:r-1)*sin(ang) + c_x)], [round((r-step_edge_window-1:r-1)*cos(ang) + c_y)]);
                
                temp_func(real(r - min_length_radii + 1)) = (sum(imSmoothed(real(idx))) - sum(imSmoothed(real(idx2)))) / step_edge_window ;  
             %Check if it is not going outside the top border
             else
                temp_func(r - min_length_radii + 1) = 0;
             end 
     end
     %Keep max N highest edges function
     [values indices] = sort(temp_func, 'descend');
     max_values(radii_index,:) = values(1:n_best_values);
     max_indices(radii_index,:) = indices(1:n_best_values);
     % Compute best probability fit for the radius
     overall_mean =  (mean(max_indices(radii_index,:)));  
     overall_std =  (std(max_indices(radii_index,:)));
     probabilities = max_values(radii_index,:)/(overall_std * sqrt(2*pi) ) .* exp( - 0.5 * (( max_indices(radii_index,:) - overall_mean ) / overall_std).^2);
     [max_probs best_radii_index] =  max(probabilities) ;
     final_edge_x(radii_index) = ( max_indices(radii_index,best_radii_index) + min_length_radii - 1)*cos(ang) + c_y;
     final_edge_y(radii_index) = ( max_indices(radii_index,best_radii_index) + min_length_radii - 1)*sin(ang) + c_x;  
      
     if(display_res)
        plot(final_edge_x(radii_index),final_edge_y(radii_index),'*g','Markersize',10);
     end
     radii_index = radii_index + 1;
end

[a_axis, b_axis, c_x_new, c_y_new, phi] = ellipse_fit(final_edge_x,final_edge_y);

if(display_res)
    %[A,c_x_new,c_y_new] = polycenter(final_edge_x,final_edge_y);
    plot(c_x_new, c_y_new ,'*b','Markersize',5);
    % For N radii compute step-edge detection 
    radii_index = 1;
    for  ang = 0: 2*pi / N_radii : 2*pi - ( 2*pi / N_radii); %Do not compute twice the same angle
               plot( a_axis * cos(ang) + c_x_new , b_axis * sin(ang) + c_y_new, '*r','Markersize',5  );
               radii_index = radii_index + 1;
    end
    hold off
end

end %end Function





 
