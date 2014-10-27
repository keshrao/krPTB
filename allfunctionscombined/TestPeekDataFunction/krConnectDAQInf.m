function [ai, dio] = krConnectDAQInf()

% connection to daq
ai = analoginput('mcc');

ai.SampleRate = 1000000;  % crazy high
ai.SamplesPerTrigger = ai.SampleRate; % one second of data per trigger

addchannel(ai,0); % eyeh
addchannel(ai,1); % eyev
addchannel(ai,2); % spike triggers
addchannel(ai,3); % dummy channel

ai.TriggerType = 'manual';
set(ai,'TriggerRepeat',inf); % as soon as buffer filled, trigger again

stop(ai);
stop(ai);

start(ai);
trigger(ai); % begin running and logging

% output connections
dio = digitalio('mcc');
addline(dio, 0, 'out'); % reward line
addline(dio, 2, 'out'); % trial triggers
