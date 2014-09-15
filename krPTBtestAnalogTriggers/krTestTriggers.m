%function krTestTriggers()
clc, clear

[ai, ~] = krConnectDAQtemptest();

%toplot = zeros(1,3);

trig = zeros(200,4000);
temptic = nan(1,200);

close all
for p = 1:200
    tic
    try
        
        [eyePosX eyePosY trigger] = krGetEyePostemptest1(ai);
        
        temptic(p) = toc;
        
        
        trig(p,:) = trigger;
        
        
    catch
        %disp(toc)
    end
    %toplot(end+1,:) = [eyePosX, eyePosY, trigger];
%    tic
    %plot(trigger); 
    %plot(toplot);
    %axis([size(toplot,1)-100 size(toplot,1)+20 -5 5])
    
    %ylim([-1 10])
    %drawnow
    
    
%    tig(p*400000+1:(p+1)*400000)=  trigger;
%    toc
end

fprintf('Mean Sample Delay: %f\n',nanmean(temptic))


figure(1);clf;
plot(trig(1,:));
figure(2);clf;
plot(diff(trig(1,:)));
a = zeros(1,200);

for row = 1:200, 
    a(row) = ceil(length(findpeaks(abs(diff(trig(row,:))),'MINPEAKHEIGHT',0.3))/2); 
end

figure(3)
hist(a)
