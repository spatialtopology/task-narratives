function narratives(sub, run_num, biopac, fMRI)
%% -----------------------------------------------------------------------------
%                           Parameters
% ------------------------------------------------------------------------------

script_dir = pwd;
% debug = 0;
% if debug
%     ListenChar(0);
%     PsychDebugWindowConfiguration;
% end

% biopac channel
channel_trigger     = 0;
channel_fixation    = 1;
channel_text        = 2;
channel_audio       = 3;
channel_feel        = 4;
channel_expect      = 5;
%% 0. Biopac parameters _________________________________________________
if biopac == 1
    script_dir = pwd;
    cd('/home/spacetop/repos/labjackpython');
    pe = pyenv;
    try
        py.importlib.import_module('u3');
    catch
        warning("u3 already imported!");
    end
    % Check to see if u3 was imported correctly
    % py.help('u3')
    b = py.u3.U3();
    % set every channel to 0
    b.configIO(pyargs('FIOAnalog', int64(0), 'EIOAnalog', int64(0)));
    for FIONUM = 0:7
        b.setFIOState(pyargs('fioNum', int64(FIONUM), 'state', int64(0)));
    end
    cd(script_dir);

end

%% A. Psychtoolbox parameters _________________________________________________

global p
Screen('Preference', 'SkipSyncTests', 0);
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
HideCursor;

% four random orders -- shuffle runs (not trials)
orders=[1:4; 2 4 1 3; 1 3 2 4; 4 3 2 1];
% reorder = orders(rem(sub,4)+1,:);
reorder = orders(rem(55,4)+1,:);
o_run_num=run_num;
shuffled_run_num=reorder(run_num);

% if fMRI
% [index, productname, allinfo] = GetMouseIndices();
% trigger_index = find(contains(productname, 'Current Designs'));
% trigger_inputDevice = index(trigger_index);
% else trigger_inputDevice = -3;
% end


%% B. Directories ______________________________________________________________

%addpath(genpath(pwd))
script_dir = pwd;
main_dir                       = fileparts(script_dir); % '/home/spacetop/repos/narratives';
repo_dir                       = fileparts(fileparts(script_dir)); % '/home/spacetop/repos'
taskname                       = 'narratives';
% dir_text                     = fullfile(main_dir,'stimuli','text');
% dir_audio                    = fullfile(main_dir,'stimuli','audio');
% counterbalancefile           = fullfile(main_dir,'design', 'task-narratives_counterbalance_ver-01.csv');
session_id                     = 2;
bids_string                    = [strcat('sub-',sprintf('%04d', sub)), ...
    strcat('_ses-',sprintf('%02d', session_id)),...
    strcat('_task-', taskname),...
    strcat('_run-',sprintf('%02d', o_run_num))];
sub_save_dir = fullfile(main_dir, 'data', strcat('sub-', sprintf('%04d', sub)),...
    'beh' );
repo_save_dir = fullfile(repo_dir, 'data', strcat('sub-', sprintf('%04d', sub)),...
    'task-narratives');
if ~exist(sub_save_dir, 'dir');     mkdir(sub_save_dir);    end
if ~exist(repo_save_dir, 'dir');    mkdir(repo_save_dir);   end

dir_text                       = fullfile(main_dir,'stimuli','text');
dir_audio                      = fullfile(main_dir,'stimuli','audio_mp4_48000');
counterbalancefile             = fullfile(main_dir,'design', 'task-narratives_counterbalance_ver-01_48k_mp4.csv');
countBalMat                    = readtable(counterbalancefile);
countBalMat                    = countBalMat(countBalMat.RunNumber==shuffled_run_num,:);





if rem(sub,2)+1==1
    countBalMat=countBalMat([10:18,1:9],:);
end


% empty options for video Screen
shader = [];
pixelFormat = [];
maxThreads = [];

iteration = 0;
escape = 0;

% Use blocking wait for new frames by default:
blocking = 1;

% Default preload setting:
preloadsecs = [];
% Playbackrate defaults to 1:
rate=1;


%% C. making output table ________________________________________________________
vnames = {'src_subject_id', 'session_id','param_run_num','shuffled_run_from_counterbalance','param_counterbalance_ver',...
    'param_stimulus_filename','param_trigger_onset','param_start_biopac'...
    'event01_fixation_onset','event01_fixation_biopac','event01_fixation_duration',...
    'event02_administer_type','event02_administer_onset',...
    'event02_administer_biopac',  ...
    'event03_feel_displayonset','event03_feel_responseonset','event03_feel_RT', 'event03_feel_biopac',...
    'event04_expect_displayonset','event04_expect_responseonset','event04_expect_RT', 'event04_expect_biopac', ...
    'param_end_biopac', 'param_end_instruct_onset' ,'param_experiment_duration'};
varTypes = {'double', 'double', 'double', 'double', 'double', ...
    'string', 'double', 'double', ...
    'double', 'double', 'double',...
    'string', 'double',...
    'double', ...
    'double', 'double', 'double', 'double', ...
    'double', 'double', 'double', 'double', ...
    'double', 'double', 'double'};

T = table('Size', [size(countBalMat,1) size(vnames,2)],'VariableNames', vnames, 'VariableTypes', varTypes);

a                              = split(counterbalancefile,filesep);
version_chunk                  = split(extractAfter(a(end),"ver-"),"_");
T.src_subject_id(:)            = sub;
T.session_id(:)                = session_id;
T.param_run_num(:)             = o_run_num;
T.shuffled_run_from_counterbalance(:)   = shuffled_run_num;
T.param_counterbalance_ver(:)  = str2double(version_chunk{1});
T.param_stimulus_filename      = countBalMat.stimulus_filename;

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

% [id, name]                     = GetKeyboardIndices;
% trigger_index                  = find(contains(name, 'Current Designs'));
% trigger_inputDevice            = id(trigger_index);
%
% keyboard_index                 = find(contains(name, 'AT Translated Set 2 Keyboard'));
% keyboard_inputDevice           = id(keyboard_index);

%% E. fmri Parameters __________________________________________________________
TR                             = 0.46;


%% F. Circular rating scale _____________________________________________________
image_filepath                 = fullfile(main_dir,'stimuli','ratingscale');
image_scale_filename           = lower(['task-',taskname,'_scale.jpg']);
image_scale                    = fullfile(image_filepath,image_scale_filename);

%% preload
DrawFormattedText(p.ptb.window,sprintf('LOADING\n\n0%% complete'),'center','center',p.ptb.white );
Screen('Flip',p.ptb.window);
for trl = 1:size(countBalMat,1)
    preloadsecs =[];
    if countBalMat.isText(trl)
%         text_filename = [countBalMat.stimulus_filename{trl}];
%         text_file = fullfile(dir_text, text_filename);
%         text_time = showText(text_file,p);
        %         T.event02_administer_text_onset(trl,:) = text_time;
    else
        audio_filename = [countBalMat.stimulus_filename{trl}];
        audio_file = fullfile(dir_audio, audio_filename);		% Read audio file from filesystem:
        %[y{trl}, freq{trl}] = audioread(audio_file);

        %preloadsecs =[];
        %video_file      = fullfile(main_dir, 'stimuli', 'videos',strcat('ses-',sprintf('%02d', ses_num)),...
        %    strcat('run-',sprintf('%02d', r)), T.param_video_filename{v});
        [movie{trl}, dur{trl}, fps{trl}, imgw{trl}, imgh{trl}] = Screen('OpenMovie', p.ptb.window, audio_file, [], preloadsecs, [], pixelFormat, maxThreads);

    end
    DrawFormattedText(p.ptb.window,sprintf('LOADING\n\n%d%% complete', ceil(100*trl/size(countBalMat,1))),'center','center',p.ptb.white);
    Screen('Flip',p.ptb.window);
end
rating_tex = Screen('MakeTexture', p.ptb.window, imread(image_scale)); % pure rating scale
%% -----------------------------------------------------------------------------
%                              Start Experiment
% ------------------------------------------------------------------------------

%% ______________________________ Instructions _________________________________
Screen('TextSize',p.ptb.window,72);
DrawFormattedText(p.ptb.window,'.','center',p.ptb.screenYpixels/2,255);
Screen('Flip',p.ptb.window);

%% _______________________ Wait for Trigger to Begin ___________________________

% DisableKeysForKbCheck([]);
WaitKeyPress(p.keys.start);
Screen('TextSize',p.ptb.window,28);

DrawFormattedText(p.ptb.window,'Waiting for trigger','center',p.ptb.screenYpixels/2,255);

Screen('Flip',p.ptb.window);
WaitKeyPress(p.keys.trigger);
% T.param_trigger_onset(:)                = KbTriggerWait(p.keys.trigger, trigger_inputDevice);
T.param_trigger_onset(:) = GetSecs;
T.param_start_biopac(:)                   = biopac_linux_matlab(biopac, channel_trigger, 1);

WaitSecs(TR*6);

%% initialize
rating_Trajectory=cell(size(countBalMat,1),2);
%% 0. Experimental loop _________________________________________________________
for trl = 1:size(countBalMat,1)

    %% 1. Fixation Jitter  ____________________________________________________
    jitter1 = countBalMat.ISI(trl);
    if rem(trl,9)==1
        Screen('TextSize',p.ptb.window); % 2
        DrawFormattedText(p.ptb.window,'New Story','center',p.ptb.screenYpixels/2,255);

    else
        Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
            p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
    end
    T.event01_fixation_onset(trl)         = Screen('Flip', p.ptb.window);
    T.event01_fixation_biopac(trl)        = biopac_linux_matlab(biopac, channel_fixation, 1);
    WaitSecs('UntilTime', T.event01_fixation_onset(trl) + jitter1);
    jitter1_end                           = biopac_linux_matlab(biopac, channel_fixation, 0);
    T.event01_fixation_duration(trl)      = jitter1_end - T.event01_fixation_onset(trl);

    %% 2. situation ________________________________________________________________

    Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
        p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
    Screen('Flip', p.ptb.window);

    if countBalMat.isText(trl)
        text_filename = [countBalMat.stimulus_filename{trl}];
        text_file = fullfile(dir_text, text_filename);
        first_text_onsettime = showText(text_file,p);
%         size(text_time)

        T.event02_administer_biopac(trl)        = biopac_linux_matlab(biopac, channel_text, 1);
        T.event02_administer_type(trl)    = 'text';

        T.event02_administer_onset(trl) = first_text_onsettime;
        biopac_linux_matlab(biopac, channel_text, 0);

    else
        audio_filename = [countBalMat.stimulus_filename{trl}];
        audio_file = fullfile(dir_audio, audio_filename);
        T.event02_administer_biopac(trl)        = biopac_linux_matlab(biopac, channel_audio, 1);
        % audio_time = playAudio(audio_file,y{trl},freq{trl});
        totalframes = floor(fps{trl} * dur{trl});
        %fprintf('Movie: %s  : %f seconds duration, %f fps, w x h = %i x %i...\n', T.param_video_filename{trl}, dur{trl}, fps{trl}, imgw{trl}, imgh{trl});
        %disp('line 381')
        i=0;
        Screen('PlayMovie', movie{trl}, rate, 1, 1.0);

       % biopac_linux_matlab(biopac, channel_audio, 0);
        %COMMENT BACK IN
        %T.event02_administer_onset(trl) = audio_time;
        T.event02_administer_type(trl)    = 'audio';

        while i<totalframes-1

            escape=0;
            [keyIsDown,secs,keyCode]=KbCheck;
            if (keyIsDown==1 && keyCode(p.keys.esc))
                % Set the abort-demo flag.
                escape=2;
                % break;
            end


            % Only perform video image fetch/drawing if playback is active
            % and the movie actually has a video track (imgw and imgh > 0):

            if ((abs(rate)>0) && (imgw{trl}>0) && (imgh{trl}>0))
                % Return next frame in movie, in sync with current playback
                % time and sound.
                % tex is either the positive texture handle or zero if no
                % new frame is ready yet in non-blocking mode (blocking == 0).
                % It is -1 if something went wrong and playback needs to be stopped:
                tex = Screen('GetMovieImage', p.ptb.window, movie{trl}, blocking);

                % Valid texture returned?
                if tex < 0
                    % No, and there wont be any in the future, due to some
                    % error. Abort playback loop:
                    %  break;
                end

                if tex == 0
                    % No new frame in polling wait (blocking == 0). Just sleep
                    % a bit and then retry.
                    WaitSecs('YieldSecs', 0.005);
                    continue;
                end

                Screen('DrawTexture', p.ptb.window, tex, [], [], [], [], [], [], shader); % Draw the new texture immediately to screen:
                Screen('Flip', p.ptb.window); % Update display:
                Screen('Close', tex);% Release texture:
                i=i+1; % Framecounter:

            end % end if statement for grabbing next frame
        end % end while statement for playing until no more frames exist

        T.event01_video_end(trl) = GetSecs;
        %T.event01_biopac_stop(trl) = biopac_video(biopac, channel.movie, 0);

        Screen('Flip', p.ptb.window);
        KbReleaseWait;

        Screen('PlayMovie', movie{trl}, 0); % Done. Stop playback:
        Screen('CloseMovie', movie{trl});  % Close movie object:

        % Release texture:
        %         Screen('Close', tex);

        % if escape is pressed during video, exit
        if escape==2
            %break
        end

    end

    %% 3. rating of feelings ___________________________________________________
    T.event03_feel_displayonset(trl) = GetSecs;
    T.event03_feel_biopac(trl)          = biopac_linux_matlab(biopac, channel_feel, 1);
    [trajectory, RT, buttonPressOnset] = circular_rating_output(4,p,rating_tex,'FEEL');
    biopac_linux_matlab(biopac, channel_feel, 0);
    rating_Trajectory{trl,1} = trajectory;
    T.event03_feel_responseonset(trl) = buttonPressOnset;
    T.event03_feel_RT(trl) = RT;

    %% 3. rating of expectations ___________________________________________________
    T.event04_expect_displayonset(trl) = GetSecs;
    T.event04_expect_biopac(trl)          = biopac_linux_matlab(biopac, channel_expect, 1);
    [trajectory, RT, buttonPressOnset] = circular_rating_output(4,p,rating_tex,'EXPECT');
    biopac_linux_matlab(biopac, channel_expect, 0);
    rating_Trajectory{trl,2} = trajectory;
    T.event04_expect_responseonset(trl) = buttonPressOnset;
    T.event04_expect_RT(trl) = RT;

        %% ________________________ 7. temporarily save file _______________________
    tmp_file_name = fullfile(sub_save_dir,[strcat('sub-', sprintf('%04d', sub)),strcat('_run-', sprintf('%02d', o_run_num)), '_task-',taskname,'_TEMPbeh.csv' ]);
    writetable(T,tmp_file_name);
%     Screen('Close'); % HEEJUNG see if this helps
end

%% ______________________________ End Instructions _________________________________
Screen('TextSize',p.ptb.window,72);
DrawFormattedText(p.ptb.window,'Run Finished','center',p.ptb.screenYpixels/2,255);
T.param_end_instruct_onset(:)             = Screen('Flip',p.ptb.window);
T.param_end_biopac(:)                     = biopac_linux_matlab(biopac, channel_trigger, 0);
WaitKeyPress(KbName('e'));
T.param_experiment_duration(:) = T.param_end_instruct_onset(1) - T.param_trigger_onset(1);
Screen('Close');

%% save parameter ______________________________________________________________
saveFileName = fullfile(sub_save_dir,[bids_string,'_beh.csv' ]);
repoFileName = fullfile(repo_save_dir,[bids_string,'_beh.csv' ]);
writetable(T,saveFileName);
writetable(T,repoFileName);

traject_saveFileName = fullfile(sub_save_dir, [bids_string,'_beh_trajectory.mat' ]);
traject_repoFileName = fullfile(repo_save_dir, [bids_string,'_beh_trajectory.mat' ]);
save(traject_saveFileName, 'rating_Trajectory');
save(traject_repoFileName, 'rating_Trajectory');

psychtoolbox_saveFileName = fullfile(sub_save_dir, [bids_string,'_psychtoolbox_params.mat' ]);
psychtoolbox_repoFileName = fullfile(repo_save_dir, [bids_string,'_psychtoolbox_params.mat' ]);
save(psychtoolbox_saveFileName, 'p');
save(psychtoolbox_repoFileName, 'p');

sca;
if biopac
    b.close()
end
%% -----------------------------------------------------------------------------
%                                   Function
%-------------------------------------------------------------------------------
    function [time] = biopac_linux_matlab(biopac, channel_num, state_num)
        if biopac
            b.setFIOState(pyargs('fioNum', int64(channel_num), 'state', int64(state_num)))
            time = GetSecs;
        else
            time = GetSecs;
            return
        end
    end

% Function by Phil Kragel
    function t1=playAudio(audiofilename, y, freq)
        % Read audio file from filesystem:
        % [y, freq] = audioread(audiofilename);
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

        %device = [];
        device = [6];

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

    end

    function WaitKeyPress(kID)
        while KbCheck(-3); end  % Wait until all keys are released.
        while 1
            % Check the state of the keyboard.
            [ keyIsDown, ~, keyCode ] = KbCheck(-3);
            % If the user is pressing a key, then display its code number and name.
            if keyIsDown

                if keyCode(p.keys.esc)
                    cleanup; break;
                elseif keyCode(kID)
                    break;
                end
                % make sure key's released
                while KbCheck(-3); end
            end
        end
    end
% Function by Phil Kragel
    function first_text_onsettime=showText(textfilename,p)
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
%         Screen('Close')
        first_text_onsettime = timing.initialized(1);
    end
ShowCursor;
end
