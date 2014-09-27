%
load('SixxL3P1')

%raw_signal = S20_1p5.values;
%filteredSignal = S10L3P0_510_Ch401.values;

spk_waveforms = S20_1p5_Ch6.values; % includes spk times & 76 idx of data per waveform
spk_codes = S20_1p5_Ch6.codes; % all neuron units recorded. Find uniques
spk_times = S20_1p5_Ch6.times; % in sec 

eyeH = S20_1p5_Ch3.values;
eyeV = S20_1p5_Ch4.values;

trigTimes = S20_1p5_Ch5.times;
%

%% detect saccades

durSesh = length(eyeH);

eyeSpd = sqrt(diff(eyeH).^2 + diff(eyeV).^2); 

%arbit threshold of 0.03
[pks, locs] = findpeaks(eyeSpd, 'minpeakheight', 0.03, 'minpeakdistance', 200);

% clf
% plot([locs locs], [-4 4]', '-r'); hold all
% plot(1:durSesh, eyeH, 'b', 'LineWidth', 2) 
% plot(1:durSesh, eyeV, 'g', 'LineWidth', 2)
% plot(1:durSesh-1, eyeSpd, 'b', locs, pks, 'r^')

%look 25 index before and after the peak saccade velocity to determine dir
locsPre = locs - 25;
locsPost = locs + 25;

deltaH = eyeH(locsPost) - eyeH(locsPre);
deltaV = eyeV(locsPost) - eyeH(locsPre);
dirVec = nan(length(deltaH),1);

for row = 1:length(deltaH)
   
    if deltaH(row) < 0 && deltaV(row) > 0 
        %top left
        dirVec(row) = 1;
    elseif deltaH(row) > 0 && deltaV(row) > 0 
        %top right
        dirVec(row) = 2;
    elseif deltaH(row) > 0 && deltaV(row) < 0
        %bottom right
        dirVec(row) = 3;
    elseif deltaH(row) < 0 && deltaV(row) < 0 
        %bottom left
        dirVec(row) = 4;
    end    
    
end


%%

%thisNeu = spk_codes(:,1) == 1;
%subSetSpkTimes = spk_times(thisNeu);
subSetSpkTimes = spk_times;


sacTimes = locs./1000; % in sec

% combine all directions
%subSac = sacTimes;

% or take the subsets of directions
 dirNum = 1;
 thisDir = dirVec == dirNum;
 subSac = sacTimes(thisDir);


totRelSpks = [];

pretime = -0.3; % look 200ms prior to the saccade
posttime = 0.3; % time after saccade

figure(5); %clf % this will be for the raster
subplot(2,2,dirNum), 
hold all
plot([0 0],[-1 length(subSac)+10],'r')

for s = 1:length(subSac) % for all saccades
    
    thisIdx = find(subSetSpkTimes > subSac(s)+pretime & subSetSpkTimes < subSac(s) + posttime);
    thisSpkTimes = subSetSpkTimes(thisIdx);
    relSpkTimes = thisSpkTimes -  subSac(s);
    
    % force col vector
    
    if ~isempty(relSpkTimes) && length(relSpkTimes) == 2
        plot([relSpkTimes'; relSpkTimes'], [s-0.9 s-0.1], 'k')
    elseif ~isempty(relSpkTimes)
        plot([relSpkTimes relSpkTimes], [s-1 s], 'k', 'LineWidth', 3)
    end
    
    totRelSpks = cat(1,totRelSpks, relSpkTimes);
    
end


%% construct psth

% bin data into 5ms bins & determine firing rate
binwidth = 0.01;
bins = pretime:binwidth:posttime;
binned = nan(1,length(bins)-1);

for bi = 1:length(bins)-1
    thisDataIdx = totRelSpks > bins(bi) & totRelSpks < bins(bi+1);
    binned(bi) = sum(thisDataIdx)./binwidth;
end

gausKer = normpdf(-0.01:0.001:0.01, 0, 0.01);
psth = conv(binned, gausKer, 'same');

plot(bins(1:end-1)+(binwidth/2), psth./sum(gausKer)./10,'r')

ylim([-1 length(subSac)+10])
%ylim([-1 100])

xlabel('Time Rel To Saccade Onset (sec)', 'FontSize',20)
ylabel('Trial # (or) Neuron Firing','FontSize',20)

t=title('S10L3P0_510','FontSize',20);
set(t, 'Interpreter', 'none'); % silly underscore controler