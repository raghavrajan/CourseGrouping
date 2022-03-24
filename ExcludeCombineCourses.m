function [DataTable, CourseCodes, CourseCredits] = ExcludeCombineCourses(DataTable, CoursesToExclude, CourseCodes, CourseCredits, CoursesToCombine)

%% First remove courses to exclude
for i = 1:length(CoursesToExclude),
    Match = find(strcmp(CoursesToExclude{i}, CourseCodes));
    if (~isempty(Match))
        CourseCodes(Match) = [];
        CourseCredits(Match) = [];
        DataTable(:,Match) = [];
    end
end

%% Next combine courses that have to be combined
if (~isempty(CoursesToCombine))
    for i = 1:length(CoursesToCombine),
        clear Match;
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
end