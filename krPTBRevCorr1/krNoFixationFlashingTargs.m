function krNoFixationFlashingTargs()
% testing psychtoolbox screen command

clc, clear

try
    [ai, dio] = krConnectDAQ();
    isDaq = true;
catch %#ok<*CTCH>
    disp('no daq')
    isDaq = false;
end


% remember to clear this out for real experiments
Screen('Preference', 'SkipSyncTests', 0);

whichScreen = 2;
res = Screen('Resolution',whichScreen);
centX = res.width/2;
centY = res.height/2;

numstimthistrl = 2;

viewingFigure = true;
if viewingFigure
    % now open up a second matlab figure to be used to view eye position
    figure(2), clf
    axis([-res.width/2 res.width/2 -res.height/2 res.height/2]);
    hold on
    rectangle('Position', [0 0 10 10], 'FaceColor', 'black'); % center of the screen
    hEye = rectangle('Position', [0, 0 25 25],'FaceColor','red'); %<- note, x,y,w,h as opposed to PTB's convention
    for numtargsi = 1:numstimthistrl
        hTargs(numtargsi) = rectangle('Position', [0, 0 10 10],'FaceColor','white'); %#ok
    end
    set(gca, 'color', 'none')
end

    function updateViewingFigure()
        try
            set(hEye, 'Position', [eyePosX eyePosY 25 25]); %note this different convention
            for drawi = 1:numstimthistrl 
               set(hTargs(drawi), 'Position', [randXpos(drawi)-centX -(randYpos(drawi)-centY) 10 10]) 
            end
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
    
    black = BlackIndex(window); % pixel value for black
    
    % wipe screen & fill bac
    Screen(window, 'FillRect', black);
    Screen(window, 'Flip');
    
    
    ntrls = 10;
    
    % --- variables and declarations common to all trials
        
    % this is be a good photodiode cell box
    photoSq = [0 0 30 30]';
    colorWhite = [255 255 255]'; % white color
    
    stimoffsetW = round(res.width/3);
    stimoffsetH = round(res.height/3);
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
        
        
        xFlashesIter = nan(numflashes,numstimthistrl);
        yFlashesIter = nan(numflashes,numstimthistrl);
        
        
        for nf = 1:numflashes
            
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
            
            % --------------------------
            
            % we'd like to create a flash of stimuli relative to where the
            % eye is so that we account for any biases in gaze. The goal is
            % to get an even sampling of space around the fovea
            
            % the eye data in eye coordinates. Convert to screen
            % coordinates generate an appropriate set of stimuli
            screenEX = round(eyePosX + centX);
            screenEY = round(-eyePosY + centY);
            
            % choose one of four quadrants 
            
            try % sometimes she looks off the edge of the screen so just be careful about that 
                
                for nsti = 1:numstimthistrl

                    quad = randi(4);

                    if quad == 1 %top left of eye
                        randXpos(1,nsti) = randi([round(stimoffsetW/2) screenEX], 1, 1); % left
                        randYpos(1,nsti) = randi([round(stimoffsetH/2) screenEY], 1, 1); % above
                    elseif quad == 2 % top right of eye
                        randXpos(1,nsti) = randi([screenEX round(res.width - stimoffsetW/2)], 1, 1); % right
                        randYpos(1,nsti) = randi([round(stimoffsetH/2) screenEY], 1, 1); % above
                    elseif quad == 3 % bottom left of eye
                        randXpos(1,nsti) = randi([round(stimoffsetW/2) screenEX], 1, 1); % left
                        randYpos(1,nsti) = randi([screenEY round(res.height - stimoffsetH/2)], 1, 1); % below
                    else % bottom right
                        randXpos(1,nsti) = randi([screenEX round(res.width - stimoffsetW/2)], 1, 1); % right
                        randYpos(1,nsti) = randi([screenEY round(res.height - stimoffsetH/2)], 1, 1); % below
                    end
                    
                end
            catch
                % generate nstim stimulus squares and not on the edges of the screen
                randXpos = randi(res.width - stimoffsetW, 1, numstimthistrl) + stimoffsetW/2;
                randYpos = randi(res.height - stimoffsetH, 1, numstimthistrl) + stimoffsetH/2;
            end
            
            xFlashesIter(nf,:) = randXpos;
            yFlashesIter(nf,:) = randYpos;
            
            
            stims = [photoSq];
            stimcolors = [colorWhite];
            
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
            
            thisdur = tic;
            while toc(thisdur) < stimwaitdur
                if viewingFigure, updateViewingFigure(); end
            end
            
            
            blankDur = 0.1; 
            % after stim duration, then blank screen (leave fixation) for 100ms
            Screen(window, 'FillRect', black);
            Screen(window, 'Flip');
            
            thisBlank = tic;
            while toc(thisBlank) < blankDur
                if viewingFigure, updateViewingFigure(); end
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
    
    
catch 
    
    ShowCursor
    Screen('CloseAll');
    if isDaq, krEndTrial(dio); end
    save(fName, 'storeXlocs', 'storeYlocs')
    disp(fName)
    disp(lasterr) %#ok
    keyboard
end

if isDaq, krEndTrial(dio); end
Screen('CloseAll');
save(fName, 'storeXlocs', 'storeYlocs')
Priority(0);

keyboard

end %function