function krDeliverReward(dio)

for r = 1:2
    putvalue(dio.line(1),1) % turn bit ON; 
    pause(0.05); %wait short delay
    putvalue(dio.line(1),0); % turn bit OFF;
    pause(0.05);
end