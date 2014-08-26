% testing psychtoolbox screen command

clc, clear

try
    [ai, dio] = krConnectDAQ();
    isDaq = true;
catch
    disp('no daq')
    isDaq = false;
end


% remember to clear this out for real experiments
Screen('Preference', 'SkipSyncTests', 2 );

whichScreen = 2;
res = Screen('Resolution',whichScreen);

Priority(2);

try
    HideCursor;
    window = Screen(whichScreen, 'OpenWindow');
    ShowCursor;
    
    white = WhiteIndex(window); % pixel value for white
    black = BlackIndex(window); % pixel value for black
    
    % wipe screen & fill bac
    Screen(window, 'FillRect', black);
    Screen(window, 'Flip')
    
    ntrls = 100;
    framedel = nan(1,ntrls);
    
    
    % --- variables and declarations common to all trials
    
    % center fixation square
    fixSq = [res.width/2-5 res.height/2-5 res.width/2 res.height/2]';
    colorBlue = [0 0 255]';
    
    % this is be a good photodiode cell box
    photoSq = [0 0 30 30]';
    colorWhite = [255 255 255]'; % white color
    
    
    stimoffsetW = res.width/10;
    stimoffsetH = res.height/10;
    % ---- starting trial loop
    
    % show n stimuli combinations
    for trls = 1:ntrls
        
        
        if isDaq, krStartTrial(dio); end
        
        stims = [fixSq photoSq];
        stimcolors = [colorBlue colorWhite];
        
        % how many stimuli do I want to create - for now , always 2
        % numstimthistrl = randi([1 5], 1);
        numstimthistrl = 2;
        
        % generate nstim stimulus squares and not on the edges of the screen
        
        randXpos = randi(res.width - stimoffsetW, numstimthistrl, 1) + stimoffsetW/2;
        randYpos = randi(res.height - stimoffsetH, numstimthistrl, 1) + stimoffsetH/2;
        
        
        for i = 1:numstimthistrl
            thisSq = [randXpos(i)-10 randYpos(i)-10 randXpos(i) randYpos(i)]';
            stims = [stims thisSq];
            stimcolors = [stimcolors colorWhite];
        end
        
        
        % draw fixation dot
        Screen(window, 'FillRect', stimcolors , stims);
        Screen(window, 'Flip');
        
        % leave stimulus on for short priod of time
        stimwaitdur = rand/10; %<- uniformly distributed between 0 & 100ms
        
        % note that if stimwaitdur < 0.016, then it's just waiting one
        % frame
        thisdur = tic;
        while toc(thisdur) < stimwaitdur
            % some code
        end
        
        
        % after stim duration, then blank screen (leave fixation) for 100ms
        Screen(window, 'FillRect', colorBlue, fixSq);
        Screen(window, 'Flip');
        
        if isDaq, krEndTrial(dio); end
        
        if mod(trls, 25) == 0
            % wipe screen & fill bac
            Screen(window, 'FillRect', black);
            Screen(window, 'Flip');
            
            if isDaq, krDeliverReward(dio); end;
            
            WaitSecs(2);
        end
        
    end
    
    Screen('CloseAll');
    
    %
catch %#ok
    
    ShowCursor
    Screen('CloseAll');
    disp('Error')
end

Priority(0);

