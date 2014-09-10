function krCalibrateEyeCoil()

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
catch
    disp('no daq')
    isDaq = false;
end

% remember to clear this out for real experiments
Screen('Preference', 'SkipSyncTests', 2);

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
    end

colorblue = [0; 0; 255];

photoSq = [0 0 30 30]';
colorwhite = [255; 255; 255];

% now open up a second matlab figure to be used to view eye position
figure(2), clf 
axis([-res.width/2 res.width/2 -res.height/2 res.height/2]);
hold on
rectangle('Position', [0 0 10 10], 'FaceColor', 'black'); % center of the screen
hFix = rectangle('Position', [0, 0 25 25],'FaceColor','blue'); %<- note, x,y,w,h as opposed to PTB's convention
hEye = rectangle('Position', [0, 0 25 25],'FaceColor','red'); 
axis off



try
    
    HideCursor;
    window = Screen(whichScreen, 'OpenWindow');
    ShowCursor;
    
    black = BlackIndex(window); % pixel value for black
    
    
    ntrls = 9;
    
    storeGlobalTics = nan(ntrls, 1);
    storeLocIDs = nan(ntrls,1); % save the location of stimuli
    
    prevLoc = 0;
    indLoc = 0;
    
    ticGlobal = tic;
    
    for trls = 1:ntrls
        % wipe screen & fill bac
        Screen(window, 'FillRect', black);
        Screen(window, 'Flip');
        
        % this is mostly just to test if dio working 
        krStartTrial(dio)
        krEndTrial(dio)
        
        % select random location
        % select random location
%         while indLoc == prevLoc
%             indLoc = randi(9);
%         end
%         prevLoc = indLoc;
        
        indLoc = indLoc + 1; % if you want to just go sequentially 

        storeGlobalTics(trls) = toc(ticGlobal); % trial start times
        storeLocIDs(trls) = indLoc; % these two to be saved later
        
        
        Screen(window, 'FillRect', [colorblue colorwhite], [sq(:,indLoc) photoSq]);
        Screen(window, 'Flip');
        
        ticTrl = tic;
        
        while toc(ticTrl) < 2
            % draw fixation dot & add the mouse/eye position dot
            
            if isDaq 
                
                try
                    [eyePosX eyePosY] = krGetEyePos(ai);
                catch
                    disp('Missed Get Data')
                end
                
            else
                [eyePosX,eyePosY] = GetMouse(window);
                eyePosX = eyePosX - centX;
                eyePosY = eyePosY - centY;
            end
            
            set(hFix, 'Position', [sq(3,indLoc)-centX -(sq(4, indLoc)-centY) 25 25]);
            set(hEye, 'Position', [eyePosX eyePosY 25 25]); %note this different convention
            drawnow
        end
        
        % give reward 
        if isDaq, krDeliverReward(dio,2); end;
        
        % wipe screen & fill bac
        Screen(window, 'FillRect', black);
        Screen(window, 'Flip');
        
        % this is mostly just to test if dio working 
        krStartTrial(dio)
        krEndTrial(dio)
        
        WaitSecs(1);
        
    end % end trl
    
catch MException;
    
    ShowCursor;
    Screen('CloseAll');
    disp(MException.message)
    
end



ShowCursor;
Screen('CloseAll');



end