function diramp()
% this program will help analyze the dir
clear, clc


figure(1), clf
figure(2), clf

for i = 1:9, totRelSpksT{i} = []; end
for i = 1:9, totRelSpksS{i} = []; end
trlyT = zeros(9,1);
trlyS = zeros(9,1);

clus = 1;

targetdir = 'C:\Users\Hrishikesh\Data\krPTBData\';
[filename pathname] = uigetfile([targetdir 'S32*.mat'], 'Load Exp Session File (not sp2)', 'MultiSelect', 'on');
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
    
    
    spktimes = Allspktimes(spkcodes(:,1) == clus);
    %spktimes = Allspktimes;
    
    fprintf('Num Clusters: %i, Cluster Plotted: %i \n', length(unique(spkcodes(:,1))), clus)
    
    %% Get data (bookkeeping)
    
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
    
    % sometimes, the trial whole system doesn't shut down properly and 
    % spike2 starts with trig on. Somehow eliminate that. 
    if length(idxTstop) > length(idxTstart)
        idxTstop(1) = [];
        disp('Eliminated first idxTstop')
    end
        
        
    
    %% determine when stimuli were flashes during the successful trials
    
    timeFlashes = [];
    nonzerotrls = find(storeSuccesses);
    
    if length(idxTstart) ~= max(nonzerotrls)
        fprintf('Deleting Last Trial\n')
        nonzerotrls(end) = [];
    end
    
    numsucctrls = length(nonzerotrls);
    
    for ti = 1:numsucctrls
        
        trl = storeSuccesses(nonzerotrls(ti));
        
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
    
    fprintf('Number of successful trials: %i. \nNumber of flashes: %i.\n', length(nonzerotrls), length(timeFlashes))
    
    %% if the distvar variable didn't get saved, then generate it here
    % but may also be good to run this anyway and determine when the saccade happens 
    
    %if ~exist('distvar', 'var'), ,end
    
    dirsac = nan(length(nonzerotrls),1); % direction the saccade was made to
    sactimes = nan(length(nonzerotrls),1);
    
    for ti = 1:numsucctrls
        
        trl = storeSuccesses(nonzerotrls(ti));
        
        %time stamps matter here bc comaping different times and metrics
        idxThisTrl = find(eyeTS > timeFlashes(ti) & eyeTS < trigTS(idxTstop(trl)));
        
        thisEyeTS = eyeTS(idxThisTrl);
        thiseyeh = eyeh(idxThisTrl); 
        thiseyev = eyev(idxThisTrl);
        
        velx = diff(thiseyeh)./ eyeSamplingRate;
        vely = diff(thiseyev)./ eyeSamplingRate;
        spd = sqrt(velx.^2 + vely.^2);
        
        % find the peak in the first 600ms
        if max(spd(100:min(length(spd),600))) > 20
            [~,locs] = findpeaks(spd(1:min(length(spd),600)), 'minpeakheight', 20, 'minpeakdistance',100);
                
            while length(locs) > 1 && locs(1) < 100 % erroneous saccade during fixation
                locs(1) = [];
            end
                    
            locs = locs(1);
            
            if length(thiseyev) < locs + 100
                gotill = length(thiseyev)-locs-1;
            else
                gotill = 100;
            end
            
            dirsac(ti) = atan2d(thiseyev(locs+gotill)-thiseyev(locs-gotill), thiseyeh(locs+gotill)-thiseyeh(locs-gotill));
            sactimes(ti) = thisEyeTS(locs);
            
        else
            % no saccade made
            dirsac(ti) = nan;
            sactimes(ti) = nan;
        end
        
        
    end
    
    
    %% now that we have our flash times, saccade times, and directions, plot rasters
    
    for TorS = 1:2
        
        figure(TorS)
        
        % split up into 8 directions + 1 center
        dirbins = linspace(-30,330,8);
        % the analogous subplot numbers
        subpdirs = [6,3,2,1,4,7,8,9];
        
         
        prestimdur = .300;
        poststimdur = .400;
        
        
        if TorS == 1
            aligntimes = timeFlashes;
        elseif TorS == 2
            aligntimes = sactimes;
        end
        
                % first align to flash times
        for ti = 1:numsucctrls
            
            thisspkidx = spktimes > aligntimes(ti)-prestimdur & spktimes < aligntimes(ti)+poststimdur;
            thisspktimes = spktimes(thisspkidx);
            thisspkreltimes = thisspktimes - aligntimes(ti);
            
            if isnan(dirsac(ti))
                subpnum = 5;
            else
                whichsubplot = find(dirbins < dirsac(ti), 1, 'last');
                subpnum = subpdirs(whichsubplot);
            end
            
            if TorS == 1
                trlyT(subpnum) = trlyT(subpnum) + 1;
                trly = trlyT;
            else
                trlyS(subpnum) = trlyS(subpnum) + 1;
                trly = trlyS;
            end
            
            subplot(3,3,subpnum), hold on
            for spi = 1:length(thisspkreltimes)
                plot([thisspkreltimes(spi) thisspkreltimes(spi)], [0.1+trly(subpnum) 1+trly(subpnum)], 'k')
                xlim([-prestimdur poststimdur])
            end
            
            if TorS == 1
                totRelSpksT{subpnum} = [totRelSpksT{subpnum}; thisspkreltimes];
            else
                totRelSpksS{subpnum} = [totRelSpksS{subpnum}; thisspkreltimes];
            end
            
            drawnow
        end
        
        
    end % target or saccade
    
end %files

for TorS = 1:2
    
    figure(TorS)
    if TorS == 1
        totRelSpks = totRelSpksT;
    else
        totRelSpks = totRelSpksS;
    end
    
    for subpnum = 1:9
        subplot(3,3,subpnum)
        ax = axis;
        
        plot([0 0], [0 ax(4)], 'b', 'LineWidth', 2)
        
        
        [bins, binwidth, psth] = buildpsth(prestimdur, poststimdur, totRelSpks{subpnum});
        
        plot(bins(1:end-1)+(binwidth/2), psth./40, 'r', 'LineWidth', 1)
        
        if subpnum == 2 && TorS == 1
            title('Aligned to Target Onset')
        elseif subpnum == 2 && TorS == 2
            title('Aligned to Saccade')
        end
        
        drawnow
    end %subplot titles
end


function [bins, binwidth, psth] = buildpsth(prestimdur, poststimdur, totRelSpks)

    
    % bin data into 5ms bins & determine firing rate
    binwidth = 0.001;
    bins = -prestimdur:binwidth:poststimdur;
    binned = nan(1,length(bins)-1);
    
        
    for bi = 1:length(bins)-1
        thisDataIdx = totRelSpks > bins(bi) & totRelSpks < bins(bi+1);
        binned(bi) = sum(thisDataIdx)./binwidth;
    end
    
    gausKer = normpdf(-0.05:0.001:0.05, 0, 0.01);
    psth = conv(binned, gausKer, 'same') ./ sum(gausKer);
       
    
