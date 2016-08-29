function [ header, images, pressures ] = vpReader( fileName, dataFileName, frames )
%vpReader Reading of VeinPress files

%
%============ HEADER V1 ===================
%  version                 uint8_t                 (must be 1)
%  depthCues.p1            int32_t
%  depthCues.p2            int32_t
%  depthCues.p3            int32_t
%  N Frames                uint32_t
%  N Pressures             uint32_t
%  FrameFormat.width       uint16_t
%  FrameFormat.height      uint16_t
%  FrameFormat.byteSize    uint8_t                 (must be 1)
%============ PRESSURE RELATED ============
%  Pressure values         float   * NPressures
%  Pressure times          int64_t * NPressures    (all time values are in ms)
%============ FRAME RELATED ===============
%  Approx. pressure values float   * NFrames
%  Approx. pressure times  int64_t * NFrames
%  Frame times             int64_t * NFrames
%  Frame data              uint8_t * (FrameFormat.width *
%                                     FrameFormat.height *
%                                     FrameFormat.byteSize) * NFrames
%
%
% ============== HEADER V2 =================
% version                 uint8_t                 (must be 2)
% depthCues.p1            int32_t
% depthCues.p2            int32_t
% depthCues.p3            int32_t
% N Frames                uint32_t
% N Pressures             uint32_t
% FrameFormat.width       uint16_t
% FrameFormat.height      uint16_t
% FrameFormat.byteSize    uint8_t                 (must be 1)
% relativeDelay           int64_t
% reserved for future     int64_t * 19
% ============ PRESSURE RELATED ============
% Pressure values         float   * NPressures
% Pressure times          int64_t * NPressures    (all time values are in ms)
% ============ FRAME RELATED ===============
% Approx. pressure values float   * NFrames
% Approx. pressure times  int64_t * NFrames
% Frame times             int64_t * NFrames
%
% ============= Separate File ==============
%  Frame data              uint8_t * (FrameFormat.width *
%                                     FrameFormat.height *
%                                     FrameFormat.byteSize) * NFrames


[fid, msg] = fopen( fileName, 'r' );
if( fid < 0 )
    error( msg );
    return
end    

% Reading header
version    = fread( fid, 1, '*uint8' );
depthCue1  = fread( fid, 1, '*int32',  0, 'b' );
depthCue2  = fread( fid, 1, '*int32',  0, 'b' );
depthCue3  = fread( fid, 1, '*int32',  0, 'b' );
nFrames    = fread( fid, 1, '*uint32', 0, 'b' );
nPressures = fread( fid, 1, '*uint32', 0, 'b' );
width      = int32(fread( fid, 1, '*uint16', 0, 'b' ));
height     = int32(fread( fid, 1, '*uint16', 0, 'b' ));
bytes      = int32(fread( fid, 1, '*uint8',  0, 'b' ));
relativeDelay = 0;
if( version >= 2 )
    relativeDelay = int64(fread( fid, 1, '*int64', 0, 'b' ));
    fseek( fid, 19*8, 'cof' );
end
headerOffset = int64(ftell( fid ));
imgOffset = headerOffset + int64(nPressures * ( 4 + 8 )) +...
                           int64(nFrames    * ( 4 + 8 + 8 ));

pressureOffset = headerOffset + int64(nPressures * ( 4 + 8 ));

if( numel(frames) == 2 )
    readFrames = frames(2)-frames(1);
else
    readFrames = 1;
end

% Reading pressure data
fseek( fid, pressureOffset + int64(4*frames(1)), 'bof' );
pressures = fread( fid, readFrames, '*float' );

% Reading image data
tmp = 0;
if( version == 1 )
    fseek( fid, imgOffset + int64(width*height*frames(1)), 'bof' );
    tmp = fread( fid, width*height*readFrames, '*uint8' );
    fclose( fid );
else
    if( version >= 2 )
        fclose( fid );

        [fidD, msg] = fopen( dataFileName, 'r' );
        if( fidD < 0 )
            error( msg );
            return
        end
        fseek( fidD, int64(width*height*frames(1)), 'bof' );
        tmp = fread( fidD, width*height*readFrames, '*uint8' );
        fclose( fidD );
    end
end
 
images = reshape( tmp, [ width height readFrames ] );

%images = zeros( 0 );

%disp( ['nElements: ' num2str(size( tmp )) ]);
%disp( ['w:', num2str(width),  ' h:',  num2str(height),  ' n:', num2str(readFrames)]);
%disp( ['whn:', num2str(width*height*readFrames) ] );
%disp( ['first frame: ', num2str( frames(1)) ] );


header = struct...
  ('version'  ,version,...
   'depthCue1',depthCue1,...
   'depthCue2',depthCue2,...
   'depthCue3',depthCue3,...
   'nPressures',nPressures,...
   'nFrames',  nFrames,...
   'width',    width,...
   'height',   height,...
   'bytesPerPixel', bytes,...
   'relativeDelay', relativeDelay );

% Reading pressure and image data


end

