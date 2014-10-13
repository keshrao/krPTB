function krDirRequestable()

distvar = 10;
warning off

try
    [ai, dio] = krConnectDAQTrigger();
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

winTol = 30;


viewingFigure = true;
if viewingFigure
    % now open up a second matlab figure to be used to view eye position
    fig2 = figure(2); clf
    axis([-res.width/2 res.width/2 -res.height/2 res.height/2]);
    hold on
    rectangle('Position', [0 0 10 10], 'FaceColor', 'black'); % center of the screen
    hFix = rectangle('Position', [0, 0 25 25],'FaceColor','blue'); %<- note, x,y,w,h as opposed to PTB's convention
    hEye = rectangle('Position', [0, 0 25 25],'FaceColor','red');
    axis off    
    
    
    % this is for the easy ending of programs
    uicontrol('Parent',fig2,'Style','pushbutton','String','End Task','Callback',@cb_EndTask,'Position',[450 350 60 20]);
    drawnow
    
    
    fig3 = figure(3); clf;
    hTune = plot(zeros(9,1), 'o','MarkerSize',3);
    set(gca, 'XTick', 1:9, 'XTickLabel',{'UL', 'U','UR','L','M','R','DL','D','DR'})
    xlim([0 10])
    ylim([-1 10])
    
    uicontrol('Parent',fig3,'Style','pushbutton','String','UL','Callback',@cb_UL,'Position',[100 300 20 20]);
    uicontrol('Parent',fig3,'Style','pushbutton','String','U','Callback',@cb_U,'Position',  [150 300 20 20]);
    uicontrol('Parent',fig3,'Style','pushbutton','String','UR','Callback',@cb_UR,'Position',[200 300 20 20]);
    uicontrol('Parent',fig3,'Style','pushbutton','String','L','Callback',@cb_L,'Position',  [250 300 20 20]);
    uicontrol('Parent',fig3,'Style','pushbutton','String','M','Callback',@cb_M,'Position',  [290 300 20 20]);
    uicontrol('Parent',fig3,'Style','pushbutton','String','R','Callback',@cb_R,'Position',  [330 300 20 20]);
    uicontrol('Parent',fig3,'Style','pushbutton','String','DL','Callback',@cb_DL,'Position',[370 300 20 20]);
    uicontrol('Parent',fig3,'Style','pushbutton','String','D','Callback',@cb_D,'Position',  [410 300 20 20]);
    uicontrol('Parent',fig3,'Style','pushbutton','String','DR','Callback',@cb_DR,'Position',[450 300 20 20]);
    
    drawnow
    
end

    function cb_UL (~,~), isRequested = true; indLoc = 1; prevLoc = indLoc; end
    function cb_U (~,~), isRequested = true; indLoc = 2; prevLoc = indLoc; end
    function cb_UR (~,~), isRequested = true; indLoc = 3; prevLoc = indLoc; end
    function cb_L (~,~), isRequested = true; indLoc = 4; prevLoc = indLoc; end
    function cb_M (~,~), isRequested = true; indLoc = 5; prevLoc = indLoc; end
    function cb_R (~,~), isRequested = true; indLoc = 6; prevLoc = indLoc; end
    function cb_DL (~,~), isRequested = true; indLoc = 7; prevLoc = indLoc; end
    function cb_D (~,~), isRequested = true; indLoc = 8; prevLoc = indLoc; end
    function cb_DR (~,~), isRequested = true; indLoc = 9; prevLoc = indLoc; end
    

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
        isRun = false;
    end

isRun = true;
isRequested = false;

% ---- PTB segment
try
    
    window = Screen(whichScreen, 'OpenWindow');
    
    black = BlackIndex(window); % pixel value for black
    
    ntrls = 300;
    
    prevLoc = 0;
    indLoc = 1;
    
    storeLocs = nan(ntrls,2); % save the location of stimuli
    storeSuccesses = zeros(ntrls, 1);
    storeDistVar = nan(ntrls,1);
    successCount = 0;
    
    plottuning = zeros(9,1); % just add the num peaks to appropriate location
    plottrls = zeros(9,1); % to normalize firing rates
    
    % reset states
    if isDaq, krEndTrial(dio); end
    
    disp(fName)

    
    trls = 1;
    while trls <= ntrls && isRun
        
        distvar = randi([6 12],1,1);
        generateTableSquares(distvar)
        
        if distvar <= 8
            winTol = 50;
        else
            winTol = 30;
        end
        
        % wipe screen & fill back
        Screen(window, 'FillRect', black); Screen(window, 'Flip');
        
        % select random location
        if ~isRequested 
            while indLoc == prevLoc % because that's the center square
                indLoc = randi(9);
            end
            prevLoc = indLoc;
        else
            isRequested = false;
        end
            
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
        
        set(hFix, 'visible', 'off')
        
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
            temptic = tic;
            while toc(temptic) < 0.5
                try
                    [eyePosX eyePosY] = krGetEyePos(ai);
                end
                if viewingFigure, updateViewingFigure(); end
            end
                        
            % draw target and photocell
            Screen(window, 'FillRect', [colorwhite colorwhite], [sq(:,indLoc) photocell]);
            Screen(window, 'Flip');
            set(hFix, 'visible', 'on')
            
            % give it another .300 seconds to get into target zone
            getspikesonce = false;
            numPeaks = 0;
            
            temptic = tic;
            while toc(temptic) < 0.300
                if ~getspikesonce 
                    try
                        trigtic = tic;
                        numPeaks = krTriggers(ai, 0.2); % capture 200ms after onset of stimulus
                        trigtime = toc(trigtic);
                    end
                    getspikesonce = true;
                end
                
                try
                    [eyePosX eyePosY] = krGetEyePos(ai);
                end
                if viewingFigure, updateViewingFigure(); end
                
                
            end
            
           
            % successful fixation
            temptic = tic;
            
            while toc(temptic) < 0.3 && isInWindow % maintin fix for 0.5 sec
                
                if isDaq
                    try
                        [eyePosX eyePosY] = krGetEyePos(ai);
                    catch
                        disp(['Missed Eye Pos Acquisition: ' num2str(trls)])
                    end
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
        set(hFix, 'visible', 'off')
        
        % check if fixation failed
        if ~isInWindow
            if isDaq, krEndTrial(dio);end
            WaitSecs(1);
        else
            WaitSecs(0.5);
            if isDaq, krEndTrial(dio);end
            WaitSecs(0.5);
            if isDaq, krDeliverReward(dio,2);end
            
            
            plottuning(indLoc) = plottuning(indLoc) + numPeaks;
            plottrls(indLoc) = plottrls(indLoc) + 1;
            try
                set(hTune, 'ydata', plottuning./plottrls);
                %ylim([-1 max(plottuning./plottrls)+3])
            end
            
            %fprintf('Time Spent in Trigger: %f. \n', trigtime)
            
            storeSuccesses(trls) = trls;
            storeDistVar(trls) = distvar;
            successCount = successCount+1;
            WaitSecs(1);

        end
        
        
        if mod(trls,20) == 0
            save(fName, 'storeLocs','storeSuccesses', 'storeDistVar')
        end
        
        if isDaq, krEndTrial(dio); end
        
        trls = trls + 1;
    end
    
catch MException;
    
    ShowCursor;
    Screen('CloseAll');
    save(fName, 'storeLocs','storeSuccesses', 'storeDistVar')
    close all
    
    disp(MException.message)
    keyboard
    
end

if isDaq, krEndTrial(dio);end
disp(fName)
save(fName, 'storeLocs','storeSuccesses', 'storeDistVar')
ShowCursor;
Screen('CloseAll');

keyboard

end