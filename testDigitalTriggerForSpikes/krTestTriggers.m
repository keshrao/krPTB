%function krTestTriggers()


[ai, ~] = krConnectDAQ();

toplot = 1;

close
toStore = [];

while toplot
    [eyePosX eyePosY triggs] = krGetEyePos(ai);
    %plot(0, eyePosX, 'bo', eyePosY, 0, 'ro', triggs, triggs, 'gx')
    %axis([-20 20 -20 20])
    
    
    toStore(end+1) = triggs;
    
    plot(toStore)
    
    ylim([-10 10])
    xlim([length(toStore)-200 length(toStore)+20])
    drawnow
end
    


