clear, clc


targetdir = 'C:\Users\Hrishikesh\Data\krPTBData\';
[filename pathname] = uigetfile([targetdir '*.mat'], 'Load Exp Session File (not sp2)', 'MultiSelect', 'on');
fullpathname = strcat(pathname, filename); % all the files in pathname

%% Because I want to combine files and build up the firing rate plots

if iscell(fullpathname)
    numfiles = length(fullpathname);
else
    numfiles = 1;
end


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
    eval(['eyeTS = ' rawname(1:end-4) '_Ch3.times;'])
    eval(['trig = ' rawname(1:end-4) '_Ch5.values;'])
    eval(['trigTS = ' rawname(1:end-4) '_Ch5.times;'])
    eval(['photo = ' rawname(1:end-4) '_Ch6.values;'])
    eval(['photoTS = ' rawname(1:end-4) '_Ch6.times;'])
    
    eval(['eyeSamplingRate = ' rawname(1:end-4) '_Ch3.interval;'])
    numIdx1sec = round(1/eyeSamplingRate);
    
    %eval(['Allspktimes = ' rawname(1:end-4) '_Ch7.times;'])
    %eval(['spkcodes = ' rawname(1:end-4) '_Ch7.codes;'])
    
    clus = 1;
    %spktimes = Allspktimes(spkcodes(:,1) == clus);
    
    %fprintf('Num Clusters: %i, Cluster Plotted: %i \n', length(unique(spkcodes(:,1))), clus)
    
    %% Get data (bookkeeping)
    
    % smooth out the photocell
    idxPhoto = photo > 0.05;
    photo(idxPhoto) = 0.5;
    photo(~idxPhoto) = 0;
    
    dphoto = diff(photo);
    dphoto = [0; dphoto]; % to take care of the indexing issue
    
    idxOn = find(dphoto == 0.5); % photocell on
    idxOff = find(dphoto == -0.5);
    
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
    
    nztrig = find(dTrig > 0);
    
    id = 1;
    while id <= length(nztrig)
        
        threecheck = nztrig(id:id+2);
        
    end
    
    
    % sometimes, the trial whole system doesn't shut down properly and
    % spike2 starts with trig on. Somehow eliminate that.
    if length(idxTstop) > length(idxTstart)
        idxTstop(1) = [];
        disp('Eliminated first idxTstop')
    end
    
    
    %% find successful trials
    
    
    
    
end