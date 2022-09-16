%% SEEK HUBS
function[AllSource, AllDest, TW] = SeekHubs(subject,freq,start_t,end_t,epochs,plot_opt,saveFig)
%{
AIM: - plot topographic distribution of amplitude waves
TW criteria are defined in DetectTWfromTraj.m

INPUT:
    *subject (string) = subject label from IRB1 study
    *freq = center frequency of the 1Hz wide band pass filter.
    *start_t/end_t = beginning and end of the considered time window (ms)
    *epochs (float or 'All')   = epoch number from the IRB1 naming task
    (vector)
    * plot_opt =plot options, 
    *save_fig = 'on' to save figure in specified directory
                                

Requires access to: EEGLAB,
                    DetectTWfromTraj.m,
                    CartoonHead.m,
                    FindEpochsNum.m,
                    .set EEG datasets

****
Written by Quentin Mesnildrey (2021): contact: quentin.mesnildrey@gmail.com
****
%}
%% ------- DEFAULT PARAMETERS ----------------------------------------------
if ~ismember(plot_opt,{'lines';'arrows'})
    disp('!! WRONG "plot_opt" arg')
    return
end

StudySubs = {'A01';'A02';'A03';'A04';'A05';'A06';...
    'C01';'C02';'C03';'C04';'C05';'C06';'C07'};

% DataRoot  = ['..\Data\Starstim\Study\',subject];
DataRoot  = '';
% DataSubFolder = '\Preprocessing\Sets EEG\';
DataSubFolder = '';

if ~ismember(subject,StudySubs)
    disp('!! WRONG "subject" arg')
    return
end
% _____ colormap properties
% color as a function of time/speed/frequency
color_type = 'time';

%% ------------------------------------------------------------------------
% ____ load EEG data and latency data
EEG_path = [DataRoot,DataSubFolder, 'Preprocess_',subject,'.set'];
EEG = pop_loadset(EEG_path);
load('C:\Users\quent\Desktop\CORSTIM\Analysis\Quentin\Data\Starstim\Study\Resultats\WordsAC07.mat',...
    'WordsAC07')
NLtab = WordsAC07(WordsAC07.Person == subject,'Latency');
NL = NLtab.Latency;


if ischar(epochs)
    epochs_num = FindEpochsNum(subject,epochs)  ;
else
    epochs_num = epochs;
end

% _____ Initialize empty vectors
AllSource_X = [];
AllDest_X   = [];
AllSource_Y = [];
AllDest_Y   = [];
TW          = [];
MedNL = median( NL(epochs_num) , 'omitnan');%#ok<NASGU> % just in case

%% LOOP OVER FREQUENCIES
for f = freq
    % __ LOOP OVER EPOCHS
    for epoch = epochs_num
        %Latency = NL(epoch); % just in case

        switch plot_opt
            case {'arrows','lines'}
                [TW, ~, ~, ~, ~, Origin, Destination] = Copy_of_DetectTWfromTraj(subject,epoch,start_t,end_t,'on',f,...
                    color_type,EEG);     
            otherwise              
                [TW, ~, ~, ~, ~, Origin, Destination] = Copy_of_DetectTWfromTraj(subject,epoch,start_t,end_t,'off',f,...
                    color_type,EEG);                             
        end
        
        if ~isempty(Origin)
            AllSource_X = [AllSource_X    Origin(epoch,:,1)]; %#ok<AGROW>
            AllSource_Y = [AllSource_Y    Origin(epoch,:,2)]; %#ok<AGROW>
            
            AllDest_X = [AllDest_X  Destination(epoch,:,1)];%#ok<AGROW>
            AllDest_Y =[ AllDest_Y  Destination(epoch,:,2)];%#ok<AGROW>
        end
               
    end
end

switch plot_opt
    case {'arrows';'lines'}
        cbh = colorbar ; %Create Colorbar
        switch color_type
            case 'time'
                cbh.Ticks = linspace(0, 1, 5) ; %Create 8 ticks from zero to 1
                cbh.TickLabels = num2cell(start_t:(end_t-start_t)/4:end_t) ;
                text(.65,-.65,'Time (ms)')               
            case 'freq'
                cbh.Ticks = [ 5 7 9 12 16 22 30]./30;
                cbh.TickLabels = num2cell([5 7 9 12 16 22 30]) ;
            case 'speed'
                cbh.Ticks = linspace(0, 1, 5) ; %Create 8 ticks from zero to 1
                cbh.TickLabels = num2cell(0:6:30) ;
        end
        axis([-0.6 0.6 -0.6 0.6])
        axis square
        set(gcf,'color','w'),box on
        set(gca,'ytick',[])
        set(gca,'xtick',[])
        
        if ischar(epochs)
            title([subject, ' - ', num2str(f),' Hz', ' - ', epochs ])
        end
        
        CartoonHead(EEG.chanlocs,0,'2D','off');
        FigName = ['SeekHubs_',num2str(f),'Hz_',...
            num2str(start_t), '_' , num2str(end_t), 'ms_', subject,'.tiff'];
        
        % ____ save figure ____
        switch saveFig
            case 'on'
                exportgraphics(gcf,fullfile('.\Figures_Study\',FigName))
                close
        end             
    
end

% ____ add arrow heads ____  
%!! WARNING !! CAN BE TIME CONSUMING IF MANY TWs
%!! Figure changes afterwards will not be applied to the arrow heads
% need to rerun this to update figure.
switch plot_opt
    case {'arrows'}
        pause(2)
        h = findobj(gcf,'type','line');
        if ~isempty(h)
            line2arrow(h,'HeadWidth',7,'HeadLength',7,'LineStyle','none');
        end
        
end

% ____ Store Source/Dest coordinates
AllSource(:,1) = AllSource_X;
AllSource(:,2) = AllSource_Y;
AllDest(:,1) = AllDest_X;
AllDest(:,2) = AllDest_Y;

end