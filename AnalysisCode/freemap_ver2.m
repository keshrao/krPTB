clear, clc
warning off

%% setting various parameters

% for heatmaps
xdiv = 40;
ydiv = 40; % number of x/y divisions

frmatpref = zeros(xdiv, ydiv);
frtrlspref = zeros(xdiv, ydiv);
frmeanpref = zeros(xdiv, ydiv);
frmeansqpref = zeros(xdiv, ydiv);
stdevpref = zeros(xdiv, ydiv);

frmatnonpref = zeros(xdiv, ydiv);
frtrlsnonpref = zeros(xdiv, ydiv);
frmeannonpref = zeros(xdiv, ydiv);
frmeansqnonpref = zeros(xdiv, ydiv);
stdevnonpref = zeros(xdiv, ydiv);

%%

% arrays for targs
nonprefXlocs = [];
nonprefYlocs = [];
nonprefFR = [];

prefXlocs = [];
prefYlocs = [];
prefFR = [];

presacdur = 0.3;
postsacdur = 0.3;

% screen resolution 1024x768
xcent = 512;
ycent = 384;



%% pick a file

targetdir = 'C:\Users\Hrishikesh\Data\krPTBData\';
[filename, pathname] = uigetfile([targetdir 'S43*.mat'], 'Load Exp Session File (not sp2)', 'MultiSelect', 'on');
fullpathname = strcat(pathname, filename); % all the files in pathname

if iscell(fullpathname)
    numfiles = length(fullpathname);
else
    numfiles = 1;
end


clustertouse = 1;

for clus = clustertouse;
    hasprinted = false;
    
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
        eval(['photoTS = ' rawname(1:end-4) '_Ch6.times;'])
        
        eval(['Allspktimes = ' rawname(1:end-4) '_Ch7.times;'])
        eval(['spkcodes = ' rawname(1:end-4) '_Ch7.codes;'])
        
        eval(['eyeSamplingRate = ' rawname(1:end-4) '_Ch3.interval;'])
        eval(['eyeTS = ' rawname(1:end-4) '_Ch3.times;'])
        
        numIdx1sec = round(1/eyeSamplingRate);
        
        spktimes = Allspktimes(spkcodes(:,1) == clus);
        
        if ~hasprinted, fprintf('Num Clusters: %i, Cluster Plotted: %i \n', length(unique(spkcodes(:,1))), clus); hasprinted = true; end
        
        %% data bookkeeping
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
        
        % - also importantly, note that the actual times that the photo is on/off
        % photoTS(idxOn(i)) or photoTS(idxOff(i))
        
        if photoTS(idxOff(1)) < photoTS(idxOn(1))
            fprintf('Deleting First Photo Off');
            idxOff(1) = []; % if some video is on the screen, photo dioded is non zero
        end
        
        % smooth out triggers
        idxTrig = trig > 0.1;
        trig(idxTrig) = 0.5;
        trig(~idxTrig) = 0;
        
        dTrig = diff(trig);
        dTrig = [0; dTrig];
        
        idxTstart = find(dTrig == 0.5);
        idxTstop = find(dTrig == -0.5);
        
        %% check for all flashes and store times of each flash
        
        timeFlashesOn = [];
        timeFlashesOff = [];
        % look in every start/stop sequence & count total flashes
        for trl = 1:length(idxTstart)
            thisIndFlashes = find(idxOn > idxTstart(trl) & idxOn < idxTstop(trl));
            
            if length(thisIndFlashes) == 10 || length(thisIndFlashes) == 5
                timeFlashesOn = [timeFlashesOn; photoTS(idxOn(thisIndFlashes))];
                timeFlashesOff = [timeFlashesOff; photoTS(idxOff(thisIndFlashes))];
            elseif length(thisIndFlashes) ~= 10
                fprintf('Removed Trial: %i\n', trl)
                storeXlocs(trl*10-9:trl*10,:) = [];
                storeYlocs(trl*10-9:trl*10,:) = [];
                continue
            end
            
        end
        
        if size(storeXlocs,1) ~= length(timeFlashesOn)
            fprintf('different sizes');
        end
        fprintf('Num Locs/ Num Flashes: %i/%i\n', size(storeXlocs,1), length(timeFlashesOn))
        
        %% for each flash
        cXlocs = storeXlocs - xcent;
        cYlocs = storeYlocs - ycent;
        
        for nf = 1:length(storeXlocs)
            
            % what is the eye doing during the flash window + plus a litte bit more after the stimulus turned off
            idxThisEyeDur = find(eyeTS > timeFlashesOn(nf) & eyeTS < timeFlashesOff(nf)+0.150);
            % what is the eye doing during the subsequent blank window
            idxThisBlankDur = find(eyeTS > timeFlashesOff(nf) & eyeTS < timeFlashesOff(nf)+.150);
            
            ex = eyeh(idxThisEyeDur).*100;
            ey = -eyev(idxThisEyeDur).*100;
            
            % saccadic parameters
            filtex = movingmean(ex, 5); % this process can be slow
            filtey = movingmean(ey, 5);
            
            % find when saccades happen
            spdeye = sqrt(diff(filtex) .^2 + diff(filtey).^2); % to secs & then to deg
            
            %arbitrary threshold
            sacthresh = 2; %deg/sec
            [pks, saclocs] = findpeaks(spdeye, 'MINPEAKHEIGHT', sacthresh ,'MINPEAKDISTANCE',50);
            
            % eliminate any weird saccade movements (too early or too late)
            badsac = zeros(1,length(saclocs));
            for si = 1:length(saclocs)
                if saclocs(si) <= 20 || length(filtex) <= saclocs(si) + 20
                    % bad saccade
                    badsac(si) = 1;
                end
            end
            saclocs(logical(badsac)) = [];
            
            sacstart = saclocs;
            sacend = saclocs;
            % for each saccade, find the start and end locations
            for si = 1:length(saclocs)
                
                % keep going backward till saccade start
                while sacstart(si) >= 2 && spdeye(sacstart(si)) >= 0.2
                    sacstart(si) = sacstart(si) - 1;
                end
                
                % keep going forward till saccade end
                while sacend(si) <= length(spdeye)-2 && spdeye(sacend(si)) >= 0.2
                    sacend(si) = sacend(si) + 1;
                end
            end
            
            %         figure(5)
            %         clf, subplot(2,2,1), hold on,
            %         plot(ex,ey,'.r'), plot(cXlocs(nf,:),cYlocs(nf,:),'ks');
            %         plot(eyeh(idxThisBlankDur).*100, -eyev(idxThisBlankDur).*100,'ob'),
            %         axis([-400 400 -400 400])
            %         subplot(2,2,3:4), hold on,
            %         plot(eyeTS(idxThisEyeDur(1:end-1)),spdeye)
            %         plot(eyeTS(idxThisEyeDur(saclocs)), spdeye(saclocs), 'ro')
            %         plot(eyeTS(idxThisEyeDur(sacstart)), spdeye(sacstart), 'rx', 'MarkerSize', 20)
            %         plot(eyeTS(idxThisEyeDur(sacend)), spdeye(sacend), 'rx', 'MarkerSize', 20)
            %         ylim([0 10])
            
            
            
            
            
            %% for each stimulus, determine if a saccade landed on the target
            % if a saccade lands on a target, designate it a preferred target (preftarg)
            % for the target that the saccade avoids, designate it the non preferred target (nonpreftarg)
            
            % number of spikes that occured for this stimulus setting
            thisnumspks = length(spktimes(spktimes > timeFlashesOn(nf) & spktimes < timeFlashesOff(nf)+0.2));
            
            
            % if no saccade happens, both targets are non preferred
            if isempty(saclocs)
                
                % if no saccades, for now, just skip it 
                continue
                
                % if both non-preferred, then find out where the targets were relative to the eye position
                relXlocs = cXlocs(nf,:) - nanmean(filtex);
                relYlocs = cYlocs(nf,:) - nanmean(filtey);
                
                % store into array the nonpref targ locations and the number of spikes that occured in that on+off window
                nonprefXlocs = [nonprefXlocs relXlocs];
                nonprefYlocs = [nonprefYlocs relYlocs];
                nonprefFR = [nonprefFR thisnumspks thisnumspks]; % two values
                
            else
                
                % if there is a saccade, find out if a saccade ended on a target
                for si = 1:length(saclocs)
                    
                    % for ease of access, the local saccade index
                    sacind = saclocs(si);
                    % global saccade time
                    sactime = eyeTS(idxThisEyeDur(sacind));
                    
                    
                    expost = filtex(sacend(si)); eypost = filtey(sacend(si));
                    logicXloc = abs(expost - cXlocs(nf,:)) < 60;
                    logicYloc = abs(eypost - cYlocs(nf,:)) < 60;
                    logictarg = find(logicXloc & logicYloc);
                    
                    
                    expre = filtex(sacstart(si)); eypre = filtey(sacstart(si));
                    relXlocs = cXlocs(nf,:) - expre;
                    relYlocs = cYlocs(nf,:) - eypre;
                    
                    if length(logictarg) == 1 && logictarg == 1 % targ one is pref and targ 2 is nonpref
                        prefXlocs = [prefXlocs relXlocs(1)];
                        prefYlocs = [prefYlocs relYlocs(1)];
                        prefFR = [prefFR thisnumspks];
                        
                        nonprefXlocs = [nonprefXlocs relXlocs(2)];
                        nonprefYlocs = [nonprefYlocs relYlocs(2)];
                        nonprefFR = [nonprefFR thisnumspks];
                        
                    elseif length(logictarg) == 1 && logictarg == 2 % target two is pref and targ 1 is nonpref
                        
                        prefXlocs = [prefXlocs relXlocs(2)];
                        prefYlocs = [prefYlocs relYlocs(2)];
                        prefFR = [prefFR thisnumspks];
                        
                        nonprefXlocs = [nonprefXlocs relXlocs(1)];
                        nonprefYlocs = [nonprefYlocs relYlocs(1)];
                        nonprefFR = [nonprefFR thisnumspks];
                        
                    elseif length(logictarg) == 2
                        
                        continue
                        prefXlocs = [prefXlocs relXlocs];
                        prefYlocs = [prefYlocs relYlocs];
                        prefFR = [prefFR thisnumspks thisnumspks];
                        
                        
                    end % logic targ statements
                    
                    
                    
                end % si sacades
                
            end % if saccaded
            
        end % num flashes (nf)
        
        
        %% now that all the matricies are collected, plot the heatmaps
        
        hbins = linspace(-xcent, xcent, xdiv);
        vbins = linspace(-ycent, ycent, ydiv);
        
        for col = 1:ydiv - 1
            for row = 1:xdiv - 1
                
                indFlashPref = find(prefXlocs > hbins(row) & prefXlocs < hbins(row+1) & ...
                    prefYlocs > vbins(col) & prefYlocs < vbins(col+1));
                
                
                if ~isempty(indFlashPref)
                    frmatpref(row,col) = frmatpref(row,col) + sum(prefFR(indFlashPref));
                    frtrlspref(row,col) = frtrlspref(row,col) + length(indFlashPref);
                    
                    frmeansqpref(row,col) = frmeansqpref(row,col) + sum(prefFR(indFlashPref))^2;
                    
                end
                
                
                indFlashNonPref = find(nonprefXlocs > hbins(row) & nonprefXlocs < hbins(row+1) & ...
                    nonprefYlocs > vbins(col) & nonprefYlocs < vbins(col+1));
                
                if ~isempty(indFlashNonPref)
                    frmatnonpref(row,col) = frmatnonpref(row,col) + sum(nonprefFR(indFlashNonPref));
                    frtrlsnonpref(row,col) = frtrlsnonpref(row,col) + length(indFlashNonPref);
                    
                    frmeansqnonpref(row,col) = frmeansqnonpref(row,col) + sum(nonprefFR(indFlashNonPref))^2;
                end
                
                
            end %row
        end% col
        
        
        
        %% now that we've collected the data, plot the heatmaps
        
        % compute the std based on mean and mean^2
        stdevpref = sqrt((frmeansqpref./frtrlspref) - (frmeanpref.^2));
        stdevnonpref = sqrt((frmeansqnonpref./frtrlsnonpref) - (frmeannonpref.^2));

        stdevpref(isnan(stdevpref)) = 1;
        stdevnonpref(isnan(stdevnonpref)) = 1;
        
        figure(1), clf, hold on
        heatmap(rot90(frmatpref./frtrlspref));
        axis([0.5 xdiv 0.5 ydiv])
        ax = axis;
        line(ax(1:2),[mean(ax(3:4)) mean(ax(3:4))], 'LineStyle', '--','LineWidth', 2, 'Color', 'k')
        line([mean(ax(1:2)) mean(ax(1:2))], ax(3:4), 'LineStyle', '--','LineWidth', 2, 'Color', 'k')
        title('Preferred/Selected Stimuli')
        drawnow
        
        figure(2), clf, hold on
        heatmap(rot90(frmatnonpref./frtrlsnonpref));
        axis([0.5 xdiv 0.5 ydiv])
        ax = axis;
        line(ax(1:2),[mean(ax(3:4)) mean(ax(3:4))], 'LineStyle', '--','LineWidth', 2, 'Color', 'k')
        line([mean(ax(1:2)) mean(ax(1:2))], ax(3:4), 'LineStyle', '--','LineWidth', 2, 'Color', 'k')
        title('Non-Preferred/Un-Selected Stimuli')
        drawnow
        
        
        fprintf('Total Trials: %i/%i\n', sum(sum(frtrlspref)), sum(sum(frtrlsnonpref)))
        
    end%dt
    
    
end %clus