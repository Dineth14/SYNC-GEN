%% EE354 Assignment: Exercise 2 - Task 3 (Gen B at Lower Frequency)
% Filename: EE354_Ex2_Task3.slx

% 1. Define the model name
modelName = 'SMControl';

% 2. Run the simulation
% This creates a 'simlog_EE354_Ex2_Task3' object in your workspace
sim(modelName);

% 3. Extract Data from Simulation Log
% Using the path for 'Round Rotor (standard)' blocks for Gen A and Gen B
logObj = eval(['simlog_', modelName]);

% Extract Time vector
t = logObj.Synchronous_Machine_Round_Rotor_standard_Gen_A.pu_output.series.time;

% Extract Generator A (Reference Generator) Data
dataA_task3 = logObj.Governor_and_Prime_Mover_Gen_A.Rotor_Velocity_Measurement.pu_output.series.values;
f_A_Task3 = dataA_task3*60 ;


% Extract Generator B (Incoming Generator - Lower Freq) Data
dataB_task3 = logObj.Governor_and_Prime_Mover_Gen_B.Rotor_Velocity_Measurement.pu_output.series.values;
f_B_Task3 = dataB_task3*60 ;


% 4. Generate Combined Plot for Task 3b
figure('Name', 'Task 3: Parallel Operation (Lower Frequency)', 'Color', 'w');

% Frequency Variation (Hz)
plot(t, f_A_Task3, 'b', t, f_B_Task3, 'r', 'LineWidth', 1.5);
title('Frequency Variation'); xlabel('Time (s)'); ylabel('f (Hz)');
legend('Gen A', 'Gen B'); grid on;

% Frequency Variation (Hz)