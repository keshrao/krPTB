clear, clc

xdiv = 40;
ydiv = 40; % number of x/y divisions

frmat = zeros(xdiv, ydiv);
frtrls = zeros(xdiv, ydiv);
frstd = zeros(xdiv, ydiv);

targetdir = 'C:\Users\Hrishikesh\Data\krPTBData\';
[filename pathname] = uigetfile([targetdir 'S3*.mat'], 'Load Exp Session File (not sp2)', 'MultiSelect', 'on');
fullpathname = strcat(pathname, filename); % all the files in pathname

%% Because I want to combine files and build up the firing rate plots

if iscell(fullpathname)
    numfiles = length(fullpathname);
else
    numfiles = 1;
end


hasprinted = false;

subpnum = 1;
clf,

for poststimdur = 0.05:0.05:(8*0.05+0.05)
    
    subplot(3,3,subpnum)
    subpnum = subpnum + 1;
    
    
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
        
        numIdx1sec = round(1/eyeSamplingRate);
        %numIdxLittlePost = round(0.5/eyeSamplingRate);
        
        
        clus = 1;
        %spktimes = Allspktimes(spkcodes(:,1) == clus);
        spktimes = Allspktimes;
        
        if ~hasprinted, fprintf('Num Clusters: %i, Cluster Plotted: %i \n', length(unique(spkcodes(:,1))), clus), end
        
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
        
        
        
        %% find the times during the trial start/stop in which 10 flashes triggered
        
        succTrls = [];
        timeFlashes = [];
        
        for trl = 1:length(idxTstart)
            thisIndFlashes = find(idxOn > idxTstart(trl) & idxOn < idxTstop(trl));
            thisNumFlashes = length(thisIndFlashes);
            
            if thisNumFlashes == 10
                % full set
                succTrls(end+1) = trl; %#ok
                timeFlashes(end+1:end+10,1) = photoTS(idxOn(thisIndFlashes));
                
            end
        end
        
        % note: the indexs for succTrls and storeSuccesses should be the
        % same. Both should report the accurate number of successful trials.
        
        if ~hasprinted, fprintf('# SuccTrls: %i.\n# storeSuccesses %i.\n', length(succTrls), length(find(storeSuccess))); hasprinted = true; end
        %% Divide the space into smaller squares to collect firing rate data
        
        % screen resolution 1024x768
        xcent = 512;
        ycent = 384;
        
        % xrange = 100 - 1000
        % yrange = 50 - 700
        xrng = [-xcent/1.5 xcent/1.5];
        yrng = [-ycent/1.5 ycent/1.5];
        
        % center the axis
        storeXlocs = storeXlocs - xcent;
        storeYlocs = storeYlocs - ycent;
        
        hbins = linspace(xrng(1), xrng(2), xdiv);
        vbins = linspace(yrng(1), yrng(2), ydiv);
        
        %    poststimdur = 0.150; % in seconds
        prestimdur = poststimdur - 0.05;
        
        for col = 1:ydiv - 1
            for row = 1:xdiv - 1
                
                totIndFlashes = [];
                for nf = 1:size(storeXlocs,2)
                    indFlash = find(storeXlocs(:,nf) > hbins(row) & storeXlocs(:,nf) < hbins(row+1) & storeYlocs(:,nf) > vbins(col) & storeYlocs(:,nf) < vbins(col+1));
                    totIndFlashes = [totIndFlashes; indFlash];
                end
                
                timeFlash = timeFlashes(totIndFlashes);
                
                if ~isempty(timeFlash)
                    frtrls(row,col) = frtrls(row,col) + length(timeFlash);
                end
                
                % determine the number of spikes that occur in the 200ms after the
                % flashs in this location
                
                thisNeuSpks = zeros(1,length(timeFlash));
                
                for numF = 1:length(timeFlash)
                    thisNeuSpks(numF) = sum(spktimes > timeFlash(numF) + prestimdur & spktimes < timeFlash(numF) + poststimdur);
                end % numF
                
                frmat(row,col) = sum(thisNeuSpks);
                
                if length(timeFlash) > 3
                     frstd(row,col) = var(thisNeuSpks);
                else
                    frstd(row,col) = 1;
                end
                
                
            end %row
        end% col
        
    end
    
    %% plot what the heatmap looks like
    
    hold on
    heatmap(rot90(frmat./frtrls./frstd)); % the x/y axis is flipped. So transpose
    axis([0.5 xdiv 0.5 ydiv])
    
    ax = axis;
    line(ax(1:2),[mean(ax(3:4)) mean(ax(3:4))], 'LineStyle', '--','LineWidth', 2, 'Color', 'k')
    line([mean(ax(1:2)) mean(ax(1:2))], ax(3:4), 'LineStyle', '--','LineWidth', 2, 'Color', 'k')
    title([num2str(prestimdur) 'ms : ' num2str(poststimdur) 'ms']) 
    drawnow
end