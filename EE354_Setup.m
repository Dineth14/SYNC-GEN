%% =========================================================================
%  EE354_Setup.m
%  Run this FIRST, before anything else.
%  It opens the Simulink example and saves your working copies safely.
%
%  USAGE: Type  EE354_Setup  in the MATLAB Command Window and press Enter.
%
%  WHAT IT DOES:
%    1. Opens the built-in Simscape example
%    2. Waits for it to fully load
%    3. Saves three working copies (one per exercise)
%    4. Closes the original (leaves your copies open)
%    5. Confirms everything is ready
%
%  MATLAB R2025b | Simscape Electrical required
%% =========================================================================

clc;
fprintf('===========================================\n');
fprintf('  EE354 Setup — Saving Working Copies\n');
fprintf('===========================================\n\n');

%% Step 1: Check Simscape Electrical is installed
if ~license('test','simscape')
    error('Simscape is not installed or licensed. Please install it via the Add-On Explorer.');
end
fprintf('[1/5] Simscape license confirmed.\n');

%% Step 2: Open the example
fprintf('[2/5] Opening Simscape example (this may take 10-20 seconds)...\n');
try
    openExample('simscapeelectrical/SMControlExample');
    pause(3);  % Give Simulink time to fully load the model
catch ME
    error('Could not open example: %s\nMake sure Simscape Electrical is installed.', ME.message);
end

%% Step 3: Find the model handle
% bdroot returns the name of the currently open model
% We wait up to 20 seconds for it to appear
model_name = '';
for attempt = 1:20
    models = find_system('SearchDepth',0,'Type','block_diagram');
    if ~isempty(models)
        model_name = models{1};
        break;
    end
    pause(1);
end

if isempty(model_name)
    error('Model did not open after 20 seconds. Please try opening it manually:\n  openExample(''simscapeelectrical/SMControlExample'')');
end
fprintf('[3/5] Model loaded: %s\n', model_name);

%% Step 4: Save three working copies
output_files = {
    'EE354_Exercise1_Base.slx',
    'EE354_Exercise2_Parallel.slx',
    'EE354_Exercise3_InfiniteBus.slx'
};

for i = 1:length(output_files)
    fname = output_files{i};
    if exist(fname, 'file')
        fprintf('       Skipping %s (already exists — delete it to re-create)\n', fname);
    else
        % Save a copy using save_system with the 'NewName' option
        try
            save_system(model_name, fname);
            fprintf('[4/%d] Saved: %s\n', 3+i, fname);
        catch ME
            % Fallback: use copyfile on the source .slx
            src = which([model_name '.slx']);
            if isempty(src)
                % Try finding it via the example path
                src = fullfile(matlabroot,'toolbox','simelectrical','simelectrical',...
                               'examples','SMControlExample.slx');
            end
            if exist(src,'file')
                copyfile(src, fname);
                fprintf('[4/%d] Copied: %s\n', 3+i, fname);
            else
                warning('Could not save %s. You may need to save it manually via File > Save As.', fname);
            end
        end
    end
end

%% Step 5: Close the original example, open your copies
try
    close_system(model_name, 0);  % 0 = don't save changes to original
catch; end

fprintf('[5/5] Setup complete!\n\n');
fprintf('Files ready in: %s\n\n', pwd);
for i = 1:length(output_files)
    if exist(output_files{i},'file')
        fprintf('  ✓  %s\n', output_files{i});
    else
        fprintf('  ✗  %s  ← NOT FOUND (see warnings above)\n', output_files{i});
    end
end

fprintf('\nNEXT STEPS:\n');
fprintf('  1. Run EE354_AutoPlot.m  (RUN_SIMULATIONS=false) to generate all plots immediately\n');
fprintf('  2. Open EE354_Exercise1_Base.slx to verify the model\n');
fprintf('  3. Follow MATLAB_STEP_BY_STEP_GUIDE.md to add measurement blocks\n');
fprintf('  4. When models are ready, set RUN_SIMULATIONS=true in EE354_AutoPlot.m\n\n');
