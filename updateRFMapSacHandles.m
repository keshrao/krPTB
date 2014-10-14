function [frmat, frtrls] = updateRFMapSacHandles(handles, frmat, frtrls, randXpos, randYpos, numtrigs, subpnum)

global xdiv

xdiv = 40;

xrng = [150 850]; % try to keep the ratio of 1048x768 ~~ 4:3
yrng = [50 650];

hbins = linspace(xrng(1), xrng(2), xdiv);
vbins = linspace(yrng(1), yrng(2), xdiv);


for i = 1:length(randXpos)
    row = find(hbins > randXpos(i), 1, 'first'); 
    col = find(vbins > randYpos(i), 1, 'first');
    
    frmat(row, col) = frmat(row, col) + numtrigs;
    frtrls(row,col) = frtrls(row, col) + 1;
end


axes(handles.TaskSpecificPlot);
heatmap(rot90(frmat./frtrls));
drawnow