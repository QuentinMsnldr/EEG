%% EXTRACT TRAJECTORIES FROM HEAD MAPS
function []=ExtractTrajectories(subject,fc,epochs)
%{
AIM: Extract 2D coordinates of the maxima of amplitude from .set EEG data.
This code performs a loop over epochs (arg3) and all time samples.
Uses topoplot function to get the 2D map of activity (GRID)
X/Y coordinates of the maxima are extracted from this map using the
extrema2 function. 

INPUT:
    *subject (string) = subject label from IRB1 study
    *fc = float -> center frequency of the 1Hz wide band pass filter.
          -> see "filter data" cell.
    *epochs (float or 'All')   = epoch number from the IRB1 naming task
                                 'All' for loop across all trials in the
                                 dataset
Saved OUTPUT: Traj = 4D tensor of size =
num_of_epochs*number_of_samples*2(x,y)

>> To be used in DetectTWfromTraj.m, SplitBrainRegions.m, ...

Requires access to: EEGLAB,
                    SelectBand.m,
                    extrema2.m,
                    .set EEG datasets
****
Written by Quentin Mesnildrey (2021): contact: quentin.mesnildrey@gmail.com
****
%}

%% Main folders -- ADAPT FOLDERS DIRECTORIES/NAME AS NEEDED
% DataRoot  = ['..\Data\Starstim\Study\',subject]; % for IRB1
DataRoot  = '';
% DataSubFolder = '\Preprocessing\Sets EEG\'; % for IRB1
DataSubFolder = '';
TrajFolder    = '';

%% LOAD EEG DATA
EEG_path = [ DataRoot,...
             DataSubFolder,...
             'Preprocess_',subject,'.set']; % Make sure data are labelled like this
EEG = pop_loadset(EEG_path);

%% FILTER DATA
bw            = 1;% bandwidth of the bandpass filter
low_f         = fc-bw/2;
high_f        = fc+bw/2;

EEG_hp_lp = SelectBand(EEG,low_f,high_f,402); % Band-Pass Filtered EEG data

%% INITIALIZE 
time_vec      =  1:length(EEG.times); % considered samples
k             =  0 ; % init epoch counter
FileName      = ['AllTraj_' subject ,'_', num2str(round(fc)),'Hz']; % output file name

% ______ check file existence in case of uncomplete extraction.
if exist([FileName,'.mat'],'file') == 2
    load(FileName,'Traj')% update k variable to start from last epoch
else
Traj          = zeros(length(epochs),length(EEG.times),2);% preallocate traject coordinates for each epoch
end
% ______ wait bar
if ischar(epochs) && strcmp(epochs,'all')
    epochs = 1:EEG.trials;
end
wtbar = waitbar(0,'1','Name','Progression...',...
    'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(wtbar,'canceling',0);

%% LOOP OVER EPOCHS
for epoch = epochs
% ______ wait bar    
    if getappdata(wtbar,'canceling')
        break
    end
    waitbar(epoch/length(epochs),wtbar,sprintf('%d/%d',epoch,length(epochs)))
% ______
    k=k+1;
    PlotData =    EEG_hp_lp.data(:,:,epoch);% select epoch data
    j = 0;
% ______ loop across time steps    
    for i = time_vec
        j=j+1; 
        [~, GRID, ~, ~, ~]=topoplot(  PlotData(:,i), EEG.chanlocs,...
            'maplimits','maxmin','style','both','conv','off',...
            'shading','flat',...
            'noplot','on');% GRID = interpolated map
        
% ______ find max coordinates in GRID
        [~,IMAX,~,~]  = extrema2(GRID);
        if ~isempty(IMAX)
            [ Traj(epoch,j,1),  Traj(epoch,j,2)] = ind2sub( size(GRID,1),IMAX(1));
        else
            [ Traj(epoch,j,1),  Traj(epoch,j,2)] = deal(NaN);
        end
    end
end
%% SAVE TRAJECTORIES IN SPECIFIED FOLDER
save(fullfile(DataRoot,...
     TrajFolder,FileName),'Traj')

%% close waitbar
F = findall(0,'type','figure','tag','TMWWaitbar');
delete(F);