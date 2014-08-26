% testing psychtoolbox screen command

clc, clear

try
    [ai, dio] = krConnectDAQ();
catch
    disp('no daq')
end
if exist('ai') && exist('dio') %#ok
    isDaq = true;
else
    isDaq = false;
end


% remember to clear this out for real experiments
Screen('Preference', 'SkipSyncTests', 0 );

whichScreen = 2;
res = Screen('Resolution',whichScreen);

Priority(2);

try
    HideCursor;

    window = Screen(whichScreen, 'OpenWindow');
    
    white = WhiteIndex(window); % pixel value for white
    black = BlackIndex(window); % pixel value for black
    
    % wipe screen & fill bac
    Screen(window, 'FillRect', black);
    Screen(window, 'Flip')
    
    ntrls = 100;
    framedel = nan(1,ntrls);
    
    isPhotoOn = false;
    
    % show n stimuli combinations
    for trls = 1:ntrls
        
        
        krStartTrial(dio)
        
        
        % to use this function, the last two arguements are the location of the
        % bottom right point in the square. Then take the first two arguements
        % and subtract out the size you want the square to be.
        
        % center fixation square
        sq1 = [res.width/2-5 res.height/2-5 res.width/2 res.height/2]';
        color1 = [0 0 255]';

        stims = [sq1];
        stimcolors = [color1];
        
        % this is be a good photodiode cell box
        sq2 = [0 0 30 30]';
        color2 = [255 255 255]'; % white color
        if ~isPhotoOn
            stims = [stims sq2];
            stimcolors = [stimcolors color2];
            isPhotoOn = true;
        else
            isPhotoOn = false;
        end
        
        % how many stimuli do I want to create
        numstimthistrl = randi([1 5], 1);
        
        % generate 5 stimulus squares and not on the edges of the screen
        randXpos = randi(res.width - 400, numstimthistrl, 1) + 200;
        randYpos = randi(res.height - 400, numstimthistrl, 1) + 200;
        
        
        for i = 1:numstimthistrl
            thisSq = [randXpos(i)-20 randYpos(i)-20 randXpos(i) randYpos(i)]';
            stims = [stims thisSq];
            stimcolors = [stimcolors color2];
        end
        
        
        
        % draw fixation dot
        Screen(window, 'FillRect', stimcolors , stims);
        framedel(trls) = Screen(window, 'Flip');
        
        
        %KbWait;
        %WaitSecs(rand/10);
        krEndTrial(dio)
        
        if mod(trls, 25) == 0
            % wipe screen & fill bac
            Screen(window, 'FillRect', black);
            Screen(window, 'Flip')
            
            krDeliverReward(dio)
        end
    end
    
    ShowCursor;
    Screen('CloseAll');
    
    %
catch %#ok
    
    ShowCursor
    Screen('CloseAll');
    disp('Error')
end

Priority(0);

% plot frame delays
%plot(diff(framedel)); ylim([nanmedian(diff(framedel))-2*nanstd(diff(framedel)) nanmedian(diff(framedel))+2*nanstd(diff(framedel))])