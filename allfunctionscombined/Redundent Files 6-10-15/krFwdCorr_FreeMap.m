function krFwdCorr_FreeMap(ntrls,handles)

if isempty(ntrls)
    ntrls = 300;
end

warning off

ai = handles.ai;
dio = handles.dio;
isDaq = true;


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
    axes(handles.EyePosition);cla
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

% bin data into 5ms bins & determine firing rate
sacpre = 0.3;
sacpost = 0.3;
binwidth = 0.001;
bins = -sacpre:binwidth:sacpost;

figure(2), clf
for subp = 1:9
    subplot(3,3,subp), hold on
    plot([0 0], [0 100], 'b', 'LineWidth', 1.5)
	hPSTH(subp) = plot(bins(1:end-1)+(binwidth/2), ones(length(bins)-1,1), 'r', 'LineWidth', 1.5);
end

% store all the spikes for psth construction
for i = 1:9, totRelSpks{i} = []; end
prow = ones(9,1); % number of saccades in 8 cardinal directions
% number 5 = center and will never be used


% data to be stored into this filename
c = clock;
fName = ['FreeMap_' date '-' num2str(c(4)) num2str(c(5))]; % date and hour and min

Priority(2);
%%
try
    window = Screen(whichScreen, 'OpenWindow');
    
    disp(fName)
    
    black = BlackIndex(window); % pixel value for black
    
    % wipe screen & fill bac
    Screen(window, 'FillRect', black);
    Screen(window, 'Flip');
    
    % --- variables and declarations common to all trials
        
    % this is be a good photodiode cell box
    photoSq = [0 0 30 30]';
    colorWhite = [255 255 255]'; % white color
    
    stimoffsetW = round(res.width/2);
    stimoffsetH = round(res.height/2);
    % ---- starting trial loop
    
    % this will be used to store ALL flash locations
    storeXlocs = [];
    storeYlocs = [];
    globeTic = [];
    
    gt = tic;
    
    trl = 1;
    while trl <= ntrls && isRun
        
        set(handles.TrialNumber,'String',num2str(trl));
        
        % successful fixation trial logic goes here
        if isDaq, krStartTrial(dio); end
        
        % begin series of stimuli flashes
        numflashes = 5;
        
        xFlashesIter = nan(numflashes,numstimthistrl);
        yFlashesIter = nan(numflashes,numstimthistrl);
        ticIter = nan(numflashes, 1);
        
        %%
        for nf = 1:numflashes
            
            try
                  [eyePosX eyePosY] = krPeekEyePos(ai);
            catch
                disp(['Missed Eye Pos Acquisition: ' num2str(trl)])
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
            ticIter(nf) = toc(gt);
            
            stims = [photoSq];
            stimcolors = [colorWhite];
            
            for i = 1:numstimthistrl
                thisSq = [randXpos(i)-10 randYpos(i)-10 randXpos(i) randYpos(i)]';
                stims = [stims thisSq];
                stimcolors = [stimcolors colorWhite];
            end
            if viewingFigure, updateViewingFigure(); end
            
            % draw fixation dot
            Screen(window, 'FillRect', stimcolors , stims);
            Screen(window, 'Flip');
            
            
            
            % leave stimulus on for short priod of time
            stimwaitdur = 0.3; % always 300ms
            
            getspikesonce = false; 
            
            thisdur = tic;
            while toc(thisdur) < stimwaitdur
                if ~getspikesonce 
                    try
%                         [data, time, slocs, ex, ey] = krFullEyePosTrigs(ai, stimwaitdur-0.05);
                          [data, time, slocs, ex, ey, filtspdeye] = krPeekFullEyePosTrigs(ai, stimwaitdur-0.05);
                    catch
                    end
                    
                end
                getspikesonce = true; 
            end
            
            
            blankDur = 0.3; 
            % after stim duration, then blank screen (leave fixation) for 100ms
            Screen(window, 'FillRect', black);
            Screen(window, 'Flip');
            
            thisBlank = tic;
            while toc(thisBlank) < blankDur
                if viewingFigure, updateViewingFigure(); end
            end
            
            
            % during the "blank phase", plot out the data
            [~, tlocs] = findpeaks(diff(data(:,3)),'MINPEAKHEIGHT',1);
            % a vector the length of the number of saccades that give the proper subplot
            if isempty(slocs), slocs = 1; end
            subpnum = computedirsacs(ex, ey, slocs);
            
            % now plot the raster
            if isempty(slocs)
                timeSac = 0; % note there's a condition of no saccade
            else
                for saci = 1:length(slocs)
                    
                    if time(slocs(saci)) - sacpre < 0
                        % if the saccade happens within 300ms of acquisition
                        % then just take the first data point
                        tlow = 1;
                    else
                        tlow = find(time > time(slocs(saci)) - sacpre, 1, 'first');
                    end
                    
                    if time(slocs(saci)) + sacpre > time(end)
                        % if the saccade happens within 300ms of acquisition
                        % then just take the first data point
                        thigh = length(time);
                    else
                        thigh = find(time > time(slocs(saci)) + sacpost, 1, 'first');
                    end
                    
                    % tlow and thigh are indexes corresponding to when to look for triggers
                    indTrig = tlocs(tlocs > tlow & tlocs < thigh);
                    timeTrig = time(indTrig) - time(slocs(saci));
                    
                    figure(2),subplot(3,3,subpnum(saci))
                    if ~isempty(timeTrig) && length(timeTrig) == 2
                        plot([timeTrig'; timeTrig'], [prow(subpnum(saci))-0.9 prow(subpnum(saci))-0.1], 'k', 'LineWidth', 2)
                    elseif ~isempty(timeTrig)
                        plot([timeTrig timeTrig], [prow(subpnum(saci))-0.9 prow(subpnum(saci))-0.1], 'k', 'LineWidth', 2)
                    end
                    xlim([-sacpre sacpost])
                    
                    totRelSpks{subpnum(saci)} = [totRelSpks{subpnum(saci)}; timeTrig];
                    thispsth = buildpsth(sacpre, sacpost, totRelSpks{subpnum(saci)});
                    set(hPSTH(subpnum(saci)), 'ydata', thispsth./40);
                    drawnow
                    
                    
                    prow(subpnum(saci)) = prow(subpnum(saci)) + 1;
                end
            end
            
            
        end %nflahses
        %%
        % collect flashes
        storeXlocs = [storeXlocs; xFlashesIter]; %#ok
        storeYlocs = [storeYlocs; yFlashesIter]; %#ok
        globeTic = [globeTic; ticIter]; %#ok
        
        % wipe screen & fill bac
        Screen(window, 'FillRect', black);
        Screen(window, 'Flip');
        
        if isDaq, krEndTrial(dio); end
        
        WaitSecs(2);
        if isDaq, krDeliverReward(dio, 4); end
        WaitSecs(2);
        
        if mod(trl,10) == 0
            save(fName, 'storeXlocs', 'storeYlocs','globeTic')
        end
        
        trl = trl + 1;
    end % ntrials
    
    
catch lasterr
    
    ShowCursor
    Screen('CloseAll');
    if isDaq, krEndTrial(dio); end
    save(fName, 'storeXlocs', 'storeYlocs','globeTic')
    
    delete(uic)
    axes(handles.EyePosition);cla;
    axes(handles.TaskSpecificPlot);cla;
    
    keyboard
end





if isDaq, krEndTrial(dio); end
Screen('CloseAll');
save(fName, 'storeXlocs', 'storeYlocs','globeTic')
Priority(0);

delete(uic)
axes(handles.EyePosition);cla;
axes(handles.TaskSpecificPlot);cla;

disp(fName)

end %function