xdiv = 60;
ydiv = 60; % number of x/y divisions

frmat = zeros(xdiv, ydiv);
frtrls = zeros(xdiv, ydiv);

datetimeDate = {'08-Sep'};
datetimeTime = {'1131'};
    
whichdir = '\\ccn-sommerserv.win.duke.edu\Data\ke$ha\Sixx\krPTB\';

%% Because I want to combine files and build up the firing rate plots

for dt = 1:length(datetimeTime)
    
    fName = [datetimeDate{dt} '-2014-' datetimeTime{dt}];
    fEval = ['V' datetimeDate{dt} '_2014_' datetimeTime{dt}];
    
    load([whichdir fName '.mat'])
    load([whichdir fName '_sp2.mat'])
    
    eval(['eyeh = ' fEval '_Ch3.values;'])
    eval(['eyev = ' fEval '_Ch4.values;'])
    eval(['trig = ' fEval '_Ch5.values;'])
    eval(['photo = ' fEval '_Ch6.values;'])
    eval(['photoTS = ' fEval '_Ch6.times;'])
    
    try
        eval(['Allspktimes = ' fEval '_Ch7.times;'])
        eval(['spkcodes = ' fEval '_Ch7.codes;'])
    catch
        eval(['Allspktimes = ' fEval '_Ch8.times;'])
        eval(['spkcodes = ' fEval '_Ch8.codes;'])
    end
    
    eval(['eyeSamplingRate = ' fEval '_Ch3.interval;'])
    
    numIdx1sec = round(1/eyeSamplingRate);
    %numIdxLittlePost = round(0.5/eyeSamplingRate);
    
    
    if length(unique(spkcodes(:,1))) > 1
        disp([num2str(length(unique(spkcodes(:,1)))) ' Clusters'])
    end
    
    clus = 3;
    spktimes = Allspktimes(spkcodes(:,1) == clus);
    
    %% Get data (bookkeeping)
    
    % smooth out the photocell
    idxPhoto = photo > 0.01;
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
        
    %% plot the eye position
    
    % figure(1), clf
    % subplot(2,1,1), hold on, ylim([-5 5]),
    % subplot(2,1,2), hold on, ylim([-5 5])
    %
    %
    % for trl = 1:length(succTrls)
    %
    %     idxToPlot = idxTstart(succTrls(trl))-numIdx1sec:idxTstop(succTrls(trl))+numIdx1sec;
    %
    %     numSecs = length(idxToPlot)*eyeSamplingRate;
    %     plotStartSecs = -1;
    %     plotEndSecs = numSecs-1;
    %     plotXvec = linspace(plotStartSecs,plotEndSecs,length(idxToPlot));
    %
    %     subplot(2,1,1)
    %         plot(plotXvec,eyeh(idxToPlot), 'b')
    %
    %     subplot(2,1,2)
    %         plot(plotXvec,eyev(idxToPlot), 'r')
    %
    %     drawnow
    % end
    %
    % subplot(2,1,1), axis tight
    % subplot(2,1,2), axis tight
    
    
    %% Divide the space into smaller squares to collect firing rate data
    
    % xrange = 100 - 1000
    % yrange = 50 - 700
    xrng = [100 1000];
    yrng = [50 700];
    
    
    hbins = linspace(xrng(1), xrng(2), xdiv);
    vbins = linspace(yrng(1), yrng(2), ydiv);
    
    poststimdur = 0.15; % in seconds
    
    for col = 1:ydiv - 1
        for row = 1:xdiv - 1
            
            indFlash1 = find(storeXlocs(:,1) > hbins(row) & storeXlocs(:,1) < hbins(row+1) & storeYlocs(:,1) > vbins(col) & storeYlocs(:,1) < vbins(col+1));
            indFlash2 = find(storeXlocs(:,2) > hbins(row) & storeXlocs(:,2) < hbins(row+1) & storeYlocs(:,2) > vbins(col) & storeYlocs(:,2) < vbins(col+1));
            
            timeFlash = [];
            try
                timeFlash1 = timeFlashes(indFlash1);
                timeFlash2 = timeFlashes(indFlash2);
                frtrls(row,col) = frtrls(row,col) + 1;
            end
            
            timeFlash = [timeFlash1; timeFlash2];
            
            % determine the number of spikes that occur in the 200ms after the
            % flashs in this location
            
            thisNeuSpks = 0;
            
            for numF = 1:length(timeFlash)
                thisNeuSpks = thisNeuSpks + sum(spktimes > timeFlash(numF) & spktimes < timeFlash(numF) + poststimdur);
            end % numF
            
            
            frmat(row,col) = frmat(row,col) + thisNeuSpks;
            
        end %row
    end% col
    
end

%% plot what the heatmap looks like

clf, hold on
figure(1), heatmap(frmat)
axis([0.5 30 0.5 27])

ax = axis;
line(ax(1:2),[mean(ax(3:4)) mean(ax(3:4))], 'LineStyle', '--','LineWidth', 2, 'Color', 'k')
line([mean(ax(1:2)) mean(ax(1:2))], ax(3:4), 'LineStyle', '--','LineWidth', 2, 'Color', 'k')
