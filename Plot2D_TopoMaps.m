%% PLOT HEAD MAP SERIES
function []=Plot2D_TopoMaps(subject,epoch,fc,start_t,end_t)
%{
AIM: - plot topographic distribution of EEG activity

INPUT:
    *subject (string) = subject label from IRB1 study
    *fc = center frequency of the 1Hz wide band pass filter.
    *start_t/end_t = beginning and end of the considered time window (ms)
    *epoch    = epoch number from the IRB1 naming task

Requires access to: EEGLAB,
                    CartoonHead.m,
                    SelectBand.m,
                    .set EEG datasets

****
Written by Quentin Mesnildrey (2021): contact: quentin.mesnildrey@gmail.com
****
%}

% ------- directories
% DataRoot  = ['..\Data\Starstim\Study\',subject];
DataRoot  = '';
% DataSubFolder = '\Preprocessing\Sets EEG\';
DataSubFolder = '';




%% ---------------------------------------------------------- params
StudySubs = {'A01';'A02';'A03';'A04';'A05';'A06';...
    'C01';'C02';'C03';'C04';'C05';'C06';'C07'};
if ~ismember(subject,StudySubs)
    disp('!! WRONG "subject" arg')
    return
end

% latency data just in case
load('C:\Users\quent\Desktop\CORSTIM\Analysis\Quentin\Data\Starstim\Study\Resultats\WordsAC07.mat')
NLtab = WordsAC07(WordsAC07.Person == subject,'Latency');
NL = NLtab.Latency(1:100);
%% ---------------------------------------------------------- LOAD EEG DATA
EEG_path = [DataRoot,DataSubFolder, 'Preprocess_',subject,'.set'];
EEG = pop_loadset(EEG_path);

% ........... options ............
filterData    = 'on';
makemov       = 'off';
traj          = 'on';

%% filter data
switch fc
    case 'alpha'
        low_f        = 8;
        high_f       = 12;
    case 'beta1'
        low_f        = 12;
        high_f       = 17;
    case 'beta2'
        low_f        = 18;
        high_f       = 20;
    case 'beta3'
        low_f        = 21;
        high_f       = 30;
    case 'gamma'
        low_f        = 30;
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
    otherwise
        low_f         = fc-0.5;
        high_f        = fc+0.5;
end

% ---------------------------------------------------------- filter data
if strcmp(filterData, 'on')
    EEG_hp_lp = SelectBand(EEG,low_f,high_f,402);
    PlotData = EEG_hp_lp.data(:,:,epoch);
else
    PlotData =  EEG.data  ;
end

%% ----------------------------------------------------- select time window
[~, start_id] = min( abs(EEG.times - start_t));
[~, end_id]   = min( abs(EEG.times - end_t));
time_vec     = start_id:end_id;
% ------------------------------------------------- initialize data storage
j             =  0;
[ xmax,  ymax] = deal( NaN*ones(1,length(time_vec)) );

%% make video
if strcmp(makemov, 'on')
    figure(1)
    movName = ['TopoEEG_' subject '_' 'ep' num2str(epoch) '_', num2str(fc),'Hz.mp4'];
    vidfile = VideoWriter(movName,'MPEG-4');
    open(vidfile);
end

%% loop across time steps
for i = time_vec
    j=j+1;
    disp([num2str(i) '/' num2str(time_vec(end))])
    
    [~, grid_or_val, ~, ~, ~]=topoplot(  PlotData(:,i), EEG.chanlocs,...
        'maplimits','maxmin',...
        'style','both',...
        'conv','off',...
        'shading','flat',...
        'noplot','off');hold on % 'straight' = no lines
    
    
    if strcmp(traj,'on')   % -------------------------------  follow trajectory
        % ---------------------------- store max amp coordinates to draw trajectory
        % ----------------------------------------------- find single max value
        
        [Val_MAX,IMAX,~,~]  = extrema2( grid_or_val);
        if ~isempty(IMAX)
            [ xmax(j),  ymax(j)] = ind2sub( size(grid_or_val,1),IMAX(1));
        else
            [ xmax(j),  ymax(j)] = deal(NaN);
        end
        
        % refresh plot traj
        if j> 40
            plot(ymax(j-40:j)/size(grid_or_val,1)-.5, xmax(j-40:j)/size(grid_or_val,1)-.5,...
                'o' ,'linestyle','-','color',[0.5 0.5 0.5],'MarkerSize',10,...
                'markerfacecolor','y'),hold on,
        else
            plot(ymax(1:j)/size(grid_or_val,1)-.5, xmax(1:j)/size(grid_or_val,1)-.5,...
                'o' ,'linestyle','-','color',[0.5 0.5 0.5],'MarkerSize',10,...
                'markerfacecolor','y'),hold on,
        end
        
        %------------------------------------------------------ local max        
%         testMap = grid_or_val;
%         testMap(testMap < 0.75*Val_MAX(1)) = 0 ;
%         [Val_MAX_thrsholded,~,~,~]  = extrema2( testMap);
%         NumSources(j) = length(Val_MAX_thrsholded);
% %         find crest only if val > 2e-7
%         TF1= islocalmax(testMap,1,...
%             'MinProminence',0,...
%             'MinSeparation', 100,...
%             'MaxNumExtrema', 50);
%         [rows1,cols1,vals1]=find(TF1);
%         
%             for l = 1:length(rows1')
%                 plot(cols1(l)/size(grid_or_val,1)-.5,rows1(l)/size(grid_or_val,1)-.5,'ro','markerFaceColor','y'),hold on
%             end
%         
%         TF2= islocalmax(testMap,2,...
%             'MinProminence',0,...
%             'MinSeparation', 0,...
%             'MaxNumExtrema', 20,...
%             'FlatSelection','center');
%         [rows2,cols2,vals2]=find(TF2);
%         
%             for l = 1:length(rows2')
%                 plot(cols2(l)/size(grid_or_val,1)-.5,rows2(l)/size(grid_or_val,1)-.5,'ro','markerFaceColor','y'),hold on
%             end
        %--------------------------------------------------------------------------
        % -----------------------    attribute approx. BNS with repect to time step
        
        
    end
    time = EEG.times(i);
    title(['t = ' num2str(time) ' ms'])
    drawnow
    
    if strcmp(makemov, 'on')
        F(j) = getframe(gcf);
        writeVideo(vidfile,F(j));
    end
    
    if i ~= time_vec(end)
        clf,
    else
        hold on
    end
end
%% ----------------------------------------------- close video frames
if strcmp(makemov, 'on')
    close(vidfile)
end
close