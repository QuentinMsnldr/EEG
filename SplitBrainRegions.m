%% SplitBrainRegions
function[]=SplitBrainRegions(subject,frequencies,savefig)
%{
AIM: Analyze trajectories from all 100 trials. Counts the number of
occurence of a maximum of amplitude in each scalp region. 

INPUT:
    *subject (string) = subject label from IRB1 study
    *frequencies = frequency of the considered trajectories.      
    *savefig     = 'on' to save figure

Requires access to: EEGLAB,
                    CheckRegionsSplit.m,
                    Traj data
****
Written by Quentin Mesnildrey (2021): contact: quentin.mesnildrey@gmail.com
****
%}
%% FOLDERS

% DataRoot  = ['..\Data\Starstim\Study\',subject];
DataRoot  = '';
% DataSubFolder = '\Preprocessing\Sets EEG\';
DataSubFolder = '';
TrajFolder    = '';

%% CHECK SUBJECTS
StudySubs = {'A01';'A02';'A03';'A04';'A06';...
             'C01';'C02';'C03';'C04';'C06'};

if ~ismember(subject,StudySubs)
    disp('!! WRONG "subject" arg')
    return
end
%% LOAD LATENCIES
load('C:\Users\quent\Desktop\CORSTIM\Analysis\Quentin\Data\Starstim\Study\Resultats\WordsAC07.mat',...
    'WordsAC07')
NLtab = WordsAC07(WordsAC07.Person == subject,'Latency');
NL = NLtab.Latency;

%% LOOP OVER FREQ
for freq = frequencies

speech_centered = 'off';

%% LOAD FILES (EEG and Traj)
EEG_path = [DataRoot,DataSubFolder,'Preprocess_',subject,'.set'];
EEG = pop_loadset(EEG_path); 
TrajFileName = [DataRoot,TrajFolder,'AllTraj_', subject,'_', num2str(freq),'Hz.mat'];
load(TrajFileName,'Traj');

%% --------- DEFINE SCALP REGIONS
Copy_of_CheckRegionsSplit

%% CHOOSE EPOCHS CHECK FOR SUCCESS/FAILS    
%     perfFilepath= ['..\Data\Starstim\Study\',subject,...
%     '\Raw\',subject,'_ImageOrder\',subject,'_ImageOrder.xlsx'];
% xlRange ='C2:C101';
% SuccessFails = xlsread(perfFilepath,'Sheet1',xlRange );
% Success_ep = find(SuccessFails);
% Fail_ep = find(SuccessFails == 0);

epochs = 1:100;

%% LOOP OVER EPOCHS
for ep = epochs
    switch speech_centered
        case 'on'
            [~, NL_id] = min( abs(EEG.times - NL(ep)));
            prespeech  = 1000;%ms
            postspeech = 200;%
            start_id   = NL_id - round( prespeech/2 );
            end_id     = NL_id + round( postspeech/2);
            TimeVec    = -prespeech : 2 : postspeech;
        otherwise
            start_t = -100;
            end_t   = 3000;
            [~, start_id] = min( abs(EEG.times - start_t));
            [~, end_id]   = min( abs(EEG.times - end_t));
            TimeVec       = EEG.times(start_id:end_id);
    end
    
if end_id <=2750 %&& ~isnan(NL(ep)) % length(EEG.times)
    X = Traj(ep,start_id:end_id,2)/67 -.5;
    Y = Traj(ep,start_id:end_id,1)/67 -.5;
    size(X)
    size(Y)
    
    ActLFront(:,ep) = isinterior(LFront,X,Y);
    ActRFront(:,ep) = isinterior(RFront,X,Y);
    ActLPar(:,ep)  = isinterior(LPar,X,Y);
    ActRPar(:,ep)  = isinterior(RPar,X,Y);
    ActLTemp(:,ep) = isinterior(LTemp,X,Y);
    ActRTemp(:,ep) = isinterior(RTemp,X,Y);
    ActOcc(:,ep)   = isinterior(Occ,X,Y);
    ActAntFront(:,ep) = isinterior(AntFront,X,Y);
    ActCz(:,ep)    = isinterior(Cz,X,Y);
else
    [ActLFront(:,ep) ,...
        ActRFront(:,ep),...
        ActLPar(:,ep)  ,...
        ActRPar(:,ep) ,...
        ActLTemp(:,ep) ,...
        ActRTemp(:,ep) ,...
        ActOcc(:,ep)   ,...
        ActAntFront(:,ep) ,...
        ActCz(:,ep)  ]  =    deal(zeros(length(TimeVec),1));
end

end


%% MAKE PLOT 
tplot = tiledlayout(6,1);
ax1 = nexttile;
 plot(TimeVec,sum(ActAntFront,2)/(length(epochs)),'k')
 xline(median(NL,'omitnan'))
 title('Front.')

ax2 = nexttile;
plot(TimeVec,sum(ActLFront,2)/(length(epochs)),'r' ),hold on
plot(TimeVec,sum(ActRFront,2)/(length(epochs)),'b' )
 xline(median(NL(epochs),'omitnan'))
 title('\color{red}LFront. - \color{blue}RFront.')
 
ax3 = nexttile;
 plot(TimeVec,sum(ActLTemp,2)/(length(epochs)),'r'),hold on
  plot(TimeVec,sum(ActRTemp,2)/(length(epochs)),'b')
 xline(median(NL(epochs),'omitnan'))
 title('\color{red}LTemp. - \color{blue}RTemp.')
 
 ax4 = nexttile;
 plot(TimeVec,sum(ActCz,2)/(length(epochs)),'k')
 xline(median(NL(epochs),'omitnan'))
 title('Cz')
 
 ax5 = nexttile;
 plot(TimeVec,sum(ActLPar,2)/(length(epochs)),'r'),hold on
 plot(TimeVec,sum(ActRPar,2)/(length(epochs)),'b')
 xline(median(NL(epochs),'omitnan'))
 title('\color{red}LPar - \color{blue}RPar')
 
 ax6 = nexttile([1,1]);
 plot(TimeVec,sum(ActOcc,2)/(length(epochs)),'k')
 xline(median(NL(epochs),'omitnan'))
 title('Occ.')
 
linkaxes([ax1 ax2 ax3 ax4 ax5 ax6],'xy')
ax1.XLim = [TimeVec(1) TimeVec(end)];
ax1.YLim = [0 0.5];

xlabel(tplot,'Time (ms)')
ylabel(tplot,'Frequency of presence')

sgtitle(sprintf('%s - f=%d Hz',subject,freq))
Dim=get(0, 'MonitorPositions');
set(gcf, 'Position',  [0, 0, Dim(3)/3, 0.95*Dim(4)])
NicePlot

% ____ SAVE FIGURE
switch savefig
    case 'on'
        FigName = ['SplitBrainRegions_resp_locked_',num2str(freq),'Hz_',...
            subject];
        saveas(gcf,fullfile('.\Figures_Study',FigName),'tif')
    otherwise
end
%_____
end