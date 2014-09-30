function krFwdCorr_SingleSaccade()

% testing psychtoolbox screen command

clc, clear; close all; pause(0.01);

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


ntrls = 100; % total number of trials requested
numstimthistrl = 10; % number of stimuli in each flash

viewingFigure = true;
if viewingFigure
    % now open up a second matlab figure to be used to view eye position
    fig = figure(2); clf
    axis([-res.width/2 res.width/2 -res.height/2 res.height/2]);
    hold on
    rectangle('Position', [0 0 10 10], 'FaceColor', 'black'); % center of the screen
    hEye = rectangle('Position', [0, 0 25 25],'FaceColor','red'); %<- note, x,y,w,h as opposed to PTB's convention
    for numtargsi = 1:numstimthistrl
        hTargs(numtargsi) = rectangle('Position', [0, 0 10 10],'FaceColor','white'); %#ok
    end
    set(gca, 'color', 'none')
    
    % this is for the easy ending of programs
    uicontrol('Parent',fig,'Style','pushbutton','String','End Task','Callback',@cb_EndTask,'Position',[450 350 60 20]);
    drawnow
end

    function updateViewingFigure()
        try
            set(hEye, 'Position', [eyePosX eyePosY 25 25]); %note this different convention
            for drawi = 1:numstimthistrl 
               set(hTargs(drawi), 'Position', [randXpos(drawi)-centX -(randYpos(drawi)-centY) 10 10]) 
            end
            drawnow
        end
    end

    function cb_EndTask(~,~)
        isRun = false;
    end

isRun = true;

% data to be stored into this filename
c = clock;
fName = ['sacFwd_' date '-' num2str(c(4)) num2str(c(5))]; % date and hour and min

Priority(2);
try
    HideCursor;
    window = Screen(whichScreen, 'OpenWindow');
    ShowCursor;
    
    black = BlackIndex(window); % pixel value for black
    
    % wipe screen & fill bac
    Screen(window, 'FillRect', black);
    Screen(window, 'Flip');
    
    % --- variables and declarations common to all trials
    
    winTol = 30;
    
    fixdur = 0.5; % how long to fixate on pre and post saccadic targets
    
    % fixation square left: 100pix ~ 10deg
    pixOffset = 50;
    fixSqLeft = [res.width/2-pixOffset-5, res.height/2-5, res.width/2-pixOffset, res.height/2]';
    fixSqRight = [res.width/2+pixOffset-5, res.height/2-5, res.width/2+pixOffset, res.height/2]';
    
    screenCoord_Left(1) = fixSqLeft(3) - centX;
    screenCoord_Left(2) = -(fixSqLeft(4) - centY);
    screenCoord_Right(1) = fixSqRight(3) - centX;
    screenCoord_Right(2) = -(fixSqRight(4) - centY);
    
    
    % this is be a good photodiode cell box
    photoSq = [0 0 30 30]';
    colorWhite = [255 255 255]'; % white color
    colorBlue = [0 0 255]'; % blue color
    
    baseLeft = [fixSqLeft photoSq];
    baseRight = [fixSqRight photoSq];
    baseStimcolors = [colorBlue colorWhite];
    
    
    stimoffsetW = round(res.width/2);
    stimoffsetH = round(res.height/2);
    % ---- starting trial loop
    
    % this will be used to store all flash locations
    % accumulate after every successful trial
    storeXlocs = [];
    storeYlocs = [];
    storeSuccess = 0;
    % show n stimuli combinations
    trl = 1;
    while trl <= ntrls && isRun
        
        disp(['Trl Number: ' num2str(trl)])
        
        % pulse dio on/off twice to signal start trial
        for i = 1:2, if isDaq, krStartTrial(dio); krEndTrial(dio); end, end
        
        % present fixation square
        Screen(window, 'FillRect', colorBlue, fixSqLeft);
        Screen(window, 'Flip');
        
        % wait of eye to enter fixation square to begin trial
        isInWindow = false;
        
        temptic = tic;
        while toc(temptic) < 3 % wait three seconds to enter fixation
            
            if isDaq
                try
                    [eyePosX eyePosY] = krGetEyePos(ai);
                catch
                    disp(['Missed Eye Pos Acquisition: ' num2str(trl)])
                end
            end
            
            if viewingFigure, updateViewingFigure(); end
            
            % check if within window
            if abs(eyePosX - screenCoord_Left(1)) < winTol && abs(eyePosY - screenCoord_Left(2)) < winTol
                isInWindow = true; % cue to begin wait period
                break % as soon as eye in window, break wait loop
            end
            
        end
        
        
        % if fixation has been acquired, begin flashing
        if isInWindow
            
            % accumulate flashes after each flash
            xFlashesIter = zeros(1, numstimthistrl);
            yFlashesIter = zeros(1, numstimthistrl);
            nf = 1;
            
            % successful fixation trial logic goes here
            if isDaq, krStartTrial(dio); krEndTrial(dio); end
            
            %% left fixation - phase 1 
            lefttic = tic;
            while toc(lefttic) < fixdur && isInWindow %left fixation
                
                if isDaq
                    try
                        [eyePosX eyePosY] = krGetEyePos(ai);
                    catch
                        disp(['Missed Eye Pos Acquisition: ' num2str(trl)])
                    end
                end
                
                if viewingFigure, updateViewingFigure(); end
                
                % check if within window
                if abs(eyePosX - screenCoord_Left(1)) < winTol && abs(eyePosY - screenCoord_Left(2)) < winTol
                    isInWindow = true; % cue to begin wait period
                else
                    isInWindow = false;
                end
                
                % ------ perform flashing targets here -----
                stims = [fixSqLeft photoSq];
                stimcolors = [colorBlue colorWhite];
                
                % generate nstim stimulus squares and not on the edges of the screen
                randXpos = randi([round(stimoffsetW/2) round(res.width - stimoffsetW/2)], 1, numstimthistrl);
                randYpos = randi([stimoffsetH/2 round(res.height - stimoffsetH/2)], 1, numstimthistrl);
                
                xFlashesIter(nf,:) = randXpos;
                yFlashesIter(nf,:) = randYpos;
                nf = nf + 1;
                
                for ni = 1:numstimthistrl
                    thisSq = [randXpos(ni)-10 randYpos(ni)-10 randXpos(ni) randYpos(ni)]';
                    stims = [stims thisSq];
                    stimcolors = [stimcolors colorWhite];
                end
                
                % draw fixation dot + all stimuli
                Screen(window, 'FillRect', stimcolors , stims);
                Screen(window, 'Flip');
                
                % leave stimulus on for short priod of time
                stimwaitdur = 0.05; % always 50ms
                thisstimdur = tic;
                while toc(thisstimdur) < stimwaitdur
                    if viewingFigure, updateViewingFigure(); end
                    % --- use this to acquire the triggers for online plotting 
                end
                
                blankDur = 0.1;
                % after stim duration, then blank screen (leave fixation) for 100ms
                Screen(window, 'FillRect', colorBlue, fixSqLeft);
                Screen(window, 'Flip');
                
                thisBlank = tic;
                while toc(thisBlank) < blankDur
                    if viewingFigure, updateViewingFigure(); end
                    % --- use this to acquire the triggers for online plotting 
                end
                % ------ end flashing targets segement -----
                
            end %left fixation
            
            %% Present Right Fixation (pre-saccade) - phase 2
            
            % present fixation square
            Screen(window, 'FillRect', colorBlue, fixSqRight); 
            Screen(window, 'Flip');
            % trigger pulse to denote new fixation target
            if isDaq, krStartTrial(dio); krEndTrial(dio); end
            
            
            sactic = tic; % allow for 300ms to enter new fixation window
            while toc(sactic) < 0.300
                
                % ------ perform flashing targets here -----
                stims = [fixSqRight photoSq];
                stimcolors = [colorBlue colorWhite];
                
                % generate nstim stimulus squares and not on the edges of the screen
                randXpos = randi([round(stimoffsetW/2) round(res.width - stimoffsetW/2)], 1, numstimthistrl);
                randYpos = randi([stimoffsetH/2 round(res.height - stimoffsetH/2)], 1, numstimthistrl);
                
                xFlashesIter(nf,:) = randXpos;
                yFlashesIter(nf,:) = randYpos;
                nf = nf + 1;
                
                for ni = 1:numstimthistrl
                    thisSq = [randXpos(ni)-10 randYpos(ni)-10 randXpos(ni) randYpos(ni)]';
                    stims = [stims thisSq];
                    stimcolors = [stimcolors colorWhite];
                end
                
                % draw fixation dot + all stimuli
                Screen(window, 'FillRect', stimcolors , stims);
                Screen(window, 'Flip');
                
                % leave stimulus on for short priod of time
                stimwaitdur = 0.05; % always 50ms
                thisstimdur = tic;
                while toc(thisstimdur) < stimwaitdur
                    if viewingFigure, updateViewingFigure(); end
                    % --- use this to acquire the triggers for online plotting 
                end
                
                blankDur = 0.1;
                % after stim duration, then blank screen (leave fixation) for 100ms
                Screen(window, 'FillRect', colorBlue, fixSqRight);
                Screen(window, 'Flip');
                
                thisBlank = tic;
                while toc(thisBlank) < blankDur
                    if viewingFigure, updateViewingFigure(); end
                    % --- use this to acquire the triggers for online plotting 
                end
                % ------ end flashing targets segement -----
                
            end
            
            %% Right Fixation - phase 3
            
            % trigger pulse to denote new phase
            if isDaq, krStartTrial(dio); krEndTrial(dio); end
            
            righttic = tic;
            while toc(righttic) < fixdur && isInWindow %right fixation
                
                if isDaq
                    try
                        [eyePosX eyePosY] = krGetEyePos(ai);
                    catch
                        disp(['Missed Eye Pos Acquisition: ' num2str(trl)])
                    end
                end
                
                if viewingFigure, updateViewingFigure(); end
                
                % check if within window
                if abs(eyePosX - screenCoord_Right(1)) < winTol && abs(eyePosY - screenCoord_Right(2)) < winTol
                    isInWindow = true; % cue to begin wait period
                else
                    isInWindow = false;
                end
                
                % ------ perform flashing targets here -----
                stims = [fixSqRight photoSq];
                stimcolors = [colorBlue colorWhite];
                
                % generate nstim stimulus squares and not on the edges of the screen
                randXpos = randi([round(stimoffsetW/2) round(res.width - stimoffsetW/2)], 1, numstimthistrl);
                randYpos = randi([stimoffsetH/2 round(res.height - stimoffsetH/2)], 1, numstimthistrl);
                
                xFlashesIter(nf,:) = randXpos;
                yFlashesIter(nf,:) = randYpos;
                nf = nf + 1;
                
                for ni = 1:numstimthistrl
                    thisSq = [randXpos(ni)-10 randYpos(ni)-10 randXpos(ni) randYpos(ni)]';
                    stims = [stims thisSq];
                    stimcolors = [stimcolors colorWhite];
                end
                
                % draw fixation dot + all stimuli
                Screen(window, 'FillRect', stimcolors , stims);
                Screen(window, 'Flip');
                
                % leave stimulus on for short priod of time
                stimwaitdur = 0.05; % always 50ms
                thisstimdur = tic;
                while toc(thisstimdur) < stimwaitdur
                    if viewingFigure, updateViewingFigure(); end
                    % --- use this to acquire the triggers for online plotting 
                end
                
                blankDur = 0.1;
                % after stim duration, then blank screen (leave fixation) for 100ms
                Screen(window, 'FillRect', colorBlue, fixSqRight);
                Screen(window, 'Flip');
                
                thisBlank = tic;
                while toc(thisBlank) < blankDur
                    if viewingFigure, updateViewingFigure(); end
                    % --- use this to acquire the triggers for online plotting 
                end
                % ------ end flashing targets segement -----
                
                
            end %right fixation
            
        end %if successful fixation
        
        Screen(window, 'FillRect', black); Screen(window, 'Flip');
        
        % triple pulse to signify end of trial
        for i = 1:3, if isDaq, krStartTrial(dio); krEndTrial(dio); end, end
        
        if isInWindow
            
            if isDaq, krDeliverReward(dio,5); end
            
            % collect flashes
            storeXlocs = [storeXlocs; xFlashesIter]; %#ok
            storeYlocs = [storeYlocs; yFlashesIter]; %#ok
            storeSuccess(trl) = trl;
            
        else
            % failed trial
            storeSuccess(trl) = 0;
            WaitSecs(2);
        end
        
        
        
        if mod(trl,10) == 0
            save(fName, 'storeXlocs', 'storeYlocs','storeSuccess')
        end
        
        
        trl = trl + 1;
    end % ntrials
    
   
catch lasterr
    
    ShowCursor
    Screen('CloseAll');
    if isDaq, krEndTrial(dio); end
    save(fName, 'storeXlocs', 'storeYlocs','storeSuccess')
    disp(fName)
    keyboard
end


Screen('CloseAll');
if isDaq, krEndTrial(dio); end
save(fName, 'storeXlocs', 'storeYlocs','storeSuccess')
Priority(0);


keyboard
end % function