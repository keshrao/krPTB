clear;
[ai, dio] = krConnectDAQInf();
Screen('Preference', 'SkipSyncTests', 0);
whichScreen = 2;
res = Screen('Resolution',whichScreen);


photoSq = [0 0 30 30]';
colorWhite = [255 255 255]';    
window = Screen(whichScreen, 'OpenWindow');
black = BlackIndex(window);

% numsamps = 1;
% figure(1),clf
% hp = plot(1:numsamps,zeros(1,numsamps), '.r'); axis([-500 500 -500 500])

Screen(window, 'FillRect', black);
Screen(window, 'Flip');

stims = [photoSq];
stimcolors = [colorWhite];

photos = zeros(1,10000);
fliptimes = zeros(1,10);

flipstart = tic;
for j=1:10;
Screen(window, 'FillRect', stimcolors , stims);
fliptimes(j)=toc(flipstart);
Screen(window, 'Flip');

for i=1:1000
    [eyeX photo] = krPeekEyePos(ai);
    photos(1000*(j-1)+i)=photo;
end

Screen(window, 'FillRect', black);
Screen(window, 'Flip');

pause(0.1)

end;
totaltime = toc(flipstart);
times = linspace(0,totaltime,10000);

Screen('CloseAll');

figure(1)
plot(times,photos)
hold on
plot(fliptimes,mean(photos)*ones(1,10),'ko')