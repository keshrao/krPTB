function [eyePosX eyePosY] = krGetEyePos(ai)


start(ai);
[d t] = getdata(ai);
flushdata(ai);
stop(ai);

eyePosX = d(end,1)*10; % scaling from volts to deg
eyePosY = d(end,2)*10; % scaling from volts to deg