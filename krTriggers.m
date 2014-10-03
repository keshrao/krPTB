function numPeaks = krTriggers(ai, dur, samplerate)

%% Initiate
preSampleRate = ai.SampleRate;
if nargin == 1
    dur = 1; % s
    ai.SampleRate = 100000;
elseif nargin == 2
    ai.SampleRate = 100000;
elseif nargin == 3
    ai.SampleRate = samplerate;
end
ai.SamplesPerTrigger = dur*ai.SampleRate;


%% Acquire Data
start(ai);
data = getdata(ai, ai.SampleRate*dur);
flushdata(ai);
stop(ai);


%% determine the number of pulses that occured
numPeaks = length(findpeaks(diff(data(:,3)),'MINPEAKHEIGHT',1));
ai.SampleRate = preSampleRate;
ai.SamplesPerTrigger = 1;