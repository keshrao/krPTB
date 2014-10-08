clear, clc

clus = 3;

targetdir = 'C:\Users\Hrishikesh\Data\krPTBData\';
[filename pathname] = uigetfile([targetdir 'S3*.mat'], 'Load Exp Session File (not sp2)', 'MultiSelect', 'on');
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
    
    eval(['Allspktimes = ' rawname(1:end-4) '_Ch7.times;'])
    eval(['spkcodes = ' rawname(1:end-4) '_Ch7.codes;'])
    
    spktimes = Allspktimes(spkcodes(:,1) == clus);
    
    fprintf('Num Clusters: %i, Cluster Plotted: %i \n', length(unique(spkcodes(:,1))), clus)
    
    
    
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
            idxTstart(end+1) = nztrig(id+1);
            id = id + 2;
        else
            id = id + 1;
        end
        
    end
    
    if ~isempty(find(idxTstart > idxTstop, 1)), keyboard, end
    
    fprintf('Start:Stop Trigs & Succ/Total Trials: %i:%i - %i/%i\n', length(idxTstart), length(idxTstop), length(find(storeSuccess)), length(storeSuccess));
    
    %% find successful trials & total flashes
    
    nonzeroTrls = find(storeSuccess);
    
    timeFlashes = []; % store all the times when stimuli were flashes during successful trials
    
    % intra-trial triggers. Should be three per successful trial,
    intraTT = nan(length(storeSuccess),3); % left fix acquired, right target on, right fixation acquired
    
    for st = 1:length(nonzeroTrls)
        
        trl = nonzeroTrls(st);
        
        % since trigTS & trlTS are essentially identical, just compare indexes
        thisIndFlashes = find(idxOn > idxTstart(trl) & idxOn < idxTstop(trl));
        timeFlashes(end+1:end+length(thisIndFlashes),1) = photoTS(idxOn(thisIndFlashes));
        
        % inbetween start/stop, find the three intra-trial triggers
        thisITT = find(nztrig > idxTstart(trl) & nztrig < idxTstop(trl));
        
        if length(thisITT) == 3
            intraTT(trl, :) = trigTS(nztrig(thisITT));
        else
            fprintf('Problem with trial %i\n', trl)
        end
    end
    
    
    fprintf('Successful Flashes Detected: %i/%i.\n', length(timeFlashes), length(storeXlocs))
    
    
    %% determine what the left/right fixation offsets are
    
    fixOffsetarrL = nan(length(nonzeroTrls),1);
    fixOffsetarrR = nan(length(nonzeroTrls),1);
    
    for st = 1:length(nonzeroTrls)
        
        trl = nonzeroTrls(st);
        thiseyeIdx = find(eyeTS > intraTT(trl, 1) & eyeTS < intraTT(trl,2));
        fixOffsetarrL(st) = mean(eyeh(thiseyeIdx))*-100; % these negatives are intentional
        
        thiseyeIdx = find(eyeTS > intraTT(trl,3) & eyeTS < trigTS(idxTstop(trl)));
        fixOffsetarrR(st) = mean(eyeh(thiseyeIdx))*-100;
        
    end
    
    %% center the x & y stimuli
    
    % number of x/y divisions
    xdiv = 40;
    ydiv = 40;
    
    % screen resolution 1024x768
    xcent = 512;
    ycent = 384;
    
    xrng = [-xcent/1.5 xcent/1.5];
    yrng = [-ycent/1.5 ycent/1.5];
    
    % center the axis
    storeXlocs = storeXlocs - xcent;
    storeYlocs = storeYlocs - ycent;
    
    hbins = linspace(xrng(1), xrng(2), xdiv);
    vbins = linspace(yrng(1), yrng(2), ydiv);
    
    poststimdur = 0.2;
    
    for LSR = 1:4 % left, saccade pre, saccade post right
        eval(['frmat' num2str(LSR) ' = zeros(xdiv, ydiv);'])
        eval(['frtrls' num2str(LSR) ' = zeros(xdiv, ydiv);'])
    end
    
    %% for each successful trial, map out the presaccadic "left fixation".
    
    % ten degree saccades (-50,0) -> (50,0)
    % fifteen degree saccades (-75,0) -> (75,0)
    for st = 1:length(nonzeroTrls)
        
        trl = nonzeroTrls(st);
        
        % find the index of flashes that occur during left fixation
        thisflash = find(timeFlashes > intraTT(trl,1) & timeFlashes < intraTT(trl,2));
        
        for tlf = 1:length(thisflash)
            
            % determine the number of spikes that occured in the duration after this stimuli
            thisSpks = sum(spktimes > timeFlashes(thisflash(tlf)) & spktimes < timeFlashes(thisflash(tlf)) + poststimdur);
            
            for stimn = 1:size(storeXlocs,2)
                
                % adjust for the fixation position offset
                xloc = storeXlocs(thisflash(tlf),stimn);
                yloc = storeYlocs(thisflash(tlf),stimn);
                
                row = find(hbins > xloc + fixOffsetarrL(st) , 1, 'first');
                col = find(vbins > yloc , 1, 'first');
                
                frmat1(row,col) = frmat1(row,col) + thisSpks; %#ok
                frtrls1(row,col) = frtrls1(row,col) + 1; %#ok
                
                
            end % stimn

        end
        
        
    end % st - left fixation
    
    
    
    %% for each successful trial, map out the postsaccadic "right fixation"
    
    for st = 1:length(nonzeroTrls)
        
        trl = nonzeroTrls(st);
        
        % find the index of flashes that occur during left fixation
        thisflash = find(timeFlashes > intraTT(trl,3) & timeFlashes < trigTS(idxTstop(trl)));
        
        for tlf = 1:length(thisflash)
            
            % determine the number of spikes that occured in the duration after this stimuli
            thisSpks = sum(spktimes > timeFlashes(thisflash(tlf)) & spktimes < timeFlashes(thisflash(tlf)) + poststimdur);
            
            for stimn = 1:size(storeXlocs,2)
                
                % adjust for the fixation position offset
                xloc = storeXlocs(thisflash(tlf),stimn);
                yloc = storeYlocs(thisflash(tlf),stimn);
                
                row = find(hbins > xloc + fixOffsetarrR(st) , 1, 'first');
                col = find(vbins > yloc , 1, 'first');
                
                frmat4(row,col) = frmat4(row,col) + thisSpks; %#ok
                frtrls4(row,col) = frtrls4(row,col) + 1; %#ok
                
                
            end % stimn
            
        end
        
        
    end % st - right fixation
    
    
    %% there should be two flashes around the time of the saccade: one before, and one after. map each one separately
    
    
     for st = 1:length(nonzeroTrls)
        
        trl = nonzeroTrls(st);
        
        % find the index of flashes that occur during left fixation
        thisflash = find(timeFlashes > intraTT(trl,2) & timeFlashes < intraTT(trl,3));
        
        if length(thisflash) ~= 2
            fprintf('Missed a flash in trial %i\n', trl);
            continue
        end
        
        for tlf = 1:length(thisflash)
            
            % determine the number of spikes that occured in the duration after this stimuli
            thisSpks = sum(spktimes > timeFlashes(thisflash(tlf)) & spktimes < timeFlashes(thisflash(tlf)) + poststimdur);
            
            if tlf == 1
                offset = fixOffsetarrL(st);
            elseif tlf == 2
                offset = fixOffsetarrR(st);
            end
            
            for stimn = 1:size(storeXlocs,2)
                
                % adjust for the fixation position offset
                xloc = storeXlocs(thisflash(tlf),stimn);
                yloc = storeYlocs(thisflash(tlf),stimn);
                
                row = find(hbins > xloc + offset , 1, 'first');
                col = find(vbins > yloc , 1, 'first');
                
                if tlf == 1
                    frmat2(row,col) = frmat2(row,col) + thisSpks; %#ok
                    frtrls2(row,col) = frtrls2(row,col) + 1; %#ok
                elseif tlf == 2
                    frmat3(row,col) = frmat3(row,col) + thisSpks; %#ok
                    frtrls3(row,col) = frtrls3(row,col) + 1; %#ok
                end
            end % stimn
            
        end
        
        
    end % st - saccade 
    
end



subplot(2,2,1)
heatmap(rot90(frmat1./frtrls1));
title('Left Fixation')

subplot(2,2,2)
heatmap(rot90(frmat4./frtrls4));
title('Right Fixation')

subplot(2,2,3)
heatmap(rot90(frmat2./frtrls2));
title('Presaccadic')

subplot(2,2,4)
heatmap(rot90(frmat3./frtrls3));
title('Postsaccadic')





