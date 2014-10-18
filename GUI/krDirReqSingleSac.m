function krDirReqSingleSac(ntrls,handles)

if isempty(ntrls)
    ntrls = 300;
end
distvar = 10;
warning off

ai = handles.ai;
dio = handles.dio;
isDaq = true;
%%
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

viewingFigure = true;
if viewingFigure
    % now open up a second matlab figure to be used to view eye position
    axes(handles.EyePosition);cla;
    axis([-res.width/2 res.width/2 -res.height/2 res.height/2]);
    hold on
    rectangle('Position', [0 0 10 10], 'FaceColor', 'black'); % center of the screen
    hFix = rectangle('Position', [0, 0 25 25],'FaceColor','blue'); %<- note, x,y,w,h as opposed to PTB's convention
    hTarg = rectangle('Position', [0, 0 25 25],'FaceColor','cyan');
    hEye = rectangle('Position', [0, 0 25 25],'FaceColor','red');
    axis off    
    
    
    % this is for the easy ending of programs
    uic(1) = uicontrol('Style','pushbutton','String','End Task','Callback',@cb_EndTask,'Position',[400 350 60 20]);
    drawnow
    
    axes(handles.TaskSpecificPlot);cla;
    hTune = plot(zeros(9,1), 'o','MarkerSize',3);
    set(gca, 'XTick', 1:9, 'XTickLabel',{'UL', 'U','UR','L','M','R','DL','D','DR'})
    xlim([0 10])
    ylim([-1 10])
    
    uic(2) = uicontrol('Style','pushbutton','String','UL','Callback',@cb_UL,'Position',[550 300 20 20]);
    uic(3) = uicontrol('Style','pushbutton','String','U','Callback',@cb_U,'Position',  [600 300 20 20]);
    uic(4) = uicontrol('Style','pushbutton','String','UR','Callback',@cb_UR,'Position',[650 300 20 20]);
    uic(5) = uicontrol('Style','pushbutton','String','L','Callback',@cb_L,'Position',  [690 300 20 20]);
    uic(6) = uicontrol('Style','pushbutton','String','M','Callback',@cb_M,'Position',  [730 300 20 20]);
    uic(7) = uicontrol('Style','pushbutton','String','R','Callback',@cb_R,'Position',  [770 300 20 20]);
    uic(8) = uicontrol('Style','pushbutton','String','DL','Callback',@cb_DL,'Position',[810 300 20 20]);
    uic(9) = uicontrol('Style','pushbutton','String','D','Callback',@cb_D,'Position',  [850 300 20 20]);
    uic(10) = uicontrol('Style','pushbutton','String','DR','Callback',@cb_DR,'Position',[890 300 20 20]);
    
    drawnow
    
end

    function cb_UL (~,~), isRequested = true; indLoc = 1; end
    function cb_U (~,~), isRequested = true; indLoc = 2;  end
    function cb_UR (~,~), isRequested = true; indLoc = 3; end
    function cb_L (~,~), isRequested = true; indLoc = 4; end
    function cb_M (~,~), isRequested = true; indLoc = 5; end
    function cb_R (~,~), isRequested = true; indLoc = 6; end
    function cb_DL (~,~), isRequested = true; indLoc = 7; end
    function cb_D (~,~), isRequested = true; indLoc = 8; end
    function cb_DR (~,~), isRequested = true; indLoc = 9; end

% all fot his for psth construction

% the corresponding subplot number = subpcorr(prevLoc);
figure(2), clf
subpcorr = [1 2 3 4 5 6 7 8 9];
prow = ones(9,1); % number of saccades in 8 cardinal directions

% bin data into 5ms bins & determine firing rate
sacpre = 0.3;
sacpost = 0.3;
binwidth = 0.001;
bins = -sacpre:binwidth:sacpost;

figure(2), clf
for subp = 1:9
    subplot(3,3,subp), hold on
    plot([0 0], [0 15], 'b', 'LineWidth', 1.5)
	hPSTH(subp) = plot(bins(1:end-1)+(binwidth/2), ones(length(bins)-1,1), 'r', 'LineWidth', 1.5);
end

% store all the spikes for psth construction
for ti = 1:9, totRelSpks{ti} = []; end



    function updateViewingFigure()
        try
            set(hFix, 'Position', [sq(3,indLoc)-centX -(sq(4, indLoc)-centY) 25 25]);
            set(hTarg, 'Position', [sq(3,indLoc)-centX -(sq(4, indLoc)-centY) 25 25]);
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

    trl = 1;
    while trl <= ntrls && isRun
        
        fprintf('\n')
        
        distvar = randi([6 15],1,1);
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
        
        set(handles.TrialNumber,'String',num2str(trl));
        % present fixation square
        Screen(window, 'FillRect', colorBlue, sq(:,5));
        Screen(window, 'Flip');
        
        % wait of eye to enter fixation square to begin trial
        isInWindow = false;
        fixtic = tic;
        
        set(hFix, 'visible', 'off')
        set(hTarg, 'visible', 'off')
                
        while toc(fixtic) < 3 % wait three seconds to enter fixation
            
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
            storeSuccess(trl) = 0;
            if isDaq, krEndTrial(dio); end
            WaitSecs(2);
            
        else
            set(hFix, 'visible', 'on')
            % continue the trial now that fixation is acquired
            if isDaq, krStartTrial(dio); end

            storeLocs(trl,:) = [thisPos(1), thisPos(2)]; % these two to be saved later
            
            % once fixation is acquired, hold fixation for random period ms
            % 300 - 500 ms
            
            prefixtic = tic;
            while toc(prefixtic) < 0.4 + (rand/5 - 0.1) && isInWindow
                try
                    [eyePosX eyePosY] = krGetEyePos(ai);
                end
                if viewingFigure, updateViewingFigure(); end
                
                if abs(eyePosX) < winTol && abs(eyePosY) < winTol
                    isInWindow = true; % cue to begin wait period
                else
                    isInWindow = false;
                end
            end
            
            if isInWindow
                % draw target and photocell
                
                Screen(window, 'FillRect', [colorwhite colorwhite], [sq(:,indLoc) photocell]);
                Screen(window, 'Flip');
                fprintf('End Fix: %0.3f \n', toc(prefixtic)),
                
                set(hTarg, 'visible', 'on')
                set(hFix, 'visible', 'off')
            end
            
            
            if isInWindow % but no checking of window during the saccade
                % give it another .300 seconds to get into target zone
                getspikesonce = false;

                sactic = tic;
                while toc(sactic) < 0.3
                    if ~getspikesonce 
                        try
                            trigtic = tic;
                            [data, time, saclocs] = krFullEyePosTrigs(ai, 0.25); 
                            trigtime = toc(trigtic);
                        end
                        getspikesonce = true;
                        %fprintf('Trig Time: %d\n',trigtime);
                    end
                end


                if length(saclocs) > 1
                    % multiple saccades made 
                    isInWindow = false;
                end
                fprintf('End Saccade: %0.3f \n', toc(sactic))
            end
            
            % successful fixation
            postfixtic = tic;
            while toc(postfixtic) < 0.15 && isInWindow % maintin fix for 0.5 sec
                
                if isDaq
                    try
                        [eyePosX eyePosY] = krGetEyePos(ai);
                    catch
                        disp(['Missed Eye Pos Acquisition: ' num2str(trl)])
                    end
                end
                
                if viewingFigure, updateViewingFigure(); end
                
                if abs(eyePosX - thisPos(1)) < winTol && abs(eyePosY - thisPos(2)) < winTol
                    isInWindow = true; % cue to begin wait period
                else
                    isInWindow = false;
                end
                fprintf('End Post Fix: %0.3f \n', toc(postfixtic))
            end %while fixating on target
           if isInWindow, fprintf('End Post Fix: %0.3f \n', toc(postfixtic)), end
            
            
        end % presentation of trial 
        
        Screen(window, 'FillRect', black); Screen(window, 'Flip');
        set(hFix, 'visible', 'off')
        set(hTarg, 'visible', 'off')
        drawnow 
        
        % check if fixation failed
        if ~isInWindow
            if isDaq, krEndTrial(dio);end
            WaitSecs(2);
        else
            WaitSecs(0.5);
            if isDaq, krEndTrial(dio);end
            WaitSecs(0.5);
            if isDaq, krDeliverReward(dio,2);end
            
            
            % at this point, calculate where the triggers happened and the number of peaks
            [~, tlocs] = findpeaks(diff(data(:,3)),'MINPEAKHEIGHT',1);
            numPeaks = length(tlocs);
            
            plottuning(prevLoc) = plottuning(prevLoc) + numPeaks;
            plottrls(prevLoc) = plottrls(prevLoc) + 1;
            try
                set(hTune, 'ydata', plottuning./plottrls);
            end
            
            
            % now plot the raster 
            if isempty(saclocs)
                timeSac = 0; % note there's a condition of no saccade
            else
                timeSac = time(saclocs);
            end
            
            timeTrig = time(tlocs) - timeSac;
            % you know the subplot bc of prevLoc
            subpnum = subpcorr(prevLoc);
            figure(2), subplot(3,3,subpnum);
            
            if ~isempty(timeTrig) && length(timeTrig) == 2
                plot([timeTrig'; timeTrig'], [prow(subpnum)-0.9 prow(subpnum)-0.1], 'k', 'LineWidth', 2)
            elseif ~isempty(timeTrig)
                plot([timeTrig timeTrig], [prow(subpnum)-0.9 prow(subpnum)-0.1], 'k', 'LineWidth', 2)
            end
            totRelSpks{subpnum} = [totRelSpks{subpnum}; timeTrig];
            thispsth = buildpsth(sacpre, sacpost, totRelSpks{subpnum});
            set(hPSTH(subpnum), 'ydata', thispsth./40);
            drawnow
            
            prow(subpnum) = prow(subpnum) + 1;
            
            
            % and finally, store all the success information
            storeSuccesses(trl) = trl;
            storeDistVar(trl) = distvar;
            successCount = successCount+1;
            set(handles.SuccessCount,'String',num2str(successCount));
            WaitSecs(1);
            
        end
        
        
        if mod(trl,20) == 0
            save(fName, 'storeLocs','storeSuccesses', 'storeDistVar')
        end
        
        if isDaq, krEndTrial(dio); end
        
        trl = trl + 1;
        
    end
    
catch MException;
    
    ShowCursor;
    Screen('CloseAll');
    save(fName, 'storeLocs','storeSuccesses', 'storeDistVar')
    close all
    
    disp(MException.message)
    keyboard
    
end

% delete the gui handles
delete(uic);
axes(handles.EyePosition);cla;
axes(handles.TaskSpecificPlot);cla;
    
if isDaq, krEndTrial(dio);end
disp(fName)
save(fName, 'storeLocs','storeSuccesses', 'storeDistVar')
ShowCursor;
Screen('CloseAll');


end