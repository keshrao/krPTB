clear all
[ai, dio] = krConnectDAQTrigger();
warning off

ai.SampleRate = 400000;  % crazy high
ai.SamplesPerTrigger = ai.SampleRate; % one second of data per trigger
ai.TriggerType = 'manual';
set(ai,'TriggerRepeat',inf); % as soon as buffer filled, trigger again

numsamps = ai.SampleRate * 0.5; % 100ms of data with each "peek"
timestamps = linspace(0,-numsamps/ai.SampleRate, numsamps);

numiter = 100000;
tocpeekdata = zeros(numiter,1);

figure(1),clf
hp = plot(1:numsamps,zeros(1,numsamps), 'r'); ylim([-5 5])

datanum = zeros(numiter,1);

% Eye Position plot
whichScreen = 2;
res = Screen('Resolution',whichScreen);

figure(1), clf
axis([-res.width/2 res.width/2 -res.height/2 res.height/2]);
hold on
rectangle('Position', [0 0 10 10], 'FaceColor', 'black'); % center of the screen
hEye = rectangle('Position', [0, 0 25 25],'FaceColor','red'); %<- note, x,y,w,h as opposed to PTB's convention
set(gca, 'color', 'none')


start(ai);
trigger(ai);

pause(1.1)

for i = 1:numiter;
    data = [];
    tic
    while isempty(data)
        data = peekdata(ai,10);
    end
    tocpeekdata(i) = toc; % this is the key part we're trying to test
    
    datanum(i) = numel(data(:,3));
    eyePosX = data(end,1)*100; % scaling from volts to deg
    eyePosY = data(end,2)*100; % scaling from volts to deg
    set(hEye, 'Position', [eyePosX eyePosY 25 25]); 
    drawnow
    
    flushdata(ai)
end

stop(ai)

figure(2), plot(tocpeekdata,'.'), title('Time taken for each peek')
figure(3), hist(datanum)