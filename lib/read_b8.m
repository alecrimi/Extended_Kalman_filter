% Orcun Goksel (c) Aug 2012
function tmp =  read_b8(filename)

% % filename = 'D:\SonixTablet\15-12-14 orc test.b8';
[~, hdr] = uread(filename,-1);

img = zeros(hdr.h,hdr.w,hdr.nframes);
file = fopen(filename,'rb');
fseek(file,hdr.file.headerSizeBytes,-1);
img = fread(file,numel(img),'*uint8');
fclose(file);

img = reshape(img, [hdr.w hdr.h hdr.nframes]);
%img = imrotate(img, -90);
% Remove margins (I don't know where 1s&2s come from, are they constants?)
img = img(hdr.ul(2)+1:hdr.br(2)-1,hdr.ul(1)+2:hdr.br(1)-2,:);

tmp(:,:,1,:) = img;
%implay(tmp,40);  % FPS should be hdr.dr, but 84 fps is too high to show in Matlab
