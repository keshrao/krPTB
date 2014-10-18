function krFwdCorr_OnlinePlot(ntrls, handles)

% testing psychtoolbox screen command

clc; pause(0.01);
warning off

if isempty(ntrls)
    ntrls = 300;
end

try
    [ai, dio] = krConnectDAQTrigger();
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


numstimthistrl = 5;

viewingFigure = true;
if viewingFigure
    % now open up a second matlab figure to be used to view eye position
    axes(handles.EyePosition); cla;
    axis([-res.width/2 res.width/2 -res.height/2 res.height/2]);
    hold on
    rectangle('Position', [0 0 10 10], 'FaceColor', 'black'); % center of the screen
    hEye = rectangle('Position', [0, 0 25 25],'FaceColor','red'); %<- note, x,y,w,h as opposed to PTB's convention
    for numtargsi = 1:numstimthistrl
        hTargs(numtargsi) = rectangle('Position', [0, 0 10 10],'FaceColor','white'); %#ok
    end
     % this is for the easy ending of programs
    uic = uicontrol('Style','pushbutton','String','End Task','Callback',@cb_EndTask,'Position',[350 350 60 20]);
    drawnow
    
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
    function cb_EndTask(~,~)
        isRun = false;
    end

isRun = true;

axes(handles.TaskSpecificPlot); cla;
global xdiv
xdiv = 40;
frmat = zeros(xdiv);
frtrls = zeros(xdiv);


% data to be stored into this filename
c = clock;
fName = ['fixOnline_' date '-' num2str(c(4)) num2str(c(5))]; % date and hour and min

Priority(2);

try
    window = Screen(whichScreen, 'OpenWindow');
    
    black = BlackIndex(window); % pixel value for black
    
    % wipe screen & fill bac
    Screen(window, 'FillRect', black);
    Screen(window, 'Flip');

    % --- variables and declarations common to all trials
    
    winTol = 30;
    
    % center fixation square
    fixSq = [res.width/2-5 res.height/2-5 res.width/2 res.height/2]';
    colorBlue = [0 0 255]';
    
    % this is be a good photodiode cell box
    photoSq = [0 0 30 30]';
    colorWhite = [255 255 255]'; % white color
    
    
    stimoffsetW = round(res.width/2);
    stimoffsetH = round(res.height/2);
    % ---- starting trial loop
    
    % this will be used to store all flash locations
    storeEveryXloc = [];
    storeEveryYloc = [];
    storeEveryTic = [];
    
    globeTic = tic;
    
    storeXlocs = [];
    storeYlocs = [];
    storeSuccess = 0;
    success = 0;
    trl = 1;
    
    while trl <= ntrls && isRun
        
        set(handles.TrialNumber,'String',num2str(trl));

        % present fixation square
        Screen(window, 'FillRect', colorBlue, fixSq);
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
            if isDaq, krEndTrial(dio); end
            storeSuccess(trl) = 0;
            WaitSecs(2);
        else
            
            % successful fixation trial logic goes here
            if isDaq, krStartTrial(dio); end
            
            % begin series of stimuli flashes
            numflashes = 10;
            
            while isInWindow
                
                xFlashesIter = nan(numflashes,numstimthistrl);
                yFlashesIter = nan(numflashes,numstimthistrl);
                tocFlashIter = nan(numflashes,1);
                
                tottrltrigs = 0;
                
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
                    
                    % maybe this won't be good if we're worried about timing
                    if viewingFigure, updateViewingFigure(); end
                    
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
                    randXpos = randi([round(stimoffsetW/2) round(res.width - stimoffsetW/2)], 1, numstimthistrl);
                    randYpos = randi([stimoffsetH/2 round(res.height - stimoffsetH/2)], 1, numstimthistrl);
                    % randpos = [1,n]
                    
                    xFlashesIter(nf,:) = randXpos;
                    yFlashesIter(nf,:) = randYpos;
                    
                    for i = 1:numstimthistrl
                        thisSq = [randXpos(i)-10 randYpos(i)-10 randXpos(i) randYpos(i)]';
                        stims = [stims thisSq];
                        stimcolors = [stimcolors colorWhite];
                    end
                    
                    
                    tocFlashIter(nf) = toc(globeTic);
                    
                    % draw stimuli
                    Screen(window, 'FillRect', stimcolors , stims);
                    Screen(window, 'Flip');
                    
                    numtrigs = 0;
                    
                    % leave stimulus on for short priod of time
                    stimwaitdur = 0.05; % always 50ms
                    thisstimdur = tic;
                    while toc(thisstimdur) < stimwaitdur
                        % find out how many spikes occured
                        try
                            numtrigs = numtrigs + krTriggers(ai, stimwaitdur);
                        catch
                            disp('missed trigger')
                        end
                    end
                    
                    blankDur = 0.1;
                    % after stim duration, then blank screen (leave fixation) for 100ms
                    Screen(window, 'FillRect', colorBlue, fixSq);
                    Screen(window, 'Flip');
                    
                    thisBlank = tic;
                    while toc(thisBlank) < blankDur
                       % find out how many spikes occured
                       try
                            numtrigs = numtrigs + krTriggers(ai, stimwaitdur);
                        catch
                            disp('missed trigger')
                        end
                      
                    end
                    
                    
                    if viewingFigure, [frmat, frtrls] = updateRFMapHandles(handles, frmat, frtrls, randXpos, randYpos, numtrigs); end
                    
                    tottrltrigs = tottrltrigs + numtrigs;
                    
                end %nflahses
                
                % at this point, you know the number of spikes occured
                % for this particular location
                % fprintf(', Num Trigs: %i \n', tottrltrigs)
                
                % regardless of if all ten flashes occured or not, just
                % save the flashes that did in fact occur and when they
                % happened. This gets successful and failed trials.
                storeEveryXloc = [storeEveryXloc; xFlashesIter];
                storeEveryYloc = [storeEveryYloc; yFlashesIter];
                storeEveryTic = [storeEveryTic; tocFlashIter];
                
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
                    
                    WaitSecs(1);
                    if isDaq, krDeliverReward(dio, 4); end;
                    
                    % collect flashes
                    storeXlocs = [storeXlocs; xFlashesIter]; %#ok
                    storeYlocs = [storeYlocs; yFlashesIter]; %#ok
                    storeSuccess(trl) = trl;
                    success = success+1;
                    set(handles.SuccessCount,'String',num2str(success));
                    WaitSecs(1);
                    break
                end
                
            end % while continuously fixting
            
        end %if successful fixation
        
        
        if isDaq, krEndTrial(dio); end
        
        if mod(trl,10) == 0
            save(fName, 'storeXlocs', 'storeYlocs','storeSuccess', 'storeEveryTic', 'storeEveryYloc', 'storeEveryXloc')
        end
        
        trl = trl + 1;
        
    end % ntrials
    
    Screen('CloseAll');
    
catch lasterr
    
    ShowCursor
    Screen('CloseAll');
    if isDaq, krEndTrial(dio); end
    save(fName, 'storeXlocs', 'storeYlocs','storeSuccess', 'storeEveryTic', 'storeEveryYloc', 'storeEveryXloc')
    disp(fName)
    keyboard
end

delete(uic)
axes(handles.EyePosition);cla;
axes(handles.TaskSpecificPlot);cla;

if isDaq, krEndTrial(dio); end
save(fName, 'storeXlocs', 'storeYlocs','storeSuccess', 'storeEveryTic', 'storeEveryYloc', 'storeEveryXloc')
Priority(0);

end % function