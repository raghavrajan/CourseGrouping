function [] = MakeTextFileWithGroups(Groups, CourseCodes, FileExt, Overlaps)

Fid = fopen([FileExt, '.LowestOverlapGroups.txt'], 'w');

for i = 1:length(Groups),
    fprintf(Fid, 'Grouping # %d : Overlap score = %g \n', i, Overlaps(i));
    for j = 1:length(Groups{i}),
        fprintf(Fid, 'Group %d\t', j);
    end
    fprintf(Fid, '\n');
    for j = 1:max(cellfun(@length, Groups{i})),
        for k = 1:length(Groups{i}),
            if (j <= length(Groups{i}{k}))
                fprintf(Fid, '%s (%d)\t', CourseCodes{Groups{i}{k}(j)}, Groups{i}{k}(j));
            else
                fprintf(Fid, '\t');
            end
        end
        fprintf(Fid, '\n');
    end

end
fclose(Fid);
disp('Written groups to text file');