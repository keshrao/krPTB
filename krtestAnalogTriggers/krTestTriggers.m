%function krTestTriggers()
clc, clear
warning off

[ai, ~] = krConnectDAQ_trigtest();

sampdur = 1; % 1 second acquisition
ai.SampleRate = 100000;
ai.SamplesPerTrigger = sampdur*ai.SampleRate;
ai.TriggerType = 'manual';

timestamps = []; %nan(1000,1);
numsamples = []; %nan(1000000,1);

data = [];

tscntr = 1;
cntr = 1;


start(ai)

trigger(ai)
tic


t1 = toc;
i=1;
for k=1:5
    data = getdata(ai, ai.SampleRate*sampdur/5);
    ns = size(data,1);
    
    timestamps(tscntr) = toc;
    tscntr = tscntr + 1;
    numsamples(cntr: cntr+ns-1) = data(:,3);
    cntr = cntr + ns;
    %flushdata(ai)
    i=i+1;
end
toc
flushdata(ai)
stop(ai)

plot(numsamples)


% determine the number of pulses that occured
length(findpeaks(diff(numsamples),'MINPEAKHEIGHT',1))
