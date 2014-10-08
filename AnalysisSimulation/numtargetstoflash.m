clear, clc

xdiv = 40;
ydiv = 40;

frmat = zeros(xdiv, ydiv);
frstd = zeros(xdiv, ydiv);

xrng = [-500 500];
yrng = [-500 500];

%% Generate fake flashed stimulus locations & neural responses

for numstim = 1:20
    
    numtrls = 500;
    
    storeXlocs = randi(xrng,[numtrls, numstim]);
    storeYlocs = randi(yrng,[numtrls, numstim]);
    
    RFxloc = [-100 -100];
    RFyloc = [-100 -100];
    spks = zeros(numtrls,1);
    
    for t = 1:numtrls
        if sum(storeXlocs(t,:) > RFxloc(1) & storeXlocs(t,:) < RFxloc(2) & storeYlocs(t,:) > RFyloc(1) & storeYlocs(t,:) < RFyloc(2)) > 0
            spks(t) = randi([10 20],1);
        end
    end
    
    %% Collect firing rate data and make heatmap
    
    hbins = linspace(xrng(1), xrng(2), xdiv);
    vbins = linspace(yrng(1), yrng(2), ydiv);
    
    for col = 1:ydiv - 1
        for row = 1:xdiv - 1
            
            tottnum = [];
            for nf = 1:numstim
                % gives the trial number in which the flash occured coinciding with space of this particular bin
                trlnum = find(storeXlocs(:,nf) > hbins(row) & storeXlocs(:,nf) < hbins(row+1) & storeYlocs(:,nf) > vbins(col) & storeYlocs(:,nf) < vbins(col+1));
                tottnum = [tottnum; trlnum];
            end% numstim
            
            frmat(row,col) = sum(spks(tottnum))./length(tottnum);
            frstd(row,col) = std(spks(tottnum));
            
        end %row
    end %col
    
    
    %% plot the data
    
    figure(1), clf,
    subplot(2,2,1)
    heatmap(rot90(frmat)); % -- why would this plot it rotated? wtf??!
    axis([0.5 xdiv 0.5 ydiv])
    ax = axis;
    line(ax(1:2),[mean(ax(3:4)) mean(ax(3:4))], 'LineStyle', '--','LineWidth', 5, 'Color', 'k')
    line([mean(ax(1:2)) mean(ax(1:2))], ax(3:4), 'LineStyle', '--','LineWidth', 5, 'Color', 'k')
    title(['NumStim Per Flash: ' num2str(numstim)])
    
    subplot(2,2,2)
    heatmap(rot90(frmat./frstd));
    axis([0.5 xdiv 0.5 ydiv])
    ax = axis;
    line(ax(1:2),[mean(ax(3:4)) mean(ax(3:4))], 'LineStyle', '--','LineWidth', 5, 'Color', 'k')
    line([mean(ax(1:2)) mean(ax(1:2))], ax(3:4), 'LineStyle', '--','LineWidth', 5, 'Color', 'k')
    
    drawnow
    pause(0.1)
end
