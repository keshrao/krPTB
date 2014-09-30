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
    
    idxTstart = [];
    idxTstop = [];
    
    id = 1;
    while id <= length(nztrig)
        
        % check to see if the next pulse happens within 45 indexes (approximate distance of each)
        d1 = nztrig(id+1) - nztrig(id);
        d2 = nztrig(id+2) - nztrig(id+1);
        
        if d1 < 45 && d2 < 45 % triple trigger
            idxTstop(end+1) = nztrig(id);
            id = id + 3;
        elseif d1 < 45 && d2 > 45 % double trigger
            idxTstart(end+1) = nztrig(id);
            id = id + 2;
        else
            id = id + 1;
        end
        
    end
    
    if ~isempty(find(idxTstart > idxTstop, 1)), keyboard, end
    
    fprintf('Start/Stop Trigs & Successes: %i/%i/%i\n', length(idxTstart), length(idxTstop), length(storeSuccess));
    
    %% find successful trials & total flashes
    
    nonzeroTrls = find(storeSuccess); 
    
    timeFlashes = []; % store all the times when stimuli were flashes during successful trials
    
    for st = 1:length(nonzeroTrls)
        
        trl = nonzeroTrls(st);
        
        % since trigTS & trlTS are essentially identical, just compare indexes
        thisIndFlashes = find(idxOn > idxTstart(trl) & idxOn < idxTstop(trl));
        timeFlashes(end+1:end+length(thisIndFlashes),1) = photoTS(idxOn(thisIndFlashes));
    end
    
    
    fprintf('Successful Flashes Detected: %i/%i.\n', length(timeFlashes), length(storeXlocs))
    
    
end






