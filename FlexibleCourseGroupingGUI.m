function [] = FlexibleCourseGroupingGUI(GroupingFile, CourseDataFile)

% Course grouping GUI - I already have one but that is for a fixed number
% of groups - 12. Instead I want one that is flexible and can accommodate
% any number of groups. Also, should be able to create new groups on the
% fly. This means I will have to remake the GUI each time.

% Check to see if gui exists, if yes, then close it.
    if (~isempty(findobj('Tag', 'CourseGroupingWindowGUI')))
        close(findobj('Tag', 'CourseGroupingWindowGUI'));
    end
    %% ================== LOAD COURSE DATA ====================================
    % First load up course data

    Data.CourseData = load(CourseDataFile);

    % This structure has 4 fields
    % (a) CourseCodes - a cell array
    % (b) DataTable - a table with registration data for all students -
    % students are rows and courses are columns. If a student has taken taken a
    % course then the corresponding row-column entry is 1, otherwise zero
    % (c) StudentIds - id nos. of students
    % (d) StudentNames - names of students
    % =========================================================================

    %% ================== LOAD GROUPS =========================================
    % Open file and get data
    Data.GroupingFile = GroupingFile;
    Fid = fopen(GroupingFile, 'r');
    TempData = textscan(Fid, '%s', 'DeLimiter', '\n');
    TempData = TempData{1};
    fclose(Fid);

    % Now skip the first two lines and then get courses in each group, tab separated
    % Initialize groups
    clear Data.Groups Data.GroupIndices;
    NumGroups = length((strfind(TempData{2}, 'Group')));

    for i = 1:NumGroups,
        Data.Groups{i} = [];
        Data.GroupIndices{i} = [];
    end
    for i = 3:length(TempData),
        TempGroupData = textscan(TempData{i}, '%s', 'DeLimiter', '\t');
        TempGroupData = TempGroupData{1};
        for j = 1:length(TempGroupData),
            OpenBracketIndex = find(TempGroupData{j} == '(');
            CloseBracketIndex = find(TempGroupData{j} == ')');
            if (~isempty(OpenBracketIndex))
                Data.Groups{j}{end+1} = TempGroupData{j}(1:OpenBracketIndex-2);
                Data.GroupIndices{j}(end+1) = str2double(TempGroupData{j}(OpenBracketIndex+1:CloseBracketIndex-1));
            end
        end
    end
    
    MakeGUIWindow = MakeGUI(Data);
end

function [Data] = ReCalculateOverlaps(Data)
    % Get overlap numbers for each group
    Data.AllOverlapStudentIds = [];
    if (isfield(Data, 'GroupOverlaps'))
        Data.GroupOverlaps = [];
    end
    for i = 1:length(Data.Groups),
        Data.GroupOverlaps(i) = length(find(sum(Data.CourseData.DataTable(:, Data.GroupIndices{i}), 2) > 1));
        [Data.GroupPairWiseOverlap{i}, Data.GroupOverlapStudentIds{i}] = GetGroupPairWiseOverlaps(Data.CourseData.DataTable, Data.GroupIndices{i}, Data.CourseData.StudentIds);
        for j = 1:size(Data.GroupOverlapStudentIds{i}, 1),
            for k = 1:size(Data.GroupOverlapStudentIds{i}, 2),
                if (~isempty(Data.GroupOverlapStudentIds{i}{j,k}))
                    Data.AllOverlapStudentIds = [Data.AllOverlapStudentIds; Data.GroupOverlapStudentIds{i}{j,k}];
                end
            end
        end
    end
end
    
% --- Executes on button press in MoveCourseButton.
function MoveCourseButton_Callback(hObject, eventdata, handles)
% hObject    handle to MoveCourseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    Data = guidata(findobj('Tag', 'CourseGroupingWindowGUI'));
    CourseToMove = inputdlg('Type the course code of the course to be moved', 'Course to be moved');
    for i = 1:length(Data.Groups),
        CourseCodeIndex = strmatch(CourseToMove, Data.Groups{i});
        if (~isempty(CourseCodeIndex))
            CourseGroupIndex = i;
            break;
        end
    end

    while (isempty(CourseCodeIndex))
        uiwait(msgbox('Not a valid course code'));
        CourseToMove = inputdlg('Type the course code of the course to be moved', 'Course to be moved');
        for i = 1:length(Data.Groups),
            CourseCodeIndex = strmatch(CourseToMove, Data.Groups{i});
            if (~isempty(CourseCodeIndex))
                CourseGroupIndex = i;
                OverallCourseCodeIndex = strmatch(CourseToMove, Data.CourseData.CourseCodes);
                break;
            end
        end
    end

    DestinationGroup = inputdlg('Type the group number where the course has to be moved', 'Destination group');
    DestinationGroup = str2double(DestinationGroup{1});

    if (DestinationGroup == CourseGroupIndex)
        uiwait(msgbox('Already in that group. Nothing to do'));
    else
        if (DestinationGroup > length(Data.GroupIndices))
            Data.GroupIndices{end+1} = [];
            Data.Groups{end+1} = [];
        end
        
        Data.GroupIndices{DestinationGroup}(end+1) = Data.GroupIndices{CourseGroupIndex}(CourseCodeIndex);
        Data.Groups{DestinationGroup}{end+1} = Data.Groups{CourseGroupIndex}{CourseCodeIndex};

        Data.GroupIndices{CourseGroupIndex}(CourseCodeIndex) = [];
        Data.Groups{CourseGroupIndex}(CourseCodeIndex) = [];
    end
    close(findobj('Tag', 'CourseGroupingWindowGUI'));
    MakeGUIWindow = MakeGUI(Data);
end

%
function [CourseGroupingWindow] = MakeGUI(Data)
    % Remove empty groups
    GroupLens = cellfun(@length, Data.Groups);
    EmptyGroups = find(GroupLens == 0);
    if (~isempty(EmptyGroups))
        Data.Groups(EmptyGroups) = [];
        Data.GroupIndices(EmptyGroups) = [];
    end

    NumGroups = length(Data.Groups);
    % Now add the number of students registered to the course code and put
    % that as the string that will go in the list box
    if (isfield(Data, 'GroupStrings'))
        Data.GroupStrings = [];
    end
    
    for i = 1:length(Data.Groups),
        for j = 1:length(Data.Groups{i}),
            Data.GroupStrings{i}{j} = [Data.Groups{i}{j}, '(', num2str(length(find(Data.CourseData.DataTable(:,Data.GroupIndices{i}(j)) == 1))), ')'];
        end
    end
    
    [Data] = ReCalculateOverlaps(Data);
    
    %% Build custom GUI based on the number of groups
    CourseGroupingWindow = figure('Visible', 'off', 'Position', [70 200 1800 800], 'Color', [0.7 0.7 0.7], 'Tag', 'CourseGroupingWindowGUI');
    OverallFontSize = 10;
    Padding = 25;
    ButtonHeight = 25;
    ButtonWidth = 250;
    InterGroupSpacing = 25;
    GroupBarWidth = (1800 - (NumGroups-1)*InterGroupSpacing - 2*Padding)/NumGroups;
    GroupTextLabelHeight = 35;
    GroupListBoxHeight = 170;
    GroupAxesHeight = 100;

    for i = 1:NumGroups,
        % For each group I want a text label with name of group and then a
        % listbox with group elements
        GroupLabelXPos = Padding + ((i-1) * (GroupBarWidth + InterGroupSpacing));
        GroupLabelYPos = (800 - Padding - GroupTextLabelHeight);

        GraphicElements.GroupLabels(i) = uicontrol('Style', 'text', 'String', {['Group #', num2str(i)]; ['Overlap = ', num2str(Data.GroupOverlaps(i))]}, 'FontSize', OverallFontSize, 'FontWeight', 'bold', 'Position', [GroupLabelXPos GroupLabelYPos GroupBarWidth GroupTextLabelHeight], 'BackgroundColor', 'w');

        GroupListBoxXPos = Padding + ((i-1) * (GroupBarWidth + InterGroupSpacing));
        GroupListBoxYPos = GroupLabelYPos - Padding - GroupListBoxHeight;
        GraphicElements.GroupListBox(i) = uicontrol('Style', 'text', 'String', Data.GroupStrings{i}, 'FontSize', OverallFontSize, 'FontWeight', 'bold', 'Position', [GroupListBoxXPos GroupListBoxYPos GroupBarWidth GroupListBoxHeight], 'BackgroundColor', 'w');

        GroupAxesXPos = Padding + ((i-1) * (GroupBarWidth + InterGroupSpacing));
        GroupAxesYPos = GroupListBoxYPos - Padding - GroupAxesHeight;
        if (i == NumGroups)
            GraphicElements.GroupAxes(i) = axes('Position', [GroupAxesXPos/1800 GroupAxesYPos/800 (GroupBarWidth)/1800 GroupAxesHeight/800]);
            colorbar;
        else
            GraphicElements.GroupAxes(i) = axes('Position', [GroupAxesXPos/1800 GroupAxesYPos/800 (GroupBarWidth)/1800 GroupAxesHeight/800]);
        end

        axes(GraphicElements.GroupAxes(i));
        cla;
        imagesc(Data.GroupPairWiseOverlap{i}, 'AlphaData', double(~isnan(Data.GroupPairWiseOverlap{i})));
        set(gca, 'XTick', 1:1:length(Data.GroupIndices{i}));
        set(gca, 'YTick', 1:1:length(Data.GroupIndices{i}));
        hold on;
        for j = 0:length(Data.GroupIndices{i}),
            plot([0.5 length(Data.GroupIndices{i})+0.5], ones(1,2)*(j+0.5), 'k', 'LineWidth', 0.5);
            plot(ones(1,2)*(j+0.5), [0.5 length(Data.GroupIndices{i})+0.5], 'k', 'LineWidth', 0.5);
        end
        colormap('hot');
        axis tight;
        caxis('auto');
        Data.ColourAxisVals(i,:) = caxis;

        if (i == 4)
            OtherGroupOverlapAxesYPos = GroupAxesYPos - Padding - 200;
            OtherGroupOverlapAxes = axes('Position', [GroupAxesXPos/1800 OtherGroupOverlapAxesYPos/800 (600)/1800 175/800], 'Tag', 'OtherGroupOverlaps');
        end
        if (i == 1)
            % Now make the buttons for moving courses to different groups
            WriteFilesButtonYPos = GroupAxesYPos - Padding - ButtonHeight;
            GraphicElements.WriteFilesButton = uicontrol('Style', 'pushbutton', 'String', 'Write Groups to File', 'FontSize', OverallFontSize, 'FontWeight', 'bold', 'Position', [GroupListBoxXPos WriteFilesButtonYPos ButtonWidth ButtonHeight], 'BackgroundColor', 'w', 'Callback', @WriteGroupsToFile_Callback);

            CheckOverlapWithGroupsButtonYPos = WriteFilesButtonYPos - Padding - ButtonHeight;
            GraphicElements.CheckOverlapWithGroupsButton = uicontrol('Style', 'pushbutton', 'String', 'Check Overlap with Groups', 'FontSize', OverallFontSize, 'FontWeight', 'bold', 'Position', [GroupListBoxXPos CheckOverlapWithGroupsButtonYPos ButtonWidth ButtonHeight], 'BackgroundColor', 'w', 'Callback', @CheckCourseWithOtherGroupsButton_Callback);

            MoveCourseButtonYPos = CheckOverlapWithGroupsButtonYPos - Padding - ButtonHeight;
            GraphicElements.MoveCoursesButton = uicontrol('Style', 'pushbutton', 'String', 'Move course', 'FontSize', OverallFontSize, 'FontWeight', 'bold', 'Position', [GroupListBoxXPos MoveCourseButtonYPos ButtonWidth ButtonHeight], 'BackgroundColor', 'w', 'Callback', @MoveCourseButton_Callback);
            
            TotalOverlapScoreYPos = MoveCourseButtonYPos - Padding - ButtonHeight*2;
            GraphicElements.TotalOverlapScoreLabel = uicontrol('Style', 'text', 'String', {['Total overlap = ', num2str(sum(Data.GroupOverlaps))]; ['Unique overlaps = ', num2str(length(unique(Data.AllOverlapStudentIds)))]}, 'FontSize', OverallFontSize, 'FontWeight', 'bold', 'Position', [GroupListBoxXPos TotalOverlapScoreYPos ButtonWidth ButtonHeight*2], 'BackgroundColor', 'w');
        end    
    end

    for i = 1:NumGroups,
        axes(GraphicElements.GroupAxes(i));
        caxis([0 max(Data.ColourAxisVals(:,2))]);
        if (i == NumGroups)
            colorbar;
        end
    end

    set(CourseGroupingWindow, 'Visible', 'on');
    guidata(CourseGroupingWindow, Data);
end
    

% --- Executes on button press in WriteGroupsToFile.
function WriteGroupsToFile_Callback(hObject, eventdata, handles)
% hObject    handle to WriteGroupsToFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

Data = guidata(findobj('Tag', 'CourseGroupingWindowGUI'));
TempGroups{1} = [];
[SortedVals, SortedIndices] = sort(cellfun(@length, Data.GroupIndices), 'descend');

for i = 1:length(SortedIndices),
    TempGroups{1}{i} = Data.GroupIndices{SortedIndices(i)};
end
MakeTextFileWithGroups(TempGroups, Data.CourseData.CourseCodes, [Data.GroupingFile, '.Alt'], sum(Data.GroupOverlaps));
ReadAndDisplayBestGroupInfo([Data.GroupingFile, '.Alt.LowestOverlapGroups.txt'], length(SortedIndices), Data.CourseData.DataTable, Data.CourseData.StudentIds, Data.CourseData.CourseCodes, Data.CourseData.CourseNames);
end


% --- Executes on button press in CheckCourseWithOtherGroupsButton.
function CheckCourseWithOtherGroupsButton_Callback(hObject, eventdata, handles)
% hObject    handle to CheckCourseWithOtherGroupsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

Data = guidata(findobj('Tag', 'CourseGroupingWindowGUI'));
CourseToCheck = inputdlg('Type the course code of the course to be checked', 'Course to be checked');
for i = 1:length(Data.Groups),
    CourseCodeIndex = strmatch(CourseToCheck, Data.Groups{i});
    if (~isempty(CourseCodeIndex))
        CourseGroupIndex = i;
        OverallCourseCodeIndex = strmatch(CourseToCheck, Data.CourseData.CourseCodes);
        break;
    end
end

while (isempty(CourseCodeIndex))
    uiwait(msgbox('Not a valid course code'));
    CourseToCheck = inputdlg('Type the course code of the course to be checked', 'Course to be checked');
    for i = 1:length(Data.Groups),
        CourseCodeIndex = strmatch(CourseToCheck, Data.Groups{i});
        if (~isempty(CourseCodeIndex))
            CourseGroupIndex = i;
            OverallCourseCodeIndex = strmatch(CourseToCheck, Data.CourseData.CourseCodes);
            break;
        end
    end
end

for i = 1:length(Data.Groups),
    if (i ~= CourseGroupIndex)
        Overlap(i) = length(find(sum(Data.CourseData.DataTable(:,[Data.GroupIndices{i} OverallCourseCodeIndex]),2) > 1));
    else
        Overlap(i) = NaN;
    end
end

axes(findobj('Tag', 'OtherGroupOverlaps'));
cla;
plot(Overlap, 'ks-', 'MarkerSize', 8, 'MarkerFaceColor', 'k', 'LineWidth', 1);
hold on;
plot(Overlap - Data.GroupOverlaps, 'rs-', 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'LineWidth', 1);
hold off;
legend('New group overlap score', 'Change in overlap score');
xlabel('Group #');
ylabel('# of Overlaps');
title(CourseToCheck);
set(gca, 'FontSize', 10);
zoom yon;
end
