clear, clc
warning off

clustertouse = 1;
%clus = 1;

%% pick a file

targetdir = 'C:\Users\Hrishikesh\Data\krPTBData\';
[filename, pathname] = uigetfile([targetdir 'S41*.mat'], 'Load Exp Session File (not sp2)', 'MultiSelect', 'on');
fullpathname = strcat(pathname, filename); % all the files in pathname

if iscell(fullpathname)
    numfiles = length(fullpathname);
else
    numfiles = 1;
end

%% Setting various parameters
figure(1), clf
figure(2), clf
figure(3), clf
figure(4), clf

for i = 1:9, totRelSpksT{i} = []; end % when saccade lands on a target
for i = 1:9, totRelSpksNT{i} = []; end % when saccade doesn't land on a target
for i = 1:9, totRelSpksITT{i} = []; end % inter trial time
trlyT = zeros(9,1);
trlyNT = zeros(9,1);
trlyITT = zeros(9,1);


presacdur = 0.3;
postsacdur = 0.3;

hasprinted = false;

% screen resolution 1024x768
xcent = 512;
ycent = 384;


%% begin analysis
for clus = clustertouse
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
        idxPhoto = photo > 0.25;
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
            timeFlashesOn = [timeFlashesOn; photoTS(idxOn(thisIndFlashes))];
            timeFlashesOff = [timeFlashesOff; photoTS(idxOff(thisIndFlashes))];
        end
        
        if size(storeXlocs,1) ~= length(timeFlashesOn)
            keyboard
        end
        fprintf('Num Locs/ Num Flashes: %i/%i\n', size(storeXlocs,1), length(timeFlashesOn))
        
        %% during each flash, determine
        cXlocs = storeXlocs - xcent;
        cYlocs = storeYlocs - ycent;
        
        for nf = 1:length(storeXlocs)
            
            % what is the eye doing during the flash window
            idxThisEyeDur = find(eyeTS > timeFlashesOn(nf) & eyeTS < timeFlashesOff(nf));
            % what is the eye doing during the subsequent blank window
            idxThisBlankDur = find(eyeTS > timeFlashesOff(nf) & eyeTS < timeFlashesOff(nf)+ .150);
            
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
            
            %         figure(3)
            %         clf, subplot(2,2,1), hold on,
            %         plot(ex,ey,'.r'), plot(cXlocs(nf,:),cYlocs(nf,:),'ks');
            %         plot(eyeh(idxThisBlankDur).*100, -eyev(idxThisBlankDur).*100,'.b'),
            %         axis([-400 400 -400 400])
            %         subplot(2,2,3:4), hold on, plot(eyeTS(idxThisEyeDur(1:end-1)),spdeye)
            %         plot(eyeTS(idxThisEyeDur(saclocs)), pks, 'ro'), ylim([0 10])
            %         try
            %             for si = 1:length(saclocs)
            %                 plot(eyeTS(idxThisEyeDur(saclocs(si)-20:saclocs(si)+20)), ones(length(eyeTS(idxThisEyeDur(saclocs(si)-20:saclocs(si)+20))),1), 'k', 'LineWidth', 2)
            %             end
            %         end
            
            
            % for each saccade, determine
            % 1) the direction of motion
            % 2) whether a saccade landed on a target or not
            % 3) the raster plotted in the appropirate figure & subplot
            for si = 1:length(saclocs)
                
                % for ease of access, the local saccade index % global saccade time
                sacind = saclocs(si);
                sactime = eyeTS(idxThisEyeDur(sacind));
                
                if sacind <= 20 || length(filtex) <= sacind + 20
                    % bad saccade
                    continue
                end
                
                %% direction of saccade
                expre = filtex(sacind-20); expost = filtex(sacind + 20);
                eypre = filtey(sacind-20); eypost = filtey(sacind + 20);
                
                dirsac = atan2d(eypost-eypre, expost-expre);
                subpnum = computesubpnum(dirsac);
                
                
                %% lands on target?
                logicXloc = abs(expost - cXlocs(nf,:)) < 30;
                logicYloc = abs(eypost - cYlocs(nf,:)) < 30;
                logictarg = find(logicXloc & logicYloc);
                
                
                %% raster the data
                
                thisspktimes = spktimes(spktimes > sactime-presacdur & spktimes < sactime+postsacdur);
                thisspkreltimes = thisspktimes - sactime;
                
                if isempty(logictarg) % not landed on target = not close to any target
                    totRelSpksNT{subpnum} = [totRelSpksNT{subpnum}; thisspkreltimes];
                    trlyNT(subpnum) = trlyNT(subpnum) + 1;
                    trly = trlyNT;
                    figure(2),subplot(3,3,subpnum), hold on
                else
                    totRelSpksT{subpnum} = [totRelSpksT{subpnum}; thisspkreltimes];
                    trlyT(subpnum) = trlyT(subpnum) + 1;
                    trly = trlyT;
                    figure(1),subplot(3,3,subpnum), hold on
                end
                
                
                for spi = 1:length(thisspkreltimes)
                    plot([thisspkreltimes(spi) thisspkreltimes(spi)], [0.1+trly(subpnum) 1+trly(subpnum)], 'k')
                    xlim([-presacdur postsacdur])
                end
                
                
            end %si saccade number
            
        end % num flashes (nf)
         
        
        %% now compute every saccade made when there was no trial in progress - ie. in the dark without task
        % essentially, the majority of this is the same code
        
        for trlnum = 1:length(idxTstart)-1
            % go from end of one trial to the start of the next
            idxThisEyeDur = find(eyeTS > trigTS(idxTstop(trlnum)) & eyeTS < trigTS(idxTstart(trlnum+1)));
            
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
            
            
            % for each saccade, determine
            % 1) the direction of motion
            % 2) the raster plotted in the appropirate figure & subplot
            for si = 1:length(saclocs)
                
                % for ease of access, the local saccade index % global saccade time
                sacind = saclocs(si);
                sactime = eyeTS(idxThisEyeDur(sacind));
                
                if sacind <= 20 || length(filtex) <= sacind + 20
                    % bad saccade
                    continue
                end
                
                % direction of saccade
                expre = filtex(sacind-20); expost = filtex(sacind + 20);
                eypre = filtey(sacind-20); eypost = filtey(sacind + 20);
                
                dirsac = atan2d(eypost-eypre, expost-expre);
                subpnum = computesubpnum(dirsac);
                                
                % raster the data
                
                thisspktimes = spktimes(spktimes > sactime-presacdur & spktimes < sactime+postsacdur);
                thisspkreltimes = thisspktimes - sactime;
                
                totRelSpksITT{subpnum} = [totRelSpksITT{subpnum}; thisspkreltimes];
                trlyITT(subpnum) = trlyITT(subpnum) + 1;
                trly = trlyITT;
                figure(3),subplot(3,3,subpnum), hold on
                
                for spi = 1:length(thisspkreltimes)
                    plot([thisspkreltimes(spi) thisspkreltimes(spi)], [0.1+trly(subpnum) 1+trly(subpnum)], 'k')
                    xlim([-presacdur postsacdur])
                end
                
                
            end %si saccade number
            
        end %trlnum
        
    end % dt
end %clus

%% now that the data is plotted, plot the psth
for T_NT = 1:3
    
    
    if T_NT == 1
        totRelSpks = totRelSpksT;
        compcolor = {'r'};
        trly = trlyT;
    elseif T_NT == 2
        totRelSpks = totRelSpksNT;
        compcolor = {'b'};
        trly = trlyNT;
    elseif T_NT == 3
        totRelSpks = totRelSpksITT;
        compcolor = {'g'};
        trly = trlyITT;
    end
    
    for subpnum = 1:9
        
        figure(T_NT)
        subplot(3,3,subpnum)
        
        
        [bins, binwidth, psth] = buildpsth(presacdur, postsacdur, totRelSpks{subpnum});
        
        plot(bins(1:end-1)+(binwidth/2), psth./40, 'r', 'LineWidth', 2)
        
        ax = axis; plot([0 0], [0 ax(4)], 'b', 'LineWidth', 2)
        
        if subpnum == 2 && T_NT == 1
            title('Saccade to Location with Stimulus')
        elseif subpnum == 2 && T_NT == 2
            title('Saccade to Location without Stimulus')
        elseif subpnum == 2 && T_NT == 3
            title('Inter-Trial Saccades Made')
        end
        
        % and the comparison
        figure(4)
        subplot(3,3,subpnum), hold on
        plot([0 0], [0 1], 'b', 'LineWidth', 2)
        plot(bins(1:end-1)+(binwidth/2), psth./40./trly(subpnum), compcolor{1}, 'LineWidth', 2)
        ax = axis; plot([0 0], [0 ax(4)], 'b', 'LineWidth', 2)
        
        drawnow
    end %subplot titles
    
end



