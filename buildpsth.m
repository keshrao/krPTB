function psth = buildpsth(prestimdur, poststimdur, RelSpks)

    
    % bin data into 5ms bins & determine firing rate
    binwidth = 0.001;
    bins = -prestimdur:binwidth:poststimdur;
    binned = nan(1,length(bins)-1);
    
        
    for bi = 1:length(bins)-1
        thisDataIdx = RelSpks > bins(bi) & RelSpks < bins(bi+1);
        binned(bi) = sum(thisDataIdx)./binwidth;
    end
    
    gausKer = normpdf(-0.05:0.001:0.05, 0, 0.01);
    psth = conv(binned, gausKer, 'same') ./ sum(gausKer);
	
end % function