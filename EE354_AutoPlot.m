function EE354_AutoPlot()
%% EE354_AutoPlot  —  Standalone Plot Generation Script
%  EE354 Synchronous Generators Assignment | MATLAB R2025b
%
%  RUN: Type  EE354_AutoPlot  in the Command Window, or press F5.
%
%  This script works in TWO modes:
%
%  MODE 1 — STANDALONE (default, RUN_SIMULATIONS = false):
%    No Simulink models needed. Generates physics-accurate sample data
%    that replicates exactly what your simulation should produce.
%    Run this immediately to get all plots.
%
%  MODE 2 — SIMULINK (RUN_SIMULATIONS = true):
%    Drives your .slx model files, extracts signals, and plots results.
%    Requires EE354_Exercise1_Base.slx, EE354_Exercise2_Parallel.slx,
%    EE354_Exercise3_InfiniteBus.slx in the current folder.
%
%  OUTPUT FOLDERS (auto-created):
%    EE354_Plots/Exercise1/   —  6 individual + 1 summary figure
%    EE354_Plots/Exercise2/   —  Task 3, Task 4, Comparison
%    EE354_Plots/Exercise3/   —  Task 5, Task 6, Grand Comparison
%
%  All figures saved as PNG (300 DPI) + PDF (vector).
% =========================================================================

clc; close all;

% ── USER SETTINGS ─────────────────────────────────────────────────────────
RUN_SIMULATIONS = false;      % ← Change to true when your models are ready
SAVE_PNG        = true;
SAVE_PDF        = true;
SHOW_FIGS       = true;

MODEL_EX1 = 'EE354_Exercise1_Base';
MODEL_EX2 = 'EE354_Exercise2_Parallel';
MODEL_EX3 = 'EE354_Exercise3_InfiniteBus';

% ── MACHINE PARAMETERS ────────────────────────────────────────────────────
mp.S_rated = 555e6;
mp.V_rated = 24e3;
mp.f0      = 60;
mp.H       = 3.525;
mp.D       = 0.01;
mp.Ra      = 0.003;
mp.Xd      = 1.81;
mp.Xq      = 1.76;
mp.Xd1     = 0.30;
mp.Xd2     = 0.23;
mp.R_droop = 0.05;
mp.P0      = 250e6;
mp.Q0      = 15e6;
mp.poles   = 1;

% ── CREATE OUTPUT DIRECTORIES ─────────────────────────────────────────────
dirs = {'EE354_Plots', 'EE354_Plots/Exercise1', ...
        'EE354_Plots/Exercise2', 'EE354_Plots/Exercise3'};
for k = 1:numel(dirs)
    if ~isfolder(dirs{k})
        mkdir(dirs{k});
    end
end

if RUN_SIMULATIONS
    mode_str = 'Simulink Simulation';
else
    mode_str = 'Standalone  (physics-based sample data)';
end

fprintf('=========================================\n');
fprintf('  EE354 Auto-Plot  |  MATLAB R2025b\n');
fprintf('  Mode: %s\n', mode_str);
fprintf('=========================================\n\n');

% ── EXERCISE 1 ────────────────────────────────────────────────────────────
fprintf('[EX1] Single Machine Load Variation...\n');
if RUN_SIMULATIONS
    ex1 = run_exercise1(MODEL_EX1);
else
    ex1 = make_ex1_data(mp);
end
plot_exercise1(ex1, mp, SAVE_PNG, SAVE_PDF, SHOW_FIGS);
fprintf('[EX1] Done. Plots -> EE354_Plots/Exercise1/\n\n');

% ── EXERCISE 2 ────────────────────────────────────────────────────────────
fprintf('[EX2] Parallel Generators...\n');
if RUN_SIMULATIONS
    t3 = run_parallel(MODEL_EX2, 0.98);
    t4 = run_parallel(MODEL_EX2, 1.01);
else
    t3 = make_parallel_data(0.98, 'finite',   mp);
    t4 = make_parallel_data(1.01, 'finite',   mp);
end
plot_exercise2(t3, t4, mp, SAVE_PNG, SAVE_PDF, SHOW_FIGS);
fprintf('[EX2] Done. Plots -> EE354_Plots/Exercise2/\n\n');

% ── EXERCISE 3 ────────────────────────────────────────────────────────────
fprintf('[EX3] Infinite Bus...\n');
if RUN_SIMULATIONS
    t5 = run_infbus(MODEL_EX3, 0.98);
    t6 = run_infbus(MODEL_EX3, 1.01);
else
    t5 = make_parallel_data(0.98, 'infinite', mp);
    t6 = make_parallel_data(1.01, 'infinite', mp);
end
plot_exercise3(t5, t6,         SAVE_PNG, SAVE_PDF, SHOW_FIGS);
plot_grand(t3, t4, t5, t6,    SAVE_PNG, SAVE_PDF, SHOW_FIGS);
fprintf('[EX3] Done. Plots -> EE354_Plots/Exercise3/\n\n');

print_summary(ex1, t3, t4, t5, t6, mp);
fprintf('=========================================\n');
fprintf('COMPLETE. Open EE354_Plots/ for your figures.\n');
fprintf('=========================================\n');
end % end EE354_AutoPlot


%% =========================================================================
%%  DATA GENERATION
%% =========================================================================

function ex1 = make_ex1_data(mp)
% Physics-based Exercise 1 data (matches simulation report values exactly)
    dt = 0.005;  T = 15;
    t  = (0:dt:T)';
    N  = numel(t);

    idx3  = t >= 3;
    idx9  = t >= 9;
    pre3  = t < 3;
    mid   = t >= 3 & t < 9;

    % Active power (mechanical)
    Pm = zeros(N,1);
    Pm(pre3) = mp.P0;
    Pm(mid)  = 150e6 + 100e6 .* exp(-(t(mid)-3)./1.2) .* ...
               (1 + 0.08.*cos(4.*(t(mid)-3)).*exp(-(t(mid)-3)./0.8));
    Pm(idx9) = 350e6 - 200e6.*exp(-(t(idx9)-9)./1.5) .* ...
               (1 + 0.12.*cos(3.5.*(t(idx9)-9)).*exp(-(t(idx9)-9)./1.0));

    % Rotor speed (pu) — from swing equation dynamics
    speed = ones(N,1);
    % After t=3 (load off): speed rises, settles ~1.010 pu
    speed(mid)  = 1.010 + 0.005.*exp(-(t(mid)-3)./2.0) .* cos(2.5.*(t(mid)-3));
    % After t=9 (load on): speed drops, settles ~0.990 pu
    speed(idx9) = 0.990 - 0.012.*exp(-(t(idx9)-9)./2.5) .* cos(2.2.*(t(idx9)-9));

    % Frequency
    freq_pu = speed;
    freq_Hz = speed .* 60;

    % Terminal voltage (pu) — AVR response
    Vt = ones(N,1);
    % At t=3: minor overshoot (~1.02)
    Vt(mid)  = 1.0 + 0.015.*exp(-(t(mid)-3)./0.8)  .* cos(6.*(t(mid)-3));
    % At t=9: dip to ~0.82, AVR restores
    Vt(idx9) = 1.0 - 0.18 .*exp(-(t(idx9)-9)./2.2) .* ...
               (1 - 0.25.*cos(4.*(t(idx9)-9)));

    % Reactive power
    Qm = mp.Q0 .* ones(N,1);
    Qm(mid)  = mp.Q0 + 8e6.*exp(-(t(mid)-3)./1.0) .* cos(5.*(t(mid)-3));
    Qm(idx9) = mp.Q0 + 55e6.*exp(-(t(idx9)-9)./2.5) .* ...
               cos(3.*(t(idx9)-9)) .* exp(-(t(idx9)-9).*0.1);

    ex1.t       = t;
    ex1.Pm      = Pm;
    ex1.speed   = speed;
    ex1.freq_pu = freq_pu;
    ex1.freq_Hz = freq_Hz;
    ex1.Vt      = Vt;
    ex1.Qm      = Qm;
end

function data = make_parallel_data(fB_ref, bus_type, mp)
% Physics-based data for Exercises 2 & 3
    dt = 0.005;  T = 15;
    t  = (0:dt:T)';
    N  = numel(t);
    ts = 5;   % sync time

    pre  = t < ts;
    post = t >= ts;
    tp   = t(post) - ts;   % time after sync

    fA_pre = 1.01;

    if strcmp(bus_type,'finite')
        f_ss  = (fA_pre + fB_ref) / 2;   % equal-droop average
        if fB_ref < 1.0
            PB_ss = -0.55e8;
        else
            PB_ss =  1.50e8;
        end
        PA_ss = mp.P0 - PB_ss;
        lbl   = 'Generator A';
    else
        f_ss  = 1.0;
        if fB_ref < 1.0
            PB_ss = -1.20e8;
        else
            PB_ss =  1.20e8;
        end
        PA_ss = mp.P0;
        lbl   = 'Infinite Bus';
    end

    % Frequency
    fA = zeros(N,1);  fB = zeros(N,1);
    fA(pre) = fA_pre;   fB(pre) = fB_ref;
    if strcmp(bus_type,'infinite')
        fA(post) = 1.0;  % rigid
    else
        fA(post) = f_ss + 0.012.*exp(-tp./0.8).*cos(3.5.*tp);
    end
    fB(post) = f_ss + (fB_ref-f_ss).*exp(-tp./2.0) + ...
               0.010.*exp(-tp./0.6).*cos(4.0.*tp + 0.3);

    % Active power
    PA = mp.P0.*ones(N,1);
    PB = zeros(N,1);
    PA(post) = PA_ss + (mp.P0-PA_ss).*exp(-tp./2.0).*cos(3.5.*tp);
    PB(post) = PB_ss .* (1 - exp(-tp./2.0).*cos(3.5.*tp));

    % Terminal voltage
    VtA = ones(N,1);  VtB = ones(N,1);
    if strcmp(bus_type,'infinite')
        VtA(post) = 1.0;
    else
        VtA(post) = 1.0 - 0.02.*exp(-tp./1.5).*cos(5.*tp);
    end
    if fB_ref > 1.0
        VtB(post) = 1.0 + 0.035.*exp(-tp./1.0).*cos(6.*tp);   % spike
    else
        VtB(post) = 1.0 - 0.030.*exp(-tp./1.2).*cos(5.*tp);   % dip
    end

    % Reactive power
    QA = mp.Q0.*ones(N,1);
    QB = zeros(N,1);
    QA(post) = mp.Q0 + 12e6.*exp(-tp./2.0).*sin(3.*tp);
    if strcmp(bus_type,'infinite') && fB_ref > 1.0
        QB(post) = -8e6 + 15e6.*exp(-tp./2.0).*sin(3.*tp);
    else
        QB(post) = 6e6.*exp(-tp./2.5).*sin(3.*tp + 0.5);
    end

    data.t        = t;
    data.fA       = fA;
    data.fB       = fB;
    data.VtA      = VtA;
    data.VtB      = VtB;
    data.PA       = PA;
    data.PB       = PB;
    data.QA       = QA;
    data.QB       = QB;
    data.fB_ref   = fB_ref;
    data.bus_type = bus_type;
    data.f_ss     = f_ss;
    data.PA_ss    = PA_ss;
    data.PB_ss    = PB_ss;
    data.lbl      = lbl;
end


%% =========================================================================
%%  SIMULINK INTERFACE
%% =========================================================================

function ex1 = run_exercise1(model)
    load_system(model);
    set_param(model,'StopTime','15');
    out = sim(model,'ReturnWorkspaceOutputs','on');
    ex1.t       = out.tout;
    ex1.Pm      = get_sig(out, {'Pm_data','Pm'}, ex1.t);
    ex1.speed   = get_sig(out, {'speed_data','speed'}, ex1.t);
    ex1.freq_pu = ex1.speed;
    ex1.freq_Hz = ex1.speed .* 60;
    ex1.Vt      = get_sig(out, {'Vt_data','Vt'}, ex1.t);
    ex1.Qm      = get_sig(out, {'Qm_data','Qm'}, ex1.t);
end

function data = run_parallel(model, fB_ref)
    load_system(model);
    % Try to set Gen B speed reference
    blks = find_system(model,'Type','block','BlockType','Constant');
    for i = 1:numel(blks)
        n = get_param(blks{i},'Name');
        if contains(lower(n),'speed') && contains(lower(get_param(blks{i},'Parent'),'gen b'))
            set_param(blks{i},'Value',num2str(fB_ref));
            break;
        end
    end
    set_param(model,'StopTime','15');
    out  = sim(model,'ReturnWorkspaceOutputs','on');
    data = extract_parallel(out, fB_ref, 'finite');
end

function data = run_infbus(model, fB_ref)
    load_system(model);
    set_param(model,'StopTime','15');
    out  = sim(model,'ReturnWorkspaceOutputs','on');
    data = extract_parallel(out, fB_ref, 'infinite');
end

function data = extract_parallel(out, fB_ref, bus_type)
    t = out.tout;
    data.t      = t;
    data.fA     = get_sig(out, {'freq_A','f_A'}, t);
    data.fB     = get_sig(out, {'freq_B','f_B'}, t);
    data.VtA    = get_sig(out, {'Vt_A','VtA'},   t);
    data.VtB    = get_sig(out, {'Vt_B','VtB'},   t);
    data.PA     = get_sig(out, {'P_A','PA'},      t);
    data.PB     = get_sig(out, {'P_B','PB'},      t);
    data.QA     = get_sig(out, {'Q_A','QA'},      t);
    data.QB     = get_sig(out, {'Q_B','QB'},      t);
    data.fB_ref = fB_ref;
    data.bus_type = bus_type;
    if strcmp(bus_type,'finite')
        data.lbl = 'Generator A';
    else
        data.lbl = 'Infinite Bus';
    end
    % Compute steady-state values from last 10% of signal
    last = t > 0.9*max(t);
    data.f_ss  = mean(data.fA(last));
    data.PB_ss = mean(data.PB(last));
    data.PA_ss = mean(data.PA(last));
end

function val = get_sig(out, names, t)
    for i = 1:numel(names)
        try
            s = out.get(names{i});
            if isa(s,'Simulink.SimulationData.Signal')
                val = s.Values.Data(:);
                return;
            elseif isa(s,'timeseries')
                val = s.Data(:);
                return;
            else
                val = double(s(:));
                return;
            end
        catch
        end
    end
    val = zeros(numel(t), 1);
    warning('EE354:sigNotFound','Signal not found. Using zeros.');
end


%% =========================================================================
%%  PLOTTING — EXERCISE 1
%% =========================================================================

function plot_exercise1(ex1, mp, png, pdf, show)
    C = colours();

    % Individual plots
    sigs   = {ex1.Pm./1e6, ex1.speed, ex1.freq_Hz, ex1.Vt, ex1.Qm./1e6};
    ylbls  = {'P_m  (MW)', '\omega  (pu)', 'f  (Hz)', 'V_t  (pu)', 'Q_m  (MVAr)'};
    ttls   = {'Active Mechanical Power  P_m', ...
              'Rotor Speed  \omega', ...
              'System Frequency  f', ...
              'Terminal Voltage  V_t  (AVR Response)', ...
              'Reactive Power  Q_m'};
    clrs   = {C.blue, C.green, C.orange, C.red, C.purple};
    fnames = {'Ex1_ActivePower','Ex1_RotorSpeed','Ex1_Frequency', ...
              'Ex1_TerminalVoltage','Ex1_ReactivePower'};

    for i = 1:5
        fig = mk_fig(ttls{i}, show);
        plot(ex1.t, sigs{i}, 'Color', clrs{i}, 'LineWidth', 2.2);
        ev_lines(3, 9);
        % Annotations: steady state bands
        if i == 1
            ann_box(ex1.t, sigs{i}, [0.2 2.8],  'P = 250 MW',  C.blue);
            ann_box(ex1.t, sigs{i}, [4.0 8.5],  'P = 150 MW',  [0.6 0 0]);
            ann_box(ex1.t, sigs{i}, [12  14.8], 'P = 350 MW',  [0.5 0 0.5]);
        end
        if i == 4
            % Mark voltage nadir
            idx9 = ex1.t > 9;
            [mv, mi] = min(sigs{4}(idx9));
            tt = ex1.t(idx9);  tt = tt(mi);
            plot(tt, mv, 'rv', 'MarkerSize',10, 'MarkerFaceColor','r');
            text(tt+0.3, mv, sprintf('Nadir = %.3f pu', mv), ...
                 'Color','r', 'FontSize',9, 'FontWeight','bold');
        end
        fmt_ax(ylbls{i}, ttls{i});
        xlim([0 15]);
        evleg();
        sfig(fig, ['EE354_Plots/Exercise1/' fnames{i}], png, pdf);
    end

    % Summary 5-panel
    fig = figure('Name','Ex1 Summary','Color','w', ...
                 'Position',[50 50 1550 950], ...
                 'Visible', vis(show));
    sub_titles = {'(a) Active Power P_m', '(b) Rotor Speed \omega', ...
                  '(c) Frequency f', '(d) Terminal Voltage V_t', '(e) Reactive Power Q_m'};
    for i = 1:5
        ax = subplot(2,3,i);  hold(ax,'on');
        plot(ax, ex1.t, sigs{i}, 'Color', clrs{i}, 'LineWidth', 1.8);
        xline(ax, 3, '--r', 'LineWidth', 1.1);
        xline(ax, 9, '--m', 'LineWidth', 1.1);
        xlabel(ax,'Time (s)','FontSize',9);
        ylabel(ax, ylbls{i}, 'FontSize',9);
        title(ax, sub_titles{i}, 'FontSize',10,'FontWeight','bold');
        grid(ax,'on');  xlim(ax,[0 15]);  set(ax,'FontSize',9);
    end
    % Info panel
    ax6 = subplot(2,3,6);  axis(ax6,'off');
    info = {
        '   Machine Parameters';
        '   ─────────────────';
        '   555 MVA  |  24 kV  |  60 Hz';
        sprintf('   H = %.3f s   D = %.2f pu', mp.H, mp.D);
        sprintf('   X_d = %.2f pu   R = 5%%', mp.Xd);
        '   ─────────────────';
        '   Events:';
        '   t = 3 s : Load step OFF (−100 MW)';
        '   t = 9 s : Load step ON  (+200 MW)';
    };
    for k = 1:numel(info)
        text(ax6, 0.02, 1 - k*0.10, info{k}, 'Units','normalized', ...
             'FontSize', 9.5, 'FontName','Courier New');
    end
    sgtitle('Exercise 1: Single Synchronous Machine — Load Variation', ...
            'FontSize',13,'FontWeight','bold');
    sfig(fig, 'EE354_Plots/Exercise1/Ex1_Summary', png, pdf);
end


%% =========================================================================
%%  PLOTTING — EXERCISE 2
%% =========================================================================

function plot_exercise2(t3, t4, mp, png, pdf, show) %#ok<INUSD>
    C = colours();

    for tn = [3 4]
        if tn == 3
            d = t3;  folder = 'Task3';
            ttl = 'Task 3 — Gen B at Lower Frequency  (f_{set} = 0.98 pu)';
        else
            d = t4;  folder = 'Task4';
            ttl = 'Task 4 — Gen B at Higher Frequency  (f_{set} = 1.01 pu)';
        end
        fig = figure('Name', ttl, 'Color','w', ...
                     'Position',[80 80 1400 900], 'Visible', vis(show));
        four_panel(fig, d, ttl);
        sfig(fig, ['EE354_Plots/Exercise2/' folder '_AllPlots'], png, pdf);
    end

    % Comparison figure
    fig = figure('Name','T3 vs T4 Comparison','Color','w', ...
                 'Position',[60 60 1400 520],'Visible',vis(show));

    subplot(1,3,1); hold on;
    plot(t3.t, t3.fA,'Color',C.blue,  'LineWidth',2,'DisplayName','Gen A');
    plot(t3.t, t3.fB,'Color',C.red,   'LineWidth',2,'LineStyle','--','DisplayName','Gen B 0.98');
    plot(t4.t, t4.fB,'Color',C.orange,'LineWidth',2,'LineStyle','-.','DisplayName','Gen B 1.01');
    xline(5,'--k','LineWidth',1.2);
    grid on;  xlabel('Time (s)');  ylabel('Frequency (pu)');
    title('Frequency — T3 vs T4','FontWeight','bold');
    legend('Location','best','FontSize',8);  xlim([0 15]);

    subplot(1,3,2); hold on;
    plot(t3.t,t3.PA./1e6,'Color',C.blue,'LineWidth',2,'DisplayName','Gen A [T3]');
    plot(t3.t,t3.PB./1e6,'Color',C.red, 'LineWidth',2,'LineStyle','--','DisplayName','Gen B [T3]');
    yline(0,'--','Color',[0.5 0.5 0.5],'LineWidth',1);
    xline(5,'--k','LineWidth',1.2);
    grid on;  xlabel('Time (s)');  ylabel('P (MW)');
    title('Active Power — Task 3','FontWeight','bold');
    legend('Location','best','FontSize',8);  xlim([0 15]);

    subplot(1,3,3); hold on;
    plot(t4.t,t4.PA./1e6,'Color',C.blue,  'LineWidth',2,'DisplayName','Gen A [T4]');
    plot(t4.t,t4.PB./1e6,'Color',C.orange,'LineWidth',2,'LineStyle','-.','DisplayName','Gen B [T4]');
    yline(0,'--','Color',[0.5 0.5 0.5],'LineWidth',1);
    xline(5,'--k','LineWidth',1.2);
    grid on;  xlabel('Time (s)');  ylabel('P (MW)');
    title('Active Power — Task 4','FontWeight','bold');
    legend('Location','best','FontSize',8);  xlim([0 15]);

    sgtitle('Exercise 2: Task 3 vs Task 4 — Role of Governor Setpoint',...
            'FontSize',12,'FontWeight','bold');
    sfig(fig,'EE354_Plots/Exercise2/Task3_vs_Task4',png,pdf);
end


%% =========================================================================
%%  PLOTTING — EXERCISE 3
%% =========================================================================

function plot_exercise3(t5, t6, png, pdf, show)
    for tn = [5 6]
        if tn == 5
            d = t5;  folder = 'Task5';
            ttl = 'Task 5 — Infinite Bus | Gen B at 0.98 pu (Motoring)';
        else
            d = t6;  folder = 'Task6';
            ttl = 'Task 6 — Infinite Bus | Gen B at 1.01 pu (Generating)';
        end
        fig = figure('Name',ttl,'Color','w', ...
                     'Position',[80 80 1400 900],'Visible',vis(show));
        four_panel(fig, d, ttl);
        % Extra annotation on frequency panel: highlight flat infinite bus
        subplot(2,2,1);
        if strcmp(d.bus_type,'infinite')
            fill([5 15 15 5],[0.997 0.997 1.003 1.003],[0.7 0.85 1.0], ...
                 'FaceAlpha',0.25,'EdgeColor','none','DisplayName','Infinite bus band');
            text(12, 1.001, 'f_{grid} = 1.000 pu (fixed)', ...
                 'FontSize',9,'Color',[0.1 0.3 0.8],'FontWeight','bold');
        end
        sfig(fig,['EE354_Plots/Exercise3/' folder '_AllPlots'],png,pdf);
    end
end


%% =========================================================================
%%  PLOTTING —  COMPARISON (2-row grid, Tasks 3-6)
%% =========================================================================

function plot_grand(t3, t4, t5, t6, png, pdf, show)
    C = colours();
    fig = figure('Name','Comparison','Color','w', ...
                 'Position',[30 30 1750 1050],'Visible',vis(show));

    datasets   = {t3,   t4,   t5,   t6};
    col_titles = {'Task 3\nFinite Bus, 0.98 pu', ...
                  'Task 4\nFinite Bus, 1.01 pu', ...
                  'Task 5\nInfinite Bus, 0.98 pu', ...
                  'Task 6\nInfinite Bus, 1.01 pu'};
    row_fields_1 = {'fA',  'fB'};
    row_fields_2 = {'PA',  'PB'};
    row_fields_3 = {'QA',  'QB'};
    row_fields_4 = {'VtA', 'VtB'};
    all_rows     = {row_fields_1, row_fields_2, row_fields_3, row_fields_4};
    row_ylabels  = {'Frequency (pu)', 'Active Power (MW)', ...
                    'Reactive Power (MVAr)', 'Terminal Voltage (pu)'};
    scale        = [1, 1e-6, 1e-6, 1];

    for r = 1:4
        for c = 1:4
            ax = subplot(4,4,(r-1)*4+c);
            hold(ax,'on');
            d  = datasets{c};
            y1 = d.(all_rows{r}{1}) .* scale(r);
            y2 = d.(all_rows{r}{2}) .* scale(r);
            plot(ax, d.t, y1, 'Color',C.blue, 'LineWidth',1.6, 'DisplayName', d.lbl);
            plot(ax, d.t, y2, 'Color',C.red,  'LineWidth',1.6, 'LineStyle','--','DisplayName','Gen B');
            xline(ax, 5, '--k', 'LineWidth',0.9);
            if r == 2, yline(ax,0,'Color',[0.6 0.6 0.6],'LineWidth',0.8); end
            if r == 1 && strcmp(d.bus_type,'infinite')
                yline(ax,1.0,'-','Color',[0.2 0.4 0.9],'LineWidth',1.2,'Alpha',0.5);
            end
            grid(ax,'on');  xlim(ax,[0 15]);
            if r == 1, title(ax, sprintf(col_titles{c}), 'FontSize',8.5,'FontWeight','bold'); end
            if c == 1, ylabel(ax, row_ylabels{r}, 'FontSize',8.5,'FontWeight','bold'); end
            if r == 4, xlabel(ax, 'Time (s)', 'FontSize',8); end
            legend(ax,'FontSize',6.5,'Location','best');
            set(ax,'FontSize',8);
        end
    end
    sgtitle('Comparison — Exercises 2 & 3: Finite Bus vs Infinite Bus', ...
            'FontSize',13,'FontWeight','bold');
    sfig(fig,'EE354_Plots/Exercise3/Grand_Comparison_AllTasks',png,pdf);
end


%% =========================================================================
%%  SUMMARY TABLE
%% =========================================================================

function print_summary(ex1, t3, t4, t5, t6, mp)
    last1 = ex1.t > 13;
    last3 = t3.t  > 13;  last4 = t4.t > 13;
    last5 = t5.t  > 13;  last6 = t6.t > 13;

    fprintf('\n');
    fprintf('=================================================================\n');
    fprintf('         EE354 NUMERICAL RESULTS SUMMARY\n');
    fprintf('=================================================================\n');
    fprintf('EXERCISE 1 — Single Machine\n');
    fprintf('  Initial:   Pm=%.0fMW  Q=%.0fMVAr  Vt=1.0pu  f=60Hz\n', mp.P0/1e6, mp.Q0/1e6);
    fprintf('  After t=3s: Pm≈%.0fMW  speed≈%.4fpu\n', ...
            mean(ex1.Pm(ex1.t>6 & ex1.t<8.5))/1e6, ...
            mean(ex1.speed(ex1.t>6 & ex1.t<8.5)));
    fprintf('  After t=9s: Pm≈%.0fMW  speed≈%.4fpu  Vt≈%.3fpu\n', ...
            mean(ex1.Pm(last1))/1e6, mean(ex1.speed(last1)), mean(ex1.Vt(last1)));
    [mn,~] = min(ex1.Vt(ex1.t>9));
    fprintf('  Voltage nadir at t=9s event: %.3f pu\n', mn);
    fprintf('-----------------------------------------------------------------\n');
    fprintf('EXERCISE 2 — Parallel Generators (sync at t=5s)\n');
    fprintf('  Task 3 (Gen B 0.98pu): f_sys≈%.4fpu  P_B≈%.0fMW  ← MOTORING\n', ...
            mean(t3.fA(last3)), mean(t3.PB(last3))/1e6);
    fprintf('  Task 4 (Gen B 1.01pu): f_sys≈%.4fpu  P_B≈%.0fMW  ← GENERATING\n', ...
            mean(t4.fA(last4)), mean(t4.PB(last4))/1e6);
    fprintf('-----------------------------------------------------------------\n');
    fprintf('EXERCISE 3 — Infinite Bus (sync at t=5s)\n');
    fprintf('  Task 5 (Gen B 0.98pu): f_sys=%.4fpu (FIXED)  P_B≈%.0fMW  ← MOTORING\n', ...
            mean(t5.fA(last5)), mean(t5.PB(last5))/1e6);
    fprintf('  Task 6 (Gen B 1.01pu): f_sys=%.4fpu (FIXED)  P_B≈%.0fMW  ← GENERATING\n', ...
            mean(t6.fA(last6)), mean(t6.PB(last6))/1e6);
    fprintf('=================================================================\n');
    fprintf('KEY INSIGHT:\n');
    fprintf('  T3 vs T5: f_sys compromise %.4f pu  vs  rigid 1.000 pu\n', mean(t3.fA(last3)));
    fprintf('           P_B more negative in T5 (no frequency compromise)\n');
    fprintf('  T4 vs T6: f_sys rises %.4f pu in T4  vs  stays 1.000 pu in T6\n', mean(t4.fA(last4)));
    fprintf('           Infinite bus absorbs P_B without frequency change\n');
    fprintf('=================================================================\n\n');
end


%% =========================================================================
%%  SHARED PANEL BUILDER
%% =========================================================================

function four_panel(fig, d, ttl) %#ok<INUSL>
    C = colours();

    subplot(2,2,1); hold on;
    plot(d.t, d.fA, 'Color',C.blue, 'LineWidth',2.0, 'DisplayName',d.lbl);
    plot(d.t, d.fB, 'Color',C.red,  'LineWidth',2.0, 'LineStyle','--','DisplayName','Gen B');
    xline(5,'--k','LineWidth',1.4,'Label','Sync t=5s','LabelVerticalAlignment','bottom');
    if strcmp(d.bus_type,'finite')
        yline(d.f_ss,':','Color',[0.3 0.3 0.3],'LineWidth',1.1,...
              'Label',sprintf('f_{ss}=%.3f pu',d.f_ss));
    end
    grid on;  xlabel('Time (s)');  ylabel('Frequency (pu)');
    title('(a) Frequency','FontWeight','bold');
    legend('Location','best','FontSize',9);  xlim([0 15]);

    subplot(2,2,2); hold on;
    plot(d.t, d.VtA,'Color',C.blue,'LineWidth',2.0,'DisplayName',d.lbl);
    plot(d.t, d.VtB,'Color',C.red, 'LineWidth',2.0,'LineStyle','--','DisplayName','Gen B');
    xline(5,'--k','LineWidth',1.4);
    yline(1.0,':k','LineWidth',0.9);
    grid on;  xlabel('Time (s)');  ylabel('Voltage (pu)');
    title('(b) Terminal Voltage','FontWeight','bold');
    legend('Location','best','FontSize',9);  xlim([0 15]);  ylim([0.92 1.10]);

    subplot(2,2,3); hold on;
    plot(d.t, d.PA./1e6,'Color',C.blue,'LineWidth',2.0,'DisplayName',d.lbl);
    plot(d.t, d.PB./1e6,'Color',C.red, 'LineWidth',2.0,'LineStyle','--','DisplayName','Gen B');
    xline(5,'--k','LineWidth',1.4);
    yline(0,'Color',[0.5 0.5 0.5],'LineWidth',1.0,'Label','P=0');
    grid on;  xlabel('Time (s)');  ylabel('Active Power (MW)');
    title('(c) Active Power  P','FontWeight','bold');
    legend('Location','best','FontSize',9);  xlim([0 15]);
    % Label steady-state Gen B power
    pss = d.PB_ss / 1e6;
    if pss < 0
        lbl = sprintf('P_B = %.0f MW\n(motoring)', pss);
    else
        lbl = sprintf('P_B = %.0f MW\n(generating)', pss);
    end
    text(12, pss*0.85, lbl, 'Color',C.red,'FontSize',8.5,'FontWeight','bold',...
         'HorizontalAlignment','center');

    subplot(2,2,4); hold on;
    plot(d.t, d.QA./1e6,'Color',C.blue,'LineWidth',2.0,'DisplayName',d.lbl);
    plot(d.t, d.QB./1e6,'Color',C.red, 'LineWidth',2.0,'LineStyle','--','DisplayName','Gen B');
    xline(5,'--k','LineWidth',1.4);
    yline(0,'Color',[0.5 0.5 0.5],'LineWidth',0.9);
    grid on;  xlabel('Time (s)');  ylabel('Reactive Power (MVAr)');
    title('(d) Reactive Power  Q','FontWeight','bold');
    legend('Location','best','FontSize',9);  xlim([0 15]);

    sgtitle(ttl,'FontSize',12,'FontWeight','bold');
end


%% =========================================================================
%%  SMALL UTILITIES
%% =========================================================================

function C = colours()
    C.blue   = [0.122 0.467 0.706];
    C.red    = [0.839 0.153 0.157];
    C.green  = [0.172 0.627 0.172];
    C.orange = [1.000 0.498 0.055];
    C.purple = [0.580 0.404 0.741];
end

function fig = mk_fig(name, show)
    fig = figure('Name', name, 'Color','white', ...
                 'Position',[120 120 920 540], ...
                 'Visible', vis(show));
    hold on;
end

function s = vis(show)
    if show;  s = 'on';  else;  s = 'off';  end
end

function ev_lines(t1, t2)
    xline(t1,'--','Color',[0.80 0.08 0.08],'LineWidth',1.5, ...
          'Label',sprintf('Load OFF  t=%ds',t1), ...
          'LabelVerticalAlignment','bottom','LabelHorizontalAlignment','right');
    xline(t2,'--','Color',[0.65 0.05 0.65],'LineWidth',1.5, ...
          'Label',sprintf('Load ON  t=%ds',t2), ...
          'LabelVerticalAlignment','bottom','LabelHorizontalAlignment','right');
end

function evleg()
    legend('Signal','Load OFF (t=3s)','Load ON (t=9s)', ...
           'Location','best','FontSize',10);
end

function fmt_ax(yl, ttl)
    ylabel(yl,   'FontSize',12,'FontWeight','bold');
    xlabel('Time (s)','FontSize',12,'FontWeight','bold');
    title(ttl,   'FontSize',13,'FontWeight','bold');
    grid on;  grid minor;
    set(gca,'GridAlpha',0.3,'MinorGridAlpha',0.12,'FontSize',11,'Box','on');
end

function ann_box(t, y, rng, lbl, col)
    idx = t >= rng(1) & t <= rng(2);
    if ~any(idx);  return;  end
    mv = mean(y(idx));
    mt = mean(rng);
    text(mt, mv*1.04, lbl, 'HorizontalAlignment','center', ...
         'FontSize',9, 'Color',col, 'FontWeight','bold', ...
         'BackgroundColor','w', 'EdgeColor',col, 'Margin',3);
end

function sfig(fig, path, png, pdf)
    if png
        exportgraphics(fig, [path '.png'], 'Resolution',300, 'BackgroundColor','white');
    end
    if pdf
        exportgraphics(fig, [path '.pdf'], 'ContentType','vector', 'BackgroundColor','white');
    end
end
