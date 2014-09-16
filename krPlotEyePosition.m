function krPlotEyePosition()


[ai, ~] = krConnectDAQ();

whichScreen = 2;
res = Screen('Resolution',whichScreen);

figure(1), clf
axis([-res.width/2 res.width/2 -res.height/2 res.height/2]);
hold on
rectangle('Position', [0 0 10 10], 'FaceColor', 'black'); % center of the screen
hEye = rectangle('Position', [0, 0 25 25],'FaceColor','red'); %<- note, x,y,w,h as opposed to PTB's convention
set(gca, 'color', 'none')


toplot = 1;

while toplot
    [eyePosX eyePosY] = krGetEyePos(ai);
    set(hEye, 'Position', [eyePosX eyePosY 25 25]); 
end