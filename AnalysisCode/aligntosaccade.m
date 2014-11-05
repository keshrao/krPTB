%% align to all saccades
clear, clc, figure(1), clf

targetdir = 'C:\Users\Hrishikesh\Data\krPTBData\';
[filename, pathname] = uigetfile([targetdir 'S43*.mat'], 'Load Exp Session File (not sp2)', 'MultiSelect', 'on');
fullpathname = strcat(pathname, filename); % all the files in pathname

%% setting general variables

for i = 1:9, totRelSpks{i} = []; end
trly = zeros(9,1);
pretime = 0.3; % look 200ms prior to the saccade
posttime = 0.3; % time after saccade

for i = 1:9, totRelSpks{i} = []; end
trly = zeros(9,1);

%% load file and data

if iscell(fullpathname)
    thisfilename = fullpathname{dt};
    rawname = filename{dt};
else
    thisfilename = fullpathname;
    rawname = filename;
end

load(strcat(thisfilename(1:end-4)))

eval(['eyeh = ' rawname(1:end-8) '_Ch3.values;'])
eval(['eyeTS = ' rawname(1:end-8) '_Ch3.times;'])
eval(['eyev = ' rawname(1:end-8) '_Ch4.values;'])
eval(['trig = ' rawname(1:end-8) '_Ch5.values;'])
eval(['trigTS = ' rawname(1:end-8) '_Ch5.times;'])
eval(['photo = ' rawname(1:end-8) '_Ch6.values;'])
eval(['photoTS = ' rawname(1:end-8) '_Ch6.times;'])

eval(['Allspktimes = ' rawname(1:end-8) '_Ch7.times;'])
eval(['spkcodes = ' rawname(1:end-8) '_Ch7.codes;'])

eval(['eyeSamplingRate = ' rawname(1:end-8) '_Ch3.interval;'])
eval(['eyeTS = ' rawname(1:end-8) '_Ch3.times;'])

%% detect saccades

eyeSpd = sqrt(diff(eyeh).^2 + diff(eyev).^2); 

%arbit threshold of 0.03
[pks, locs] = findpeaks(eyeSpd, 'minpeakheight', 0.03, 'minpeakdistance', 200);

% clf
% plot([eyeTS(locs) eyeTS(locs)], [-4 4]', '-r'); hold all
% plot(eyeTS, eyeh, 'b', 'LineWidth', 2) 
% plot(eyeTS, eyev, 'g', 'LineWidth', 2)
% plot(eyeTS(1:end-1), eyeSpd, 'b', eyeTS(locs), pks, 'r^')

%look 25 index before and after the peak saccade velocity to determine dir
locsPre = locs - 25;
locsPost = locs + 25;

deltaH = eyeh(locsPost) - eyeh(locsPre);
deltaV = eyev(locsPost) - eyev(locsPre);

dirVec = nan(length(deltaH),1);
subpsac = nan(length(deltaH),1);

% compute the direction of saccade and the appropriate subplot to put it in
for row = 1:length(deltaH)
    
    dirVec(row) = atan2d(deltaV(row), deltaH(row));
    subpsac(row) = computesubpnum(dirVec(row));
    
end


%% Make rasters for the different directions
for clus = [1 2 3 4]
    
    fprintf('Plotting Clus: %i \n', clus)
    
    
    spktimes = Allspktimes(spkcodes(:,1) == clus);
    sactimes = eyeTS(locs);
    
    
    for si = 1:length(dirVec) % for all saccades
        
        aligntime = sactimes(si);
        thisspkidx = spktimes > aligntime - pretime & spktimes < aligntime + posttime;
        thisspktimes = spktimes(thisspkidx);
        thisspkreltimes = thisspktimes - aligntime;
        
        subplot(3,3,subpsac(si)), hold on
        for spi = 1:length(thisspkreltimes)
            plot([thisspkreltimes(spi) thisspkreltimes(spi)], [0.1+trly(subpsac(si)) 1+trly(subpsac(si))], 'k', 'LineWidth', 1.5)
            xlim([-pretime posttime])
        end
        drawnow, pause(0.000001)
        
        totRelSpks{subpsac(si)} = [totRelSpks{subpsac(si)} thisspkreltimes'];
        trly(subpsac(si)) = trly(subpsac(si)) + 1;
        
    end
   
    
end

%% construct psth

for subpnum = [1:4 6:9]
    subplot(3,3,subpnum)
    ax = axis;
    
    plot([0 0], [0 ax(4)], 'b', 'LineWidth', 2)
    
    [bins, binwidth, psth] = buildpsth(pretime, posttime, totRelSpks{subpnum});
    plot(bins(1:end-1)+(binwidth/2), psth./40, 'r', 'LineWidth', 2)
    
    
    title('Aligned to Saccade')
    drawnow
end %subplot titles