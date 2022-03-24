function [] = CheckOverlap_HexaOverlap_RawOverlaps_Jan2020(DataTable, CourseCodes, CourseCredits, StudentId, MaxGroupNum, CourseGroupingConstraints, CoursesToExclude, CoursesToCombine, StartingVal, Step)

tic
TotalNumStudents = size(DataTable, 1);

% =========================================================================
% This is a function to check for overlap between student registration for
% courses. The idea is to look at courses that have minimal overlap and
% assign them to groups accordingly that can then be scheduled at the same
% time.
% Overall I have around ~70-75 courses and I need to put them in 12 groups
% In this variant, what I plan to do is to divide them into 12 groups of 3
% with minimum overlap. Then do the same with the remaining courses and
% then merge only the ones with zero or very little overlap.
% This uses raw overlap and not normalized overlap
% =========================================================================

%% First remove courses to exclude
for i = 1:length(CoursesToExclude),
    Match = find(strcmp(CoursesToExclude{i}, CourseCodes));
    if (~isempty(Match))
        CourseCodes(Match) = [];
        CourseCredits(Match) = [];
        DataTable(:,Match) = [];
    end
end
clear Match;

%% Next combine courses that have to be combined
for i = 1:length(CoursesToCombine),
    for j = 1:length(CoursesToCombine{i}),
        Match(j) = find(strcmp(CoursesToCombine{i}{j}, CourseCodes));
    end
    CourseCodes(Match(2:end)) = [];
    CourseCredits(Match(2:end)) = [];
    DataTable(:,Match(1)) = sum(DataTable(:,Match), 2);
    DataTable(:,Match(2:end)) = [];
    DataTable(find(DataTable(:,Match(1)) > 1),Match(1)) = 1;
    clear Match;
end

disp(['Total number of valid courses = ', num2str(size(DataTable, 2))]);

%% Next divide the courses into groups randomly and do this 100000 times
% and get a distribution of overlap scores. 
NumRandomRuns = 10000;
if (exist('CourseOverlap.mat', 'file'))
    load('CourseOverlap.mat');
else
    OverlapScore = ones(1,NumRandomRuns)*NaN;

    for i = 1:NumRandomRuns,
        if (mod(i,round(NumRandomRuns/5)) == 0)
            fprintf('%d>>', i);
        end
        clear Groups;
        Groups = [];
        RandomGrouping = randperm(length(CourseCodes));
        % Now to decide group size based on the number of groups
        GroupSize = floor(length(CourseCodes)/MaxGroupNum);
        Remainder = mod(length(CourseCodes), MaxGroupNum);
        
        for j = 1:Remainder,
            Groups{j} = RandomGrouping(length(cell2mat(Groups)) + 1:length(cell2mat(Groups)) + GroupSize + 1);
        end
        
        for j = Remainder+1:MaxGroupNum,
            Groups{j} = RandomGrouping(length(cell2mat(Groups)) + 1:length(cell2mat(Groups)) + GroupSize);
        end
        FinalSortedGroups = [];
        GroupValues = [];
        clear GroupOverlaps;
        for j = 1:length(Groups),
            GroupOverlaps(j) = length(find(sum(DataTable(:,Groups{j}), 2) > 1));
            %GroupOverlaps{j} = GroupOverlaps{j}(:)';
        end
        OverlapScore(i) = sum(GroupOverlaps);
    end
    fprintf('\n');
    disp(['Median overlap score = ', num2str(median(OverlapScore)), ': range = ', num2str(min(OverlapScore)), ' - ', num2str(max(OverlapScore))]);
    toc
end

%% Get the 5 course overlaps & sort it
% if (exist('Penta_Indices_Raw.mat', 'file'))
%     load('Penta_Indices_Raw.mat');
% else
% Original_Penta_Indices = uint8(zeros(nchoosek(length(CourseCodes),5),5));
% Original_Penta_Overlap = zeros(nchoosek(length(CourseCodes),5),1);

tic
Original_Penta_Indices = combnk(1:1:length(CourseCodes), 5);
Original_Penta_Indices = uint8(Original_Penta_Indices);
Original_Penta_Overlap = zeros(size(Original_Penta_Indices,1),1);

for i = 1:size(Original_Penta_Indices,1),
    Original_Penta_Overlap(i) = length(find((sum(DataTable(:, [Original_Penta_Indices(i,:)]), 2) > 1)));
end
toc
% end

[SortedVals, SortedIndices] = sort(Original_Penta_Overlap);
Original_Penta_Indices = Original_Penta_Indices(SortedIndices, :);
Original_Penta_Overlap = Original_Penta_Overlap(SortedIndices);

%% Now find the zero overlap combinations in the penta indices and add all possible combinations of the rest and find hexa indices with lowest overlap
% if (exist('Hexa_Indices_Raw.mat', 'file'))
%     load('Hexa_Indices_Raw.mat');
% else
    NumZeroOverlapPentaCombinations = length(find(Original_Penta_Overlap == 0));
    ZeroOverlapPentaCombinationIndices = Original_Penta_Indices(find(Original_Penta_Overlap == 0), :);

    clear Original_Penta_Indices Original_Penta_Overlap SortedVals SortedIndices;
    
    Original_Hexa_Indices = uint8(zeros(NumZeroOverlapPentaCombinations * (length(CourseCodes) - 5), 6));
    Original_Hexa_Overlap = ones(size(Original_Hexa_Indices, 1),1) * NaN;

    
    Index = 1;
    Penta_Overlap_Index = 1;
    NumRows = length(CourseCodes) - 5;
    for i = 1:NumZeroOverlapPentaCombinations,
        RemainderCourses = setdiff(1:1:length(CourseCodes), ZeroOverlapPentaCombinationIndices(Penta_Overlap_Index,:));
        Original_Hexa_Indices(Index:Index + NumRows - 1, :) = [repmat(ZeroOverlapPentaCombinationIndices(Penta_Overlap_Index,:), NumRows, 1) RemainderCourses(:)];
        Index = Index + NumRows;
        Penta_Overlap_Index = Penta_Overlap_Index + 1;
    end

    clear ZeroOverlapPentaCombinationIndices;

    for i = 1:size(Original_Hexa_Indices,1),
        Original_Hexa_Overlap(i) = length(find((sum(DataTable(:, [Original_Hexa_Indices(i,:)]), 2) > 1)));
    end

    % Now one last thing, will sort all the indices and remove any repeating
    % indices in a combination that are just in a different order
    Original_Hexa_Indices = sort(Original_Hexa_Indices, 2);
    [UniqueVals, UniqueIndices] = unique(Original_Hexa_Indices, 'rows', 'stable');
    Original_Hexa_Indices = Original_Hexa_Indices(UniqueIndices, :);
    Original_Hexa_Overlap = Original_Hexa_Overlap(UniqueIndices);

    [SortedVals, SortedIndices] = sort(Original_Hexa_Overlap);
    Original_Hexa_Indices = Original_Hexa_Indices(SortedIndices, :);
    Original_Hexa_Overlap = Original_Hexa_Overlap(SortedIndices);

    clear SortedIndices SortedVals;
    clear UniqueIndices UniqueVals
    Original_Hexa_Overlap = uint8(Original_Hexa_Overlap);
    
    % Now remove the penta indices as they occupy space and are not really
    % useful now.
% end

%% Now remove certain combinations based on criteria listed below for the Hexa Overlaps
% Make a copy of datatable and the overlap matrices
DataTableCopy = DataTable;

% Now to remove the following from this datatable
% 1. All of the overlaps that are > 1/3 the minimum overlap from the random
% overlap calculations.
% 2. All of the groups with more than 2 members from the same discipline
Original_Hexa_Indices(find(Original_Hexa_Overlap >= min(OverlapScore)/3),:) = [];
Original_Hexa_Overlap(find(Original_Hexa_Overlap >= min(OverlapScore)/3),:) = [];

Disciplines = {'BI' 'CH' 'PH' 'MT'};
for i = 1:length(Disciplines),
    DisciplineCourses{i} = uint8(find(cellfun(@length, strfind(CourseCodes, Disciplines{i}))));
end

for i = 1:length(Disciplines),
    % Now any row with more than 2 zeros has more than 2 courses from the
    % same discipline, so it should be excluded.
    
    Temp_All_Indices = Original_Hexa_Indices;
    for j = 1:length(DisciplineCourses{i}),
        Temp_All_Indices = int8(Temp_All_Indices).*(int8(Original_Hexa_Indices) - int8((uint8(ones(size(Original_Hexa_Indices)))*(DisciplineCourses{i}(j)))));
    end
    Temp_All_Indices = sum((Temp_All_Indices == 0), 2);
    if (length(DisciplineCourses{i}) > MaxGroupNum)
        MoreThan2CourseRows = find(Temp_All_Indices > 2);
    else
        MoreThan2CourseRows = find(Temp_All_Indices > 1);
    end
    Original_Hexa_Overlap(MoreThan2CourseRows) = [];
    Original_Hexa_Indices(MoreThan2CourseRows,:) = [];
end

Disciplines = {'EC' 'HS'};
HSSECS_Courses = [];
for i = 1:length(Disciplines),
    HSSECS_Courses = [HSSECS_Courses(:); find(cellfun(@length, strfind(CourseCodes, Disciplines{i})))];
end

HSSECS_Courses = uint8(HSSECS_Courses);

% Now any row with more than 2 zeros has more than 2 courses from the
% same discipline, so it should be excluded.

Temp_All_Indices = Original_Hexa_Indices;
for j = 1:length(HSSECS_Courses),
    Temp_All_Indices = int8(Temp_All_Indices).*(int8(Original_Hexa_Indices) - int8((uint8(ones(size(Original_Hexa_Indices)))*(HSSECS_Courses(j)))));
end
Temp_All_Indices = sum((Temp_All_Indices == 0), 2);
MoreThan2CourseRows = find(Temp_All_Indices > 2);
Original_Hexa_Overlap(MoreThan2CourseRows) = [];
Original_Hexa_Indices(MoreThan2CourseRows,:) = [];

Hexa_Indices = Original_Hexa_Indices;
Hexa_Overlap = Original_Hexa_Overlap;

% Original_All_Indices = Hexa_Indices;
% Original_All_Overlap = Hexa_Overlap;

%% Actual algorithm section for grouping
% Now to follow the following algorithm.
% Pick the lowest overlapping course group, then eliminate all other
% groups with at least one of the members of this course group. Then pick
% the lowest overlap group among the remaining, then again eliminate all
% other groups with at least of the members of this new group and so on
% till all groups are filled. Do this with all of the 
ActualOverlapScore = [];
FinalGroups = [];

MaxGroupNum = 12;
MinOverlapScore = min(OverlapScore);
Index = ones(MaxGroupNum, 1);

ZeroOverlapCombinations = length(find(Original_Hexa_Overlap == 0));

TooManyIterationFlag = 0;

Index(1) = StartingVal;

OverlapIndexFig = figure();
set(gcf, 'Position', [1 1 1200 800]);
set(gcf, 'PaperPositionMode', 'auto');

while (Index(1) > 0)
    tic;
    Index(2:end) = 1;
    disp(['=========== Run #', num2str(Index(1)), '============']);
    RunOverlap = 0;

    Hexa_Indices = Original_Hexa_Indices;
    Hexa_Overlap = Original_Hexa_Overlap;

    clear TempGroups;
    TempGroups{1} = Hexa_Indices(Index(1),:);
    RunOverlap = RunOverlap + Hexa_Overlap(Index(1));
    disp(['Added group #1 : Overlap Score = ', num2str(RunOverlap)]);
    
    % Now remove all of the groups with any of these members
    for j = 1:length(TempGroups{1}),
        if (~isnan(TempGroups{1}(j)))
            ZeroRows = int8(Hexa_Indices) - int8(TempGroups{1}(j));
            ZeroRows = sum(ZeroRows ~= 0, 2);
            Hexa_Indices(find(ZeroRows < size(Hexa_Indices,2)),:) = [];
            Hexa_Overlap(find(ZeroRows < size(Hexa_Indices,2))) = [];
        end
    end
    
    IterationNo = 1;
    while ((~isempty(Hexa_Indices)) && (length(TempGroups) < MaxGroupNum))
        IterationNo = IterationNo + 1;
        if (IterationNo > 1.5*MaxGroupNum)
            TooManyIterationFlag = 1;
            break;
        end
        TempGroups{end+1} = Hexa_Indices(Index(length(TempGroups)+1),:);
        RunOverlap = RunOverlap + Hexa_Overlap(Index(length(TempGroups)));
        %disp(['Added group #', num2str(length(TempGroups)), ' : Overlap Score = ', num2str(RunOverlap)]);
        if (RunOverlap > MinOverlapScore)
           % disp('Removed a group as min overlap score was exceeded');
            TempGroups(end) = [];
            RunOverlap = RunOverlap - Hexa_Overlap(Index(length(TempGroups)+1));
            Index(length(TempGroups)+1) = Index(length(TempGroups)+1) + 1;
            %disp('Increased Index');
            if (Index(length(TempGroups)+1) >= size(Hexa_Indices,1))
                if (length(TempGroups) == 1) 
                    %disp('Reached the last possible grouping. Now changing the first group');
                    break;
                else
                    TempGroups(end) = [];
                    RunOverlap = RunOverlap - Hexa_Overlap(Index(length(TempGroups)+1));
                    Index(length(TempGroups)+1) = Index(length(TempGroups)+1) + 1;
                    %disp('Reached the last possible grouping at this level. Stepping back one level');
                    continue;
                end
            else
                continue;
            end
        end
        % Now remove all of the groups with any of these members
        for j = 1:length(TempGroups{end}),
            if (~isnan(TempGroups{end}(j)))
                ZeroRows = int8(Hexa_Indices) - int8(TempGroups{end}(j));
                ZeroRows = sum(ZeroRows ~= 0, 2);
                Hexa_Indices(find(ZeroRows < size(Hexa_Indices,2)),:) = [];
                Hexa_Overlap(find(ZeroRows < size(Hexa_Indices,2))) = [];
            end
        end
        if (isempty(Hexa_Indices))
            % At this point, I have exhausted all of the options in the hexa group
            % indices. Now, I need to check whether there are enough groups. If
            % yes, then continue with next section, otherwise, add more groups with
            % least possible overlaps by generating new hexa overlaps with the
            % remaining courses (this might be feasible in terms of options and
            % memory only if the total number of remaining courses is < 36
            RemainingCourses = setdiff(1:1:length(CourseCodes), cell2mat(TempGroups));
            if ((length(RemainingCourses) < 36) && (length(TempGroups) < MaxGroupNum))
                Hexa_Indices = RemainingCourses(combnk(1:1:length(RemainingCourses), 6));
                Hexa_Indices = uint8(Hexa_Indices);
                for j = 1:size(Hexa_Indices,1),
                    Hexa_Overlap(j) = length(find((sum(DataTable(:, [Hexa_Indices(j,:)]), 2) > 1)));
                end
                Hexa_Overlap = uint8(Hexa_Overlap);
                
                % Now one last thing, will sort all the indices and remove any repeating
                % indices in a combination that are just in a different order
                Hexa_Indices = sort(Hexa_Indices, 2);
                [UniqueVals, UniqueIndices] = unique(Hexa_Indices, 'rows', 'stable');
                Hexa_Indices = Hexa_Indices(UniqueIndices, :);
                Hexa_Overlap = Hexa_Overlap(UniqueIndices);

                [SortedVals, SortedIndices] = sort(Hexa_Overlap);
                Hexa_Indices = Hexa_Indices(SortedIndices, :);
                Hexa_Overlap = Hexa_Overlap(SortedIndices);    
            end
        end
    end
    if (TooManyIterationFlag == 1)
        %disp('Too many iterations done. Continuing with next');
        TooManyIterationFlag = 0;
        Index(1) = Index(1) + Step;
        toc
        continue;
    end
    if (length(TempGroups) == MaxGroupNum)
        RemainingCourses = setdiff(1:1:length(CourseCodes), cell2mat(TempGroups));
        while (~isempty(RemainingCourses))
            if (length(RemainingCourses)/MaxGroupNum > 1)
                [TempGroups, RunOverlap] = OptimizeRemainingCourses_FullGroup(TempGroups, DataTable, CourseCodes, RemainingCourses, Index(1));
            else
                [TempGroups, RunOverlap] = OptimizeRemainingCourses_PartGroup_RawOverlap(TempGroups, DataTable, CourseCodes, RemainingCourses, Index(1));
            end
            RemainingCourses = setdiff(1:1:length(CourseCodes), cell2mat(TempGroups));
        end
        
        % RunOverlap = RunOverlap + length(find((sum(DataTable(:, TempGroups{end}), 2) > 1)))/length(find((sum(DataTable(:, TempGroups{end}), 2) > 0)));
        disp(['No more remaining groups: Overlap Score = ', num2str(RunOverlap)]);
    else
%         if (length(TempGroups) < (MaxGroupNum - 2))
%             Index(1) = Index(1) - 1;
%             continue;
%         end
    end
    if (length(cell2mat(TempGroups)) < length(CourseCodes))
        TempGroups{end+1} = setdiff(1:1:length(CourseCodes), cell2mat(TempGroups));
        RunOverlap = RunOverlap + length(find((sum(DataTable(:, TempGroups{end}), 2) > 1)));
        disp(['Added remaining courses to group #', num2str(length(TempGroups)), ' : Overlap Score = ', num2str(RunOverlap)]);
    end
    
    FinalGroups{1} = TempGroups;
    MakeTextFileWithGroups(FinalGroups, CourseCodes, ['2021.Jan.HexaOverlap.', num2str(Index(1))], RunOverlap);
    ActualOverlapScore(end+1,:) = [Index(1) RunOverlap];
    Index(1) = Index(1) + Step;
    % FinalGroups{end+1} = TempGroups;
    
    % MinOverlapScore = min([min(OverlapScore) ActualOverlapScore(:)']);
    MinOverlapScore = min(MinOverlapScore, RunOverlap);
    % Now to delete all rows with overlap > Min overlap score
    Original_Hexa_Indices(find(Original_Hexa_Overlap >= MinOverlapScore),:) = [];
    Original_Hexa_Overlap(find(Original_Hexa_Overlap >= MinOverlapScore),:) = [];

    figure(OverlapIndexFig);
    hold on;
    plot(ActualOverlapScore(:,1), ActualOverlapScore(:,2), 'bo-');
    toc
end

figure(1);
plot(ActualOverlapScore, 'bo-');


disp('Finished');