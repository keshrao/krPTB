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
Screen('Preference', 'SkipSyncTests', 0);

whichScreen = 2;
res = Screen('Resolution',whichScreen);
centX = res.width/2;
centY = res.height/2;


% data to be stored into this filename
c = clock;
fName = [date '-' num2str(c(4)) num2str(c(5))]; % date and hour and min

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
    
    ntrls = 500;
    
    % --- variables and declarations common to all trials
    
    winTol = 30;
    
    % center fixation square
    fixSq = [res.width/2-5 res.height/2-5 res.width/2 res.height/2]';
    colorBlue = [0 0 255]';
    
    % this is be a good photodiode cell box
    photoSq = [0 0 30 30]';
    colorWhite = [255 255 255]'; % white color
    
    
    stimoffsetW = round(res.width/7);
    stimoffsetH = round(res.height/7);
    % ---- starting trial loop
    
    % this will be used to store all flash locations
    storeXlocs = [];
    storeYlocs = [];
    storeSuccess = nan(1,ntrls);
    % show n stimuli combinations
    for trl = 1:ntrls
        
        disp(['Trl Number: ' num2str(trl)])
        
        % present fixation square
        Screen(window, 'FillRect', colorBlue, fixSq);
        Screen(window, 'Flip');
        
        % wait of eye to enter fixation square to begin trial
        isInWindow = false;
        temptic = tic;
        
        while toc(temptic) < 3 % wait three seconds to enter fixation
            
            if isDaq
                [eyePosX eyePosY] = krGetEyePos(ai);
            else
                [eyePosX,eyePosY] = GetMouse(window);
                eyePosX = eyePosX - centX;
                eyePosY = eyePosY - centY;
            end
            
            % check if within window
            if abs(eyePosX) < winTol && abs(eyePosY) < winTol
                isInWindow = true; % cue to begin wait period
                break % as soon as eye in window, break wait loop
            end
            
        end
        
        
        % check if fixation failed
        if ~isInWindow
            Screen(window, 'FillRect', black);
            Screen(window, 'Flip');
            if isDaq, krEndTrial(dio); end
            storeSuccess(trl) = 0;
            WaitSecs(2);
        else
            
            % successful fixation trial logic goes here
            if isDaq, krStartTrial(dio); end
            
            % begin series of stimuli flashes
            numflashes = 10;
            
            while isInWindow
                
                numstimthistrl = 2;
                xFlashesIter = nan(numflashes,numstimthistrl);
                yFlashesIter = nan(numflashes,numstimthistrl);
                    
                
                for nf = 1:numflashes
                    
                    % how many stimuli do I want to create - for now , always 2
                    % numstimthistrl = randi([1 5], 1);
                    
                    
                    % make sure still in window
                    if isDaq
                        [eyePosX eyePosY] = krGetEyePos(ai);
                    else
                        [eyePosX,eyePosY] = GetMouse(window);
                        eyePosX = eyePosX - centX;
                        eyePosY = eyePosY - centY;
                    end
                    
                    % check if within window
                    if abs(eyePosX) < winTol && abs(eyePosY) < winTol
                        isInWindow = true; % cue to begin wait period
                    else
                        isInWindow = false;
                        break
                    end
                    % --------------------------
                    
                    
                    stims = [fixSq photoSq];
                    stimcolors = [colorBlue colorWhite];
                    
                    
                    % generate nstim stimulus squares and not on the edges of the screen
                    randXpos = randi(res.width - stimoffsetW, 1, numstimthistrl) + stimoffsetW/2;
                    randYpos = randi(res.height - stimoffsetH, 1, numstimthistrl) + stimoffsetH/2;
                    
                    xFlashesIter(nf,:) = randXpos;
                    yFlashesIter(nf,:) = randYpos;
                    
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
                    
                    
                    blankDur = 0.1;
                    % after stim duration, then blank screen (leave fixation) for 100ms
                    Screen(window, 'FillRect', colorBlue, fixSq);
                    Screen(window, 'Flip');
                    
                    thisBlank = tic;
                    while toc(thisBlank) < blankDur
                        % some code
                    end
                    
                end %nflahses
                
                if ~isInWindow
                    storeSuccess(trl) = 0;
                    Screen(window, 'FillRect', black);
                    Screen(window, 'Flip');
                    if isDaq, krEndTrial(dio); end
                    WaitSecs(2);
                    break
                end
                
                % successful completion of trial
                if isInWindow
                    
                    if isDaq, krEndTrial(dio); end
                    % wipe screen & fill bac
                    Screen(window, 'FillRect', black);
                    Screen(window, 'Flip');
                    if isDaq, krDeliverReward(dio); end;
                    
                    % collect flashes
                    storeXlocs = [storeXlocs; xFlashesIter]; %#ok
                    storeYlocs = [storeYlocs; yFlashesIter]; %#ok
                    storeSuccess(trl) = 1;
                    
                    WaitSecs(2);
                    break
                end
                
            end % while continuously fixting
            
        end %if successful fixation
        
        
        if isDaq, krEndTrial(dio); end
        
        if mod(trl,20) == 0
            save(fName, 'storeXlocs', 'storeYlocs','storeSuccess')
        end
        
    end % ntrials
    
    Screen('CloseAll');
    
catch %#ok
    
    ShowCursor
    Screen('CloseAll');
    disp('Error')
    if isDaq, krEndTrial(dio); end
    save(fName, 'storeXlocs', 'storeYlocs','storeSuccess')
end

if isDaq, krEndTrial(dio); end
save(fName, 'storeXlocs', 'storeYlocs','storeSuccess')
Priority(0);

