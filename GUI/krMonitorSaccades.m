function krMonitorSaccades(handles)

warning off

% duration to collect data 
dur = 0.3;

% get the daq
ai = handles.ai;

axes(handles.EyePosition);cla;
hold on
hEx = plot(zeros(ai.SampleRate*dur,1),'b','LineWidth',1.5);
hEy = plot(zeros(ai.SampleRate*dur,1),'g','LineWidth',1.5);
hSp = plot(zeros(ai.SampleRate*dur,1),'k','LineWidth',1.5);
ylim([-400 400])
xlim([0 ai.SampleRate*dur])
%axis off

endtaskui = uicontrol('Style','pushbutton','String','End Task','Callback',@cb_EndTask,'Position',[400 350 60 20]);
drawnow

isRun = true;
    function cb_EndTask(~,~)
        isRun = false;
    end



% bin data into 5ms bins & determine firing rate
sacpre = 0.3;
sacpost = 0.3;
binwidth = 0.001;
bins = -sacpre:binwidth:sacpost;

figure(2), clf
for subp = 1:9
    subplot(3,3,subp), hold on
    plot([0 0], [0 30], 'b', 'LineWidth', 1.5)
	hPSTH(subp) = plot(bins(1:end-1)+(binwidth/2), ones(length(bins)-1,1), 'r', 'LineWidth', 1.5);
end
drawnow, pause(0.00001)

% store all the spikes for psth construction
for i = 1:9, totRelSpks{i} = []; end


prow = ones(9,1); % number of saccades in 8 cardinal directions
% number 5 = center and will never be used

% while loop will begin here ---------
while isRun
    % acquire data
    [data,time, slocs, ex, ey, spdeye] = krPeekFullEyePosTrigs(ai, dur);
    
   
    % plot the data onto the figure
    set(hEx, 'ydata', ex);
    set(hEy, 'ydata', ey);
    set(hSp, 'ydata', spdeye); % scaled just so it's easier to see 
    drawnow, pause(0.00001)
    
    trig = data(:,3); % triggered data
    % get location of the peaks of triggers
    [~, tlocs] = findpeaks(diff(trig),'MINPEAKHEIGHT',1);
    
    % a vector the length of the number of saccades that give the proper subplot
    subpnum = computedirsacs(ex, ey, slocs);
    
    
    for saci = 1:length(slocs)
        
        if time(slocs(saci)) - sacpre < 0
            % if the saccade happens within 300ms of acquisition
            % then just take the first data point
            tlow = 1;
        else
            tlow = find(time > time(slocs(saci)) - sacpre, 1, 'first');
        end
        
        if time(slocs(saci)) + sacpre > time(end)
            % if the saccade happens within 300ms of acquisition
            % then just take the first data point
            thigh = length(time);
        else
            thigh = find(time > time(slocs(saci)) + sacpost, 1, 'first');
        end
        
        % tlow and thigh are indexes corresponding to when to look for triggers
        indTrig = tlocs(tlocs > tlow & tlocs < thigh);
        timeTrig = time(indTrig) - time(slocs(saci));
        
        figure(2),subplot(3,3,subpnum(saci))
        if ~isempty(timeTrig) && length(timeTrig) == 2
            plot([timeTrig'; timeTrig'], [prow(subpnum(saci))-0.9 prow(subpnum(saci))-0.1], 'k', 'LineWidth', 2)
        elseif ~isempty(timeTrig)
            plot([timeTrig timeTrig], [prow(subpnum(saci))-0.9 prow(subpnum(saci))-0.1], 'k', 'LineWidth', 2)
        end
        xlim([-sacpre sacpost])
        
		totRelSpks{subpnum(saci)} = [totRelSpks{subpnum(saci)}; timeTrig];
		thispsth = buildpsth(sacpre, sacpost, totRelSpks{subpnum(saci)});
		set(hPSTH(subpnum(saci)), 'ydata', thispsth./40);
		drawnow, pause(0.00001)
		
		
        prow(subpnum(saci)) = prow(subpnum(saci)) + 1;
    end
    
    
end %isRun
% ---- end of while loop

delete(endtaskui);
axes(handles.EyePosition); cla;


end % main