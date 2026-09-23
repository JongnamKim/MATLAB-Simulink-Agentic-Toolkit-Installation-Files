classdef AgenticToolkitOfflineInstallerApp < matlab.apps.AppBase
    % Programmatic app for offline MATLAB/Simulink Agentic Toolkit setup.

    properties (Access = public)
        UIFigure matlab.ui.Figure
    end

    properties (Access = private)
        RootGrid matlab.ui.container.GridLayout
        HeaderLabel matlab.ui.control.Label
        FolderGrid matlab.ui.container.GridLayout
        FolderEditField matlab.ui.control.EditField
        BrowseButton matlab.ui.control.Button
        ValidateButton matlab.ui.control.Button
        ToolkitGrid matlab.ui.container.GridLayout
        ToolkitDropDown matlab.ui.control.DropDown
        InstallButton matlab.ui.control.Button
        MainGrid matlab.ui.container.GridLayout
        MatlabPanel matlab.ui.container.Panel
        MatlabListBox matlab.ui.control.ListBox
        SimulinkPanel matlab.ui.container.Panel
        SimulinkListBox matlab.ui.control.ListBox
        SelectedPanel matlab.ui.container.Panel
        SelectedGroupsTextArea matlab.ui.control.TextArea
        ActionGrid matlab.ui.container.GridLayout
        InstallSkillsButton matlab.ui.control.Button
        ResetSkillsButton matlab.ui.control.Button
        CheckButton matlab.ui.control.Button
        LogTextArea matlab.ui.control.TextArea
        SelectedMatlabSkillGroups string = strings(0, 1)
        SelectedSimulinkSkillGroups string = strings(0, 1)
        MatlabSkillGroups string = strings(0, 1)
        SimulinkSkillGroups string = strings(0, 1)
    end

    properties (Access = private, Constant)
        DefaultMatlabSkillGroups = "matlab-core"
        DefaultSimulinkSkillGroups = "model-based-design-core"
    end

    methods (Access = public)
        function app = AgenticToolkitOfflineInstallerApp
            createComponents(app);
            registerApp(app, app.UIFigure);
            refreshSkillGroupsFromCurrentFolder(app);
            updateToolkitControls(app);
            updateSelectedGroupsDisplay(app);

            if nargout == 0
                clear app
            end
        end

        function delete(app)
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end
    end

    methods (Access = private)
        function createComponents(app)
            app.UIFigure = uifigure( ...
                Name="Agentic Toolkit Offline Installer", ...
                Position=[100 100 1120 740]);

            app.RootGrid = uigridlayout(app.UIFigure, [6 1]);
            app.RootGrid.RowHeight = {36, 44, 44, "1x", 42, 190};
            app.RootGrid.ColumnWidth = {"1x"};
            app.RootGrid.Padding = [14 12 14 12];
            app.RootGrid.RowSpacing = 10;

            app.HeaderLabel = uilabel(app.RootGrid);
            app.HeaderLabel.Text = "Agentic Toolkit Offline Installer";
            app.HeaderLabel.FontSize = 20;
            app.HeaderLabel.FontWeight = "bold";

            app.FolderGrid = uigridlayout(app.RootGrid, [1 4]);
            app.FolderGrid.ColumnWidth = {160, "1x", 96, 120};
            app.FolderGrid.RowHeight = {"1x"};
            app.FolderGrid.Padding = [0 0 0 0];
            app.FolderGrid.ColumnSpacing = 8;

            folderLabel = uilabel(app.FolderGrid);
            folderLabel.Text = "Offline Package Folder";
            folderLabel.FontWeight = "bold";

            app.FolderEditField = uieditfield(app.FolderGrid, "text");
            app.FolderEditField.Value = "D:\agentic-offline";
            app.FolderEditField.ValueChangedFcn = @(~, ~) validateInputs(app);

            app.BrowseButton = uibutton(app.FolderGrid, "push");
            app.BrowseButton.Text = "Browse";
            app.BrowseButton.ButtonPushedFcn = @(~, ~) browseFolder(app);

            app.ValidateButton = uibutton(app.FolderGrid, "push");
            app.ValidateButton.Text = "Validate Files";
            app.ValidateButton.ButtonPushedFcn = @(~, ~) validateInputs(app);

            app.ToolkitGrid = uigridlayout(app.RootGrid, [1 3]);
            app.ToolkitGrid.ColumnWidth = {160, "1x", 140};
            app.ToolkitGrid.RowHeight = {"1x"};
            app.ToolkitGrid.Padding = [0 0 0 0];
            app.ToolkitGrid.ColumnSpacing = 8;

            toolkitLabel = uilabel(app.ToolkitGrid);
            toolkitLabel.Text = "Agentic Toolkit";
            toolkitLabel.FontWeight = "bold";

            app.ToolkitDropDown = uidropdown(app.ToolkitGrid);
            app.ToolkitDropDown.Items = {'MATLAB', 'Simulink', 'MATLAB and Simulink'};
            app.ToolkitDropDown.Value = 'MATLAB and Simulink';
            app.ToolkitDropDown.ValueChangedFcn = @(~, ~) updateToolkitControls(app);

            app.InstallButton = uibutton(app.ToolkitGrid, "push");
            app.InstallButton.Text = "Install Offline";
            app.InstallButton.FontWeight = "bold";
            app.InstallButton.ButtonPushedFcn = @(~, ~) runInstall(app);

            app.MainGrid = uigridlayout(app.RootGrid, [1 3]);
            app.MainGrid.ColumnWidth = {"1x", "1x", "1x"};
            app.MainGrid.RowHeight = {"1x"};
            app.MainGrid.Padding = [0 0 0 0];
            app.MainGrid.ColumnSpacing = 12;

            app.MatlabPanel = uipanel(app.MainGrid);
            app.MatlabPanel.Title = "MATLAB Skill Groups";
            matlabGrid = uigridlayout(app.MatlabPanel, [1 1]);
            matlabGrid.Padding = [8 8 8 8];

            app.MatlabListBox = uilistbox(matlabGrid);
            app.MatlabListBox.Items = cellstr(app.MatlabSkillGroups);
            app.MatlabListBox.Multiselect = "on";
            app.MatlabListBox.Value = {};
            app.MatlabListBox.ValueChangedFcn = @(~, ~) updateSelectedSkillGroups(app, "matlab");

            app.SimulinkPanel = uipanel(app.MainGrid);
            app.SimulinkPanel.Title = "Simulink Skill Groups";
            simulinkGrid = uigridlayout(app.SimulinkPanel, [1 1]);
            simulinkGrid.Padding = [8 8 8 8];

            app.SimulinkListBox = uilistbox(simulinkGrid);
            app.SimulinkListBox.Items = cellstr(app.SimulinkSkillGroups);
            app.SimulinkListBox.Multiselect = "on";
            app.SimulinkListBox.Value = {};
            app.SimulinkListBox.ValueChangedFcn = @(~, ~) updateSelectedSkillGroups(app, "simulink");

            app.SelectedPanel = uipanel(app.MainGrid);
            app.SelectedPanel.Title = "Selected Skill Groups";
            selectedGrid = uigridlayout(app.SelectedPanel, [2 1]);
            selectedGrid.RowHeight = {"1x", 30};
            selectedGrid.ColumnWidth = {"1x"};
            selectedGrid.Padding = [8 8 8 8];
            selectedGrid.RowSpacing = 8;

            app.SelectedGroupsTextArea = uitextarea(selectedGrid);
            app.SelectedGroupsTextArea.Editable = "off";
            app.SelectedGroupsTextArea.Value = "No skill groups selected.";

            app.ResetSkillsButton = uibutton(selectedGrid, "push");
            app.ResetSkillsButton.Text = "Reset Selection";
            app.ResetSkillsButton.ButtonPushedFcn = @(~, ~) resetSelectedSkillGroups(app);

            app.ActionGrid = uigridlayout(app.RootGrid, [1 2]);
            app.ActionGrid.ColumnWidth = {"1x", "1x"};
            app.ActionGrid.RowHeight = {"1x"};
            app.ActionGrid.Padding = [0 0 0 0];
            app.ActionGrid.ColumnSpacing = 8;

            app.InstallSkillsButton = uibutton(app.ActionGrid, "push");
            app.InstallSkillsButton.Text = "Install Skills";
            app.InstallSkillsButton.FontWeight = "bold";
            app.InstallSkillsButton.ButtonPushedFcn = @(~, ~) runInstallSkills(app);

            app.CheckButton = uibutton(app.ActionGrid, "push");
            app.CheckButton.Text = "Status / Initialize";
            app.CheckButton.ButtonPushedFcn = @(~, ~) runStatusAndInitialize(app);

            app.LogTextArea = uitextarea(app.RootGrid);
            app.LogTextArea.Editable = "off";
            app.LogTextArea.Value = [
                "Ready."
                "Expected files: agenticToolkitInstaller.mltbx, matlab-mcp-server-windows-x64.exe, MATLABMCPServerToolbox.mltbx."
                "Expected folders: matlab-agentic-toolkit-main and/or simulink-agentic-toolkit-main."
                ];
        end

        function browseFolder(app)
            startFolder = app.FolderEditField.Value;
            if ~isfolder(startFolder)
                startFolder = pwd;
            end

            selectedFolder = uigetdir(startFolder, "Select offline package folder");
            if isequal(selectedFolder, 0)
                return
            end

            app.FolderEditField.Value = selectedFolder;
            validateInputs(app);
        end

        function updateToolkitControls(app)
            installMatlab = wantsToolkit(app, "matlab");
            installSimulink = wantsToolkit(app, "simulink");

            app.MatlabListBox.Enable = onOff(app, installMatlab);
            app.SimulinkListBox.Enable = onOff(app, installSimulink);

            if ~installMatlab
                app.MatlabListBox.Value = {};
                app.SelectedMatlabSkillGroups = strings(0, 1);
            end
            if ~installSimulink
                app.SimulinkListBox.Value = {};
                app.SelectedSimulinkSkillGroups = strings(0, 1);
            end

            applyDefaultSkillGroups(app, false);
            updateSelectedGroupsDisplay(app);
        end

        function updateSelectedSkillGroups(app, toolkitName)
            toolkitName = string(toolkitName);
            switch toolkitName
                case "matlab"
                    selectedNow = selectedGroups(app, app.MatlabListBox);
                    app.SelectedMatlabSkillGroups = unique([app.SelectedMatlabSkillGroups; selectedNow(:)], "stable");
                    setListBoxSelection(app, app.MatlabListBox, app.SelectedMatlabSkillGroups);
                case "simulink"
                    selectedNow = selectedGroups(app, app.SimulinkListBox);
                    app.SelectedSimulinkSkillGroups = unique([app.SelectedSimulinkSkillGroups; selectedNow(:)], "stable");
                    setListBoxSelection(app, app.SimulinkListBox, app.SelectedSimulinkSkillGroups);
            end

            updateSelectedGroupsDisplay(app);
        end

        function resetSelectedSkillGroups(app)
            applyDefaultSkillGroups(app, true);
            updateSelectedGroupsDisplay(app);
            appendLog(app, "Selected skill groups reset to defaults.");
        end

        function applyDefaultSkillGroups(app, resetToDefaults)
            if wantsToolkit(app, "matlab")
                app.SelectedMatlabSkillGroups = mergeDefaultSkillGroups( ...
                    app, app.SelectedMatlabSkillGroups, app.MatlabSkillGroups, ...
                    app.DefaultMatlabSkillGroups, resetToDefaults);
                setListBoxSelection(app, app.MatlabListBox, app.SelectedMatlabSkillGroups);
            else
                app.SelectedMatlabSkillGroups = strings(0, 1);
                app.MatlabListBox.Value = {};
            end

            if wantsToolkit(app, "simulink")
                app.SelectedSimulinkSkillGroups = mergeDefaultSkillGroups( ...
                    app, app.SelectedSimulinkSkillGroups, app.SimulinkSkillGroups, ...
                    app.DefaultSimulinkSkillGroups, resetToDefaults);
                setListBoxSelection(app, app.SimulinkListBox, app.SelectedSimulinkSkillGroups);
            else
                app.SelectedSimulinkSkillGroups = strings(0, 1);
                app.SimulinkListBox.Value = {};
            end
        end

        function selected = mergeDefaultSkillGroups(~, selected, availableGroups, defaultGroups, resetToDefaults)
            availableGroups = string(availableGroups(:));
            defaultGroups = string(defaultGroups(:));

            if resetToDefaults
                selected = strings(0, 1);
            else
                selected = string(selected(:));
                selected = selected(ismember(selected, availableGroups));
            end

            defaultGroups = defaultGroups(ismember(defaultGroups, availableGroups));
            selected = unique([selected(:); defaultGroups(:)], "stable");
        end

        function setListBoxSelection(~, listBox, groups)
            if isempty(groups)
                listBox.Value = {};
            else
                listBox.Value = cellstr(groups(:));
            end
        end

        function updateSelectedGroupsDisplay(app)
            matlabGroups = app.SelectedMatlabSkillGroups;
            simulinkGroups = app.SelectedSimulinkSkillGroups;
            lines = strings(0, 1);

            if wantsToolkit(app, "matlab")
                lines(end + 1) = "MATLAB Skill Groups";
                lines = [lines; formatSelectedGroups(app, matlabGroups)];
            end

            if wantsToolkit(app, "simulink")
                if ~isempty(lines)
                    lines(end + 1) = "";
                end
                lines(end + 1) = "Simulink Skill Groups";
                lines = [lines; formatSelectedGroups(app, simulinkGroups)];
            end

            if isempty(lines)
                lines = "No skill groups selected.";
            end

            app.SelectedGroupsTextArea.Value = lines;
        end

        function lines = formatSelectedGroups(~, groups)
            if isempty(groups)
                lines = "  (none selected)";
            else
                lines = "  - " + groups(:);
            end
        end

        function tf = wantsToolkit(app, toolkitName)
            selection = string(app.ToolkitDropDown.Value);
            switch string(toolkitName)
                case "matlab"
                    tf = selection == "MATLAB" || selection == "MATLAB and Simulink";
                case "simulink"
                    tf = selection == "Simulink" || selection == "MATLAB and Simulink";
                otherwise
                    tf = false;
            end
        end

        function paths = getOfflinePaths(app)
            packageFolder = string(strtrim(app.FolderEditField.Value));
            matlabSource = findToolkitSourceFolder(app, packageFolder, "matlab-agentic-toolkit-main");
            simulinkSource = findToolkitSourceFolder(app, packageFolder, "simulink-agentic-toolkit-main");

            paths = struct( ...
                PackageFolder=packageFolder, ...
                InstallerToolbox=fullfile(packageFolder, "agenticToolkitInstaller.mltbx"), ...
                MCPServer=fullfile(packageFolder, "matlab-mcp-server-windows-x64.exe"), ...
                MCPToolbox=fullfile(packageFolder, "MATLABMCPServerToolbox.mltbx"), ...
                MatlabSource=matlabSource, ...
                SimulinkSource=simulinkSource, ...
                MatlabInstalled=fullfile(getenv("USERPROFILE"), ".matlab", "agentic-toolkits", "matlab"), ...
                SimulinkInstalled=fullfile(getenv("USERPROFILE"), ".matlab", "agentic-toolkits", "simulink"), ...
                SkillsDir=fullfile(getenv("USERPROFILE"), ".agents", "skills"));
        end

        function validateInputs(app)
            try
                paths = getOfflinePaths(app);
                refreshSkillGroupsFromOfflineFolder(app, paths);
                validateOfflineFiles(app, paths);
                appendLog(app, "Validated offline package folder: " + paths.PackageFolder);
            catch ME
                appendLog(app, "Validation failed: " + ME.message);
                uialert(app.UIFigure, ME.message, "Validation Failed");
            end
        end

        function validateOfflineFiles(app, paths)
            if paths.PackageFolder == "" || ~isfolder(paths.PackageFolder)
                error("Offline package folder does not exist: %s", paths.PackageFolder);
            end

            requiredPaths = [
                paths.InstallerToolbox
                paths.MCPServer
                paths.MCPToolbox
                ];

            if wantsToolkit(app, "matlab")
                requiredPaths(end + 1) = paths.MatlabSource;
            end
            if wantsToolkit(app, "simulink")
                requiredPaths(end + 1) = paths.SimulinkSource;
            end

            existsMask = arrayfun(@(p) isfile(p) || isfolder(p), requiredPaths);
            missing = requiredPaths(~existsMask);

            if ~isempty(missing)
                error("Missing required file or folder:%s%s", newline, strjoin(missing, newline));
            end
        end

        function refreshSkillGroupsFromCurrentFolder(app)
            try
                paths = getOfflinePaths(app);
                if isfolder(paths.PackageFolder)
                    refreshSkillGroupsFromOfflineFolder(app, paths);
                end
            catch ME
                appendLog(app, "Skill group refresh failed: " + ME.message);
            end
        end

        function refreshSkillGroupsFromOfflineFolder(app, paths)
            matlabGroups = listSkillGroupFolders(app, paths.MatlabSource);
            simulinkGroups = listSkillGroupFolders(app, paths.SimulinkSource);

            setSkillGroupItems(app, "matlab", matlabGroups);
            setSkillGroupItems(app, "simulink", simulinkGroups);
            applyDefaultSkillGroups(app, false);
            updateSelectedGroupsDisplay(app);

            if isfolder(paths.MatlabSource)
                appendLog(app, "Loaded MATLAB skill groups from: " + fullfile(paths.MatlabSource, "skills-catalog"));
            end
            if isfolder(paths.SimulinkSource)
                appendLog(app, "Loaded Simulink skill groups from: " + fullfile(paths.SimulinkSource, "skills-catalog"));
            end
        end

        function sourceFolder = findToolkitSourceFolder(~, packageFolder, folderName)
            packageFolder = string(packageFolder);
            folderName = string(folderName);
            sourceFolder = fullfile(packageFolder, folderName);

            if packageFolder == "" || ~isfolder(packageFolder) || isfolder(sourceFolder)
                return
            end

            matches = dir(fullfile(packageFolder, "**", folderName));
            matches = matches([matches.isdir]);
            if isempty(matches)
                return
            end

            candidates = sort(string(fullfile({matches.folder}, {matches.name})));
            sourceFolder = candidates(1);
        end

        function groups = listSkillGroupFolders(~, toolkitSource)
            catalogFolder = fullfile(toolkitSource, "skills-catalog");
            if ~isfolder(catalogFolder)
                groups = strings(0, 1);
                return
            end

            folderInfo = dir(catalogFolder);
            folderInfo = folderInfo([folderInfo.isdir]);
            folderInfo = folderInfo(~ismember({folderInfo.name}, {'.', '..'}));
            groups = sort(string({folderInfo.name})).';
        end

        function setSkillGroupItems(app, toolkitName, groups)
            groups = string(groups(:));
            switch string(toolkitName)
                case "matlab"
                    app.MatlabSkillGroups = groups;
                    app.SelectedMatlabSkillGroups = app.SelectedMatlabSkillGroups(ismember(app.SelectedMatlabSkillGroups, groups));
                    app.MatlabListBox.Items = cellstr(groups);
                    setListBoxSelection(app, app.MatlabListBox, app.SelectedMatlabSkillGroups);
                case "simulink"
                    app.SimulinkSkillGroups = groups;
                    app.SelectedSimulinkSkillGroups = app.SelectedSimulinkSkillGroups(ismember(app.SelectedSimulinkSkillGroups, groups));
                    app.SimulinkListBox.Items = cellstr(groups);
                    setListBoxSelection(app, app.SimulinkListBox, app.SelectedSimulinkSkillGroups);
            end
        end

        function runInstall(app)
            setBusy(app, true);
            try
                paths = getOfflinePaths(app);
                refreshSkillGroupsFromOfflineFolder(app, paths);
                validateOfflineFiles(app, paths);

                appendLog(app, "Installing Agentic Toolkit installer toolbox.");
                appendLog(app, captureOutput(app, @() matlab.addons.toolbox.installToolbox(paths.InstallerToolbox)));

                toolkitSelection = selectedToolkitArgument(app);
                baseArgs = { ...
                    "install", ...
                    "Toolkit", toolkitSelection, ...
                    "Offline", true, ...
                    "MCPServerLocation", paths.MCPServer, ...
                    "MCPToolboxLocation", paths.MCPToolbox, ...
                    "Prompt", false};

                if wantsToolkit(app, "matlab") && wantsToolkit(app, "simulink")
                    args = [baseArgs, { ...
                        "MATLABAgenticToolkitLocation", paths.MatlabSource, ...
                        "SimulinkAgenticToolkitLocation", paths.SimulinkSource}];
                elseif wantsToolkit(app, "matlab")
                    args = [baseArgs, {"MATLABAgenticToolkitLocation", paths.MatlabSource}];
                else
                    args = [baseArgs, {"SimulinkAgenticToolkitLocation", paths.SimulinkSource}];
                end

                appendLog(app, "Running setupAgenticToolkit install for: " + strjoin(toolkitSelection, ", "));
                appendLog(app, captureOutput(app, @() setupAgenticToolkit(args{:})));
                appendLog(app, "Offline Agentic Toolkit installation completed.");
                setBusy(app, false);
            catch ME
                setBusy(app, false);
                appendLog(app, "Offline installation failed: " + ME.message);
                uialert(app.UIFigure, getReport(ME, "basic", "hyperlinks", "off"), "Installation Failed");
            end
        end

        function runInstallSkills(app)
            setBusy(app, true);
            try
                matlabGroups = app.SelectedMatlabSkillGroups;
                simulinkGroups = app.SelectedSimulinkSkillGroups;

                if wantsToolkit(app, "matlab") && isempty(matlabGroups)
                    appendLog(app, "No MATLAB skill groups selected.");
                end
                if wantsToolkit(app, "simulink") && isempty(simulinkGroups)
                    appendLog(app, "No Simulink skill groups selected.");
                end

                installSelectedSkills(app, "matlab", matlabGroups);
                installSelectedSkills(app, "simulink", simulinkGroups);
                appendLog(app, "Skill installation step completed.");
                setBusy(app, false);
            catch ME
                setBusy(app, false);
                appendLog(app, "Skill installation failed: " + ME.message);
                uialert(app.UIFigure, getReport(ME, "basic", "hyperlinks", "off"), "Skill Installation Failed");
            end
        end

        function runStatusAndInitialize(app)
            setBusy(app, true);
            try
                runStatus(app);
                runInitialize(app);
                appendLog(app, "Status and initialize step completed.");
                setBusy(app, false);
            catch ME
                setBusy(app, false);
                appendLog(app, "Status / Initialize failed: " + ME.message);
                uialert(app.UIFigure, getReport(ME, "basic", "hyperlinks", "off"), "Status / Initialize Failed");
            end
        end

        function toolkitSelection = selectedToolkitArgument(app)
            if wantsToolkit(app, "matlab") && wantsToolkit(app, "simulink")
                toolkitSelection = ["matlab", "simulink"];
            elseif wantsToolkit(app, "matlab")
                toolkitSelection = "matlab";
            else
                toolkitSelection = "simulink";
            end
        end

        function installSelectedSkills(app, toolkitName, groups)
            toolkitName = string(toolkitName);
            groups = unique(string(groups(:)), "stable");

            if ~wantsToolkit(app, toolkitName) || isempty(groups)
                return
            end

            paths = getOfflinePaths(app);
            if toolkitName == "matlab"
                toolkitRoot = paths.MatlabInstalled;
            else
                toolkitRoot = paths.SimulinkInstalled;
            end

            if ~isfolder(toolkitRoot)
                appendLog(app, "Skipping " + toolkitName + " skills; installed toolkit folder not found: " + toolkitRoot);
                return
            end

            if ~isfolder(paths.SkillsDir)
                mkdir(paths.SkillsDir);
                appendLog(app, "Created skills folder: " + paths.SkillsDir);
            end

            appendLog(app, "Installing " + toolkitName + " skill groups: " + strjoin(groups, ", "));
            for g = 1:numel(groups)
                installSkillGroup(app, toolkitRoot, paths.SkillsDir, groups(g));
            end
        end

        function installSkillGroup(app, toolkitRoot, skillsDir, groupName)
            groupDir = fullfile(toolkitRoot, "skills-catalog", groupName);
            if ~isfolder(groupDir)
                appendLog(app, "Skill group folder not found: " + groupDir);
                return
            end

            skills = dir(groupDir);
            skills = skills([skills.isdir]);
            skills = skills(~ismember({skills.name}, {'.', '..'}));

            for k = 1:numel(skills)
                target = fullfile(skills(k).folder, skills(k).name);
                link = fullfile(skillsDir, skills(k).name);
                createSkillLink(app, link, target);
            end
        end

        function createSkillLink(app, link, target)
            link = string(link);
            target = string(target);

            if contains(link, '"') || contains(target, '"')
                error("Skill link paths cannot contain double quotes.");
            end

            if isfolder(link) || isfile(link)
                appendLog(app, "Skipping existing skill path: " + link);
                return
            end

            if exist("createSymbolicLink", "file") == 2
                createSymbolicLink(link, target);
                appendLog(app, "Linked skill: " + link + " -> " + target);
                return
            end

            command = sprintf('cmd /c mklink /J "%s" "%s"', char(link), char(target));
            [status, output] = system(command);
            if status ~= 0
                error("Failed to create skill link: %s%s%s", link, newline, output);
            end

            appendLog(app, "Linked skill junction: " + link + " -> " + target);
        end

        function runStatus(app)
            try
                appendLog(app, "Running setupAgenticToolkit status.");
                appendLog(app, captureOutput(app, @() setupAgenticToolkit("status")));
            catch ME
                appendLog(app, "Status check failed: " + ME.message);
            end
        end

        function runInitialize(app)
            try
                paths = getOfflinePaths(app);

                if wantsToolkit(app, "matlab")
                    addToolkitPath(app, paths.MatlabInstalled);
                end
                if wantsToolkit(app, "simulink")
                    addToolkitPath(app, paths.SimulinkInstalled);
                end

                ranInitializer = false;
                if wantsToolkit(app, "matlab")
                    ranInitializer = runInitializerIfAvailable(app, "stak_initialize") || ranInitializer;
                end
                if wantsToolkit(app, "simulink")
                    ranInitializer = runInitializerIfAvailable(app, "satk_initialize") || ranInitializer;
                end

                if ~ranInitializer
                    appendLog(app, "No initializer found on the MATLAB path.");
                end
            catch ME
                appendLog(app, "Initialize failed: " + ME.message);
            end
        end

        function addToolkitPath(app, toolkitRoot)
            toolkitRoot = string(toolkitRoot);
            if isfolder(toolkitRoot)
                addpath(toolkitRoot);
                appendLog(app, "addpath: " + toolkitRoot);
            else
                appendLog(app, "Toolkit folder not found for addpath: " + toolkitRoot);
            end
        end

        function didRun = runInitializerIfAvailable(app, functionName)
            didRun = false;
            existCode = exist(functionName, "file");
            if ~ismember(existCode, [2, 3, 5, 6])
                appendLog(app, "Initializer not found: " + functionName);
                return
            end

            appendLog(app, "Running " + functionName + ".");
            initializer = str2func(functionName);
            appendLog(app, captureOutput(app, initializer));
            didRun = true;
        end

        function output = captureOutput(~, functionHandle) %#ok<INUSD>
            output = evalc("functionHandle()");
        end

        function values = selectedGroups(~, listBox)
            rawValue = listBox.Value;
            if isempty(rawValue)
                values = strings(0, 1);
            else
                values = string(rawValue);
            end
        end

        function appendLog(app, message)
            message = string(message);
            lines = splitlines(message);
            lines = lines(lines ~= "");

            if isempty(lines)
                return
            end

            currentValue = string(app.LogTextArea.Value);
            app.LogTextArea.Value = [currentValue(:); lines(:)];
            drawnow limitrate
        end

        function setBusy(app, isBusy)
            commonState = onOff(app, ~isBusy);
            app.ValidateButton.Enable = commonState;
            app.InstallButton.Enable = commonState;
            app.InstallSkillsButton.Enable = commonState;
            app.CheckButton.Enable = commonState;
            app.ResetSkillsButton.Enable = commonState;
            app.BrowseButton.Enable = commonState;
            app.FolderEditField.Enable = commonState;
            app.ToolkitDropDown.Enable = commonState;
            app.MatlabListBox.Enable = onOff(app, ~isBusy && wantsToolkit(app, "matlab"));
            app.SimulinkListBox.Enable = onOff(app, ~isBusy && wantsToolkit(app, "simulink"));
            drawnow
        end

        function state = onOff(~, tf)
            if tf
                state = "on";
            else
                state = "off";
            end
        end
    end
end






