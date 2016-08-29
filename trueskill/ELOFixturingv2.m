%% ELO Fixturing

% Initiation lines
clear
close all
clc

% Load ELO data & Organise Data
% [ELOValues,TeamNames] = xlsread('TeamELODataSorted.xlsx');
load('InitialELOData.mat')
NumberOfTeams = size(TeamNames,1);
ELODifference = repmat(ELOValues,[1,NumberOfTeams]) - repmat(ELOValues',[NumberOfTeams,1]);
AbsELODifference = abs(ELODifference);
NumberOfGames = NumberOfTeams/2;
NumberOfRounds = 12;

% Sort Teams
[SortedVals, SortELOInd] = sort(ELOValues,'descend');
ELONameOrder = TeamNames(SortELOInd);
[AZOrder, AZInd] = sort(ELONameOrder);

TeamsLeft = NumberOfTeams;
OwnTeams = diag(ones(102,1));
TeamsPlayed = OwnTeams;
RoundELODiffs = zeros(NumberOfRounds,1);


% Initial Variables
MaxPosDiff = 15;
TeamsCounted = 0;
NumberToKeep = 100;
RoundName = 'Sheet 1';

% Excel File Info
Excel = actxserver('Excel.Application');
Workbook = Excel.Workbooks.Add;
Sheets = Excel.ActiveWorkbook.Sheets;


for ri = 1:NumberOfRounds
    fprintf('Current Round is: Round %.f \n',ri)
    for gi = 1:NumberOfGames
        % Work out how many available possibilities there are
        
        TeamsLeft = NumberOfTeams - TeamsCounted;
        if isequal(gi,1)
            OverallPotentialGames = 0;
            NumberGamesCounted = 1;
        else
            OverallPotentialGames = NewPotentialGames;
            NumberGamesCounted = size(OverallPotentialGames,1);
        end
        
        NPossibilities = 2*MaxPosDiff*NumberGamesCounted;
        NewPotentials = zeros(NPossibilities,2,gi);
        PossibilityIt = 1;
        for ni = 1:NumberGamesCounted
            OldPotentialGames = OverallPotentialGames(ni,:);
            CurrentAvailableTeams = setdiff(SortELOInd', OldPotentialGames, 'stable');
            [SortedVals, AvailSortInd] = sort(ELOValues(CurrentAvailableTeams),'descend');
            CurrentTeam = CurrentAvailableTeams(1);
            CurrentPosition = find(SortELOInd == CurrentTeam);
            FirstTeam = max(CurrentPosition - MaxPosDiff,1);
            LastTeam  = min(CurrentPosition + MaxPosDiff,NumberOfTeams);
            CurrentTeamsPlayed = TeamsPlayed(CurrentTeam,:);
            TeamsCannotPlay = find(CurrentTeamsPlayed == 1);
            OppositionsIndex = SortELOInd(FirstTeam:LastTeam);
            
            PotentialTeams1 = intersect(OppositionsIndex,CurrentAvailableTeams);
            PotentialTeams2 = setdiff(PotentialTeams1,TeamsCannotPlay);
            if ~isempty(PotentialTeams2)
                NumberAvailableTeams = size(PotentialTeams2,1);           
                PossRange = PossibilityIt:(PossibilityIt + NumberAvailableTeams - 1);
                if gi>1
                    PreviousPotentialGames = reshape(OldPotentialGames,[1,2,gi-1]);
                    PreviousPossibilities = repmat(PreviousPotentialGames, [NumberAvailableTeams,1,1]);
                    NewPotentials(PossRange,1:2,1:gi-1) = PreviousPossibilities;
                end
                NewPotentials(PossRange,1,gi) = CurrentTeam*ones(1,NumberAvailableTeams);
                NewPotentials(PossRange,2,gi) = PotentialTeams2;
                PossibilityIt = PossibilityIt + NumberAvailableTeams;
            end
        end
        
        ActualNewPotentials = NewPotentials(1:(PossibilityIt-1),:,:);
        PotentialELODiffs = abs(ELOValues(ActualNewPotentials(:,1,:)) - ELOValues(ActualNewPotentials(:,2,:)));
        PotentialELOSums = sum(PotentialELODiffs,3);
        NumberOfSums = size(PotentialELOSums,1);
        TeamsCounted = gi*2;
        
        PercentageSelection = 0.05; % Select from first 10% of possibilties
        NumberSelect = ceil(PercentageSelection*NumberOfSums);
        
        if NumberSelect>NumberToKeep
            [SortedSums,SortIndices] = sort(PotentialELOSums,'ascend');
            SelectValues = randperm(NumberSelect,NumberToKeep);
            PossibilitiesToKeep = ActualNewPotentials(SelectValues,:,:);
            NewPotentialGames = reshape(PossibilitiesToKeep,[NumberToKeep,TeamsCounted]);
        else
            PossibilitiesToKeep = ActualNewPotentials;
            NewPotentialGames = reshape(PossibilitiesToKeep,[NumberOfSums,TeamsCounted]);
        end
    end
    
    ChosenFixture = 1;
    FixtureList = cell(NumberOfGames,3);
    for gameind = 1:NumberOfGames
        Teams = PossibilitiesToKeep(ChosenFixture,:,gameind);
        HomeAway = randperm(2);
        FixtureList{gameind,1} = TeamNames{Teams(HomeAway(1)),1};
        FixtureList{gameind,2} = 'v';
        FixtureList{gameind,3} = TeamNames{Teams(HomeAway(2)),1};
        
        TeamsPlayed(Teams(1),Teams(2)) = 1;
        TeamsPlayed(Teams(2),Teams(1)) = 1;
    end
    
    % Add fixtures to excel document
    WorkSheets = Workbook.Sheets;
    WorkSheets.Add([], WorkSheets.Item(WorkSheets.Count));
    RoundName = sprintf('Round %.f',ri);
    CurrentSheet = Sheets.get('Item',ri+1);
    CurrentSheet.Range('A1').Value = RoundName;
    CurrentSheet.Range(strcat('A2:C',num2str(NumberOfGames+1))).Value = FixtureList;
    CurrentSheet.Name = RoundName;
end
%%
ExcelFile = fullfile(pwd,'FixtureInfo.xlsx');
Workbook.SaveAs(ExcelFile);
Excel.Quit
Excel.delete
clear Excel