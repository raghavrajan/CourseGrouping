function [OverlapScore] = FindOverallOverlapScore(DataTable, Groups)

for i = 1:length(Groups),
    OverlapScore(i) = length(find(sum(DataTable(:, [Groups{i}]), 2) > 1));
    disp(['Group #', num2str(i), ': Overlap = ', num2str(OverlapScore(i))]);
end
%disp(OverlapScore);

OverlapScore = sum(OverlapScore);