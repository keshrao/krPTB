clear 

xdiv = 40;
ydiv = 40; % number of x/y divisions

frmat = zeros(xdiv, ydiv);
frtrls = zeros(xdiv, ydiv);

screenres = [1024 768];

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
    eval(['trig = ' rawname(1:end-4) '_Ch5.values;'])
    eval(['photo = ' rawname(1:end-4) '_Ch6.values;'])
    eval(['photoTS = ' rawname(1:end-4) '_Ch6.times;'])
    
    eval(['Allspktimes = ' rawname(1:end-4) '_Ch7.times;'])
    eval(['spkcodes = ' rawname(1:end-4) '_Ch7.codes;'])
    
    
    eval(['eyeSamplingRate = ' rawname(1:end-4) '_Ch3.interval;'])
    eval(['eyeTimeStamps = ' rawname(1:end-4) '_Ch3.times;'])
    
    numIdx1sec = round(1/eyeSamplingRate);
    %numIdxLittlePost = round(0.5/eyeSamplingRate);
    
    
    if length(unique(spkcodes(:,1))) > 1
        disp([num2str(length(unique(spkcodes(:,1)))) ' Clusters'])
    end
    
    clus = 1;
    spktimes = Allspktimes(spkcodes(:,1) == clus);
    
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
    
    timeFlashes = [];
    numFlashesTBE = 25; % number of flashes to be expected
    
    for trl = 1:length(idxTstart)
        thisIndFlashes = find(idxOn > idxTstart(trl) & idxOn < idxTstop(trl));
        thisNumFlashes = length(thisIndFlashes);
        
        if thisNumFlashes == numFlashesTBE
            % full set
            timeFlashes(end+1:end+ numFlashesTBE,1) = photoTS(idxOn(thisIndFlashes));
        else
            fprintf('Num flashes: %i \n', thisNumFlashes);
        end
    end
    
    fprintf('Number of flashes Per Trial: %i. \n Number of Flashes Total: %i \n', numFlashesTBE, length(timeFlashes))
        
    %% determine when the eye was stationary and where the eye was for each of the flashes
    
    poststimdur = 0.15; % in seconds; the duration to look at after stim onset
    
    eyePosX = nan(length(timeFlashes),1);
    eyePosY = nan(length(timeFlashes),1);
    
    for nf = 1:length(timeFlashes)
        
        idxThisEyeDur = find(eyeTimeStamps > timeFlashes(nf) & eyeTimeStamps < timeFlashes(nf)+poststimdur);
        
        if abs(eyeh(idxThisEyeDur(end)) - eyeh(idxThisEyeDur(1))) < 0.1 & abs(eyev(idxThisEyeDur(end)) - eyev(idxThisEyeDur(1))) < 0.1
            % no saccade occured, use this data
            eyePosX(nf) = nanmean(eyeh(idxThisEyeDur));
            eyePosY(nf) = nanmean(eyev(idxThisEyeDur));
            
            %plot(eyeh(idxThisEyeDur), eyev(idxThisEyeDur),'.r')
            %axis([-5 5 -5 5])
        end
        
    end
    
    % convert voltages to positions
    eyePosX = eyePosX*100;
    eyePosY = -eyePosY*100;
    
        
%% Divide the space into smaller squares to collect firing rate data ------------------- kesh -------- make all this into a loop. In case you use more than 2 stimuli per flash
    
    centeredStoreXlocs(:,1) = storeXlocs(:,1) - screenres(1)/2; centeredStoreXlocs(:,2) = storeXlocs(:,2) - screenres(1)/2;
    centeredStoreYlocs(:,1) = storeYlocs(:,1) - screenres(2)/2; centeredStoreYlocs(:,2) = storeYlocs(:,2) - screenres(2)/2;
    
    % determine where the flash was relative to fixation
    relXlocs1 = eyePosX - centeredStoreXlocs(:,1); relXlocs2 = eyePosX - centeredStoreXlocs(:,2);
    relYlocs1 = -eyePosY - (-centeredStoreYlocs(:,1)); relYlocs2 = -eyePosY - (-centeredStoreYlocs(:,2));
    
    % some quick checks
    %plot(eyePosX, -eyePosY, '.b', storeXlocs, -storeYlocs, '.r', relXlocs1, relYlocs1, 'bo'); axis([-screenres(1) screenres(1) -screenres(2) screenres(2)]); view(0, -90)
    %plot(eyePosX(2), eyePosY(2), '.b', storeXlocs(2,1), storeYlocs(2,1), '.r', relXlocs1(2), relYlocs1(2), 'bo'); axis([-screenres(1) screenres(1) -screenres(2) screenres(2)]);
    
    % x range and y range
    xrng = [-screenres(1)/1.5 screenres(1)/1.5];
    yrng = [-screenres(2)/1.5 screenres(2)/1.5];
    
    hbins = linspace(xrng(1), xrng(2), xdiv);
    vbins = linspace(yrng(1), yrng(2), ydiv);
    
    
    for col = 1:ydiv - 1
        for row = 1:xdiv - 1
            
            indFlash1 = find(relXlocs1 > hbins(row) & relXlocs1 < hbins(row+1) & relYlocs1 > vbins(col) & relYlocs1 < vbins(col+1));
            indFlash2 = find(relXlocs2 > hbins(row) & relXlocs2 < hbins(row+1) & relYlocs2 > vbins(col) & relYlocs2 < vbins(col+1));
            
            thisTimeFlash = [];
            
            try
                timeFlash1 = timeFlashes(indFlash1);
                timeFlash2 = timeFlashes(indFlash2);
                
                thistotflashes = length(timeFlash1) + length(timeFlash2);
                
                if thistotflashes > 0
                    frtrls(row,col) = frtrls(row,col) + thistotflashes; % can be used later to normalize fr by number of flashes - in cases there's some biases
                end
            end
            
            thisTimeFlash = [timeFlash1; timeFlash2];

            
            % determine the number of spikes that occur in the epoch after the
            % flashs in this location
            
            thisNeuSpks = 0;
            
            for numF = 1:length(thisTimeFlash)
                thisNeuSpks = thisNeuSpks + sum(spktimes > thisTimeFlash(numF) & spktimes < thisTimeFlash(numF) + poststimdur);
            end % numF
            
            
            frmat(row,col) = frmat(row,col) + thisNeuSpks;
            
        end %row
    end% col
    
end

% plot what the heatmap looks like


figure(1), clf, hold on,
heatmap(rot90(frmat./frtrls));
axis([0 xdiv 0 ydiv])
ax = axis;
line(ax(1:2),[mean(ax(3:4)) mean(ax(3:4))], 'LineStyle', '--','LineWidth', 2, 'Color', 'k')
line([mean(ax(1:2)) mean(ax(1:2))], ax(3:4), 'LineStyle', '--','LineWidth', 2, 'Color', 'k')

figure(2), clf
subplot(2,2,1)
heatmap(rot90(frmat));
subplot(2,2,2)
heatmap(rot90(frtrls));
