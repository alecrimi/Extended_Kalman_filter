function global_script()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Wrap script to iterate the test_star_kalman over an entire dataset
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

matlabpool local 4

pathFolder = pwd;

d = dir(pathFolder);
isub = [d(:).isdir]; % returns logical vector
nameFolds = {d(isub).name}'; %Keep only folders
nameFolds(ismember(nameFolds,{'.','..'})) = []; %remove . and ..

for kk = 1: length(nameFolds)
 
    star_kalman_wrap(nameFolds{kk});
    %dice_wrap(nameFolds{kk});
 
end
matlabpool close force

end %End function

