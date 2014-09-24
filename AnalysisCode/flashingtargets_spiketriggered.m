clear, clc

xdiv = 40;
ydiv = 40; % number of x/y divisions

frmat = zeros(xdiv, ydiv);
frtrls = zeros(xdiv, ydiv);

targetdir = 'C:\Users\Hrishikesh\Data\krPTBData\';
[filename pathname] = uigetfile([targetdir 'S30*.mat'], 'Load Exp Session File (not sp2)', 'MultiSelect', 'on');
fullpathname = strcat(pathname, filename); % all the files in pathname

%% Because I want to combine files and build up the firing rate plots

if iscell(fullpathname)
    numfiles = length(fullpathname);
else
    numfiles = 1;
end


window = 0.06; % time back


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
    eval(['trigTS = ' rawname(1:end-4) '_Ch5.times;'])
    eval(['photo = ' rawname(1:end-4) '_Ch6.values;'])
    eval(['photoTS = ' rawname(1:end-4) '_Ch6.times;'])
    
    eval(['Allspktimes = ' rawname(1:end-4) '_Ch7.times;'])
    eval(['spkcodes = ' rawname(1:end-4) '_Ch7.codes;'])
    
    
    eval(['eyeSamplingRate = ' rawname(1:end-4) '_Ch3.interval;'])
    
    numIdx1sec = round(1/eyeSamplingRate);
    %numIdxLittlePost = round(0.5/eyeSamplingRate);
    
    
    clus = 1;
    spktimes = Allspktimes(spkcodes(:,1) == clus); %seconds
    
    fprintf('Num Clusters: %i, Cluster Plotted: %i \n', length(unique(spkcodes(:,1))), clus)
    
    %% Get data (bookkeeping)
    
    % smooth out the photocell
    idxPhoto = photo > 0.05;
    photo(idxPhoto) = 0.3;
    photo(~idxPhoto) = 0;
    
    dphoto = diff(photo);
    dphoto = [0; dphoto]; % to take care of the indexing issue
    
    idxOn = find(dphoto == 0.3); % photocell on
    idxOff = find(dphoto == -0.3);
    
    % note, the first one will be due to the PTB syncing routine
    idxOn(1) = [];
    idxOff(1) = [];
    
    % - also importantly, note that the times that the photo is on/off
    % photoTS(idxOn(i)) or photoTS(idxOff(i))
    
    % smooth out triggers
    idxTrig = trig > 0.1;
    trig(idxTrig) = 0.5;
    trig(~idxTrig) = 0;
    
    dTrig = diff(trig);
    dTrig = [0; dTrig];
    
    idxTstart = find(dTrig == 0.5);
    idxTstop = find(dTrig == -0.5);
    
    
    %% just find when the flashes happened in the "storeSuccess" lists
    timeFlashesStarts = [];
    timeFlashesEnds = [];
    
    nonzeroidx = find(storeSuccess);
    
    for ti = 1:length(find(storeSuccess))
        
        trl = storeSuccess(nonzeroidx(ti));
        
        thisIndFlashes = find(idxOn > idxTstart(trl) & idxOn < idxTstop(trl));
        thisNumFlashes = length(thisIndFlashes);
        
        if thisNumFlashes == 5
            
            tflashes = nan(10,1);
            tflashes([1,3,5,7,9]) = photoTS(idxOn(thisIndFlashes));
            tflashes([2,4,6,8,10]) = photoTS(idxOff(thisIndFlashes));
            timeFlashesStarts(end+1:end+10,1) = tflashes;
            
            tflashes = nan(10,1);
            tflashes([1,3,5,7,9]) = photoTS(idxOff(thisIndFlashes));
            tflashes([2,4,6,8]) = photoTS(idxOn(thisIndFlashes(2:end)));
            tflashes(10) = tflashes(9)+nanmean(diff(tflashes));
            timeFlashesEnds(end+1:end+10,1) = tflashes;
            
        else
            
            fprintf('Possible Error with Trial: %i. Num flashes = %i. \n', trl, thisNumFlashes)
            storeSuccess(ti) = 0;
            
        end
        
    end
    
    fprintf('Num Flashes Detected: %i. Num storeXlocs: %i. \n', length(timeFlashesStarts), length(storeXlocs))
    
    
    %% find every spike and determine what the frame was some time before it
    
    
    for spi = 1:length(spktimes)
        
        thisspiketime = spktimes(spi);
        timetolookat = thisspiketime - window;
        
        idxFS = find(timeFlashesStarts < thisspiketime, 1, 'last');
        idxFE = find(timeFlashesEnds < thisspiketime, 1, 'last');
        
        if ~isempty(idxFE) && ~isempty(idxFS) && timeFlashesStarts(idxFS) < thisspiketime && timeFlashesEnds(idxFE) > thisspiketime
            
            fprintf('Flash Start: %f. Spike: %f. Flash End: %f\n', timeFlashesStarts(idxFS), thisspiketime, timeFlashesEnds(idxFE))
            fprintf('IdxFS: %i, IdxFE: %i.\n', idxFS, idxFE)
            fprintf('Spike Num: %i\n \n \n', spi)
            
        end
    end
    
end

