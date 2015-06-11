function numtrigs = krPeekTriggers(ai, dur)

%% Acquire Data
data = [];
temptic = tic;
while isempty(data) && toc(temptic) < dur*1.5
    data = peekdata(ai,ai.SampleRate*dur);
end

flushdata(ai);

numtrigs = length(findpeaks(diff(data(:,3)),'MINPEAKHEIGHT',1));