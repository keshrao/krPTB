function krDir(ntrls)
if isempty(ntrls)
    ntrls = 300;
end
distvar = 10;

try
    [ai, dio] = krConnectDAQ();
    isDaq = true;
catch MException;
    disp('no daq')
    isDaq = false;
end


Priority(2); % realtime priority

% remember to clear this out for real experiments
Screen('Preference', 'SkipSyncTests', 0);

whichScreen = 2;
res = Screen('Resolution',whichScreen);

centX = res.width/2;
centY = res.height/2;

ssq = 10; % size of square
sq = nan(4,9);

generateTableSquares(distvar)

    function generateTableSquares(distvar)
        
        distbet = res.width./distvar; % distance between squares
        
        % generate an array of squares - columns
        sq(:,1) = [centX-distbet-ssq  centY-distbet-ssq centX-distbet   centY-distbet];
        sq(:,2) = [centX-ssq          centY-distbet-ssq centX           centY-distbet];
        sq(:,3) = [centX+distbet-ssq  centY-distbet-ssq centX+distbet   centY-distbet];
        
        sq(:,4) = [centX-distbet-ssq  centY-ssq         centX-distbet   centY];
        % for dir, don't need center square
        sq(:,5) = [centX-ssq          centY-ssq         centX           centY]; % center
        sq(:,6) = [centX+distbet-ssq  centY-ssq         centX+distbet   centY];
        
        sq(:,7) = [centX-distbet-ssq  centY+distbet-ssq centX-distbet   centY+distbet];
        sq(:,8) = [centX-ssq          centY+distbet-ssq centX           centY+distbet];
        sq(:,9) = [centX+distbet-ssq  centY+distbet-ssq centX+distbet   centY+distbet];
        
        
        allLocsPos = [  centX-distbet   centY-distbet;
                        centX           centY-distbet;
                        centX+distbet   centY-distbet;

                        centX-distbet   centY;
                        centX           centY;
                        centX+distbet   centY;

                        centX-distbet   centY+distbet;
                        centX           centY+distbet;
                        centX+distbet   centY+distbet; ];
        
    end

colorBlue = [0; 0; 255];
colorwhite = [255; 255; 255];
photocell = [0; 0; 50; 50;];

% data to be stored into this filename
c = clock;
fName = ['dir_' date '-' num2str(c(4)) num2str(c(5))]; % date and hour and min

winTol = 60;


viewingFigure = true;
if viewingFigure
    % now open up a second matlab figure to be used to view eye position
    fig = figure(2); clf
    axis([-res.width/2 res.width/2 -res.height/2 res.height/2]);
    hold on
    rectangle('Position', [0 0 10 10], 'FaceColor', 'black'); % center of the screen
    hFix = rectangle('Position', [0, 0 25 25],'FaceColor','blue'); %<- note, x,y,w,h as opposed to PTB's convention
    hEye = rectangle('Position', [0, 0 25 25],'FaceColor','red');
    axis off    
    
    % this is for the easy ending of programs
    uicontrol('Parent',fig,'Style','pushbutton','String','End Task','Callback',@cb_EndTask,'Position',[450 350 60 20]);
    drawnow
    
end

    function updateViewingFigure()
        try
            
            set(hFix, 'Position', [sq(3,indLoc)-centX -(sq(4, indLoc)-centY) 25 25]);
            set(hEye, 'Position', [eyePosX eyePosY 25 25]); %note this different convention
            drawnow
            
        catch
            % don't want the program to crash if something happens to a figure
        end
    end


    function cb_EndTask(~,~)
        dbstop if error
        ShowCursor
        Screen('CloseAll');
        if isDaq, krEndTrial(dio); end
        %save(fName, 'storeXlocs', 'storeYlocs','storeSuccess')
        %disp(fName)
        error('Manually Stopped Program. Remember to Save File')
    end

% ---- PTB segment
try
    
    HideCursor;
    window = Screen(whichScreen, 'OpenWindow');
    ShowCursor;
    
    black = BlackIndex(window); % pixel value for black
    

    
    prevLoc = 0;
    indLoc = 1;
    
    storeLocs = nan(ntrls,2); % save the location of stimuli
    storeSuccesses = zeros(ntrls, 1);
    successCount = 0;
    
    % reset states
    if isDaq, krEndTrial(dio); end
    
    for trls = 1:ntrls
        % wipe screen & fill back
        Screen(window, 'FillRect', black); Screen(window, 'Flip');
        
        % select random location
        while indLoc == prevLoc % because that's the center square
            indLoc = randi(9);
        end
        prevLoc = indLoc;
        
        % deal with scaling difference
        thisPos = allLocsPos(indLoc,:); % x/y position of target
        % subtract out the screen offset bias & scaling
        thisPos(1) = thisPos(1) - centX;
        thisPos(2) = -(thisPos(2) - centY);
        
        % ----------------- start --------------------------- %
        
        disp(['Trl Number: ' num2str(trls)])
        % present fixation square
        Screen(window, 'FillRect', colorBlue, sq(:,5));
        Screen(window, 'Flip');
        
        % wait of eye to enter fixation square to begin trial
        isInWindow = false;
        fixtic = tic;
        
        while toc(fixtic) < 3 % wait three seconds to enter fixation
            
            if isDaq
                try
                    [eyePosX eyePosY] = krGetEyePos(ai);
                catch
                    disp(['Missed Eye Pos Acquisition: ' num2str(trls)])
                end
            else
                [eyePosX,eyePosY] = GetMouse(window);
                eyePosX = eyePosX - centX;
                eyePosY = eyePosY - centY;
            end
            
            if viewingFigure, updateViewingFigure(); end
            
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
            storeSuccess(trls) = 0;
            if isDaq, krEndTrial(dio); end
            WaitSecs(2);
            
        else
            
            % continue the trial now that fixation is acquired
            if isDaq, krStartTrial(dio); end

            storeLocs(trls,:) = [thisPos(1), thisPos(2)]; % these two to be saved later
            
            % once fixation is acquired, hold fixation for 300 ms
            WaitSecs(0.3);
            % draw target and photocell
            Screen(window, 'FillRect', [colorwhite colorwhite], [sq(:,indLoc) photocell]);
            Screen(window, 'Flip');
            
            
            % give it another 500 seconds to get into target zone
            WaitSecs(0.5);
            
            
            % successful fixation
            temptic = tic;
            
            while toc(temptic) < 0.5 && isInWindow % maintin fix for 1 sec
                
                if isDaq
                    try
                        [eyePosX eyePosY] = krGetEyePos(ai);
                    catch
                        disp(['Missed Eye Pos Acquisition: ' num2str(trls)])
                    end
                else
                    [eyePosX,eyePosY] = GetMouse(window);
                    eyePosX = eyePosX - centX;
                    eyePosY = eyePosY - centY;
                end
                
                if viewingFigure, updateViewingFigure(); end
                
                if abs(eyePosX - thisPos(1)) < winTol && abs(eyePosY - thisPos(2)) < winTol
                    isInWindow = true; % cue to begin wait period
                else
                    isInWindow = false;
                end
                
            end %while fixating on target
            
            
            
        end % presentation of trial 
        
        Screen(window, 'FillRect', black); Screen(window, 'Flip');
        
        % check if fixation failed
        if ~isInWindow
            if isDaq, krEndTrial(dio);end
        else
            WaitSecs(0.5);
            if isDaq, krEndTrial(dio);end
            WaitSecs(0.5);
            if isDaq, krDeliverReward(dio,2);end
            storeSuccesses(trls) = trls;
            successCount = successCount+1;
            WaitSecs(1);
        end
        
        
        if mod(trls,20) == 0
            save(fName, 'storeLocs','storeSuccesses')
        end
        
        if isDaq, krEndTrial(dio); end
    end
    
catch MException;
    
    ShowCursor;
    Screen('CloseAll');
    save(fName, 'storeLocs','storeSuccesses')
    close all
    
    disp(MException.message)
    
end

if isDaq, krEndTrial(dio);end
save(fName, 'storeLocs','storeSuccesses')
ShowCursor;
Screen('CloseAll');



end