function [data,time, saclocs, ex, ey, spdeye] = krPeekFullEyePosTrigs(ai, dur)

%% Acquire Data
data = [];
temptic = tic;
while isempty(data) && toc(temptic) < dur*1.5
    data = peekdata(ai,ai.SampleRate*dur);
end
if isempty(data)
    data(1,4) = 0;
end

flushdata(ai);
time = linspace(0,dur,length(data))';
%% determine the number of saccades that occur

filtdur = 2000;

ex = movingmean(data(:,1)*100,filtdur); % this process can be slow
ey = movingmean(data(:,2)*100,filtdur);



% find when saccades happen
spdeye = sqrt(diff(ex) .^2 + diff(ey).^2) .* 1000 .* 100; % to secs & then to deg
spdeye = movingmean(spdeye, filtdur);
spdeye(1:filtdur*1.5) = 0;
spdeye(end-(filtdur*1.5):end) = 0; % around 2ms

%arbitrary threshold
sacthresh = 150; %deg/sec
[~, saclocs] = findpeaks(spdeye, 'MINPEAKHEIGHT', sacthresh ,'MINPEAKDISTANCE',100000);

length(saclocs)

%% reset to old settings
