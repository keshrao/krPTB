function krTestTriggers()


[ai, ~] = krConnectDAQtemptest();


toplot = zeros(1,3);

close all
while 1
    try
        [eyePosX eyePosY trigger] = krGetEyePostemptest(ai);
    end
    toplot(end+1,:) = [eyePosX, eyePosY, trigger];
    plot(toplot); 
    axis([size(toplot,1)-100 size(toplot,1)+20 -5 5])
    drawnow
end