close all; clc
[ai, dio] = krConnectDAQInf();
warning off

numiter = 100;
datanum = zeros(numiter,100);
tocpeekdata = zeros(numiter,100);

for j = 1:100
numsamps = ai.SampleRate * 0.0001 * j; % 100ms of data with each "peek"
timestamps = linspace(0,-numsamps/ai.SampleRate, numsamps);



% figure(1),clf
% hp = plot(1:numsamps,zeros(1,numsamps), '.r'); axis([-500 500 -500 500])



% Eye Position plot
whichScreen = 2;
res = Screen('Resolution',whichScreen);

% figure(1), clf
% axis([-res.width/2 res.width/2 -res.height/2 res.height/2]);
% hold on
% rectangle('Position', [0 0 10 10], 'FaceColor', 'black'); % center of the screen
% hEye = rectangle('Position', [0, 0 25 25],'FaceColor','red'); %<- note, x,y,w,h as opposed to PTB's convention
% set(gca, 'color', 'white')

pause(1)

for i = 1:numiter;
    data = [];
    tic
    while isempty(data)
        data = peekdata(ai,numsamps);
    end
   tocpeekdata(j,i) = toc; % this is the key part we're trying to test
   datanum(j,i) = numel(data(:,3));
   
%    eyePosX = data(:,1)*100; % scaling from volts to deg
%    eyePosY = data(:,2)*100; % scaling from volts to deg
%    %set(hEye, 'Position', [eyePosX(end) eyePosY(end) 25 25]);
%    set(hp, 'xdata', eyePosX)
%    set(hp, 'ydata', eyePosY)
%    drawnow
   
    flushdata(ai)
    pause(0.0001)
end

end

stop(ai)

figure(2), plot(tocpeekdata,'.'), title('Time taken for each peek')
figure(3), hist(datanum)