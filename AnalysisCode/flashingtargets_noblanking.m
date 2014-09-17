clear, clc

xdiv = 40;
ydiv = 40; % number of x/y divisions

frmat = zeros(xdiv, ydiv);
frtrls = zeros(xdiv, ydiv);

targetdir = 'C:\Users\Hrishikesh\Data\krPTBData\';
[filename pathname] = uigetfile([targetdir '*.mat'], 'Load Exp Session File (not sp2)', 'MultiSelect', 'on');
fullpathname = strcat(pathname, filename); % all the files in pathname

%% Because I want to combine files and build up the firing rate plots

if iscell(fullpathname)
    numfiles = length(fullpathname);
else
    numfiles = 1;
end


windows = 0.010:0.010:0.150;
dur = 0.20;

for wi = 1:length(windows)
    
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
        idxPhoto = photo > 0.15;
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
        
        
        
        %% find the times during the trial start/stop - for now i'm just check to see if greater than 1800ms
        
        trialdurations = idxTstop - idxTstart;
        
        succTrls = find(trialdurations > 1800);
        
        fprintf('Num Succ Trls Detected: %i. \nNum Succ Trls Stored: %i. \nNum Flashes: %i \n', length(succTrls), length(find(storeSuccess)), size(storeXlocs,1))
        
        timeFlashes = [];
        
        for trl = 1:length(succTrls)
            
            % I happen to know that there are ten targets flashed evenly spaced in time
            tmptimes = linspace(idxTstart(succTrls(trl)), idxTstop(succTrls(trl)), 11);
            timeFlashes(end+1:end+10,1) = trigTS(round(tmptimes(1:10)));
            
        end
        
        
        
        %% Divide the space into smaller squares to collect firing rate data
        
        % xrange = 100 - 1000
        % yrange = 50 - 700
        xrng = [100 1000];
        yrng = [50 700];
        
        
        hbins = linspace(xrng(1), xrng(2), xdiv);
        vbins = linspace(yrng(1), yrng(2), ydiv);
        
        poststimTimePre = windows(wi);
        poststimTimePost = poststimTimePre + dur; % in seconds
        
        for col = 1:ydiv - 1
            for row = 1:xdiv - 1
                
                totIndFlashes = [];
                for nf = 1:size(storeXlocs,2)
                    indFlash = find(storeXlocs(:,nf) > hbins(row) & storeXlocs(:,nf) < hbins(row+1) & storeYlocs(:,nf) > vbins(col) & storeYlocs(:,nf) < vbins(col+1));
                    totIndFlashes = [totIndFlashes; indFlash];
                end
                
                timeFlash = timeFlashes(totIndFlashes);
                
                if ~isempty(timeFlash)
                    frtrls(row,col) = frtrls(row,col) + 1;
                end
                
                % determine the number of spikes that occur in the 200ms after the
                % flashs in this location
                
                thisNeuSpks = 0;
                
                for numF = 1:length(timeFlash)
                    thisNeuSpks = thisNeuSpks + sum(spktimes > timeFlash(numF) + poststimTimePre & spktimes < timeFlash(numF) + poststimTimePost);
                end % numF
                
                
                frmat(row,col) = frmat(row,col) + thisNeuSpks;
                
            end %row
        end% col
        
    end
    
    %% plot what the heatmap looks like
    
    clf, hold on
    figure(1), heatmap(frmat./frtrls);
    axis([0.5 xdiv 0.5 ydiv])
    title(['Window: ' num2str(windows(wi))])
    
    ax = axis;
    line(ax(1:2),[mean(ax(3:4)) mean(ax(3:4))], 'LineStyle', '--','LineWidth', 2, 'Color', 'k')
    line([mean(ax(1:2)) mean(ax(1:2))], ax(3:4), 'LineStyle', '--','LineWidth', 2, 'Color', 'k')
    
    
    pause(1)
end% windows