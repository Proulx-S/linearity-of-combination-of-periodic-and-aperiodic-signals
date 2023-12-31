clear all
close all

%% Example real data from a single voxel
load exampleSingleVox.mat

figure('WindowStyle','docked');
tiledlayout(2,1)
nexttile
plot(t,ts);
xlabel('time (sec)')
ylabel('MR signal (a.u.)')

nexttile
plot(f,psdK1);
xlabel('Hz')
ylabel('PSD')
xlim([0 4])
ax = gca; ax.YScale = 'log';

ts_fft = fft(ts-mean(ts));
ts_fft = ts_fft(1:length(f));
% ts_fft = ts_fft./mean(abs(ts_fft(f>4 & f<5.5)));
plot(f,abs(ts_fft))



%% Simulated 1/f noise
n = size(ts,1);
tmp = zeros(n,1);
q_d = 3500;
alpha = 0.4;
for i = 1:100
    tsSim = f_alpha_gaussian ( n, q_d, alpha );
    tsSim_fft = fft(tsSim); tsSim_fft = tsSim_fft(1:length(f));
    tmp = abs(tmp)+abs(tsSim_fft)';
end
tmp = tmp'/100;

figure('WindowStyle','docked');
plot(f,abs(ts_fft)); hold on
plot(f,tmp)
% plot(f,abs(tsSim_fft));
ax = gca; ax.YScale = 'log';



figure('WindowStyle','docked');
tiledlayout(2,1)

n = size(t,1);

nexttile
q_d = 3500;
alpha = 0.4;
ts_noise = f_alpha_gaussian ( n, q_d, alpha );
plot(t,ts_noise); hold on

F=0.1;
ts_sig = sqrt(q_d)./2.*sin(2*pi*F*t);
plot(t,ts_sig); hold on

plot(t,ts_noise+ts_sig); hold on

nexttile
tmp = fft(ts_noise); tmp = abs(tmp(1:length(f)));
plot(f,tmp); hold on
tmp = fft(ts_sig); tmp = abs(tmp(1:length(f)));
plot(f,tmp); hold on
tmp1 = fft(ts_noise); tmp1 = abs(tmp1(1:length(f)));
tmp2 = fft(ts_sig); tmp2 = abs(tmp2(1:length(f)));
plot(f,tmp1+tmp2); hold on
tmp = fft(ts_noise+ts_sig); tmp = abs(tmp(1:length(f)));
plot(f,tmp); hold on
ax = gca; ax.YScale = 'linear';
% ax.XLim = [0 0.2];
legend({'noise' 'signal' 'freq sum' 'temp sum'})



%% Iterate the simulation
nIt = 1000;
n = size(t,1);
q_d = 3500;

%%% generate signal
F=0.1;
ts_sig = 0.1.*sqrt(q_d).*sin(2*pi*F*t);

%%% generate noise
alpha = 0.4;
ts_noise = nan(size(t));
for i = 1:nIt
    ts_noise(:,i) = f_alpha_gaussian ( n, q_d, alpha );
end

%%% combine noise and signal in temporal domain
ts_noiseNsig = ts_noise + ts_sig;

%%% fouirier transform in frequency domain
freq_noise = abs(fft(ts_noise));
freq_sig = abs(fft(ts_sig));
freq_noiseNsig_time = abs(fft(ts_noiseNsig));

%%% combine noise and signal in frequency domain
freq_noiseNsig_freq = freq_noise + freq_sig;

%%% average noise realizations
freq_noise = mean(freq_noise(1:length(f),:),2);
freq_sig = freq_sig(1:length(f),:);
freq_noiseNsig_time = mean(freq_noiseNsig_time(1:length(f),:),2);
freq_noiseNsig_freq = mean(freq_noiseNsig_freq(1:length(f),:),2);

%%% plot
figure('WindowStyle','docked');
plot(f,freq_noise); hold on
plot(f,freq_sig);
plot(f,freq_noiseNsig_time)
plot(f,freq_noiseNsig_freq)
legend({'noise' 'signal' 'sum in time domain' 'sum in frequency domain'})
fMax=0.15; [a,b] = min(abs((f-fMax)));
psdMax = min(freq_noise(1:b));
ax = gca; ax.XLim = [0 fMax]; ax.YLim(1) = psdMax;

%% Repeat at various noise level with fixed signal
%%% At summarize signal peak at increasing multiples of noise
close all
ts_noise_orig = nan(size(t));
for i = 1:nIt
    ts_noise_orig(:,i) = f_alpha_gaussian ( n, q_d, alpha );
end
ts_sig_orig = sin(2*pi*F*t);
ts_sig = ts_sig_orig;

% noiseFac = [1 0.5 0.25 0.25/2 0.25/4 0.25/8 0.25/8/2 0.25/8/4];
noiseFac = 1./(2.^(-5:1:15));
clear hFig yLim_all
for i = 1:length(noiseFac)
    ts_noise = ts_noise_orig.*noiseFac(i);

    % combine noise and signal in temporal domain
    ts_noiseNsig = ts_noise + ts_sig;

    % fouirier transform in frequency domain
    freq_noise = abs(fft(ts_noise));
    freq_sig = abs(fft(ts_sig));
    freq_noiseNsig_time = abs(fft(ts_noiseNsig));

    % combine noise and signal in frequency domain
    freq_noiseNsig_freq = freq_noise + freq_sig;

    % combine noise and signal in logged frequency domain
    freq_noiseNsig_logFreq = exp(log(freq_noise) + log(freq_sig));

    % compute power relative to noise
    freq_noiseNsig_freq_minNoise = freq_noiseNsig_freq - freq_noise;
    freq_noiseNsig_freq_overNoise = freq_noiseNsig_freq ./ freq_noise;
    freq_noiseNsig_time_minNoise = freq_noiseNsig_time - freq_noise;
    freq_noiseNsig_time_overNoise = freq_noiseNsig_time ./ freq_noise;
    freq_noiseNsig_time_logMinNoise = exp(log(freq_noiseNsig_time) - log(freq_noise));

    % average noise realizations
    freq_noise = mean(freq_noise(1:length(f),:),2);
    freq_sig = freq_sig(1:length(f),:);
    freq_noiseNsig_time = mean(freq_noiseNsig_time(1:length(f),:),2);
    freq_noiseNsig_freq = mean(freq_noiseNsig_freq(1:length(f),:),2);
    freq_noiseNsig_logFreq = mean(freq_noiseNsig_logFreq(1:length(f),:),2);
    
    freq_noiseNsig_freq_minNoise = mean(freq_noiseNsig_freq_minNoise(1:length(f),:),2);
    freq_noiseNsig_freq_overNoise = mean(freq_noiseNsig_freq_overNoise(1:length(f),:),2);
    freq_noiseNsig_time_minNoise = mean(freq_noiseNsig_time_minNoise(1:length(f),:),2);
    freq_noiseNsig_time_overNoise = mean(freq_noiseNsig_time_overNoise(1:length(f),:),2);
    freq_noiseNsig_time_logMinNoise = mean(freq_noiseNsig_time_logMinNoise(1:length(f),:),2);

    % visualize
    hFig(i) = figure('WindowStyle','docked');
    plot(f,freq_noise); hold on
    plot(f,freq_sig);
    plot(f,freq_noiseNsig_time)
%     plot(f,freq_noiseNsig_freq)
%     plot(f,freq_noiseNsig_logFreq)
%     plot(f,freq_noiseNsig_freq_minNoise)
%     plot(f,freq_noiseNsig_freq_overNoise)
    plot(f,freq_noiseNsig_time_minNoise)
%     plot(f,freq_noiseNsig_time_overNoise)
    plot(f,freq_noiseNsig_time_logMinNoise)
    legend({'noise'
        'signal'
        'time domain sum'
%         'frequency domain sum'
%         'frequency domain log sum'
%         'frequency domain sum - noise'
%         'frequency domain sum / noise'
        'time domain sum - noise'
%         'time domain sum / noise'
        'exp( log(time domain sum) - log(noise) )'}')
    fMax=0.15; [a,b] = min(abs((f-fMax)));
    ax = gca; ax.XLim = [0 fMax];
    ax.YScale = 'log';
    title(num2str(noiseFac(i)))


    yLim = [freq_noise(1:b)
        freq_sig(1:b)
        freq_noiseNsig_time(1:b)
%         freq_noiseNsig_freq(1:b)
%         freq_noiseNsig_logFreq(1:b)
%         freq_noiseNsig_freq_minNoise(1:b)
%         freq_noiseNsig_freq_overNoise(1:b)
        freq_noiseNsig_time_minNoise(1:b)
%         freq_noiseNsig_time_overNoise(1:b)
        freq_noiseNsig_time_logMinNoise(1:b)];
    yLim = [min(yLim) max(yLim)];
    yLim_all(i,:) = yLim;

    % compile power at signal frequency
    [~,b] = min(abs(f-F));
    freq_noise_all(i) = freq_noise(b);
    freq_sig_all(i) = freq_sig(b);
    freq_noiseNsig_time_all(i) = freq_noiseNsig_time(b);
    freq_noiseNsig_freq_all(i) = freq_noiseNsig_freq(b);
    freq_noiseNsig_logFreq_all(i) = freq_noiseNsig_logFreq(b);
    freq_noiseNsig_time_all(i) = freq_noiseNsig_time(b);
    freq_noiseNsig_freq_minNoise_all(i) = freq_noiseNsig_freq_minNoise(b);
    freq_noiseNsig_freq_overNoise_all(i) = freq_noiseNsig_freq_overNoise(b);
    freq_noiseNsig_time_minNoise_all(i) = freq_noiseNsig_time_minNoise(b);
%     freq_noiseNsig_time_overNoise_all(i) = freq_noiseNsig_time_overNoise(b);
    freq_noiseNsig_time_logMinNoise_all(i) = freq_noiseNsig_time_logMinNoise(b);
end
yLim_all(yLim_all<0) = 1e-1;
yLim = [min(yLim_all(:,1)) max(yLim_all(:,2))];
for i = 1:length(noiseFac)
    hFig(i).Children(2).YLim = yLim;
    hFig(i).Children(2).Legend.Location = 'northwest';
end
   


figure('WindowStyle','docked');
% plot(noiseFac,[freq_noise_all
%     freq_sig_all
%     freq_noiseNsig_time_all
%     freq_noiseNsig_freq_all
%     freq_noiseNsig_logFreq_all
%     freq_noiseNsig_freq_minNoise_all
%     freq_noiseNsig_freq_overNoise_all
%     freq_noiseNsig_time_minNoise_all
%     freq_noiseNsig_time_overNoise_all]')
% ax = gca;
% ax.XTick = flip(noiseFac);
bar([freq_noise_all
    freq_sig_all
    freq_noiseNsig_time_all
%     freq_noiseNsig_freq_all
%     freq_noiseNsig_logFreq_all
%     freq_noiseNsig_freq_minNoise_all
%     freq_noiseNsig_freq_overNoise_all
    freq_noiseNsig_time_minNoise_all
%     freq_noiseNsig_time_overNoise_all
    freq_noiseNsig_time_logMinNoise_all]')
ax = gca; ax.XTickLabel = num2str(noiseFac');
xlabel('noiseFac')
ax.YScale = 'log';
legend({'noise'
        'signal'
        'time domain sum'
%         'frequency domain sum'
%         'frequency domain log sum'
%         'frequency domain sum - noise'
%         'frequency domain sum / noise'
        'time domain sum - noise'
%         'time domain sum / noise'
        'exp( log(time domain sum) - log(noise) )'}' ...
        ,'Location','northwest')

