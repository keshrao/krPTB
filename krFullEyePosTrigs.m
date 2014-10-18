function [data,time, saclocs] = krFullEyePosTrigs(ai, dur)

%% Initiate
preSampleRate = ai.SampleRate;

ai.SampleRate = 500000;
ai.SamplesPerTrigger = dur*ai.SampleRate;

%% Acquire Data
start(ai);
[data, time] = getdata(ai, ai.SampleRate*dur);
flushdata(ai);
stop(ai);

%% determine the number of saccades that occur

ex = movingmean(data(:,1)*100, 2000); % this process can be slow
ey = movingmean(data(:,2)*100, 2000);

% find when saccades happen
spdeye = sqrt(diff(ex) .^2 + diff(ey).^2) .* 1000 .* 10; % to secs & then to deg

%arbitrary threshold
sacthresh = 30; %deg/sec
[~, saclocs] = findpeaks(spdeye, 'MINPEAKHEIGHT', sacthresh ,'MINPEAKDISTANCE',5000);

%% reset to old settings
ai.SampleRate = preSampleRate;
ai.SamplesPerTrigger = 1;