%% calculat Global Field Power
function [GFP, times] = calculateGFP(subject,epochs,fband,makeplot)
%{
AIM: - plot GFP curves for broadband and common brain rythms

INPUT:
    *subject (string) = subject label from IRB1 study
    *fband = frequency band ('alpha';'theta',etc)
    *epochs (float or 'All')   = epoch number from the IRB1 naming task
    (vector)
    * plot_opt =plot options, 
    *save_fig = 

Requires access to: EEGLAB, SelectBand function, .set EEG datasets
****
Written by Quentin Mesnildrey
%}

StudySubs = {'A01';'A02';'A03';'A04';'A05';'A06';...
            'C01';'C02';'C03';'C04';'C05';'C06';'C07'};
if ~ismember(subject,StudySubs)
    disp('!! WRONG "subject" arg')
    return
end        

allbands = {'broadband';'delta';'theta';'alpha';...
            'beta1';'beta2';'beta3';'gamma'};
if ~ismember(fband,allbands)
    disp('!! WRONG "fband" arg')
    return
else
    f_idx= find(strcmp(allbands,fband));
end   

% DataRoot  = ['..\Data\Starstim\Study\',subject];
DataRoot  = '';
% DataSubFolder = '\Preprocessing\Sets EEG\';
DataSubFolder = '';

colors = 	[0, 0.4470, 0.7410;...
            0.8500, 0.3250, 0.0980;...
            0.9290, 0.6940, 0.1250;...
            0.4940, 0.1840, 0.5560;...
            0.4660, 0.6740, 0.1880;...
            0.3010, 0.7450, 0.9330;...
            0.6350, 0.0780, 0.1840];
        
if exist('EEG','var') && strcmp(EEG.subject,subject)
else
    
EEG_path = [DataRoot,DataSubFolder,'Preprocess_',subject,'.set'];
load('C:\Users\quent\Desktop\CORSTIM\Analysis\Quentin\Data\Starstim\Study\Resultats\WordsAC07.mat')
NLtab = WordsAC07(WordsAC07.Person == subject,'Latency');
NL = NLtab.Latency(1:100);
EEG = pop_loadset(EEG_path);  
end
%% -------------- select frequency band
switch fband
    case 'alpha'
        low_f        = 8;
        high_f       = 12;
    case 'beta1'
        low_f        = 12;
        high_f       = 17;
    case 'beta2'
        low_f        = 17;
        high_f       = 20;        
    case 'beta3'
        low_f        = 20;
        high_f       = 30;
    case 'gamma'
        low_f        = 31;
        high_f       = 40;
    case 'theta'
        low_f        = 4;
        high_f       = 8;      
    case 'delta'
        low_f        = 1;
        high_f       = 4;
    case 'broadband'
        low_f        = 1;
        high_f       = 40;
end
DATA = SelectBand(EEG,low_f,high_f,402);

%% -------------- calculate GFP
if length(size(DATA.data))==3
    GFP = std(mean(DATA.data(:,:,epochs),3));
end
% --------------- plot GFP + latencies
times = EEG.times;
[~, start_id] = min( abs(times - -100));
[~, end_id] =   min( abs(times - 2500));
%% make plot
if strcmp(makeplot,'on')
    switch fband
        case 'broadband'
        area(times(start_id:end_id),GFP(start_id:end_id),'linestyle', 'none'),hold on
        alpha 0.2
        otherwise
        plot(times(start_id:end_id),GFP(start_id:end_id),'linewidth',1.5,'color',colors(f_idx-1,:)),hold on
    end  
    xlim([times(start_id), times(end_id)])
end

% axis labels
xlabel('Time (ms)'),ylabel('GFP (\muV)')
NicePlot
