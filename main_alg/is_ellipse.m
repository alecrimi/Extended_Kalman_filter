function [ flag_ellipse ratio ellipse_mask ] = is_ellipse( im , c_x, c_y, a_axis, b_axis)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Script to verify if the starting area is an ellipse, or the vessel has collapsed
%
%   A.Crimi ETH 08/12/2012
%
%   Input:
%   - im: an image where to check the ellipse presence
%   - cx: centroid of the ellipse, x-coordinate
%   - cy: centroid of the ellipse, y-coordinate
%   - a_axis: horizontal axis of the ellipse 
%   - b_axis: vertical axis of the ellipse 
%
%   Output:
%   - flag_ellipse: Flag stating the absence or collapse of the vessel, '1' means there is no visible ellipse
%   - ratio: ration between the intensity values inside and around the tracked vessel, it can also be used as a confidence value.
%   - ellipse_mask: the new position where we looked for the vessel as a mask
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[X, Y] = meshgrid(1:size(im ,2), 1:size(im ,1));
ellipse_mask = ((b_axis )^2 * (X - c_y) .^ 2 + (a_axis )^2 * (Y - c_x) .^ 2 <= ((a_axis)^2 * (b_axis)^2) );

%Apply the mask to the image
%A_cropped = bsxfun(@times, imSmoothed, uint8(ellipse_mask));
vector_im = im(:);
% compute the mean intensity value within the mask
mean_i_mask = mean(double(vector_im(find(ellipse_mask(:)>0))));

%Create the mask in the image 
ellipse_mask_t = (2*(b_axis^2) * (X - c_y) .^ 2 +2*(a_axis^2) * (Y - c_x) .^ 2 <= (2*(a_axis^2) * 2*(b_axis^2)) );
ellipse_mask_large =  ellipse_mask_t - ellipse_mask;

% compute the mean intensity value around the mask
mean_o_mask =  mean(double(vector_im(find(ellipse_mask_large(:)>0)))); 

% Compute intensity ration between the inside and around the mask
ratio = (mean_o_mask)/(mean_i_mask+1);
flag_ellipse = ratio<2; 
