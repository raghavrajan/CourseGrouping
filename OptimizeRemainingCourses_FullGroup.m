function [Groups, OverlapScore] = OptimizeRemainingCourses_FullGroup(InputGroups, DataTable, CourseCodes, RemainingCourses, Index)

% This is a function to optimize the remaining groups. The idea is to take
% the groups and optimize the overlap with the rest of the courses, while
% adding them one at a time to the existing groups. This does it when the
% number of remaining courses are more than a full group. This code adds
% one course to each group and stop.

AllCombinations = combnk(1:1:length(RemainingCourses), length(InputGroups));

for i = 1:size(AllCombinations,1),
    Groups{i} = cellfun(@horzcat, InputGroups, num2cell(RemainingCourses(AllCombinations(i,:))), 'UniformOutput', 0);
    OverlapScore(i) = FindOverallOverlapScore(DataTable, Groups{i});
    CoursesRemaining(i,:) = RemainingCourses(setdiff(1:1:length(RemainingCourses), AllCombinations(i,:)));
end

%MakeTextFileWithGroups(Groups, CourseCodes, ['2019.May', Index], OverlapScore);

[MinOverlap, MinOverlapIndex] = min(OverlapScore);
Groups = Groups{MinOverlapIndex};
OverlapScore = OverlapScore(MinOverlapIndex);

