function krMonitorSaccades(handles)

warning off

% get the daq
ai = handles.ai;
%[ai, dio] = krConnectDAQTrigger();

% save old information
preSampleRate = ai.SampleRate;

% put in new daq acquisition parameters
dur = 1;
ai.SampleRate = 100000;
ai.SamplesPerTrigger = dur * ai.SampleRate;

axes(handles.EyePosition);cla;
hold on
hEx = plot(zeros(ai.SamplesPerTrigger,1),'b','LineWidth',1.5);
hEy = plot(zeros(ai.SamplesPerTrigger,1),'g','LineWidth',1.5);
hSp = plot(zeros(ai.SamplesPerTrigger,1),'k','LineWidth',1.5);
ylim([-400 400])
xlim([0 ai.SamplesPerTrigger])
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

% store all the spikes for psth construction
for i = 1:9, totRelSpks{i} = []; end


prow = ones(9,1); % number of saccades in 8 cardinal directions
% number 5 = center and will never be used

% while loop will begin here ---------
while isRun
    % acquire data
    start(ai);
    [data, time] = getdata(ai, ai.SampleRate*dur);
    flushdata(ai);
    stop(ai);
    
    ex = data(:,1)*100; % scaling from volts to deg
    ey = data(:,2)*100; % scaling from volts to deg
    
    ex = movingmean(ex, 2000); % this process can be slow
    ey = movingmean(ey, 2000);
    
    % find when saccades happen
    spdeye = sqrt(diff(ex) .^2 + diff(ey).^2) .* 1000; % to secs & then to deg
    
    % plot the data onto the figure
    set(hEx, 'ydata', ex);
    set(hEy, 'ydata', ey);
    set(hSp, 'ydata', spdeye * 5); % scaled just so it's easier to see 
    
    %arbitrary threshold
    sacthresh = 20; %deg/sec
    [~, slocs] = findpeaks(spdeye, 'MINPEAKHEIGHT', sacthresh ,'MINPEAKDISTANCE',5000);
    
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
		drawnow
		
		
        prow(subpnum(saci)) = prow(subpnum(saci)) + 1;
    end
    
    
end %isRun
% ---- end of while loop

delete(endtaskui);
axes(handles.EyePosition); cla;

% reset to old parameters
ai.SampleRate = preSampleRate;
ai.SamplesPerTrigger = 1;

end % main