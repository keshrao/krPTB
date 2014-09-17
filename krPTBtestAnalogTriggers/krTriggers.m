function numPeaks = krTriggers(ai, dur, samplerate)

%% Initiate
preSampleRate = ai.SampleRate;
if nargin < 3 && nargin > 1
    dur = 1; % s
    ai.SampleRate = 100000;
end
ai.SamplesPerTrigger = dur*ai.SampleRate;
ai.TriggerType = 'manual';

%% Acquire Data
start(ai);
trigger(ai);

data = getdata(ai, ai.SampleRate*dur);

flushdata(ai);
stop(ai);

plot(data(:,3))
%% determine the number of pulses that occured
numPeaks = length(findpeaks(diff(data(:,3)),'MINPEAKHEIGHT',1));
ai.SampleRate = preSampleRate;