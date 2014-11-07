
clear

load('thisrun.mat')
load('thisrunphoto.mat')

photo = Data17__Stopped__Ch6.values;
timesp2 = Data17__Stopped__Ch6.times;


% smooth out the photocell
idxPhoto = photo > 0.02;
photo(idxPhoto) = 0.5;
photo(~idxPhoto) = 0;

dphoto = diff(photo);
dphoto = [0; dphoto]; % to take care of the indexing issue

idxOn = find(dphoto == 0.5); % photocell on
idxOff = find(dphoto == -0.5);

% note, the first one will be due to the PTB syncing routine
idxOn(1) = [];
idxOff(1) = [];

timeson = timesp2(idxOn);
timesoff = timesp2(idxOff);


% figure(1);clf;
% plot(timesp2, photo)
% hold on
% plot(timesp2(idxOn), 0.5, 'ro')
% plot(timesp2(idxOff), 0, 'kx')
% 
% 
% figure(2);clf;
% plot(fliptimesOnA,ones(length(fliptimesOnA)),'ko');hold on
% plot(fliptimesOffA,ones(length(fliptimesOffA)),'kx')


% time taken to turn on screen
fprintf('Mean Time To Turn On Screen (60Hz): %0.3f \n', mean(fliptimesOnB - fliptimesOnA))

% time taken to turn off screen
fprintf('Mean Time To Turn Off Screen (60Hz): %0.3f \n', mean(fliptimesOffB - fliptimesOffA))

% time photo On
fprintf('Photo On For (Should Be 100ms) : %0.4f \n', mean(timesp2(idxOff) - timesp2(idxOn)))

% time photo Off
fprintf('Photo Off For (Should Be 100ms) : %0.4f \n', mean(timesp2(idxOn(2:end)) - timesp2(idxOff(1:end-1))))







