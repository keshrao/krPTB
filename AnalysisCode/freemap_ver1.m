clear, clc

clustertouse = 1;
clus = 1;

%% pick a file

targetdir = 'C:\Users\Hrishikesh\Desktop\';
[filename, pathname] = uigetfile([targetdir 'S40*.mat'], 'Load Exp Session File (not sp2)', 'MultiSelect', 'on');
fullpathname = strcat(pathname, filename); % all the files in pathname

if iscell(fullpathname)
    numfiles = length(fullpathname);
else
    numfiles = 1;
end

%% Setting various parameters


hasprinted = false;

% screen resolution 1024x768
xcent = 512;
ycent = 384;


%% begin analysis
for dt = 1:numfiles
    
    if iscell(fullpathname)
        thisfilename = fullpathname{dt};
        rawname = filename{dt};
    else
        thisfilename = fullpathname;
        rawname = filename;
    end
    
    % first load the session file
    load(thisfilename) % this has the locs and successes
    
    
    load(strcat(thisfilename(1:end-4), '_sp2.mat'))
    
    eval(['eyeh = ' rawname(1:end-4) '_Ch3.values;'])
    eval(['eyev = ' rawname(1:end-4) '_Ch4.values;'])
    eval(['trig = ' rawname(1:end-4) '_Ch5.values;'])
    eval(['photo = ' rawname(1:end-4) '_Ch6.values;'])
    eval(['photoTS = ' rawname(1:end-4) '_Ch6.times;'])
    
    eval(['Allspktimes = ' rawname(1:end-4) '_Ch7.times;'])
    eval(['spkcodes = ' rawname(1:end-4) '_Ch7.codes;'])
    
    
    eval(['eyeSamplingRate = ' rawname(1:end-4) '_Ch3.interval;'])
    eval(['eyeTS = ' rawname(1:end-4) '_Ch3.times;'])
    
    numIdx1sec = round(1/eyeSamplingRate);
    
    spktimes = Allspktimes(spkcodes(:,1) == clus);
    
    if ~hasprinted, fprintf('Num Clusters: %i, Cluster Plotted: %i \n', length(unique(spkcodes(:,1))), clus), end
    
    %% data bookkeeping
    % smooth out the photocell
    idxPhoto = photo > 0.02;
    photo(idxPhoto) = 0.3;
    photo(~idxPhoto) = 0;
    
    dphoto = diff(photo);
    dphoto = [0; dphoto]; % to take care of the indexing issue
    
    idxOn = find(dphoto == 0.3); % photocell on
    idxOff = find(dphoto == -0.3);
    
    % note, the first one will be due to the PTB syncing routine
    idxOn(1) = [];
    idxOff(1) = [];
    
    % - also importantly, note that the actual times that the photo is on/off
    % photoTS(idxOn(i)) or photoTS(idxOff(i))
    
    if photoTS(idxOff(1)) < photoTS(idxOn(1))
        idxOff(1) = []; % if some video is on the screen, photo dioded is non zero
    end
    
    % smooth out triggers
    idxTrig = trig > 0.1;
    trig(idxTrig) = 0.5;
    trig(~idxTrig) = 0;
    
    dTrig = diff(trig);
    dTrig = [0; dTrig];
    
    idxTstart = find(dTrig == 0.5);
    idxTstop = find(dTrig == -0.5);
    
    %% check for all flashes and store times of each flash
    
    timeFlashesOn = [];
    timeFlashesOff = [];
    
    % look in every start/stop sequence & count total flashes
    for trl = 1:length(idxTstart)
        thisIndFlashes = find(idxOn > idxTstart(trl) & idxOn < idxTstop(trl));
        timeFlashesOn = [timeFlashesOn; photoTS(idxOn(thisIndFlashes))];
        timeFlashesOff = [timeFlashesOff; photoTS(idxOff(thisIndFlashes))];
    end
    
    if size(storeXlocs,1) ~= length(timeFlashesOn)
        keyboard
    end
    fprintf('Num Locs/ Num Flashes: %i/%i\n', size(storeXlocs,1), length(timeFlashesOn))
    
    %% during each flash, determine
    cXlocs = storeXlocs - xcent;
    cYlocs = storeYlocs - ycent;
    
    for nf = 1:length(timeFlashesOn)
        
        % what is the eye doing during the flash window
        idxThisEyeDur = find(eyeTS > timeFlashesOn(nf) & eyeTS < timeFlashesOff(nf));
        % what is the eye doing during the subsequent blank window
        idxThisBlankDur = find(eyeTS > timeFlashesOff(nf) & eyeTS < timeFlashesOff(nf)+ .150);
        
        ex = eyeh(idxThisEyeDur).*100;
        ey = -eyev(idxThisEyeDur).*100;
        
        % saccadic parameters
        filtex = movingmean(ex, 5); % this process can be slow
        filtey = movingmean(ey, 5);
        
        % find when saccades happen
        spdeye = sqrt(diff(filtex) .^2 + diff(filtey).^2); % to secs & then to deg
        
        %arbitrary threshold
        sacthresh = 2; %deg/sec
        [~, saclocs] = findpeaks(spdeye, 'MINPEAKHEIGHT', sacthresh ,'MINPEAKDISTANCE',50);
        
        
        %         clf, subplot(2,2,1), hold on,
        %         plot(ex,ey,'.r'), plot(cXlocs(nf,:),cYlocs(nf,:),'ks');
        %         plot(eyeh(idxThisBlankDur).*100, -eyev(idxThisBlankDur).*100,'.b'),
        %         axis([-400 400 -400 400])
        %         subplot(2,2,3:4), hold on, plot(spdeye)
        %         plot(saclocs, pks, 'ro'), ylim([0 10])
        
        
        
        
        
    end
    
end % dt