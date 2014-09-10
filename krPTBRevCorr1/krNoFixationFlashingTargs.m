function krNoFixationFlashingTargs()
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

viewingFigure = true;
if viewingFigure
    % now open up a second matlab figure to be used to view eye position
    figure(2), clf
    axis([-res.width/2 res.width/2 -res.height/2 res.height/2]);
    hold on
    rectangle('Position', [0 0 10 10], 'FaceColor', 'black'); % center of the screen
    hEye = rectangle('Position', [0, 0 25 25],'FaceColor','red'); %<- note, x,y,w,h as opposed to PTB's convention
    axis off
end

    function updateViewingFigure()
        try
            set(hEye, 'Position', [eyePosX eyePosY 25 25]); %note this different convention
            drawnow
            % don't want the program to crash if something happens to a figure
        end
    end

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
    Screen(window, 'Flip');
    
    
    ntrls = 50;
    
    % --- variables and declarations common to all trials
    
    winTol = 30;
    
    % this is be a good photodiode cell box
    photoSq = [0 0 30 30]';
    colorWhite = [255 255 255]'; % white color
    
    stimoffsetW = round(res.width/5);
    stimoffsetH = round(res.height/5);
    % ---- starting trial loop
    
    % this will be used to store all flash locations
    storeXlocs = [];
    storeYlocs = [];
    
    % show n stimuli combinations
    for trl = 1:ntrls
        
        disp(['Trl Number: ' num2str(trl)])
        
        % successful fixation trial logic goes here
        if isDaq, krStartTrial(dio); end
        
        % begin series of stimuli flashes
        numflashes = 25;
        
        
        numstimthistrl = 2;
        xFlashesIter = nan(numflashes,numstimthistrl);
        yFlashesIter = nan(numflashes,numstimthistrl);
        
        
        for nf = 1:numflashes
            
            % how many stimuli do I want to create - for now , always 2
            % numstimthistrl = randi([1 5], 1);
            
            
            % make sure still in window
            if isDaq
                try
                    [eyePosX eyePosY] = krGetEyePos(ai);
                catch
                    disp(['Missed Eye Pos Acquisition: ' num2str(trl)])
                end
            else
                [eyePosX,eyePosY] = GetMouse(window);
                eyePosX = eyePosX - centX;
                eyePosY = eyePosY - centY;
            end
            
            if viewingFigure, updateViewingFigure(); end
            
            % --------------------------
            
            
            stims = [photoSq];
            stimcolors = [colorWhite];
            
            
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
            stimwaitdur = 0.05; % always 50ms
            %rand/10; %<- uniformly distributed between 0 & 100ms
            
            % note that if stimwaitdur < 0.016, then it's just waiting one
            % frame
            thisdur = tic;
            while toc(thisdur) < stimwaitdur
                % some code
            end
            
            
            blankDur = 0.1;
            % after stim duration, then blank screen (leave fixation) for 100ms
            Screen(window, 'FillRect', black);
            Screen(window, 'Flip');
            
            thisBlank = tic;
            while toc(thisBlank) < blankDur
                % some code
            end
            
            
        end %nflahses
        
        % collect flashes
        storeXlocs = [storeXlocs; xFlashesIter]; %#ok
        storeYlocs = [storeYlocs; yFlashesIter]; %#ok
        
        % wipe screen & fill bac
        Screen(window, 'FillRect', black);
        Screen(window, 'Flip');
        
        if isDaq, krEndTrial(dio); end
        
        WaitSecs(2);
        if isDaq, krDeliverReward(dio, 4); end
        WaitSecs(2);
        
        if mod(trl,5) == 0
            save(fName, 'storeXlocs', 'storeYlocs')
        end
        
    end % ntrials
    
    
catch %#ok
    
    ShowCursor
    Screen('CloseAll');
    if isDaq, krEndTrial(dio); end
    save(fName, 'storeXlocs', 'storeYlocs')
    disp(fName)
    keyboard
end

if isDaq, krEndTrial(dio); end
Screen('CloseAll');
save(fName, 'storeXlocs', 'storeYlocs')
Priority(0);

keyboard

end %function