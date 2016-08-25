%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [frame,header] = uread(filename,frameNumber,varargin) - loads
% data from a Sonix RF ultrasound file using a 0 based frame index number.
%
%DESCRIPTION
% Function loads an image or images from ultrasound RF data saved in
% the Sonix software and returns them after the requested post processing.
% This can also load an ECG file (type 65536) but you may need to invert
% the signal.  This function will load "version 1" files (files created by
% Sonix RP software versions before 5.6.x), and "version 2" files (files
% created by Sonix RP software versions after 5.6.x).  The difference
% between version 1 and version 2 is that in version 2 the frame tags were
% removed (http://research.ultrasonix.com/viewtopic.php?f=2&t=656).  The
% function will automatically determine which version the file is and
% open it.
% 
%EXAMPLES
% 1. To read all the frames in a file: 
%        >>[frame,header] = uread(filename,[]);
% 2. To read frames 0:20 in a file: 
%       >>[frame,header] = uread(filename,[0:20]);
% 3. To read just the header information in a file: 
%       >>[~,header] = uread(filename,-1);
% 4. To read the rf data as complex values:
%       >>[frame,header] = uread(filename,[0:20],'frameFormatComplex',true);
% 5. To read the rf data as complex values with decimation:
%       >>[frame,header] = uread(filename,[0:20],'decimateLaterial',true,'frameFormatComplex',true);
%
%INPUTS
%filename - The fullpath and filename of the data file to open.  It must
%  be a sonix rf file.
%
%frameNumber -  This is the frame number being read.  The valid range is [0,(header.nframes-1)].
%  This value can also be a vector and return a set of  frames with the
%  index corresponding to the frame number being the third dimension of
%  img, the returned image frames.  If this is empty then all of the frames 
%  are loaded.  This could cause your function to crash if you do not have enough
%  continuous free memory available.  If the frameNumber is -1 then only the
%  header information is read, and frame is returned as an empty.
%
%frameFormatComplex  -  A logical pair value which indicates if IQ data should be formed
%  from the raw RF using the hilbert transform.  The IQ data is the analytic
%  signal.  The default is false.
%
%decimateLaterial - A logical pair value which indicates if the software should skip the
%  even rows (laterical columns) to reduce interpolation effects when the
%  number of lines exceeds the number of elements in the transducer.
%  The default is false.
%
%OUTPUT
%frame  - The image data returned into a 3D array (h, w, numframes)
%header - The file header information.  The values for the header are:
% header.filetype - data type (can be determined by file extensions)
% header.nframes - number of frames in file
% header.w - width (number of vectors for raw, image width for processed data)
% header.h - height (number of samples for raw, image height for processed data)
% header.ss - data sample size in bits
% header.ul - region of interest (roi) {upper left x, upper left y}
% header.ur - roi {upper right x, upper right y}
% header.br - roi {bottom right x, bottom right y}
% header.bl - roi {bottom left x, bottom left y}
% header.probe - probe identifier - additional probe information can be found using this id
% header.txf - transmit frequency in Hz
% header.sf - sampling frequency in Hz
% header.dr - data rate (fps or prp in Doppler modes)
% header.ld - line density (can be used to calculate element spacing if pitch and native # elements is known)
% header.extra - extra information (ensemble for color RF)
% header.file - a struct containing details about the file such as the
%   header size and version type.
%AUTHOR
%Paul Otto (potto@gmu.edu).
%The code for the frame read is based on code by Corina Leung, corina.leung@ultrasonix.com.
%
%NOTES:
%The .b8 file might need to be read in as uint8 instead of int8.  This has
%not been tested yet.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [frame,header] = uread(filename,frameNumber,varargin)

p = inputParser;   % Create an instance of the class.
p.addRequired('filename', @ischar);
p.addRequired('frameNumber', @(x) (isnumeric(x) && isvector(x)) || isempty(x));
p.addParamValue('frameFormatComplex',false,@islogical);
p.addParamValue('decimateLaterial',false,@islogical);
p.addParamValue('magOnly',false,@islogical);

p.parse(filename,frameNumber,varargin{:});

frameFormatComplex=p.Results.frameFormatComplex;
decimateLaterial=p.Results.decimateLaterial;
magOnly=p.Results.magOnly;
 
fid=fopen(filename, 'r');
if( fid == -1)
    error(['Cannot open the file ' filename]);
end


header=ultrasonixReadHeader(fid);

if any(frameNumber<0) || any(frameNumber>=header.nframes)
    %make sure it is not the scalar read header case
    if length(frameNumber)==1 && frameNumber==-1
        %okay value
    else
        error(['Invalid frame number.  Must be in the integer set [0,' num2str(header.nframes-1) '] or a scalar of -1 to just read the header']);
    end
end

if isempty(frameNumber)
    frameNumber =(0:(header.nframes-1));
else
    %do nothing
end

if length(frameNumber)==1 && frameNumber==-1
    %only load the header and not any frames
    frame = [];
else
    frameCount=length(frameNumber);
    
    if frameFormatComplex
        frame =complex(zeros(header.h,header.w,frameCount),zeros(header.h,header.w,frameCount));
    else
        frame =zeros(header.h,header.w,frameCount);
    end
    
    
    for ii=1:length(frameNumber)
        
        if frameFormatComplex
            frame(:,:,ii)=hilbert(double(readFrame(fid,header,frameNumber(ii))));
        else
            frame(:,:,ii)=double(readFrame(fid,header,frameNumber(ii)));
        end
        
        if magOnly
            
            frame(:,:,ii)=abs(frame(:,:,ii));
        end
        
    end
    
    if decimateLaterial
        frame=frame(:,1:2:end,:);
    else
        %do nothing
    end
    
end

fclose(fid);

end

%reads a frame from the file, but needs to account for the header which is
%19 words that are 4 bytes long so 76 bytes.
%This assumes the frame number starts at 0
function img= readFrame(fid,header,frameNumber)

fPass=fseek(fid,header.file.headerSizeBytes+header.file.frameSizeBytes*frameNumber,SEEK_SET());

if fPass~=0
    error('fseek failed')
end


switch(header.file.version)
    case '1.0';
        img=readFrameVersion1_0(fid,header);
        
    case '2.0'
        img=readFrameVersion2_0(fid,header);
    otherwise
        error(['Unsupported file version of ' header.file.version])
end


end

%Notes on Version 1.  Has a tag with each frame
function img=readFrameVersion1_0(fid,header)
% load the data and save into individual .mat files

if(header.filetype == 2) %.bpr
    %Each frame has 4 byte header for frame number
    tag = fread(fid,1,'int32'); %#ok<NASGU>
    [v,count] = fread(fid,header.w*header.h,'uchar=>uchar'); %#ok<NASGU>
    img = uint8(reshape(v,header.h,header.w));
    
elseif(header.filetype == 4) %postscan B .b8
    tag = fread(fid,1,'int32'); %#ok<NASGU>
    [v,count] = fread(fid,header.w*header.h,'int8'); %#ok<NASGU>
    temp = int16(reshape(v,header.w,header.h));
    img = imrotate(temp, -90);
    
elseif(header.filetype == 8) %postscan B .b32
    %          tag = fread(fid,1,'int32');
    [v,count] = fread(fid,header.w*header.h,'int32'); %#ok<NASGU>
    temp = reshape(v,header.w,header.h);
    img = imrotate(temp, -90);
    
elseif(header.filetype == 16) %rf
    tag = fread(fid,1,'int32'); %#ok<NASGU>
    [v,count] = fread(fid,header.w*header.h,'int16'); %#ok<NASGU>
    img = int16(reshape(v,header.h,header.w));
    
elseif(header.filetype == 32) %.mpr
    tag = fread(fid,1,'int32'); %#ok<NASGU>
    [v,count] = fread(fid,header.w*header.h,'int16'); %#ok<NASGU>
    img = v;%int16(reshape(v,header.h,header.w));
    
elseif(header.filetype == 64) %.m
    [v,count] = fread(fid,'uint8'); %#ok<NASGU>
    temp = reshape(v,header.w,header.h);
    img = imrotate(temp,-90);
    
elseif(header.filetype == 128) %.drf
    tag = fread(fid,1,'int32'); %#ok<NASGU>
    [v,count] = fread(fid,header.h,'int16'); %#ok<NASGU>
    img = int16(reshape(v,header.w,header.h));
    
elseif(header.filetype == 512) %crf
    tag = fread(fid,1,'int32'); %#ok<NASGU>
    [v,count] = fread(fid,header.extra*header.w*header.h,'int16'); %#ok<NASGU>
    img = reshape(v,header.h,header.w*header.extra);
    %to obtain data per packet size use
    % img(:,:,:,frameCount) = reshape(v,header.h,header.w,header.extra);
    
elseif(header.filetype == 256) %.pw
    [v,count] = fread(fid,'uint8'); %#ok<NASGU>
    temp = reshape(v,header.w,header.h);
    img = imrotate(temp,-90);
    
elseif(header.filetype == 1024) %.col
    [v,count] = fread(fid,header.w*header.h,'int'); %#ok<NASGU>
    temp = reshape(v,header.w,header.h);
    temp2 = imrotate(temp, -90);
    img = mirror(temp2,header.w);
    
elseif(header.filetype == 4096) %color vel
    %Each frame has 4 byte header for frame number
    tag = fread(fid,1,'int32'); %#ok<NASGU>
    [v,count] = fread(fid,header.w*header.h,'uchar=>uchar'); %#ok<NASGU>
    temp = reshape(v,header.w,header.h);
    temp2 = imrotate(temp, -90);
    img = mirror(temp2,header.w);
    
elseif(header.filetype == 8192) %.el
    [v,count] = fread(fid,header.w*header.h,'int32'); %#ok<NASGU>
    temp = reshape(v,header.w,header.h);
    temp2 = imrotate(temp, -90);
    img = mirror(temp2,header.w);
    
elseif(header.filetype == 16384) %.elo
    [v,count] = fread(fid,header.w*header.h,'uchar=>uchar'); %#ok<NASGU>
    temp = int16(reshape(v,header.w,header.h));
    temp2 = imrotate(temp, -90);
    img = mirror(temp2,header.w);
    
elseif(header.filetype == 32768) %.epr
    [v,count] = fread(fid,header.w*header.h,'uchar=>uchar'); %#ok<NASGU>
    img = int16(reshape(v,header.h,header.w));
    
elseif(header.filetype == 65536) %.ecg
    [v,count] = fread(fid,header.w*header.h,'uchar=>uchar'); %#ok<NASGU>
    img = v;
else
    error(['Filetype ' num2str(header.filetype ) ' is not supported']);
end
end


%Notes on Version 2
%http://research.ultrasonix.com/viewtopic.php?f=2&t=656
%The frame tags are removed in all data types including .bpr, .b8..etc in version 5.6.x.
%So if you are using RP 5.6, ensure not to read for the frame tag or else the images read will be "shifted".
function img=readFrameVersion2_0(fid,header)
% load the data and save into individual .mat files

if(header.filetype == 2) %.bpr
    %Each frame has 4 byte header for frame number
    [v,count] = fread(fid,header.w*header.h,'uchar=>uchar'); %#ok<NASGU>
    img = uint8(reshape(v,header.h,header.w));
    
elseif(header.filetype == 4) %postscan B .b8
    
    [v,count] = fread(fid,header.w*header.h,'int8'); %#ok<NASGU>
    temp = int16(reshape(v,header.w,header.h));
    img = imrotate(temp, -90);
    
elseif(header.filetype == 8) %postscan B .b32
    
    [v,count] = fread(fid,header.w*header.h,'int32'); %#ok<NASGU>
    temp = reshape(v,header.w,header.h);
    img = imrotate(temp, -90);
    
elseif(header.filetype == 16) %rf
    
    [v,count] = fread(fid,header.w*header.h,'int16'); %#ok<NASGU>
    img = int16(reshape(v,header.h,header.w));
    
elseif(header.filetype == 32) %.mpr
    
    [v,count] = fread(fid,header.w*header.h,'int16'); %#ok<NASGU>
    img = v;%int16(reshape(v,header.h,header.w));
    
elseif(header.filetype == 64) %.m
    [v,count] = fread(fid,'uint8'); %#ok<NASGU>
    temp = reshape(v,header.w,header.h);
    img = imrotate(temp,-90);
    
elseif(header.filetype == 128) %.drf
    
    [v,count] = fread(fid,header.h,'int16'); %#ok<NASGU>
    img = int16(reshape(v,header.w,header.h));
    
elseif(header.filetype == 512) %crf
    
    [v,count] = fread(fid,header.extra*header.w*header.h,'int16'); %#ok<NASGU>
    img = reshape(v,header.h,header.w*header.extra);
    %to obtain data per packet size use
    % img(:,:,:,frameCount) = reshape(v,header.h,header.w,header.extra);
    
elseif(header.filetype == 256) %.pw
    [v,count] = fread(fid,'uint8'); %#ok<NASGU>
    temp = reshape(v,header.w,header.h);
    img = imrotate(temp,-90);
    
elseif(header.filetype == 1024) %.col
    [v,count] = fread(fid,header.w*header.h,'int'); %#ok<NASGU>
    temp = reshape(v,header.w,header.h);
    temp2 = imrotate(temp, -90);
    img = mirror(temp2,header.w);
    
elseif(header.filetype == 4096) %color vel
    %Each frame has 4 byte header for frame number
    
    [v,count] = fread(fid,header.w*header.h,'uchar=>uchar'); %#ok<NASGU>
    temp = reshape(v,header.w,header.h);
    temp2 = imrotate(temp, -90);
    img = mirror(temp2,header.w);
    
elseif(header.filetype == 8192) %.el
    [v,count] = fread(fid,header.w*header.h,'int32'); %#ok<NASGU>
    temp = reshape(v,header.w,header.h);
    temp2 = imrotate(temp, -90);
    img = mirror(temp2,header.w);
    
elseif(header.filetype == 16384) %.elo
    [v,count] = fread(fid,header.w*header.h,'uchar=>uchar'); %#ok<NASGU>
    temp = int16(reshape(v,header.w,header.h));
    temp2 = imrotate(temp, -90);
    img = mirror(temp2,header.w);
    
elseif(header.filetype == 32768) %.epr
    [v,count] = fread(fid,header.w*header.h,'uchar=>uchar'); %#ok<NASGU>
    img = int16(reshape(v,header.h,header.w));
    
elseif(header.filetype == 65536) %.ecg
    [v,count] = fread(fid,header.w*header.h,'uchar=>uchar'); %#ok<NASGU>
    img = v;
else
    error(['Filetype ' num2str(header.filetype ) ' is not supported']);
end
end


function [header]=ultrasonixReadHeader(fid)

fPass=fseek(fid,0,SEEK_SET());
if fPass~=0
    error('fseek failed')
end

% read the header info
hinfo = fread(fid, 19, 'int32');

% load the header information into a structure and save under a separate file
header = struct('filetype', 0, 'nframes', 0, 'w', 0, 'h', 0, 'ss', 0, 'ul', [0,0], 'ur', [0,0], 'br', [0,0], 'bl', [0,0], 'probe',0, 'txf', 0, 'sf', 0, 'dr', 0, 'ld', 0, 'extra', 0);
header.filetype = hinfo(1);
header.nframes = hinfo(2);
header.w = hinfo(3);
header.h = hinfo(4);
header.ss = hinfo(5);
header.ul = [hinfo(6), hinfo(7)];
header.ur = [hinfo(8), hinfo(9)];
header.br = [hinfo(10), hinfo(11)];
header.bl = [hinfo(12), hinfo(13)];
header.probe = hinfo(14);
header.txf = hinfo(15);
header.sf = hinfo(16);
header.dr = hinfo(17);
header.ld = hinfo(18);
header.extra = hinfo(19);

%frameSizeBytes=(header.w*header.h)*2+(1*4);
if mod(header.ss,8)~=0
    error(['Unsupported sample size of ' num2str(header.ss) ' bits when reading the header.  Sample size must be a multiple of 8 bits.']);
end

fPass=fseek(fid,0,'eof');
if fPass~=0
    error('fseek failed')
end
fileSizeInBytes=ftell(fid);


headerSizeBytes=(19*4);
frameSizeBytesWithoutTag=(header.w*header.h)*(header.ss/8);
frameSizeBytesWithTag=((header.w*header.h)*(header.ss/8)+4); %the tag is 4 bytes

%we need to decide what file version this is.  the table below shows how we
%refer to them.
%Version Name | Description
% 1.0         | This is the "original" version we used with frame tag numbers.
%             | SonixRP 3.2.2 uses it
% 2.0         | This version  which is used with Sonix RP 5.6.5 does not
%             | have frame tag numbers

%To do the check we look at the file size and compare the total size
if fileSizeInBytes == (headerSizeBytes+frameSizeBytesWithTag*header.nframes)
    header.file.version='1.0';
    header.file.headerSizeBytes=headerSizeBytes;
    header.file.frameSizeBytes=frameSizeBytesWithTag;
elseif fileSizeInBytes == (headerSizeBytes+frameSizeBytesWithoutTag*header.nframes)
    header.file.version='2.0';
    header.file.headerSizeBytes=headerSizeBytes;
    header.file.frameSizeBytes=frameSizeBytesWithoutTag;
else
    warning('UREAD:UNSUPPORTED_VERSION',['Unsupported file type. Defaulting to version 1.  There are ' num2str(fileSizeInBytes-(headerSizeBytes+frameSizeBytesWithTag*header.nframes)) ' unexpected bytes.']);
    header.file.version='1.0';
    header.file.headerSizeBytes=headerSizeBytes;
    header.file.frameSizeBytes=frameSizeBytesWithTag;
    
end

end

%Position file relative to the beginning. this is -1 in Matlab
function [val]=SEEK_SET()
val=-1;
return
end