clear;
[ai, dio] = krConnectDAQInf();

Screen('Preference', 'SkipSyncTests', 0);
whichScreen = 2;

photoSq = [0 0 30 30]';
colorWhite = [255 255 255]';
window = Screen(whichScreen, 'OpenWindow');
black = BlackIndex(window);

Screen(window, 'FillRect', black);
Screen(window, 'Flip');
pause(1);


stims = [photoSq];
stimcolors = [colorWhite];

numflash = 1;

photos = zeros(numflash,1000);
photosOff = zeros(numflash,1000);

fliptimesOnA = zeros(1,numflash);
fliptimesOnB = zeros(1,numflash);

fliptimesOffA = zeros(1,numflash);
fliptimesOffB = zeros(1,numflash);

scfliptime = zeros(2,numflash);

photodata = zeros(numflash,500);
flipstart = tic;
for j=1:numflash;
    
    fliptimesOnA(j)=toc(flipstart);
        Screen(window, 'FillRect', stimcolors , stims);
        %scfliptime(1,j) = Screen(window, 'Flip');
%         Screen(window, 'Flip');
    fliptimesOnB(j)=toc(flipstart);
    
    pause(0.01)
    itimes = zeros(1,500);
    istart = tic;
    onTime = 0;
    offTime = 0;
    
    for i=1:500
        if i==100
            Screen(window, 'Flip');
            onTime = toc(istart);
        end
        if i== 300
            Screen(window,'FillRect',black);
            Screen(window,'Flip');
            offTime = toc(istart);
        end
        itimes(i) = toc(istart);
        [eyex eyey photo]=krPeekEyePos(ai);
        photodata(j,i) = photo;
        pause(0.00005);
    end
    
    
    fliptimesOffA(j) = toc(flipstart);
        Screen(window, 'FillRect', black);
        scfliptime(2,j) = Screen(window, 'Flip');
    fliptimesOffB(j) = toc(flipstart);
    
    %pause(0.1);
%     for i=1:1000
%         [eyex eyey photo]=krPeekEyePos(ai);
%     end
    
end;
totaltime = toc(flipstart);

Screen('CloseAll');

figure(1);clf;
plot(itimes,photodata,onTime,min(photodata),'r*',offTime,min(photodata),'r*')

% figure(1);clf
% tt = fliptimesOffA-fliptimesOnB;
% subplot(2,1,1)
% for i = 1:numflash; plot(linspace(0,tt(i),1000),photos(i,:)); hold all; end
% subplot(2,1,2)
% for i = 1:numflash; plot(linspace(0,tt(i),1000),photosOff(i,:)); hold all; end


%save('thisrun.mat', 'fliptimesOnA','fliptimesOffA','fliptimesOnB','fliptimesOffB', 'scfliptime')


% figure(1);clf;hold on
% plot(times,photos)
%
% plot(fliptimesOnA,mean(photos)*ones(1,numflash),'ko')
% plot(fliptimesOnB,mean(photos)*ones(1,numflash),'kx')
%
% plot(fliptimesOffA,mean(photos)*ones(1,numflash),'ro')
% plot(fliptimesOffB,mean(photos)*ones(1,numflash),'rx')
