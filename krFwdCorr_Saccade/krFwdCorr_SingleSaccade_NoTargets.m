function krFwdCorr_SingleSaccade_NoTargets()

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


ntrls = 200; % total number of trials requested

viewingFigure = true;
if viewingFigure
    % now open up a second matlab figure to be used to view eye position
    fig = figure(2); clf
    axis([-res.width/2 res.width/2 -res.height/2 res.height/2]);
    hold on
    rectangle('Position', [0 0 10 10], 'FaceColor', 'black'); % center of the screen
    hEye = rectangle('Position', [0, 0 25 25],'FaceColor','red'); %<- note, x,y,w,h as opposed to PTB's convention
    set(gca, 'color', 'none')
    
    % this is for the easy ending of programs
    uicontrol('Parent',fig,'Style','pushbutton','String','End Task','Callback',@cb_EndTask,'Position',[450 350 60 20]);
    drawnow
end

    function updateViewingFigure()
        try
            set(hEye, 'Position', [eyePosX eyePosY 25 25]); %note this different convention
            drawnow
        end
    end

    function cb_EndTask(~,~)
        isRun = false;
    end

isRun = true;

% data to be stored into this filename
c = clock;
fName = ['sacNoTarg_' date '-' num2str(c(4)) num2str(c(5))]; % date and hour and min

Priority(2);
try
    HideCursor;
    window = Screen(whichScreen, 'OpenWindow');
    ShowCursor;
    
    black = BlackIndex(window); % pixel value for black
    
    % wipe screen & fill bac
    Screen(window, 'FillRect', black);
    Screen(window, 'Flip');
    
    WaitSecs(1); % just to let the photdiode settle.
    
    % --- variables and declarations common to all trials
    
    winTol = 30;
    
    % fixation square left: 100pix ~ 10deg
    pixOffset = 50;
    fixSqLeft = [res.width/2-pixOffset-5, res.height/2-5, res.width/2-pixOffset, res.height/2]';
    fixSqRight = [res.width/2+pixOffset-5, res.height/2-5, res.width/2+pixOffset, res.height/2]';
    
    screenCoord_Left(1) = fixSqLeft(3) - centX;
    screenCoord_Left(2) = -(fixSqLeft(4) - centY);
    screenCoord_Right(1) = fixSqRight(3) - centX;
    screenCoord_Right(2) = -(fixSqRight(4) - centY);
    
    
    % fixation color
    colorBlue = [0 0 255]'; % blue color
    
    % ---- starting trial loop
    
    % storeSuccess
    storeSuccess = zeros(ntrls, 1);
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
        
        
        % check if fixation failed
        if isInWindow
            
            % successful fixation trial logic goes here
            if isDaq, krStartTrial(dio); krEndTrial(dio); end
            
            lefttic = tic;
            while toc(lefttic) < 0.75 && isInWindow %left fixation
                
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
                
            end %left fixation
            
            % present fixation square
            Screen(window, 'FillRect', colorBlue, fixSqRight); 
            Screen(window, 'Flip');
            % trigger pulse to denote new fixation target
            if isDaq, krStartTrial(dio); krEndTrial(dio); end
            
            
            sactic = tic; % allow for 300ms to enter new fixation window
            while toc(sactic) < 0.300
                % --- flashing targets here
            end
            
            
            righttic = tic;
            while toc(righttic) < 0.75 && isInWindow %right fixation
                
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
                
            end %right fixation
            
        end %if successful fixation
        
        Screen(window, 'FillRect', black); Screen(window, 'Flip');
        
        % triple pulse to signify end of trial
        for i = 1:3, if isDaq, krStartTrial(dio); krEndTrial(dio); end, end
        
        if isInWindow
            if isDaq, krDeliverReward(dio,3); end
            storeSuccess(trl) = trl;
        else
            WaitSecs(2);
        end
        
        
        
        if mod(trl,10) == 0
            save(fName,'storeSuccess')
        end
        
        
        trl = trl + 1;
    end % ntrials
    
   
catch lasterr
    
    ShowCursor
    Screen('CloseAll');
    if isDaq, krEndTrial(dio); end
    save(fName,'storeSuccess')
    disp(fName)
    keyboard
end


Screen('CloseAll');
if isDaq, krEndTrial(dio); end
save(fName, 'storeSuccess')
Priority(0);


keyboard
end % function