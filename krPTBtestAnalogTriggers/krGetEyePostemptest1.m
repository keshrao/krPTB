function [eyePosX eyePosY trigger] = krGetEyePostemptest1(ai)

% this file is in krPlotEPos

start(ai);
[d ~] = getdata(ai);
flushdata(ai);
stop(ai);


eyePosX = d(:,1); % scaling from volts to deg
eyePosY = d(:,2); % scaling from volts to deg
trigger = d(:,3);