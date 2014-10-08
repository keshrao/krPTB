clear, clc

xdiv = 30;
ydiv = 30; % number of x/y divisions

frmat = zeros(xdiv, ydiv);
frtrls = zeros(xdiv, ydiv);
frstd = zeros(xdiv, ydiv);

targetdir = 'C:\Users\Hrishikesh\Data\krPTBData\';
[filename pathname] = uigetfile([targetdir 'S36*.mat'], 'Load Exp Session File (not sp2)', 'MultiSelect', 'on');
fullpathname = strcat(pathname, filename); % all the files in pathname

%% Because I want to combine files and build up the firing rate plots

if iscell(fullpathname)
    numfiles = length(fullpathname);
else
    numfiles = 1;
end


hasprinted = false;

subpnum = 1;
figure(1), clf,

for prestimdur = [0.05:0.05:(8*0.05+0.05) 0]
    
    if prestimdur == 0 % accumulate all times for like 300ms
        figure(2), clf
        timeforward = 0.300;
    else
        subplot(3,3,subpnum)
        subpnum = subpnum + 1;
        timeforward = 0.05;
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
        eval(['trig = ' rawname(1:end-4) '_Ch5.values;'])
        eval(['photo = ' rawname(1:end-4) '_Ch6.values;'])
        eval(['photoTS = ' rawname(1:end-4) '_Ch6.times;'])
        
        eval(['Allspktimes = ' rawname(1:end-4) '_Ch7.times;'])
        eval(['spkcodes = ' rawname(1:end-4) '_Ch7.codes;'])
        
        
        eval(['eyeSamplingRate = ' rawname(1:end-4) '_Ch3.interval;'])
        
        numIdx1sec = round(1/eyeSamplingRate);
        %numIdxLittlePost = round(0.5/eyeSamplingRate);
        
        
        clus = 1;
        spktimes = Allspktimes(spkcodes(:,1) == clus);
        %spktimes = Allspktimes;
        
        if ~hasprinted, fprintf('Num Clusters: %i, Cluster Plotted: %i \n', length(unique(spkcodes(:,1))), clus), end
        
        %% Get data (bookkeeping)
        
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
        poststimdur = prestimdur + timeforward;
        
        for col = 1:ydiv - 1
            for row = 1:xdiv - 1
                
                totIndFlashes = [];
                for nf = 1:size(storeXlocs,2)
                    indFlash = find(storeXlocs(:,nf) > hbins(row) & storeXlocs(:,nf) < hbins(row+1) & storeYlocs(:,nf) > vbins(col) & storeYlocs(:,nf) < vbins(col+1));
                    totIndFlashes = [totIndFlashes; indFlash];
                end
                
                thisTimeFlash = timeFlashes(totIndFlashes);
                
                if ~isempty(thisTimeFlash)
                    frtrls(row,col) = frtrls(row,col) + length(thisTimeFlash);
                end
                
                % determine the number of spikes that occur in the 200ms after the
                % flashs in this location
                
                thisNeuSpks = zeros(1,length(thisTimeFlash));
                
                for numF = 1:length(thisTimeFlash)
                    thisNeuSpks(numF) = sum(spktimes > thisTimeFlash(numF) + prestimdur & spktimes < thisTimeFlash(numF) + poststimdur);
                end % numF
                
                frmat(row,col) = sum(thisNeuSpks);
                
                %if length(thisTimeFlash) > 3
                    frstd(row,col) = std(thisNeuSpks);
                %else
                %    frstd(row,col) = 1;
                %end
                
                
            end %row
        end% col
        
    end
    
    %% plot what the heatmap looks like
    
    hold on
    heatmap(rot90(frmat./frtrls./frstd)); % the x/y axis is flipped. So transpose
    axis([0 xdiv 0 ydiv])
    
    ax = axis;
    line(ax(1:2),[mean(ax(3:4)) mean(ax(3:4))], 'LineStyle', '--','LineWidth', 2, 'Color', 'k')
    line([mean(ax(1:2)) mean(ax(1:2))], ax(3:4), 'LineStyle', '--','LineWidth', 2, 'Color', 'k')
    title([num2str(prestimdur) 'ms : ' num2str(poststimdur) 'ms'])
    drawnow
end

%% I want to get the center location of the perceived RF and plot the rasters for RF & non-RF stimuli

% on figure, bottom left is (0,0) & top right is (xdiv,ydiv)

% % figure(2)
% % fprintf('\nPick the center of the RF\n')
% % [xfig,yfig] = ginput(1);
% % 
% % xmid = hbins(round(xfig));
% % ymid = vbins(round(yfig));
% % 
% % sizerf = input('Num Bins Size RF: ');
% % 
% % % assume the size is like 3 bins on either side
% % xlow = hbins(round(xfig)-sizerf); xhigh = hbins(round(xfig)+sizerf);
% % ylow = vbins(round(yfig)-sizerf); yhigh = vbins(round(yfig)+sizerf);

figure(2)
fprintf('\nOutline The RF - xlow,xhigh,ylow,yhigh\n')
[xfig,yfig] = ginput(4);
xlow = hbins(round(xfig(1))); xhigh = hbins(round(xfig(2))); 
ylow = vbins(round(yfig(3))); yhigh = vbins(round(yfig(4))); 


% time before and after raster
raspre = 0.1;
raspost = 0.3;

% vectores of time points relative to flash to when spikes occur
hasRFstim = [];
noRFstim = [];

% index counters for rasters
rfcntr = 1;
norfcntr = 1;

figure(3), clf

% iterate through all the presented locations
for sloc = 1:size(storeXlocs,1)
    
    % spikes that occured after this stimulus
    relSpkTimes = spktimes(spktimes > timeFlashes(sloc) - raspre & spktimes < timeFlashes(sloc) + raspost) - timeFlashes(sloc);
    
    % in each row, check if stimulus lands in RF
    idxInRF = storeXlocs(sloc,:) > xlow & storeXlocs(sloc,:) < xhigh & storeYlocs(sloc,:) > ylow & storeYlocs(sloc,:) < yhigh;
    
    if sum(idxInRF) > 0 % RF stim
        
        hasRFstim = [hasRFstim relSpkTimes'];
        
        subplot(2,2,1), hold on
        if ~isempty(relSpkTimes) && length(relSpkTimes) == 2
            plot([relSpkTimes'; relSpkTimes'], [rfcntr-0.9 rfcntr-0.1], 'k')
        elseif ~isempty(relSpkTimes)
            plot([relSpkTimes relSpkTimes], [rfcntr-0.9 rfcntr-0.1], 'k', 'LineWidth', 3)
        end
        
        rfcntr = rfcntr + 1;
    else %no rf stim
        
        
        noRFstim = [noRFstim relSpkTimes'];
        
        subplot(2,2,2), hold on
        if ~isempty(relSpkTimes) && length(relSpkTimes) == 2
            plot([relSpkTimes'; relSpkTimes'], [norfcntr-0.9 norfcntr-0.1], 'k')
        elseif ~isempty(relSpkTimes)
            plot([relSpkTimes relSpkTimes], [norfcntr-0.9 norfcntr-0.1], 'k', 'LineWidth', 3)
        end
        
        norfcntr = norfcntr + 1;
    end % raster accumulation
    
end


for subp = 1:2
    subplot(2,2,subp)
    ax = axis;
    plot([0 0], [-1 ax(4)], 'b', 'LineWidth', 3)
end


% construct psth

for subp = 1:2
    
    % bin data into 5ms bins & determine firing rate
    binwidth = 0.001;
    bins = -raspre:binwidth:raspost;
    binned = nan(1,length(bins)-1);
    
    subplot(2,2,subp)
    if subp == 1
        ax = axis;
        plot([0 0], [-1 ax(4)], 'b', 'LineWidth', 3)
        title('Within RF Stimulus')
        
        totRelSpks = hasRFstim;
        normalizer = rfcntr;
    else
        ax = axis;
        plot([0 0], [-1 ax(4)], 'b', 'LineWidth', 3)
        title('No RF Stimulus')
        
        totRelSpks = noRFstim;
        normalizer = norfcntr;
    end
        
    for bi = 1:length(bins)-1
        thisDataIdx = totRelSpks > bins(bi) & totRelSpks < bins(bi+1);
        binned(bi) = sum(thisDataIdx)./binwidth;
    end
    
    gausKer = normpdf(-0.01:0.001:0.01, 0, 0.1);
    psth = conv(binned, gausKer, 'same');
    
    plot(bins(1:end-1)+(binwidth/2), psth./sum(gausKer)./normalizer*2,'r', 'LineWidth',2)
    
    ax = axis;
    ymaxval(subp) = ax(4);
    ylim([-10 ax(4)])
end

[miv,mii]= min(ymaxval);
[mav, mai] = max(ymaxval);
subplot(2,2,mii)
ylim([-10 mav])
