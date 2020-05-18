function [trajectory, RT, buttonPressOnset] = circular_rating_output(duration, p, image_scale, rating_type)
% global screenNumber window windowRect xCenter yCenter screenXpixels screenYpixels
% shows a circular rating scale and records mouse position
%
% Input: duration - length of response period in seconds)
% Output: trajectory - n samples x 2 matrix (x coord, y coord)
%
% Note - this function call a new instance of PTB
% you likely wont want to use it this way in a paradigm
% just copy paste the relevant sections or use this as a subfunction
% initializing screen
%
% You will need PTB installed for this to work.
%
% [trajectory, dspl,cursor] = circular_rating(3);
% figure; comet(trajectory(:,1),trajectory(:,2))
%
% Phil Kragel 6/20/2019
% edited Heejung Jung 7/26/2019
% edited Phil Kragel for faces task 11/15/2019
%
% Additions ________________
% 1. duration:    length of rating scale, NOTE that the duration is filled with a fixation
%                 once the participant incidates a response.
%                 e.g. * experimenter fixes rating duration to 4 sec.
%                      * participant RT to respond to rating scale was 1.6 sec.
%                      * response will stay on screen for 0.5 sec
%                      * fixation cross will fill the the remainder of the duration
%                              i.e., 4-1.6-0.5 = 1.9 sec of fixation
% 2. p: psychtoolbox window parameters
% 3. image_scale: social influence task requires different rating scales
%                 (pain rating vs cognitive effort rating)
%                 The code takes different rating scale images
% 4. rating_type: social influence task has two ratings "expectation" & "actual experience"
%                 rating_type takes the keyword and displays it onto the rating scale



SAMPLERATE = .01; % used in continuous ratings
TRACKBALL_MULTIPLIER=1;
RT = NaN;
buttonPressOnset = NaN;

HideCursor;

%%% configure screen
dspl.screenWidth = p.ptb.rect(3);
dspl.screenHeight = p.ptb.rect(4);
dspl.xcenter = dspl.screenWidth/2;
dspl.ycenter = dspl.screenHeight/2;

dspl.cscale.width = 964; % image scale width
dspl.cscale.height = 480; % image scale height
dspl.cscale.xcenter = 483; % scale center (does not equal to screen center)
dspl.cscale.ycenter = 407;
dspl.cscale.w = Screen('OpenOffscreenWindow',p.ptb.screenNumber);

Screen('FillRect',dspl.cscale.w,0);
dspl.cscale.texture = Screen('MakeTexture',p.ptb.window, imread(image_scale));
% placement
dspl.cscale.rect = [...
    [dspl.xcenter dspl.ycenter]-[0.5*dspl.cscale.width 0.5*dspl.cscale.height] ...
    [dspl.xcenter dspl.ycenter]+[0.5*dspl.cscale.width 0.5*dspl.cscale.height]];
Screen('DrawTexture',dspl.cscale.w,dspl.cscale.texture,[],dspl.cscale.rect);
Screen('TextSize',dspl.cscale.w,24);

% determine cursor parameters for all scales
cursor.xmin = dspl.cscale.rect(1);
cursor.xmax = dspl.cscale.rect(3);
cursor.ymin = dspl.cscale.rect(2);
cursor.ymax = dspl.cscale.rect(4);

cursor.size = 8;
cursor.xcenter = ceil(dspl.cscale.rect(1) + (dspl.cscale.rect(3) - dspl.cscale.rect(1))*0.5);
cursor.ycenter = ceil(dspl.cscale.rect(2) + (dspl.cscale.rect(4)-dspl.cscale.rect(2))*0.847);

RATINGTITLES = {'INTENSITY'};


% initialize
Screen('TextSize',p.ptb.window,36);
DrawFormattedText(p.ptb.window,rating_type,'center',dspl.screenHeight/2+150,255);
timing.initialized = Screen('Flip',p.ptb.window);

cursor.x = cursor.xcenter;
cursor.y = cursor.ycenter;
sample = 1;
SetMouse(cursor.xcenter,cursor.ycenter);
nextsample = GetSecs;

buttonpressed  = false;
rlim = 500;
xlim = cursor.xcenter;
ylim = cursor.ycenter;
while GetSecs < timing.initialized + duration

    loopstart = GetSecs;

    % sample at SAMPLERATE
    if loopstart >= nextsample
        ctime(sample) = loopstart; %#ok
        trajectory(sample,1) = cursor.x; %#ok
        trajectory(sample,2) = cursor.y;
        nextsample = nextsample+SAMPLERATE;
        sample = sample+1;
    end


    if ~buttonpressed
    [x, y, buttonpressed] = GetMouse; % measure mouse movement
    SetMouse(cursor.xcenter,cursor.ycenter); % reset mouse position

    % calculate displacement
    cursor.x = (cursor.x + x-cursor.xcenter) * TRACKBALL_MULTIPLIER;
    cursor.y = (cursor.y + y-cursor.ycenter) * TRACKBALL_MULTIPLIER;
    [cursor.x, cursor.y, xlim, ylim] = limit(cursor.x, cursor.y, cursor.xcenter, cursor.ycenter, rlim, xlim, ylim);

    % check bounds
    if cursor.x > cursor.xmax
        cursor.x = cursor.xmax;
    elseif cursor.x < cursor.xmin
        cursor.x = cursor.xmin;
    end

    if cursor.y > cursor.ymax
        cursor.y = cursor.ymax;
    elseif cursor.y < cursor.ymin
        cursor.y = cursor.ymin;
    end

    % produce screen
    Screen('CopyWindow',dspl.cscale.w,p.ptb.window);
    DrawFormattedText(p.ptb.window,rating_type,'center',dspl.screenHeight/2+150,255);
    % add rating indicator ball
    Screen('FillOval',p.ptb.window,[255 0 0],[[cursor.x cursor.y]-cursor.size [cursor.x cursor.y]+cursor.size]);
    Screen('Flip',p.ptb.window);

    elseif any(buttonpressed)
       RT = GetSecs - timing.initialized;
       buttonPressOnset = GetSecs;
       buttonpressed = [0 0 0];
       Screen('CopyWindow',dspl.cscale.w,p.ptb.window);
       DrawFormattedText(p.ptb.window,rating_type,'center',dspl.screenHeight/2+150,255);
       % cursor changes
       Screen('FillOval',p.ptb.window,[255 0 255],[[cursor.x cursor.y]-cursor.size [cursor.x cursor.y]+cursor.size]);
       Screen('Flip',p.ptb.window);
       remainder_time = duration-0.5-RT;
       WaitSecs(remainder_time);
    end

end


end


%-------------------------------------------------------------------------------
%                            function Limit cursor
%-------------------------------------------------------------------------------
% Function by Xiaochun Han
function [x, y, xlim, ylim] = limit(x, y, xcenter, ycenter, r, xlim,ylim)
if (y<=ycenter) && (((x-xcenter)^2 + (y-ycenter)^2) <= r^2)
   xlim = x;
   ylim = y;
elseif (y<=ycenter) && (((x-xcenter)^2 + (y-ycenter)^2) > r^2)
   x = xlim;
   y = ylim;
elseif y>ycenter && (((x-xcenter)^2 + (y-ycenter)^2) <= r^2)
   xlim = x;
   y = ycenter;
elseif y>ycenter && (((x-xcenter)^2 + (y-ycenter)^2) > r^2)
   x = xlim;
   y = ycenter;
end
end
