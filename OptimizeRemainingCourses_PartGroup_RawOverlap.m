function [Groups, OverlapScore] = OptimizeRemainingCourses_PartGroup_RawOverlap(InputGroups, DataTable, CourseCodes, RemainingCourses, Index)

% This is a function to optimize the remaining groups. The idea is to take
% the groups and optimize the overlap with the rest of the courses, while
% adding them one at a time to the existing groups. This does it when the
% number of remaining courses are less than a full group. It tries out all
% possible combinations with the remaining courses and gives the best
% option with minimum overlap.

AllCombinations = combnk(1:1:length(InputGroups), length(RemainingCourses));

for i = 1:size(AllCombinations,1),
    Groups{i} = InputGroups;
    Groups{i}(AllCombinations(i,:)) = cellfun(@horzcat, Groups{i}(AllCombinations(i,:)), num2cell(RemainingCourses(:)'), 'UniformOutput', 0);
    OverlapScore(i) = FindOverallOverlapScore_RawOverlap(DataTable, Groups{i});
end

%MakeTextFileWithGroups(Groups, CourseCodes, ['2019.May', Index], OverlapScore);

[MinOverlap, MinOverlapIndex] = min(OverlapScore);
Groups = Groups{MinOverlapIndex};
OverlapScore = OverlapScore(MinOverlapIndex);

