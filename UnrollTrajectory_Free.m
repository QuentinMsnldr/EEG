%% IDENTIFY TRAJECTORIES
function []=Copy_of_UnrollTrajectory_Free(subject, epoch, start_t,end_t,freq)
%{
AIM: Plot unrolled trajectories (3D)
INPUT:
    *subject (string) = subject label from IRB1 study
    *freq = frequency of trajectory extraction
    *epoch = epoch number from the IRB1 naming task
    *start_t/end_t = beginning and end of the considered time window
                                 '
Requires access to: EEGLAB,
                    Traj data
**** 
Written by Quentin Mesnildrey (2021): quentin.mesnildrey@gmail.com
****
%}

StudySubs = {'A01';'A02';'A03';'A04';'A06';...
             'C01';'C02';'C03';'C04';'C06';'C07'};
if ~ismember(subject,StudySubs)
    disp('!! WRONG "subject" arg')
    return
end

% DataRoot  = ['..\Data\Starstim\Study\',subject];
DataRoot    = '';
% DataSubFolder = '\Preprocessing\Sets EEG\';
DataSubFolder = '';
TrajFolder    = '';

%% LOAD EEG DATA / LATENCY DATA / Trajectories ----------------------------
EEG_path     = [DataRoot, DataSubFolder,'Preprocess_',subject,'.set'];
TrajFileName = [DataRoot, TrajFolder,   'AllTraj_',   subject,'_', num2str(freq),'Hz.mat'];
EEG          = pop_loadset(EEG_path);
load(TrajFileName,'Traj');

load('C:\Users\quent\Desktop\CORSTIM\Analysis\Quentin\Data\Starstim\Study\Resultats\WordsAC07.mat','WordsAC07');
NLtab = WordsAC07(WordsAC07.Person == subject,'Latency');
NL = NLtab.Latency;

% ___ check for valid data
% if ~ischar(epoch)
%     [id_nan_y] = find(isnan(Traj(epoch ,:,2)));
%     [id_nan_x] = find(isnan(Traj(epoch ,:,1)));
%     for i =1:length(id_nan_x)
%         Traj(epoch ,id_nan_y(i),2) = (Traj(epoch ,id_nan_y(i)-1,2)+Traj(epoch ,id_nan_y(i)+1,2))/2;
%         Traj(epoch ,id_nan_y(i),1) = (Traj(epoch ,id_nan_y(i)-1,1)+Traj(epoch ,id_nan_y(i)+1,1))/2;
%     end
% end

%% select time window   ---------------------------------------------------
t             =   EEG.times;
[~, start_id] =   min( abs(t - start_t));
[~, end_id]   =   min( abs(t - end_t));
win           =   start_id:end_id;

%% plot static unrolled trajectory
plot3(t(win),Traj(epoch ,win,2)/67 -.5,...
             Traj(epoch ,win,1)/67 -.5, ...
        '-', 'color',[.4 .4 .4],'linewidth',1,...
        'Marker','o','MarkerFaceColor',[.4 .4 .4],'MarkerSize',3,...
        'linewidth',2),hold on   
  
%% image presentation
plot3([0, 0],...
    [-0.6 0.6],[-0.6 -0.6], ':k','linewidth',3),hold on    

%% voice marker   
latency=NL(epoch);
plot3([latency, latency],...
    [-0.6 0.6],[-0.6 -0.6], 'r','linewidth',2),hold on

%% BNS V2 
% [t_markers]=ExtractBNSfromTraj(subject,freq,epoch,start_t, end_t);
% for mk = 1:length(t_markers)
% 
% plot3([t_markers(mk), t_markers(mk)],...
%       [-0.6  0.6],...
%       [-0.6 -0.6],...
%        ':k','linewidth',1.5),hold on
% 
% [~, start_phs_id] = min( abs(t - t_markers(mk) ));
% if mk == length(t_markers)
%     end_phs_id = length(t);
% 
% else
%     [~, end_phs_id  ] = min( abs(t - t_markers(mk+1) ));
% 
% end
% 
% plot3(t(start_phs_id:end_phs_id),...
%     Traj(epoch ,start_phs_id:end_phs_id,2)/67 -.5,...
%         Traj(epoch ,start_phs_id:end_phs_id,1)/67 -.5, ...
%         '-', 'color',[rand rand rand],'linewidth',2),hold on   
% end


%% plot options
axis([start_t end_t+100 -0.6 0.6 -0.6 0.6])
CartoonHead(EEG.chanlocs,end_t+100,'3D','off')
CartoonHead(EEG.chanlocs,  t(1),'3D','off' )
xlabel('Time (ms)')

Dim=get(0, 'MonitorPositions');
set(gcf, 'Position',  [200, 200, 0.7*Dim(3), 0.4*Dim(4)])

set(gca, 'Ydir', 'reverse')% reverse axis direction to match topoplot view nose up
set(gcf,'color','w')
view([-5 25])
grid minor
box on
set(gca,'ytick',[],'ztick',[],'yticklabel',[],'zticklabel',[])

if ischar(epoch)
    title(sprintf('%s - epoch: %s - %dHz',subject,epoch,freq))
else
    title(sprintf('%s - epoch: %d - %dHz',subject,epoch,freq))
end
