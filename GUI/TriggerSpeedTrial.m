clear all;
[ai, dio] = krConnectDAQTrigger();

ai.SampleRate = 1000000;
ai.SamplesPerTrigger = 1000;
ai.TriggerType = 'manual';
set(ai,'TriggerRepeat',inf);

num = 10;
tocpeekdata = zeros(num,1);
a = zeros(1000,4);

stop(ai);
start(ai);
pause(0.01);
trigger(ai);
for i = 1:num;
   l = (i*4)-4;
   tic
   a=peekdata(ai,1000);
   tocpeekdata(i) = toc;
   pause(0.001)
end

stop(ai)






%set(ai,'TriggerRepeat',inf);
% 
% if(isrunning(ai))
%     isrunning(ai)
%     stop(ai)
% end
% num = 10;
% tocstart = zeros(num,1);
% tocstop = zeros(num,1);
% toctrigger = zeros(num,1);
% tocgetdata = zeros(num,1);
% tic
% start(ai)
% tocstart(1) = toc;
% trigger(ai)
% for i = 1:num;
% 
% 
% % tic
% % trigger(ai)
% % toctrigger(i) = toc;
% 
% tic
% a = peekdata(ai,1000);
% tocgetdata(i) = toc;
% 
% 
% end
% tic
% stop(ai)
% tocstop(1) = toc;
% [tocstart toctrigger tocgetdata tocstop]
% 
% 
% tic
% trigger(ai);
% toc
% tic
% data = getdata(ai);
% toc
% 
% flushdata(ai)
% stop(ai)