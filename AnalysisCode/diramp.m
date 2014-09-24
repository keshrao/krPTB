% this program will help analyze the dir

clear, clc


targetdir = 'C:\Users\Hrishikesh\Data\krPTBData\';
[filename pathname] = uigetfile([targetdir 'S30*.mat'], 'Load Exp Session File (not sp2)', 'MultiSelect', 'on');
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
    
    eval(['Allspktimes = ' rawname(1:end-4) '_Ch7.times;'])
    eval(['spkcodes = ' rawname(1:end-4) '_Ch7.codes;'])
    
    
    eval(['eyeSamplingRate = ' rawname(1:end-4) '_Ch3.interval;'])
    
    numIdx1sec = round(1/eyeSamplingRate);
    %numIdxLittlePost = round(0.5/eyeSamplingRate);
    
    
    clus = 1;
    spktimes = Allspktimes(spkcodes(:,1) == clus);
    
    fprintf('Num Clusters: %i, Cluster Plotted: %i \n', length(unique(spkcodes(:,1))), clus)
    
    %% Get data (bookkeeping)
    
    % smooth out the photocell
    idxPhoto = photo > 0.1;
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
    
    
    %% determine when stimuli were flashes during the successful trials
    
    timeFlashes = [];
    nonzeroidx = find(storeSuccesses);
    
    for ti = 1:length(find(storeSuccesses))
        
        trl = storeSuccesses(nonzeroidx(ti));
        
        % note that time stamps don't matter here bc all this is comapring indexes
        thisIndFlashes = find(idxOn > idxTstart(trl) & idxOn < idxTstop(trl));
        thisNumFlashes = length(thisIndFlashes);
        
        if thisNumFlashes == 1
            timeFlashes(end+1) = photoTS(idxOn(thisIndFlashes));
        else
            fprintf('Something wrong with trial: %i.\n', trl);
            storeSuccesses(trl) = 0;
        end
        
    end
    
    fprintf('Number of successful trials: %i. \nNumber of flashes: %i.\n', length(nonzeroidx), length(timeFlashes))
    
    %% if the distvar variable didn't get saved, then generate it here
    % but may also be good to run this anyway and determine when the saccade happens 
    
    %if ~exist('distvar', 'var'), ,end
    
    dirsac = nan(length(nonzeroidx),1); % direction the saccade was made to
    sactimes = nan(length(nonzeroidx),1);
    
    for ti = 1:length(find(storeSuccesses))
        
        trl = storeSuccesses(nonzeroidx(ti));
        
        %time stamps matter here bc comaping different times and metrics
        idxThisTrl = find(eyeTS > timeFlashes(ti) & eyeTS < trigTS(idxTstop(trl)));
        
        thisEyeTS = eyeTS(idxThisTrl);
        thiseyeh = eyeh(idxThisTrl); 
        thiseyev = eyev(idxThisTrl);
        
        velx = diff(thiseyeh)./ eyeSamplingRate;
        vely = diff(thiseyev)./ eyeSamplingRate;
        spd = sqrt(velx.^2 + vely.^2);
        
        % find the peak in the first 600ms
        if max(spd(1:600)) > 20
            [~,locs] = findpeaks(spd(1:600), 'minpeakheight', 20, 'minpeakdistance',100);
            locs = locs(1);
            dirsac(ti) = atan2d(thiseyev(locs+100)-thiseyev(locs-100), thiseyeh(locs+100)-thiseyeh(locs-100));
            sactimes(ti) = thisEyeTS(locs);
        else
            % no saccade made
            dirsac(ti) = nan;
            sactimes(ti) = nan;
        end
        
        
    end
    
    
    %% now that we have our flash times, saccade times, and directions, plot rasters
    
    figure(1), clf
    
    % split up into 8 directions + 1 center
    dirbins = linspace(-30,330,8);
    % the analogous subplot numbers
    subpdirs = [6,3,2,1,4,7,8,9];
    
    trly = zeros(9,1);
    
    prestimdur = .100;
    poststimdur = .400;
    
    % first align to flash times
    for ti = 1:length(find(storeSuccesses))

        thisspkidx = find(spktimes > timeFlashes(ti)-prestimdur & spktimes < timeFlashes(ti)+poststimdur);
        thisspktimes = spktimes(thisspkidx);
        thisspkreltimes = thisspktimes - timeFlashes(ti);
        
        if isnan(dirsac(ti))
            subpnum = 5;
        else
            whichsubplot = find(dirbins < dirsac(ti), 1, 'last');
            subpnum = subpdirs(whichsubplot); 
        end

        trly(subpnum) = trly(subpnum) + 1;
        subplot(3,3,subpnum), hold on
        for spi = 1:length(thisspkreltimes)
            plot([thisspkreltimes(spi) thisspkreltimes(spi)], [0.1+trly(subpnum) 1+trly(subpnum)], 'k')
            xlim([-.1 .5])
        end
        
    end
    
    for subpnum = 1:9
        subplot(3,3,subpnum)
        ax = axis;
        plot([0 0], [0 ax(4)], 'b', 'LineWidth', 2)
    end
    
    
end