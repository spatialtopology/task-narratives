function narratives(sub, run_num)
%% -----------------------------------------------------------------------------
%                           Parameters
% ------------------------------------------------------------------------------

%% A. Psychtoolbox parameters _________________________________________________
HideCursor
global p
Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(2);
screens                        = Screen('Screens'); % Get the screen numbers
p.ptb.screenNumber             = max(screens); % Draw to the external screen if avaliable
p.ptb.white                    = WhiteIndex(p.ptb.screenNumber); % Define black and white
p.ptb.black                    = BlackIndex(p.ptb.screenNumber);
[p.ptb.window, p.ptb.rect]     = PsychImaging('OpenWindow',p.ptb.screenNumber,p.ptb.black);
[p.ptb.screenXpixels, p.ptb.screenYpixels] = Screen('WindowSize',p.ptb.window);
p.ptb.ifi                      = Screen('GetFlipInterval',p.ptb.window);
Screen('BlendFunction', p.ptb.window,'GL_SRC_ALPHA','GL_ONE_MINUS_SRC_ALPHA'); % Set up alpha-blending for smooth (anti-aliased) lines
Screen('TextFont', p.ptb.window, 'Arial');
Screen('TextSize', p.ptb.window, 28);
[p.ptb.xCenter, p.ptb.yCenter] = RectCenter(p.ptb.rect);
p.fix.sizePix                  = 40; % size of the arms of our fixation cross
p.fix.lineWidthPix             = 4; % Set the line width for our fixation cross
p.fix.xCoords                  = [-p.fix.sizePix p.fix.sizePix 0 0];
p.fix.yCoords                  = [0 0 -p.fix.sizePix p.fix.sizePix];
p.fix.allCoords                = [p.fix.xCoords; p.fix.yCoords];


% Perform basic initialization of the sound driver:
InitializePsychSound;


% four random orders -- shuffle runs (not trials)
orders=[1:4; 2 4 1 3; 1 3 2 4; 4 3 2 1];
% reorder = orders(rem(sub,4)+1,:);
reorder = orders(rem(55,4)+1,:);
o_run_num=run_num;
run_num=reorder(run_num);

%% B. Directories ______________________________________________________________
task_dir                       = pwd;
main_dir                       = fileparts(task_dir);
taskname                       = 'narratives';
dir_text                       = fullfile(main_dir,'stimuli','text');
dir_audio                      = fullfile(main_dir,'stimuli','audio');

counterbalancefile             = fullfile(main_dir,'design', 'task-narratives_counterbalance_ver-01.csv');
countBalMat                    = readtable(counterbalancefile);
countBalMat                    = countBalMat(countBalMat.RunNumber==run_num,:);

if rem(sub,2)+1==1
countBalMat=countBalMat([10:18,1:9],:);
end
%% C. making output table ________________________________________________________
vnames = {'param_fmriSession', 'param_counterbalanceVer','param_stimulusFilename',...
    'p1_fixation_onset','p1_fixation_duration',...
    'p2_administer_type','p2_administer_filename','p3_administer_onset',...
    'p3_actual_onset','p3_actual_responseonset','p3_actual_RT',...
    'p4_actual_onset','p4_actual_responseonset','p4_actual_RT'};
T                              = array2table(zeros(size(countBalMat,1),size(vnames,2)));
T.Properties.VariableNames     = vnames;

a                              = split(counterbalancefile,filesep);
version_chunk                  = split(extractAfter(a(end),"ver-"),"_");
T.param_fmriSession(:)=run_num;
T.param_counterbalanceVer(:)   = str2double(version_chunk{1});
T.param_stimulusFilename          = countBalMat.stimulus_filename;

%% D. Keyboard information _____________________________________________________
KbName('UnifyKeyNames');
p.keys.confirm                 = KbName('return');
p.keys.right                   = KbName('2');
p.keys.left                    = KbName('1');
p.keys.space                   = KbName('space');
p.keys.esc                     = KbName('ESCAPE');
p.keys.trigger                 = KbName('5%');
p.keys.start                   = KbName('s');
p.keys.end                     = KbName('e');

%% E. fmri Parameters __________________________________________________________
TR                             = 0.46;


%% F. Circular rating scale _____________________________________________________
image_filepath                 = fullfile(main_dir,'stimuli','ratingscale');
image_scale_filename           = lower(['task-',taskname,'_scale.jpg']);
image_scale                    = fullfile(image_filepath,image_scale_filename);


%% -----------------------------------------------------------------------------
%                              Start Experiment
% ------------------------------------------------------------------------------

%% ______________________________ Instructions _________________________________
Screen('TextSize',p.ptb.window,72);
DrawFormattedText(p.ptb.window,'.','center',p.ptb.screenYpixels/2,255);
Screen('Flip',p.ptb.window);

%% _______________________ Wait for Trigger to Begin ___________________________
DisableKeysForKbCheck([]);
KbTriggerWait(p.keys.start);
Screen('TextSize',p.ptb.window,28);
DrawFormattedText(p.ptb.window,'Waiting for trigger','center',p.ptb.screenYpixels/2,255);
Screen('Flip',p.ptb.window);
T.param_triggerOnset(:) = KbTriggerWait(p.keys.trigger);
WaitSecs(TR*6);

%% initialize
rating_Trajectory=cell(size(countBalMat,1),2);
%% 0. Experimental loop _________________________________________________________
for trl = 1:size(countBalMat,1)
    
    %% 1. Fixation Jitter  ____________________________________________________
    jitter1 = countBalMat.ISI(trl);
    if rem(trl,9)==1
        Screen('TextSize',p.ptb.window,28);
        DrawFormattedText(p.ptb.window,'New Story','center',p.ptb.screenYpixels/2,255);

    else
    Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
        p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
    end
    fStart1 = GetSecs;
    Screen('Flip', p.ptb.window);
    WaitSecs(jitter1);
    fEnd1 = GetSecs;
    
    T.p1_fixation_onset(trl) = fStart1;
    T.p1_fixation_duration(trl) = fEnd1 - fStart1;
    
    %% 2. situation ________________________________________________________________
    
    Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
        p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
    Screen('Flip', p.ptb.window);
    
    if countBalMat.isText(trl)
        text_filename = [countBalMat.stimulus_filename{trl}];
        text_file = fullfile(dir_text, text_filename);
        text_time = showText(text_file,p);
        T.p2_administer_text_onset(trl,:) = text_time;
        
    else
        audio_filename = [countBalMat.stimulus_filename{trl}];
        audio_file = fullfile(dir_audio, audio_filename);
        audio_time = playAudio(audio_file);
        T.p2_administer_audio_onset(trl) = audio_time;
    end
    
    %% 3. rating of feelings ___________________________________________________
    T.p3_actual_onset(trl) = GetSecs;
    [trajectory, RT, buttonPressOnset] = circular_rating_output(2,p,image_scale,'FEEL');
    rating_Trajectory{trl,1} = trajectory;
    T.p3_actual_responseonset(trl) = buttonPressOnset;
    T.p3_actual_RT(trl) = RT;
    
    %% 3. rating of expectations ___________________________________________________
    T.p4_actual_onset(trl) = GetSecs;
    [trajectory, RT, buttonPressOnset] = circular_rating_output(2,p,image_scale,'EXPECT');
    rating_Trajectory{trl,2} = trajectory;
    T.p4_actual_responseonset(trl) = buttonPressOnset;
    T.p4_actual_RT(trl) = RT;
    
end

%% ______________________________ Instructions _________________________________
Screen('TextSize',p.ptb.window,72);
DrawFormattedText(p.ptb.window,'Run Finished','center',p.ptb.screenYpixels/2,255);
Screen('Flip',p.ptb.window);

%% save parameter ______________________________________________________________
sub_save_dir = fullfile(main_dir, 'data', strcat('sub-', sprintf('%03d', sub)), 'beh' );
if ~exist(sub_save_dir, 'dir')
    mkdir(sub_save_dir)
end
run_num
saveFileName = fullfile(sub_save_dir,[strcat('sub-', sprintf('%03d', sub)), ...
    strcat('run-', sprintf('%03d', o_run_num)), '_task-',taskname,'_beh.csv' ]);
writetable(T,saveFileName);

traject_saveFileName = fullfile(sub_save_dir, [strcat('sub-', sprintf('%03d', sub)), ...
    strcat('run-', sprintf('%03d', o_run_num)), '_task-',taskname,'_beh_trajectory.mat' ]);
save(traject_saveFileName, 'rating_Trajectory');

psychtoolbox_saveFileName = fullfile(sub_save_dir, [strcat('sub-', sprintf('%03d', sub)),...
    strcat('run-', sprintf('%03d', o_run_num)), '_task-',taskname,'_psychtoolbox_params.mat' ]);
save(psychtoolbox_saveFileName, 'p');

sca;

%% -----------------------------------------------------------------------------
%                                   Function
%-------------------------------------------------------------------------------
% Function by Phil Kragel
function t1=playAudio(audiofilename)
% Read audio file from filesystem:
[y, freq] = audioread(audiofilename);
wavedata = y';
nrchannels = size(wavedata,1); % Number of rows == number of channels.

% Make sure we have always 2 channels stereo output.
% Why? Because some low-end and embedded soundcards
% only support 2 channels, not 1 channel, and we want
% to be robust in our demos.
if nrchannels < 2
    wavedata = [wavedata ; wavedata];
    nrchannels = 2;
end

device = [];

try
    % Try with the 'freq'uency we wanted:
    pahandle = PsychPortAudio('Open', device, [], 0, freq, nrchannels);
catch
    % Failed. Retry with default frequency as suggested by device:
    fprintf('\nCould not open device at wanted playback frequency of %i Hz. Will retry with device default frequency.\n', freq);
    fprintf('Sound may sound a bit out of tune, ...\n\n');
    
    psychlasterror('reset');
    pahandle = PsychPortAudio('Open', device, [], 0, [], nrchannels);
end

% Fill the audio playback buffer with the audio data 'wavedata':
PsychPortAudio('FillBuffer', pahandle, wavedata);

% Start audio playback for 'repetitions' repetitions of the sound data,
% start it immediately (0) and wait for the playback to start, return onset
% timestamp.
t1 = PsychPortAudio('Start', pahandle, 1, 0, 1);
pause(size(y,1)/freq);

% Stop playback:
PsychPortAudio('Stop', pahandle);

% Close the audio device:
PsychPortAudio('Close', pahandle);

%% -----------------------------------------------------------------------------
%                                   Function
%-------------------------------------------------------------------------------
% Function by Phil Kragel
function timing=showText(textfilename,p)
% Read text file from filesystem:

fid = fopen(textfilename, 'r');
if fid == -1
    error('Cannot open file for reading: %s', textfilename);
end
DataC = textscan(fid, '%s', 'delimiter', '\n', 'whitespace', '');
Data  = DataC{1}{1};
fclose(fid);
Data=string(Data);



%%% configure screen
dspl.screenWidth = p.ptb.rect(3);
dspl.screenHeight = p.ptb.rect(4);
dspl.xcenter = dspl.screenWidth/2;
dspl.ycenter = dspl.screenHeight/2;

Screen('TextSize',p.ptb.window,28);
split_text=split(Data);
ci=0;
for d=1:10:length(split_text)
    ci=ci+1;
    text_to_show =  join(split_text(d:min(d+9,length(split_text))));
    DrawFormattedText(p.ptb.window,text_to_show{1},'center',dspl.ycenter,255);
    timing.initialized(ci) = Screen('Flip',p.ptb.window);
    pause(length(d:min(d+9,length(split_text)))/3)
end

ShowCursor