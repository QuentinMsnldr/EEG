%% IDENTIFY TRAJECTORIES
function [TWCoord, NumberTW, DurTW, wv_length, Speed, Origin,  Destination] =...
                  DetectTWfromTraj(subject, Epochs,start_t,end_t,makeplot, freq,color_type,EEG)
%{
AIM: Analyze 2D coordinates of the maxima of amplitude (i.e., Traj data) 
     Identify the existence of amplitude waves.
 
INPUTs:
    *subject (string): subject label 
    *Epochs (float vector): epoch number from the IRB1 naming task
    * start_t,end_t: beginning and end of the considered time window in ms
    * makeplot: 'on': display topographic distribution of identified waves. 
    * freq: frequency in Hz
    * color_type: 'time','speed',or 'freq' = TW colored as a function of
    time, speed or frequency.
    * EEG: EEG data structure 
                     
OUTPUTs: 
    * TWCoord: coordinates of all TWs
    * NumberTW: number of identified TWs
    * DurTW: duration in ms of each TW
    * wv_length: length in cm of each TW
    * Speed: velocity in m/s of each TW
    * Origin/Destination: coordinates of the origin and destination of each
    TW
                  
Requires access to: -arclength.m (see usefulFuncs)
                  - InterpTrajCoord.m
                  - Latencies
                  - Trajectories mat files
                  
See details in Mesnildrey et al. Front. in Hum. Neurosc. 
                 
****
Written by Quentin Mesnildrey (2021): contact: quentin.mesnildrey@gmail.com
****
%}
              
%% CHECK SUBJECTS FROM IRB1
StudySubs = {'A01';'A02';'A03';'A04';'A05';'A06';'A07';...
             'C01';'C02';'C03';'C04';'C05';'C06';'C07'};

if ~ismember(subject,StudySubs)
    disp('!! WRONG "subject" arg')
    return
end
%% FOLDERS
% DataRoot  = ['..\Data\Starstim\Study\',subject]; % for IRB1
DataRoot  = '';
TrajFolder    = '';
         

% ____ LOAD LATENCIES uncomment if needed
% load([DataRoot,'\Resultats\.mat'],...
%     'WordsAC07')
% NLtab = WordsAC07(WordsAC07.Person == subject,'Latency');
% NL = NLtab.Latency;

% ____ Trajectories Filename
TrajFileName = [DataRoot, TrajFolder, 'AllTraj_', subject, '_', num2str(freq),'Hz', '.mat'];

% _____ max distance criterion (in grid pixels): 
% i.e. we consider that two consecutive samples belong to the same TW if
% the distance between them is < Dmax. 
Dmax = 20;

% ____ Time window
[~, start_id] = min( abs(EEG.times - start_t));
[~, end_id] = min( abs(EEG.times - end_t));

%% INITIALIZE
if exist(TrajFileName,'File')
    load(TrajFileName,'Traj');% load Traj data
    % __ initialize
    [NumberTW, DurTW, wv_length, Speed, Origin, Destination] = deal([]);
    TW = NaN.*ones(length(Epochs),EEG.times(end),2);
    TWCoord = [];
    TotNum = 0;
    
%% LOOP OVER EPOCHS                 
    for epoch = Epochs
        % Traj Coordinates
        Y = Traj(epoch ,:,2);
        X = Traj(epoch ,:,1);
        
        % init TW detection
        NumTW = 0;
        wv = 'False';      
        wv_vec = []; 
        % ____ plot parameter
        switch color_type
            case 'time'
       numcol = length(start_id:end_id);
             case 'speed'
       numcol = 20;
            case 'freq'
       numcol = 30;
        end
        col_map = colormap(turbo(numcol));
        col_id = 0;
        
        % ____ loop over samples
        for k = start_id+1:end_id
            switch color_type
            case 'time'
                col_id=col_id+1;
            end
% --------------------------------- calculate distance ((k)-(k-1)    
            D = sqrt( (X(k) - X(k-1)).^2 + (Y(k) -  Y(k-1)).^2  );
            
            if D <Dmax && D > 0 % Verify Distance criteria
                % update TW coordinates
                wv = 'True';
                wv_vec = [wv_vec k]; %#ok<AGROW>
                TW(epoch,k-1,  1) =  X(k-1);
                TW(epoch,k-1,  2) =  Y(k-1);
                TW(epoch,k,  1) =  X(k);
                TW(epoch,k,  2) =  Y(k);
                
            else    % end of current wave
                
                if strcmp(wv,'True')
                    full_wv = [wv_vec(1)-1, wv_vec]; % add 1st sample
                    if length( unique(TW(epoch,full_wv,  2))) == 1 && length( unique(TW(epoch,full_wv,  1))) == 1
                        % stationnary wv
                    else
                        if length(wv_vec)> 4 % count wv longer than 8 ms
                            [yint, xint] = InterpTrajCoord(Y(full_wv)/67-0.5,...
                                                           X(full_wv)/67-0.5,...
                                                           length(full_wv*3));
                            new_x = xint(~isnan(xint));
                            new_y = yint(~isnan(yint));

                            % ------------------------------------------ update counters
                            NumTW                   =  NumTW +1;
                            TotNum                  =  TotNum+1;
                            TWCoord(TotNum).Y       =  Y(full_wv)/67-0.5;% center and normalize data on grid
                            TWCoord(TotNum).X       =  X(full_wv)/67-0.5;
                            TWCoord(TotNum).Time_id =  full_wv(1);
                             
                            wv_length(epoch,NumTW) = 0.3*arclength(TW(epoch,full_wv,  2)/67-0.5,...
                                                                   TW(epoch,full_wv,  1)/67-0.5,'linear');
                            DurTW(epoch,NumTW,1)   = EEG.times(full_wv(1));
                            DurTW(epoch,NumTW,2)   = EEG.times(full_wv(end)) -EEG.times(full_wv(1));
                            Speed(epoch,NumTW )    =  wv_length(epoch,NumTW)/(DurTW(epoch,NumTW,2)*1e-3);% estimate 30cm 1/2 head circ
                            Origin(epoch,NumTW,[1 2])  = [new_y(1), new_x(1)];
                            Destination(epoch,NumTW,[1 2])  = [new_y(end), new_x(end)];
                            
                            % ----------------------------------------------------- plot wv
                            if strcmp(makeplot,'on')
                                switch color_type
                                case 'speed'
                                    col_id = round( Speed(epoch,NumTW ) );
                                case 'freq'
                                     col_id = freq;   
                                end
                                % ___ plot TW as line
                                plot(new_y,new_x,'linewidth',1.5,'color',[col_map(col_id,:), 0.2]);hold on                               
                            end
                                                        
                        else % ---------------------- do not plot wv shorter than 4*2ms
                        end
                        
                        % ---------------------- reinitialize wv_vec for next TW
                        wv_vec = [];
                        wv = 'False';
                    end
                end
                
            end
            
        end
        NumberTW(epoch) = NumTW;        
    end
%% END LOOP    
% ____ remove NaN values if any    
    if ~isempty(DurTW)
        DurTW(DurTW==0) = NaN;
        wv_length(wv_length==0) = NaN;
        Speed(Speed==0)=NaN;
        
% ____ uncomment to display stats        
        fprintf('TOTAL NUMBER OF TW = %f\n',sum(NumberTW))
        fprintf('MEAN DURATION = %f ms\n',  mean(DurTW(Epochs,:,2),'all','omitnan'))
        fprintf('MEAN LENGTH = %f cm\n',    100*mean(wv_length,'all','omitnan'))
        fprintf('MEAN SPEED = %f m/s\n',    mean(Speed,'all','omitnan'))
        fprintf('MAX SPEED = %f m/s\n',    max(Speed(:))    )
%__________________________________________________________________________
    end
% ____ plot parameters    
    if strcmp(makeplot,'on')
        axis([-0.6 0.6 -0.6 0.6])
        axis square
        set(gcf,'color','w'),box on
        set(gca,'ytick',[])
        set(gca,'xtick',[])
        title([subject,'- ep# ', num2str(epoch),'-',num2str(NumTW),'TWs detected'])              
    end
    
else
    sprintf('%s - not found!',TrajFileName)   
end