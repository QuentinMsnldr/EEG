%% Topo_ERPs
function [GFP]=Topo_ERPs(subject, fband,start_t,end_t)
%{
AIM: 
    * plot ERPs + GFP (top row).
    * plot topographic distribution of EEG activity at the peaks of GFP.
    * return GFP values.

INPUT:
    * subject = subject label from IRB1 study
    * fband = frequency band ('theta', 'alpha'...), or float
    * start_t,end_t = beginning and end of the considered time window in ms

OUTPUT: 
    * GFP signal for entire epoch length
    * figure

Requires access to: - EEGLAB
                    - SelecBand.m
                    - .set EEG datasets
                    - Latency data

Note:
if speech_centered = 'on'; make sure ou have already produced
response-locked EEG data. 

****
Written by Quentin Mesnildrey: contact: quentin.mesnildrey@gmail.com
****
%}
%% CHECK SUBJECTS
StudySubs = {'A01';'A02';'A03';'A04';'A06';...
             'C01';'C02';'C03';'C04';'C06'};
if ~ismember(subject,StudySubs)
    disp('!! WRONG "subject" arg')
    return
end

%% FOLDERS
% DataRoot  = ['..\Data\Starstim\Study\',subject];
DataRoot  = '';
% DataSubFolder = '\Preprocessing\Sets EEG\';
DataSubFolder = '';


%% LOAD LATENCIES
load('C:\Users\quent\Desktop\CORSTIM\Analysis\Quentin\Data\Starstim\Study\Resultats\WordsAC07.mat','WordsAC07')
NLtab = WordsAC07(WordsAC07.Person == subject,'Latency');
NL = NLtab.Latency(1:100);

%% LOAD EEG FILE
speech_centered = 'off'; 
% 'off' = stimulus-locked data/'on' = response-locked data    

switch speech_centered
    case 'off'
        EEG_path = [DataRoot, ...
            DataSubFolder, 'Preprocess_',subject,'.set'];
        EEG = pop_loadset(EEG_path);
        
    case 'on'
        disp('=== SPEECh RECENTERED DATA ===')
        eeg_filename = ['RecenteredEEG_', subject];
        load(eeg_filename,'EEG');
        start_t      = -500;
        end_t        = 200;
end

%% plot/display params
[~, start_id]   = min( abs(EEG.times - start_t));
[~, end_id]     = min( abs(EEG.times - end_t));

numTrials       = 100;
epochs          = 1:numTrials;
n               = length(epochs); % number of epochs considered in the calculation - cf title

%% FILTER DATA
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
        low_f        = 30;
        high_f       = 45;
    case 'theta'
        low_f        = 4;
        high_f       = 8;
    case 'delta'
        low_f        = 1;
        high_f       = 4;
    case 'broadband'
        low_f        = 1;
        high_f       = 40;
    otherwise
        low_f         = fband-0.5;
        high_f        = fband+0.5;
end
EEG_hp_lp = SelectBand(EEG,low_f,high_f,402);% filtered data

%% Average data = ERP
ERP = mean(   EEG_hp_lp.data(:,:,epochs),3  );
%% calculate global field power
GFP = std(ERP);
% _____find peaks of GFP
[~,LOCS] = findpeaks( GFP(start_id:end_id), EEG.times(start_id:end_id),...
    'MinPeakProminence',0.02,'MinPeakDistance',10,...
    'SortStr','descend');

%% PLOT TOPOMAPS AT MARKERS
for i=1:min(5,length(LOCS))
    srtLOCS = sort(LOCS(1:min(5,length(LOCS))));
    [~, LOCS_id] = min( abs(EEG.times - srtLOCS(i)));
    subplot(2,5,5+i)
    title(sprintf('t=%d',srtLOCS(i)))
    
        topoplot(  ERP(:,LOCS_id), EEG.chanlocs,...
        'maplimits','maxmin',...
        'style','both',...
        'conv','off',...
        'electrodes','off',...
        'shading','flat',...
        'noplot','off');   
end


%% PLOT ERPs and GFP
subplot(2,5,(1:5))
plot(EEG.times(start_id:end_id),ERP(:,start_id:end_id) ),hold on
plot(EEG.times(start_id:end_id),GFP(start_id:end_id),'k','linewidth',2 ),hold on
% ____ add markers at peaks of GFP
if ~isempty(LOCS)
    xline(LOCS(1:min(5,length(LOCS))))
end

switch speech_centered
    case 'off'
        xline(median(NL(epochs),'omitnan'),'r-') % plot median latency      
        ylim([-6 6])
    case 'on'
        xline(0,'r-') 
        ylim([-2 2])
end
 
% ____ plot options
set(gcf,'color','w')
xlabel('Time (ms)')
ylabel('ERPs (\muV)')
xlim([EEG.times(start_id) EEG.times(end_id)])

sgtitle(sprintf('%s - %s - n=%d',subject,fband,n))

Dim=get(0, 'MonitorPositions');
set(gcf, 'Position',  [100, 100, Dim(3)/2, Dim(4)/2])

% ___ save figure in specified directory
% exportgraphics(gcf,fullfile('.\Figures_Study',sprintf('TopoERP_%s_%s',subject,fband)),...
%     'BackgroundColor','none')
% close
