function [CourseRegnData, CourseCodes, CourseCredits, StudentIds, StudentNames] = ReadCSVFilesAndFormDataTable_Dec2019(CSVFileList)

% =========================================================================
% Each student is a row and each course is a column. If a student has
% signed up for a course, then there is a 'Y' in that course column,
% otherwise the course column is empty. First row is all course codes,
% first column is student id, second column is student names
%
% Written by Raghav 23.05.2019 (modified from the
% ReadXLSFilesAndFormDataTable.m from last semester)
% =========================================================================

%% Read in the names of the excel files that have course registration information
Fid = fopen(CSVFileList, 'r');
Files = textscan(Fid, '%s', 'DeLimiter', '\n');
Files = Files{1};
fclose(Fid);

%% Initializing some variables
CourseCodes = [];
CourseCredits = [];
StudentIds = [];
StudentNames = [];

%% Read excel files and get unique course codes, their credits, student names and Ids
for i = 1:length(Files),
    clear FileStatus SheetList TxtData NumData RawData TempCourseCodes TempCourseCredits TempStudentNames TempStudentIds TempCourseRegnData;
    Fid = fopen(Files{i});
    TxtData = textscan(Fid, '%s', 'DeLimiter', '\n');
    TxtData = TxtData{1};
    fclose(Fid);
    
    % First row is course codes; first two columns and last column are
    % not course codes
    TempCourseCodes = textscan(TxtData{1}, '%s', 'DeLimiter', ',');
    TempCourseCodes = TempCourseCodes{1};
    TempCourseCodes = TempCourseCodes(3:end-1);

    % Second row is course credit #
    TempCourseCreditRow = textscan(TxtData{2}, '%s', 'DeLimiter', ',');
    TempCourseCreditRow = TempCourseCreditRow{1};
    TempCourseCreditRow = TempCourseCreditRow(3:end);
    for k = 1:length(TempCourseCreditRow),
        if (sum(TempCourseCreditRow{k}) == 1)
            TempCourseCredits(k) = NaN;
        else
            TempCourseCredits(k) = str2double(TempCourseCreditRow{k}(regexp(TempCourseCreditRow{k}, '\d')));
        end
    end

    % Now each row is a student and the courses the student has signed up
    % for with 'Y' if the student has signed up for the course
    for k = 3:length(TxtData),
        TempStudentData = textscan(TxtData{k}, '%s', 'DeLimiter', ',');
        TempStudentData = TempStudentData{1};
        % First column is student ids
        TempStudentIds(k-2) = str2double(TempStudentData{1});
        % Second column is student names
        TempStudentNames{k-2} = TempStudentData{2};
    end

    StudentNames = [StudentNames; TempStudentNames(:)];
    StudentIds = [StudentIds; TempStudentIds(:)];
    CourseCodes = [CourseCodes; TempCourseCodes(:)];
    CourseCredits = [CourseCredits; TempCourseCredits(:)];
end

[UniqueCourseCodes, UniqueCourseCodeIndices, Temp] = unique(CourseCodes);
CourseCodes = CourseCodes(UniqueCourseCodeIndices);
CourseCredits = CourseCredits(UniqueCourseCodeIndices);

%% Now get the course registration information from the same files
% This is the course regn data matrix that has students as rows and courses
% as columns. A 0 in a particular row column indicates student has not 
% taken the course and a 1 indicates student has taken the course
CourseRegnData = zeros(length(StudentNames), length(CourseCodes));  
for i = 1:length(Files),
    clear FileStatus SheetList TxtData NumData RawData TempCourseCodes TempCourseCredits TempStudentNames TempStudentIds TempCourseRegnData;
    Fid = fopen(Files{i});
    TxtData = textscan(Fid, '%s', 'DeLimiter', '\n');
    TxtData = TxtData{1};
    fclose(Fid);
    
    % First row is course codes; first two columns and last column are
    % not course codes
    TempCourseCodes = textscan(TxtData{1}, '%s', 'DeLimiter', ',');
    TempCourseCodes = TempCourseCodes{1};
    TempCourseCodes = TempCourseCodes(3:end-1);;

    for k = 3:length(TxtData),
        TempStudentData = textscan(TxtData{k}, '%s', 'DeLimiter', ',');
        TempStudentData = TempStudentData{1};
        % First column is student ids and use this to get the row id in the
        % course registration table
        TempStudentId = str2double(TempStudentData{1});
        RowId = find(StudentIds == TempStudentId);
            
        % Now find the courses the student has taken and find the
        % course code for them. Then match this with the course code in
        % the main set of courses and get the column id for the
        % course registration table. Then enter 1 there
        CourseRegnIndices = find(strcmp(TempStudentData, 'Y'));
        
        if (~isempty(CourseRegnIndices))
            % First subtract 2 to account for the fact that the first and
            % second column are student id and student name
            CourseRegnIndices = CourseRegnIndices - 2;
            % fprintf('File #%d: Line #%d\n', i, k);
            % disp(CourseRegnIndices(:)');
            for CoursesTaken = CourseRegnIndices(:)',
                TempCourseCode = TempCourseCodes{CoursesTaken};
                ColId = find(strcmp(CourseCodes, TempCourseCode));
                CourseRegnData(RowId, ColId) = 1;
            end
        end
    end
end

%% Display some stats about registration
% Stats that I want to display
% 1. Number of courses
% 2. Number of students
% 3. Number of students with no courses (also as a fraction of total number
% of students)
% 4. For the students who have pre-registered, min, median and max number
% of courses
% 5. Same as above but number of credits
% 6. Min, median and max number of students in each course

disp('Statistics about Course Pre-Registration');
disp('==================================================');
disp(['Total number of students = ', num2str(length(StudentIds))]);
disp(['Total number of courses = ', num2str(length(CourseCodes))]);
disp(['Number of students who have pre-registered = ', num2str(length(find(sum(CourseRegnData, 2) > 0))), '(', num2str(100 * length(find(sum(CourseRegnData, 2) > 0))/length(StudentIds)), '%)']);
StudentsWithPreRegn = find(sum(CourseRegnData, 2) > 0);
disp(['Median number of courses / student for students who have pre-registered = ', num2str(median(sum(CourseRegnData(StudentsWithPreRegn,:),2))), '; range = ', num2str(min(sum(CourseRegnData(StudentsWithPreRegn,:),2))), ' - ', num2str(max(sum(CourseRegnData(StudentsWithPreRegn,:),2)))]);
CourseCreditMatrix = repmat(CourseCredits(:)', size(CourseRegnData,1), 1);
disp(['Median number of credits / student for students who have pre-registered = ', num2str(median(sum(CourseRegnData(StudentsWithPreRegn,:).*CourseCreditMatrix(StudentsWithPreRegn,:),2))), '; range = ', num2str(min(sum(CourseRegnData(StudentsWithPreRegn,:).*CourseCreditMatrix(StudentsWithPreRegn,:),2))), ' - ', num2str(max(sum(CourseRegnData(StudentsWithPreRegn,:).*CourseCreditMatrix(StudentsWithPreRegn,:),2)))]);
disp(['Median number of students / course = ', num2str(median(sum(CourseRegnData))), '; range = ', num2str(min(sum(CourseRegnData))), ' - ', num2str(max(sum(CourseRegnData)))]); 
        

