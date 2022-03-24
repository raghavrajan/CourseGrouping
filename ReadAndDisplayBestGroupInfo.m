function [Groups, GroupIndices] = ReadAndDisplayBestGroupInfo(BestFile, MaxGroupNum, DataTable, StudentIds, CourseCodes, varargin)

if (nargin > 5)
    CourseNames = varargin{1};
end

%% Open file and get data
Fid = fopen(BestFile, 'r');
Data = textscan(Fid, '%s', 'DeLimiter', '\n');
Data = Data{1};
fclose(Fid);

%% Now skip the first two lines and then get courses in each group, tab separated
% Initialize groups
for i = 1:MaxGroupNum,
    Groups{i} = [];
    GroupIndices{i} = [];
end
for i = 3:length(Data),
    TempGroupData = textscan(Data{i}, '%s', 'DeLimiter', '\t');
    TempGroupData = TempGroupData{1};
    for j = 1:length(TempGroupData),
        OpenBracketIndex = find(TempGroupData{j} == '(');
        CloseBracketIndex = find(TempGroupData{j} == ')');
        if (~isempty(OpenBracketIndex))
            Groups{j}{end+1} = TempGroupData{j}(1:OpenBracketIndex-2);
            GroupIndices{j}(end+1) = str2double(TempGroupData{j}(OpenBracketIndex+1:CloseBracketIndex-1));
        end
    end
end

%% Now save the groups as a text file with information about overlaps too
Fid = fopen([BestFile, '.Display.txt'], 'w');
fprintf(Fid, 'Grouping from %s\n\n', BestFile);

for i = 1:length(Groups),
    GroupOverlaps(i) = length(find(sum(DataTable(:, [GroupIndices{i}]), 2) > 1));
    fprintf(Fid, 'Group #%d : Overlap = %d', i, length(find(sum(DataTable(:, [GroupIndices{i}]), 2) > 1)));
    if (i ~= length(Groups))
        fprintf(Fid, ',');
    else
        fprintf(Fid, '\n');
    end
end


for j = 1:max(cellfun(@length, Groups)),
    for i = 1:length(Groups),
        if (j <= length(Groups{i}))
            if (exist('CourseNames', 'var'))
                fprintf(Fid, '%s: %s (%d)', CourseNames{GroupIndices{i}(j)}, Groups{i}{j}, sum(DataTable(:, GroupIndices{i}(j))));
            else
                fprintf(Fid, '%s (%d)', Groups{i}{j}, sum(DataTable(:, GroupIndices{i}(j))));
            end
            fprintf(Fid, ' ;');
        else
            fprintf(Fid, ' ;');
        end
    end
    fprintf(Fid, '\n');
end
fprintf(Fid, '\n\n');

AllOverlapStudents = [];
AllOverlapCoursePairs = [];
% Now print overlaps within the group as a matrix
for i = 1:length(GroupOverlaps),
    if (GroupOverlaps(i) ~= 0)
        fprintf(Fid, 'Pair-wise overlap for Group #%d (Overlap = %d);', i, GroupOverlaps(i));
        fprintf(Fid, 'Ids for students overlapping for Group #%d (Overlap = %d);', i, GroupOverlaps(i));
        [PairWiseOverlap, OverlapStudentIds] = GetGroupPairWiseOverlaps(DataTable, GroupIndices{i}, StudentIds);
               
        fprintf(Fid, '\n');
        % First the header lines with the course codes
        for j = 1:size(PairWiseOverlap,1),
            fprintf(Fid, '%s;', Groups{i}{j});
        end
        fprintf(Fid, ';;');
        for j = 1:size(PairWiseOverlap,1),
            fprintf(Fid, '%s;', Groups{i}{j});
        end
        fprintf(Fid, '\n');
        for j = 1:size(PairWiseOverlap,1),
            fprintf(Fid, '%s;', Groups{i}{j});
            for k = 1:size(PairWiseOverlap, 2),
                fprintf(Fid, '%d;', PairWiseOverlap(j,k));
            end
            fprintf(Fid, ';');
            fprintf(Fid, '%s;', Groups{i}{j});
        
            for k = 1:size(PairWiseOverlap, 2),
                if ~isnan(PairWiseOverlap(j,k))
                    for Matches = 1:PairWiseOverlap(j,k),
                        fprintf(Fid, '%d;', OverlapStudentIds{j,k}(Matches));
                        AllOverlapStudents(end+1) = OverlapStudentIds{j,k}(Matches);
                        AllOverlapCoursePairs{end+1} = [Groups{i}{j}, ':', Groups{i}{k}];
                    end
                end
                fprintf(Fid, ';');
            end
            fprintf(Fid, '\n');
        end
        fprintf(Fid, '\n');
    end
end

fprintf(Fid, '\n\n');

fprintf(Fid, 'Total number of students with overlaps = %d and number of unique students = %d\n\n', length(AllOverlapStudents), length(unique(AllOverlapStudents)));
fprintf(Fid, 'List of students with overlaps\n');
for i = 1:length(AllOverlapStudents),
    fprintf(Fid, 'Student ID %d - courses with overlap = %s\n', AllOverlapStudents(i), AllOverlapCoursePairs{i});
end

fclose(Fid);
disp('Finished');