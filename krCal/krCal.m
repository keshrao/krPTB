function krCal()

distvar = 10;
fig = figure(1); clf
axis([-200 200 -200 200])
axis off
uicontrol('Parent',fig,'Style','pushbutton','String','Increment','Callback',@cb_Increment,'Position',[200 200 60 20]);
uicontrol('Parent',fig,'Style','pushbutton','String','Decrement','Callback',@cb_Decrement,'Position',[200 150 60 20]);
edit = uicontrol('Parent',fig,'Style','edit','String', num2str(distvar),'Position',[200 250 60 20]);
drawnow, pause(0.1)

    function cb_Increment(~,~)
        distvar = distvar + 1;
        TextBox()
        generateTableSquares()
        drawnow
    end
    function cb_Decrement(~,~)
        distvar = distvar - 1;
        if distvar < 1
            distvar = 1;
        end
        TextBox()
        generateTableSquares()
        drawnow
    end
    function TextBox(~,~)
        set(edit,'String',num2str(distvar));
    end



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
generateTableSquares()

    function generateTableSquares()
        
        distbet = res.width./distvar; % distance between squares
        
        % generate an array of squares - columns
        sq(:,1) = [centX-distbet-ssq  centY-distbet-ssq centX-distbet   centY-distbet];
        sq(:,2) = [centX-ssq          centY-distbet-ssq centX           centY-distbet];
        sq(:,3) = [centX+distbet-ssq  centY-distbet-ssq centX+distbet   centY-distbet];
        
        sq(:,4) = [centX-distbet-ssq  centY-ssq         centX-distbet   centY];
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

colorblue = [0; 0; 255];
colorwhite = [255; 255; 255];
photocell = [0; 0; 50; 50;];

% data to be stored into this filename
c = clock;
fName = [date '-' num2str(c(4)) num2str(c(5))]; % date and hour and min

winTol = 30;


viewingFigure = true;
if viewingFigure
    % now open up a second matlab figure to be used to view eye position
    figure(2), clf
    axis([-res.width/2 res.width/2 -res.height/2 res.height/2]);
    hold on
    rectangle('Position', [0 0 10 10], 'FaceColor', 'black'); % center of the screen
    hFix = rectangle('Position', [0, 0 25 25],'FaceColor','blue'); %<- note, x,y,w,h as opposed to PTB's convention
    hEye = rectangle('Position', [0, 0 25 25],'FaceColor','red');
    axis off    
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


% ---- PTB segment
try
    
    HideCursor;
    window = Screen(whichScreen, 'OpenWindow');
    ShowCursor;
    
    black = BlackIndex(window); % pixel value for black
    
    
    ntrls = 100;
    
    prevLoc = 0;
    indLoc = 0;
    
    storeGlobalTics = nan(ntrls, 1);
    storeLocIDs = nan(ntrls,1); % save the location of stimuli
    storeSuccesses = zeros(ntrls, 1);
    
    % reset states
    if isDaq, krEndTrial(dio); end
    
    ticGlobal = tic;
    
    for trls = 1:ntrls
        % wipe screen & fill back
        Screen(window, 'FillRect', black); Screen(window, 'Flip');
        
        % select random location
        while indLoc == prevLoc
            indLoc = randi(9);
        end
        prevLoc = indLoc;
        
        % deal with scaling difference
        thisPos = allLocsPos(indLoc,:); % x/y position of target
        % subtract out the screen offset bias
        thisPos(1) = thisPos(1) - centX;
        thisPos(2) = -(thisPos(2) - centY);
        
        % ----------------- start
        if isDaq, krStartTrial(dio); end
        
        storeGlobalTics(trls) = toc(ticGlobal); % trial start times
        storeLocIDs(trls) = indLoc; % these two to be saved later
        
        % draw fixation dot
        Screen(window, 'FillRect', [colorblue colorwhite], [sq(:,indLoc) photocell]);
        Screen(window, 'Flip');
        
        % now that stimulus is on, wait to let monkey enter window
        
        isInWindow = false;
        temptic = tic;
        
        while toc(temptic) < 3 % wait 3 secs to enter window
            
            if isDaq
                
                try
                    [eyePosX eyePosY] = krGetEyePos(ai);
                catch
                    disp('Missed Eye Data')
                end
            else
                [eyePosX,eyePosY] = GetMouse(window);
                eyePosX = eyePosX - centX;
                eyePosY = eyePosY - centY;
            end
            
            %
            if viewingFigure, updateViewingFigure(); end
            
            if abs(eyePosX - thisPos(1)) < winTol && abs(eyePosY - thisPos(2)) < winTol
                isInWindow = true; % cue to begin wait period
                break % as soon as eye in window, break wait loop
            end
            
        end
        
        % check if fixation failed
        if ~isInWindow
            Screen(window, 'FillRect', black); Screen(window, 'Flip');
            if isDaq, krEndTrial(dio);end
        else
            
            % successful fixation
            temptic = tic;
            
            while toc(temptic) < 1 && isInWindow % maintin fix for 1 sec
                
                if isDaq
                    [eyePosX eyePosY] = krGetEyePos(ai);
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
            
            
        end
        
        % ----------------- end
        Screen(window, 'FillRect', black); Screen(window, 'Flip');
        if isDaq, krEndTrial(dio);end
        
        % broke fixation during trial
        if isInWindow
            if isDaq, krDeliverReward(dio,2);end
            storeSuccesses(trls) = 1;
        end
        
        if mod(trls,20) == 0
            save(fName, 'storeGlobalTics', 'storeLocIDs','storeSuccesses')
        end
        
    end
    
catch MException;
    
    ShowCursor;
    Screen('CloseAll');
    save(fName, 'storeGlobalTics', 'storeLocIDs','storeSuccesses')
    close all
    
    disp(MException.message)
    
end

if isDaq, krEndTrial(dio);end
save(fName, 'storeGlobalTics', 'storeLocIDs','storeSuccesses')
ShowCursor;
Screen('CloseAll');



end