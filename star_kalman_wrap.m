function  star_kalman_wrap(folder)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Wrap script to iterate the test_star_kalman over an entire dataset
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


folder = num2str(folder); % Assure that the name is a string

parfor kk = 1 : 4 

    list = dir( [ folder '\*.sw' ] );
    temp = list(kk).name;
    
    test_star_kalman( [ folder '\' temp(1:end-3) ] )
end
