function [eyePosX eyePosY trigger] = krGetEyePostemptest(ai)

% this file is in krPlotEPos

start(ai);
[d ~] = getdata(ai);
flushdata(ai);
stop(ai);

eyePosX = d(end,1); % scaling from volts to deg
eyePosY = d(end,2); % scaling from volts to deg
trigger = d(end,3);