function [PairWiseOverlap, OverlapStudentIds] = GetGroupPairWiseOverlaps(DataTable, Group, StudentIds)

PairWiseOverlap = ones(length(Group))*NaN;
if (length(Group) == 1)
    OverlapStudentIds = [];
end
for i = 1:length(Group),
    for j = i+1:length(Group),
        if (i ~= j)
            PairWiseOverlap(i,j) = length(find(sum(DataTable(:, [Group(i) Group(j)]), 2) > 1));
            OverlapStudentIds{i,j} = StudentIds(find(sum(DataTable(:, [Group(i) Group(j)]), 2) > 1));
        end
    end
end
% figure;
% imagesc(PairWiseOverlap);
% colorbar;