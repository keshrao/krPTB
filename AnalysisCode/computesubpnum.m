function subpnum = computesubpnum(dirsac)

subpnum = nan(size(dirsac));

for ti = 1:length(dirsac)
    
    if ~isnan(dirsac(ti))
        
        if dirsac(ti) >= 335 || dirsac(ti) < 25
            subpnum(ti) = 6; % right
            
        elseif dirsac(ti) >=  25 && dirsac(ti) < 70
            subpnum(ti) = 3; % up right
            
        elseif dirsac(ti) >= 67 && dirsac(ti) < 112
            subpnum(ti) = 2; % up
            
        elseif dirsac(ti) >= 112 && dirsac(ti) < 157
            subpnum(ti) = 1;   % up left
            
        elseif dirsac(ti) >= 157 && dirsac(ti) < 202
            subpnum(ti) = 4; % left
            
        elseif dirsac(ti) >= 202 && dirsac(ti) < 247
            subpnum(ti) = 7;  % down left
            
        elseif dirsac(ti) >= 247 && dirsac(ti) < 292
            subpnum(ti) = 8;  % down
            
        elseif dirsac(ti) >= 292 && dirsac(ti) < 335
            subpnum(ti) = 9;  % down right
        else
            fprintf('huh?')
        end
    else
        subpnum = 5;
    end
end