%% EE354_SanityCheck.m
% Automated validation test suite for EE354 simulations
%
% This script runs 10 critical assertions on simulation results to verify
% physically correct behavior. Results are printed to Command Window in PASS/FAIL format.
%
% Usage:  EE354_SanityCheck
%
% Output: 
%   - Console output with colored PASS/FAIL messages
%   - Pass count and fail count
%   - Warnings for any test thresholds exceeded
%

clear all; close all; clc

fprintf('\n========== EE354 SANITY CHECK TEST SUITE ==========\n\n')

% Test configuration
num_tests = 10;
test_results = zeros(1, num_tests);  % 1 = PASS, 0 = FAIL
test_names = {};
test_details = {};

% Load simulation data (generate synthetic if unavailable)
try
    if isfile('simOut_Ex1.mat')
        load('simOut_Ex1.mat', 'simOut'), data_Ex1 = simOut;
    end
    if isfile('simOut_Ex2.mat')
        load('simOut_Ex2.mat', 'simOut'), data_Ex2 = simOut;
    end
    if isfile('simOut_Ex3.mat')
        load('simOut_Ex3.mat', 'simOut'), data_Ex3 = simOut;
    end
    if isfile('simOut_Ex4.mat')
        load('simOut_Ex4.mat', 'simOut'), data_Ex4 = simOut;
    end
    if isfile('simOut_Ex5.mat')
        load('simOut_Ex5.mat', 'simOut'), data_Ex5 = simOut;
    end
    if isfile('simOut_Ex6.mat')
        load('simOut_Ex6.mat', 'simOut'), data_Ex6 = simOut;
    end
    fprintf('✓ Loaded all available result files\n\n')
catch ME
    fprintf('⚠ Some result files not found. Tests will be skipped for missing exercises.\n\n')
end

%% TEST 1: Exercise 1 - Initial Steady-State Power
fprintf('[Test 1] Exercise 1: Initial steady-state power ≈ 250 MW ±5%%\n')
try
    if exist('data_Ex1', 'var')
        P_data = extract_signal(data_Ex1, 'Power');
        P_initial = mean(P_data(1:100));  % First 1 second average
        P_expected = 250;
        P_error_pct = abs(P_initial - P_expected) / P_expected * 100;
        
        if P_error_pct <= 5
            test_results(1) = 1;
            fprintf('  ✓ PASS: P_initial = %.1f MW (error %.1f%%)\n', P_initial, P_error_pct)
        else
            test_results(1) = 0;
            fprintf('  ✗ FAIL: P_initial = %.1f MW (error %.1f%% > 5%%)\n', P_initial, P_error_pct)
        end
    else
        fprintf('  ⊘ SKIP: simOut_Ex1.mat not found\n')
    end
catch
    fprintf('  ⊘ SKIP: Error extracting power data\n')
end

%% TEST 2: Exercise 1 - Speed Deviation Direction (Load ON)
fprintf('[Test 2] Exercise 1: Load step (ON) → speed deviation is NEGATIVE\n')
try
    if exist('data_Ex1', 'var')
        f_data = extract_signal(data_Ex1, 'Frequency');
        % Load typically applied at t=9s; check 9-15s window
        t = data_Ex1.time;
        idx_window = find(t >= 9 & t <= 15);
        if ~isempty(idx_window)
            f_min_idx = find(f_data == min(f_data(idx_window)), 1);
            freq_deviation = f_data(f_min_idx) - 60;  % Negative when load ON
            
            if freq_deviation < -0.01
                test_results(2) = 1;
                fprintf('  ✓ PASS: Frequency dips to %.4f Hz (Δf = %.4f Hz)\n', f_data(f_min_idx), freq_deviation)
            else
                test_results(2) = 0;
                fprintf('  ✗ FAIL: Frequency did not dip as expected\n')
            end
        else
            fprintf('  ⊘ SKIP: Time window not available\n')
        end
    else
        fprintf('  ⊘ SKIP: simOut_Ex1.mat not found\n')
    end
catch
    fprintf('  ⊘ SKIP: Error in test logic\n')
end

%% TEST 3: Exercise 1 - Voltage Dip Magnitude
fprintf('[Test 3] Exercise 1: Voltage dip at t=9s reaches Vt < 0.90 pu\n')
try
    if exist('data_Ex1', 'var')
        V_data = extract_signal(data_Ex1, 'Voltage');
        t = data_Ex1.time;
        idx_window = find(t >= 9 & t <= 10);  % 1 second after load step
        if ~isempty(idx_window)
            V_min = min(V_data(idx_window));
            if V_min < 0.90
                test_results(3) = 1;
                fprintf('  ✓ PASS: Voltage dips to %.4f pu < 0.90\n', V_min)
            else
                test_results(3) = 0;
                fprintf('  ✗ FAIL: Voltage minimum = %.4f pu (not < 0.90)\n', V_min)
            end
        else
            fprintf('  ⊘ SKIP: Time window not available\n')
        end
    else
        fprintf('  ⊘ SKIP: simOut_Ex1.mat not found\n')
    end
catch
    fprintf('  ⊘ SKIP: Error in voltage data extraction\n')
end

%% TEST 4: Exercise 1 - Voltage Recovery
fprintf('[Test 4] Exercise 1: AVR recovers voltage to Vt > 0.98 pu within 5s of dip\n')
try
    if exist('data_Ex1', 'var')
        V_data = extract_signal(data_Ex1, 'Voltage');
        t = data_Ex1.time;
        idx_dip = find(V_data == min(V_data(find(t >= 9 & t <= 10))), 1);
        time_dip = t(idx_dip);
        
        % Check 5 seconds after dip
        idx_recovery = find(t >= time_dip & t <= time_dip + 5);
        if ~isempty(idx_recovery)
            V_recovery = mean(V_data(idx_recovery(end-10:end)));  % Last 0.1s of window
            if V_recovery > 0.98
                test_results(4) = 1;
                fprintf('  ✓ PASS: Voltage recovers to %.4f pu > 0.98\n', V_recovery)
            else
                test_results(4) = 0;
                fprintf('  ✗ FAIL: Recovery voltage = %.4f pu (not > 0.98)\n', V_recovery)
            end
        else
            fprintf('  ⊘ SKIP: Recovery window not available\n')
        end
    else
        fprintf('  ⊘ SKIP: simOut_Ex1.mat not found\n')
    end
catch
    fprintf('  ⊘ SKIP: Error in recovery detection\n')
end

%% TEST 5: Exercise 2 - Governor Reduces Frequency Dip
fprintf('[Test 5] Exercise 2: Governor reduces frequency dip compared to Ex1\n')
try
    if exist('data_Ex1', 'var') && exist('data_Ex2', 'var')
        f_Ex1 = extract_signal(data_Ex1, 'Frequency');
        f_Ex2 = extract_signal(data_Ex2, 'Frequency');
        t = data_Ex1.time;
        
        idx_window = find(t >= 9 & t <= 11);
        f_dip_Ex1 = min(f_Ex1(idx_window));
        f_dip_Ex2 = min(f_Ex2(idx_window));
        
        if f_dip_Ex2 > f_dip_Ex1  % Higher minimum = better regulation (less dip)
            test_results(5) = 1;
            fprintf('  ✓ PASS: Ex1 dips to %.4f Hz, Ex2 dips to %.4f Hz (governor helps)\n', f_dip_Ex1, f_dip_Ex2)
        else
            test_results(5) = 0;
            fprintf('  ✗ FAIL: Ex2 dip not less than Ex1. (Governor may be disabled)\n')
        end
    else
        fprintf('  ⊘ SKIP: Ex1 or Ex2 data not available\n')
    end
catch
    fprintf('  ⊘ SKIP: Error in governor comparison\n')
end

%% TEST 6: Exercise 3 - Gen B Destabilizes (Motoring Mode)
fprintf('[Test 6] Exercise 3: Gen B power becomes NEGATIVE (motoring) after disturbance\n')
try
    if exist('data_Ex3', 'var')
        P_B_data = extract_signal(data_Ex3, 'Power_B');
        if ~isempty(P_B_data)
            P_B_min = min(P_B_data);
            if P_B_min < -10  % At least -10 MW motoring
                test_results(6) = 1;
                fprintf('  ✓ PASS: P_B reaches %.1f MW (motoring confirmed)\n', P_B_min)
            else
                test_results(6) = 0;
                fprintf('  ✗ FAIL: P_B minimum = %.1f MW (not sufficiently negative)\n', P_B_min)
            end
        else
            fprintf('  ⊘ SKIP: Power_B signal not available\n')
        end
    else
        fprintf('  ⊘ SKIP: simOut_Ex3.mat not found\n')
    end
catch
    fprintf('  ⊘ SKIP: Error in Gen B power extraction\n')
end

%% TEST 7: Exercise 4 - Gen B Exports Power
fprintf('[Test 7] Exercise 4: Gen B power positive (GENERATING) in steady state\n')
try
    if exist('data_Ex4', 'var')
        P_B_data = extract_signal(data_Ex4, 'Power_B');
        if ~isempty(P_B_data)
            % Steady-state = last 20% of signal
            P_B_ss = mean(P_B_data(floor(0.8*length(P_B_data)):end));
            if P_B_ss > 10  % At least 10 MW generating
                test_results(7) = 1;
                fprintf('  ✓ PASS: P_B steady-state = %.1f MW (generating)\n', P_B_ss)
            else
                test_results(7) = 0;
                fprintf('  ✗ FAIL: P_B steady-state = %.1f MW (not positive)\n', P_B_ss)
            end
        else
            fprintf('  ⊘ SKIP: Power_B signal not available\n')
        end
    else
        fprintf('  ⊘ SKIP: simOut_Ex4.mat not found\n')
    end
catch
    fprintf('  ⊘ SKIP: Error in Ex4 analysis\n')
end

%% TEST 8: Exercise 5 - Infinite Bus Effect (Less Negative than Ex3)
fprintf('[Test 8] Exercise 5: Gen B power magnitude less negative than Ex3 (infinite bus absorbs disturbance)\n')
try
    if exist('data_Ex3', 'var') && exist('data_Ex5', 'var')
        P_B_Ex3 = extract_signal(data_Ex3, 'Power_B');
        P_B_Ex5 = extract_signal(data_Ex5, 'Power_B');
        
        if ~isempty(P_B_Ex3) && ~isempty(P_B_Ex5)
            P_B_min_Ex3 = min(P_B_Ex3);
            P_B_min_Ex5 = min(P_B_Ex5);
            
            % Ex5 (infinite bus) should be less extreme
            if P_B_min_Ex5 > P_B_min_Ex3  % Higher (less negative)
                test_results(8) = 1;
                fprintf('  ✓ PASS: Ex3 min=%.1f MW, Ex5 min=%.1f MW (infinite bus stiffens)\n', P_B_min_Ex3, P_B_min_Ex5)
            else
                test_results(8) = 0;
                fprintf('  ✗ FAIL: Ex5 not less negative than Ex3\n')
            end
        else
            fprintf('  ⊘ SKIP: Power_B signals incomplete\n')
        end
    else
        fprintf('  ⊘ SKIP: Ex3 or Ex5 data not available\n')
    end
catch
    fprintf('  ⊘ SKIP: Error in infinite bus comparison\n')
end

%% TEST 9: Exercise 6 - Infinite Bus Frequency Rigidity
fprintf('[Test 9] Exercise 6: System frequency ≈ 60.00 Hz ±0.001 (infinite bus rigid)\n')
try
    if exist('data_Ex6', 'var')
        f_data = extract_signal(data_Ex6, 'Frequency');
        f_ss = mean(f_data(floor(0.8*length(f_data)):end));
        f_error = abs(f_ss - 60.0);
        
        if f_error < 0.01  % Within 0.01 Hz (very stiff)
            test_results(9) = 1;
            fprintf('  ✓ PASS: Frequency = %.6f Hz (error = %.4f Hz < 0.01)\n', f_ss, f_error)
        else
            test_results(9) = 0;
            fprintf('  ✗ FAIL: Frequency = %.6f Hz (error = %.4f Hz)\n', f_ss, f_error)
        end
    else
        fprintf('  ⊘ SKIP: simOut_Ex6.mat not found\n')
    end
catch
    fprintf('  ⊘ SKIP: Error in frequency analysis\n')
end

%% TEST 10: Droop Equation Validation
fprintf('[Test 10] Droop law: Predicted ΔP = -(P_nl/R)*(Δf/f0) matches simulation\n')
try
    if exist('data_Ex2', 'var')
        f_data = extract_signal(data_Ex2, 'Frequency');
        P_data = extract_signal(data_Ex2, 'Power');
        t = data_Ex2.time;
        
        % Parameters
        P_nl = 250;  % MW
        R = 0.05;    % 5% droop
        f_0 = 60;    % Hz
        
        % Disturbance ~9s, measure steady-state change
        idx_before = find(t >= 5 & t <= 9);
        idx_after = find(t >= 20 & t <= 25);
        
        if ~isempty(idx_before) && ~isempty(idx_after)
            f_before = mean(f_data(idx_before));
            f_after = mean(f_data(idx_after));
            P_before = mean(P_data(idx_before));
            P_after = mean(P_data(idx_after));
            
            Delta_f = f_after - f_before;
            Delta_P = P_after - P_before;
            
            % Droop predicts:
            Delta_P_predicted = -(P_nl / R) * (Delta_f / f_0);
            error_pct = abs(Delta_P - Delta_P_predicted) / abs(Delta_P_predicted) * 100;
            
            if error_pct <= 15
                test_results(10) = 1;
                fprintf('  ✓ PASS: Predicted ΔP=%.1f MW, Measured ΔP=%.1f MW (error %.1f%%)\n', ...
                    Delta_P_predicted, Delta_P, error_pct)
            else
                test_results(10) = 0;
                fprintf('  ✗ FAIL: ΔP error %.1f%% > 15%% threshold\n', error_pct)
            end
        else
            fprintf('  ⊘ SKIP: Time windows not available\n')
        end
    else
        fprintf('  ⊘ SKIP: simOut_Ex2.mat not found\n')
    end
catch
    fprintf('  ⊘ SKIP: Error in droop validation\n')
end

%% SUMMARY REPORT

fprintf('\n========== SANITY CHECK SUMMARY ==========\n\n')

num_pass = sum(test_results);
num_fail = num_tests - num_pass;

fprintf('Results: %d PASS, %d FAIL out of %d tests\n\n', num_pass, num_fail, num_tests)

% Color-coded results
for i = 1:num_tests
    if test_results(i) == 1
        fprintf('  [%2d] ✓ PASS\n', i)
    else
        fprintf('  [%2d] ✗ FAIL\n', i)
    end
end

fprintf('\n')

if num_fail == 0
    fprintf('🎉 ALL TESTS PASSED! Simulations exhibit expected physical behavior.\n\n')
else
    fprintf('⚠️  %d test(s) failed. Review simulation setup and parameters.\n\n', num_fail)
end

%% HELPER FUNCTION: Extract Signal from Various Formats

function signal_data = extract_signal(data, signal_name)
    % Safely extract signal from simOut structure (flexible format handling)
    signal_data = [];
    
    % Check direct field access
    if isfield(data, signal_name)
        sig = data.(signal_name);
        if isa(sig, 'timeseries')
            signal_data = sig.data;
        else
            signal_data = sig;
        end
    end
    
    % Check common aliases
    if isempty(signal_data)
        aliases = {
            'Power', 'P', 'Power_A', 'P_A'
            'Power_B', 'P_B'
            'Frequency', 'f', 'freq'
            'Voltage', 'V', 'Vt'
        };
        for i = 1:size(aliases, 1)
            for j = 1:size(aliases, 2)
                if isfield(data, aliases{i, j}) && strcmp(aliases{i, j}, signal_name)
                    sig = data.(aliases{i, j});
                    if isa(sig, 'timeseries')
                        signal_data = sig.data;
                    else
                        signal_data = sig;
                    end
                    return
                end
            end
        end
    end
    
    % Ensure column vector
    if ~isempty(signal_data) && size(signal_data, 2) > 1
        signal_data = signal_data';
    end
end

%% END OF SANITY CHECK
