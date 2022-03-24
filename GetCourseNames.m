function [CourseNames] = GetCourseNames(CSVFile, CourseCodes)

Fid = fopen(CSVFile, 'r');
Data = textscan(Fid, '%s', 'DeLimiter', '\n');
Data = Data{1};
fclose(Fid);

for i = 1:length(Data),
    TempData = textscan(Data{i}, '%s', 'DeLimiter', ',');
    CourseDetails{i} = TempData{1};
end

for i = 1:length(CourseCodes),
    for j = 1:length(CourseDetails),
        if (~isempty(find(cellfun(@length, strfind(CourseDetails{j}, CourseCodes{i})))))
            CourseNames{i} = CourseDetails{j}{4};
        end
    end
end

disp('Finished');