%% Check Split Regions
%{
AIM: perform a basic scalp parcellation.
makeplot = 'on' to display schematic parcellation

Requires access to:  - EEGLAB
                    - NicePlot
                    - 
****
Written by Quentin Mesnildrey (2021): contact: quentin.mesnildrey@gmail.com
****
%}
makeplot      = 'on'; % 'on' to display schematic parcellation
DataRoot      = '';
DataSubFolder = '';

%% scalp parcellation
% ---- Cz circle
r = 0.18;
n = 100;
theta = (0:n-1)*(2*pi/n);
x = r*cos(theta);
y = r*sin(theta);
Cz = polyshape(x,y);

% ------ Occip circle
r2 = .5;
n = 100;
x2 =  r2*cos(theta);
y2 = -0.8 + r2*sin(theta);
Occ = polyshape(x2,y2);
Occ = intersect(Occ,polyshape([-0.5 0.5 0.5 -0.5],[0 0 -.5 -0.5]));

% ------ Front circle
r3 = .5;
x3 =  r2*cos(theta);
y3 = 0.8 + r2*sin(theta);
AntFront = polyshape(x3,y3);
AntFront = intersect(AntFront,polyshape([-0.5 0.5 0.5 -0.5],[0 0 .5 0.5]));
% -----------
RHem = polyshape([0 0.5 0.5 0],[-.50 -.50 .5 0.5]);
LHem = polyshape([-0.5 0 0 -0.5],[-.50 -.50 .5 0.5]);
% -----------

% ------ RTemp circle
R = 0.7;
x5 =  1+ R*cos(theta);
y5 =  R*sin(theta);
RTemp = polyshape(x5,y5);
RTemp = intersect(RTemp,RHem);
% ------ LTemp circle
x4 =  -1+ R*cos(theta);
y4 =  R*sin(theta);
LTemp = polyshape(x4,y4);
LTemp = intersect(LTemp,LHem);

% -----------
LFront = polyshape([-0.5 0 0 -0.5],[0 0 .5 0.5]);
LFront = subtract(LFront,Cz);LFront = subtract(LFront,LTemp);
LFront = subtract(LFront,AntFront);
RFront = polyshape([-0.5 0 0 -0.5]+0.5,[0 0 .5 0.5]);
RFront = subtract(RFront,Cz);RFront = subtract(RFront,RTemp);
RFront = subtract(RFront,AntFront);
LPar =   polyshape([-0.5 0 0 -0.5],[0 0 .5 0.5]-0.5);
LPar = subtract(LPar,Cz);LPar = subtract(LPar,LTemp);
LPar = subtract(LPar,Occ);
RPar = polyshape([-0.5 0 0 -0.5]+0.5,[0 0 .5 0.5]-.5);
RPar = subtract(RPar,Cz);RPar = subtract(RPar,RTemp);
RPar = subtract(RPar,Occ);

%% MAKE PLOT
switch makeplot
    case 'on'
        subject = 'C01';
        EEG_path = [DataRoot,DataSubFolder, 'Preprocess_',subject,'.set'];
        EEG = pop_loadset(EEG_path);
        figure()
        CartoonHead(EEG.chanlocs,0,'2D','on'),hold on
        plot(AntFront),text(0, 0.4,num2str(1))
        plot(LFront),  text(-.2, 0.2,num2str(2))
        plot(RFront),  text(0.2, 0.2,num2str(3))
        plot(LTemp),   text(-.4, 0,num2str(4))
        plot(RTemp),   text(0.4, 0,num2str(6))
        plot(LPar),    text(-.2, -.2,num2str(7))
        plot(RPar),    text(0.2, -.2,num2str(8))
        plot(Cz),      text(0, 0,num2str(5))
        plot(Occ),     text(0, -0.4,num2str(9))
        axis([-0.6 0.6 -.6 .6])
        axis square
        set(gca,'YTick',[],'YTickLabel',   {})
        set(gca,'XTick',[],'XTickLabel',   {})
        legend({'AFront';'LFront';'RFront';'LTemp';'RTemp';'LPar';'RPar';'Cz';'Occ'},...
            'location','NorthEastOutSide')
        NicePlot
        box on
    otherwise
end