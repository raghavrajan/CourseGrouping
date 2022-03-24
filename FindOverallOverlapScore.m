function [OverlapScore] = FindOverallOverlapScore(DataTable, Groups)

for i = 1:length(Groups),
    OverlapScore(i) = length(find(sum(DataTable(:, [Groups{i}]), 2) > 1));
end
%disp(OverlapScore);

for i = 1:length(Groups),
    OverlapScore(i) = length(find(sum(DataTable(:, [Groups{i}]), 2) > 1))/length(find(sum(DataTable(:, [Groups{i}]), 2) > 0));
end
%disp(OverlapScore);
OverlapScore = sum(OverlapScore);