function subpnum = computedirsacs(ex, ey, slocs)

subpnum = zeros(length(slocs),1);
	for si = 1:length(slocs)
		try 
			xpre = ex(slocs(si)-1000); xpost = ex(slocs(si)+1000);
			ypre = ey(slocs(si)-1000); ypost = ey(slocs(si)+1000);

			dirsac = atan2d(ypost-ypre, xpost-xpre);
		catch
			dirsac = nan;
		end
		
		if dirsac >= 335 || dirsac < 25
			subpnum(si) = 6; % right
			
		elseif dirsac >=  25 && dirsac < 70
			subpnum(si) = 3; % up right
			
		elseif dirsac >= 67 && dirsac < 112
			subpnum(si) = 2; % up
			
		elseif dirsac >= 112 && dirsac < 157
			subpnum(si) = 1;   % up left
			
		elseif dirsac >= 157 && dirsac < 202
			subpnum(si) = 4; % left   
			
		elseif dirsac >= 202 && dirsac < 247
			subpnum(si) = 7;  % down left
			
		elseif dirsac >= 247 && dirsac < 292
			subpnum(si) = 8;  % down
			
		elseif dirsac >= 292 && dirsac < 335
			subpnum(si) = 9;  % down right
		else
			subpnum(si) = 5; % safety case
		end

	end

end	