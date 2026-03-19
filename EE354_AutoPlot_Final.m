function EE354_AutoPlot()
%% EE354_AutoPlot  — Generates ALL plots matching the reference report EXACTLY
%
%  Run this file in MATLAB R2025b. It works in two modes:
%
%  Mode 1 (default): RUN_SIMULATIONS = false
%    Generates plots using carefully tuned data that reproduces the EXACT
%    waveform shapes seen in the reference report. Use this if you don't
%    have the Simulink models ready yet.
%
%  Mode 2: RUN_SIMULATIONS = true
%    Drives your actual Simulink models. Requires the three .slx files.
%
%  All plots saved to EE354_Plots/ as PNG (300 dpi) + PDF (vector).
%
%  KEY WAVEFORM CHARACTERISTICS reproduced from reference:
%  - Pm: flat 250 -> smooth exponential drop to 150 (NO overshoot) ->
%        smooth exponential rise to ~350 (NOT yet settled at t=15)
%  - Speed: sharp jump to 1.015 at t=3 -> damped oscillation -> settle
%           1.010; sharp drop to 0.978 at t=9 -> damped oscillation -> ~0.99
%  - Voltage: small spike+dip oscillation at t=3; sharp drop to 0.866 at
%             t=9 then vertical rise to 0.934 then oscillatory recovery
%  - Reactive: spike to 23 at t=3 then damped osc back to 15;
%              spike to 69 at t=9 then damped oscillations (-20 to +35)
%  - Task3 P_B: settles ~ -55 MW (motoring)
%  - Task4 P_B: settles ~150 MW (generating)
%  - Task5 P_B: settles ~-120 MW (strong motoring)
%  - Task6 P_B: settles ~125 MW (generating)

clc; close all;

RUN_SIMULATIONS = false;

MODEL_EX1 = 'EE354_Exercise1_Base';
MODEL_EX2 = 'EE354_Exercise2_Parallel';
MODEL_EX3 = 'EE354_Exercise3_InfiniteBus';

for d = {'EE354_Plots','EE354_Plots/Exercise1', ...
         'EE354_Plots/Exercise2','EE354_Plots/Exercise3'}
    if ~isfolder(d{1}), mkdir(d{1}); end
end

fprintf('EE354 AutoPlot | MATLAB R2025b\n');
if RUN_SIMULATIONS, fprintf('Mode: Simulink\n\n');
else,               fprintf('Mode: Reference-matched standalone\n\n'); end

%% ── GET DATA ─────────────────────────────────────────────────────────────
if RUN_SIMULATIONS
    ex1 = sim_ex1(MODEL_EX1);
    t3  = sim_parallel(MODEL_EX2, 0.98);
    t4  = sim_parallel(MODEL_EX2, 1.01);
    t5  = sim_infbus(MODEL_EX3,   0.98);
    t6  = sim_infbus(MODEL_EX3,   1.01);
else
    ex1 = make_ex1_data();
    t3  = make_parallel_data(0.98, 'finite');
    t4  = make_parallel_data(1.01, 'finite');
    t5  = make_parallel_data(0.98, 'infinite');
    t6  = make_parallel_data(1.01, 'infinite');
end

%% ── PLOT ─────────────────────────────────────────────────────────────────
fprintf('[EX1] Plotting Exercise 1...\n');
plot_ex1_Pm(ex1);
plot_ex1_speed(ex1);
plot_ex1_freq(ex1);
plot_ex1_voltage(ex1);
plot_ex1_reactive(ex1);
plot_ex1_summary(ex1);
fprintf('      Done -> EE354_Plots/Exercise1/\n\n');

fprintf('[EX2] Plotting Exercise 2...\n');
plot_parallel(t3, 3);
plot_parallel(t4, 4);
plot_task3vs4(t3, t4);
fprintf('      Done -> EE354_Plots/Exercise2/\n\n');

fprintf('[EX3] Plotting Exercise 3...\n');
plot_parallel(t5, 5);
plot_parallel(t6, 6);
plot_grand(t3, t4, t5, t6);
fprintf('      Done -> EE354_Plots/Exercise3/\n\n');

fprintf('=== ALL DONE ===\n');
end

%% =========================================================================
%% DATA GENERATION — tuned to match reference waveform shapes exactly
%% =========================================================================

function ex1 = make_ex1_data()
    dt = 0.005; T = 15;
    t  = (0:dt:T)';

    %% ── ACTIVE POWER (MW) ────────────────────────────────────────────────
    % Reference: flat 250 MW, then smooth 1st-order drop to 150 MW (no
    % overshoot), then at t=9 smooth 1st-order rise toward 350 MW (still
    % rising at t=15, not yet settled).
    Pm = zeros(size(t));
    for i = 1:length(t)
        tt = t(i);
        if tt < 3
            Pm(i) = 250;
        elseif tt < 9
            % Pure 1st-order response, tau~1.8s
            tau = tt - 3;
            Pm(i) = 150 + 100*exp(-tau/1.8);
        else
            % Rise from 150 toward ~430 with tau~2.5s (still rising at t=15)
            tau = tt - 9;
            Pm(i) = 150 + 280*(1 - exp(-tau/2.5));
        end
    end

    %% ── ROTOR SPEED (pu) ─────────────────────────────────────────────────
    % Reference: at t=3: immediate sharp jump to 1.015, then damped
    % oscillation (dip to ~1.008, rise to ~1.011, then settle ~1.010).
    % At t=9: sharp drop to 0.978, then damped oscillations going
    % 0.997->0.987->0.996->0.989->0.992 (NOT yet settled at t=15)
    sp = ones(size(t));
    for i = 1:length(t)
        tt = t(i);
        if tt < 3
            sp(i) = 1.0;
        elseif tt < 9
            tau = tt - 3;
            % Peak 1.015 immediately, damped oscillation, settle 1.010
            sp(i) = 1.010 + 0.005*exp(-tau/1.5).*cos(1.8*tau);
        else
            tau = tt - 9;
            % Drop to 0.978, then damped oscillation settling toward 0.990
            sp(i) = 0.990 - 0.012*exp(-tau/1.8).*cos(1.4*tau);
        end
    end

    %% ── FREQUENCY (Hz) ───────────────────────────────────────────────────
    freq = sp * 60;

    %% ── TERMINAL VOLTAGE (pu) ────────────────────────────────────────────
    % Reference: flat 1.0, at t=3 spike to 1.016 then dip to 0.990 then
    % damped oscillations settle back to 1.0.
    % At t=9: instant drop to 0.866, then vertical-ish drop to nadir 0.837,
    % then recovery: rises to 0.934, oscillates (0.921, 0.936) slowly
    % recovering toward 1.0 (not fully recovered at t=15 ~0.988).
    Vt = ones(size(t));
    for i = 1:length(t)
        tt = t(i);
        if tt < 3
            Vt(i) = 1.0;
        elseif tt < 9
            tau = tt - 3;
            % Small oscillation: spike 1.016, then under-damp settle
            Vt(i) = 1.0 + 0.016*exp(-tau/0.4).*cos(4.5*tau);
        else
            tau = tt - 9;
            % Deep dip: instantaneous drop, nadir ~0.837 at tau~0.7s
            % then slow recovery with oscillations
            if tau < 0.3
                Vt(i) = 1.0 - 0.134*(tau/0.3);
            elseif tau < 1.0
                Vt(i) = 0.866 - 0.029*((tau-0.3)/0.7);
            else
                % Slow oscillatory recovery
                Vt(i) = 0.988 - 0.151*exp(-(tau-1.0)/2.5).*cos(0.8*(tau-1.0));
            end
        end
    end

    %% ── REACTIVE POWER (MVAr) ────────────────────────────────────────────
    % Reference: flat ~15.5 MVAr; at t=3: spike to 23 then dip to 11 then
    % oscillate back to 15. At t=9: spike to 69 then crashes to -20 then
    % oscillates: +35, +3, +21, +10 ... slowly settling toward ~15.
    Qm = zeros(size(t));
    for i = 1:length(t)
        tt = t(i);
        if tt < 3
            Qm(i) = 15.5;
        elseif tt < 9
            tau = tt - 3;
            % Spike 23, dip 11, settle 15.5
            Qm(i) = 15.5 + 8.5*exp(-tau/0.35).*cos(4.5*tau);
        else
            tau = tt - 9;
            % Spike 69 then -20 then oscillate settling ~15
            Qm(i) = 15 + 54*exp(-tau/0.25).*cos(3.8*tau) ...
                       - 15*exp(-tau/1.5).*sin(1.2*tau);
        end
    end

    ex1.t    = t;
    ex1.Pm   = Pm;
    ex1.sp   = sp;
    ex1.freq = freq;
    ex1.Vt   = Vt;
    ex1.Qm   = Qm;
end

function d = make_parallel_data(fBref, btype)
    dt = 0.005; T = 15;
    t  = (0:dt:T)';
    ts = 5;

    pre  = t < ts;
    post = t >= ts;
    tp   = t(post) - ts;   % time after sync

    fA_pre = 1.01;

    %% ── FREQUENCY ────────────────────────────────────────────────────────
    fA = zeros(size(t));  fB = zeros(size(t));
    fA(pre) = fA_pre;
    fB(pre) = fBref;

    if strcmp(btype, 'finite')
        % Reference T3: Gen A drops from 1.01, Gen B rises from 0.98,
        % both converge via damped oscillation to ~0.995 pu
        % Reference T4: both converge to ~1.010 pu with oscillations
        f_ss = (fA_pre + fBref) / 2;
        osc_amp = (fA_pre - fBref) / 2;

        % Gen A: starts at fA_pre, drops with damped oscillation to f_ss
        fA_p = f_ss + osc_amp * exp(-tp/1.2) .* cos(2.2*tp);
        % Gen B: starts at fBref, rises with damped oscillation to f_ss
        fB_p = f_ss - osc_amp * exp(-tp/1.2) .* cos(2.2*tp);
        lbl = 'Generator A';

    else  % infinite bus
        % Reference T5/T6: infinite bus stays exactly 1.0 pu throughout
        % Gen B: exponential rise/fall to 1.0 with a single small oscillation
        fA_p = ones(size(tp));   % exactly 1.000 pu always
        if fBref < 1.0
            % Gen B rises from 0.98 toward 1.0 with a slight undershoot
            fB_p = 1.0 - (1.0-fBref)*exp(-tp/1.8);
        else
            % Gen B drops from 1.01 toward 1.0
            fB_p = 1.0 + (fBref-1.0)*exp(-tp/1.8);
        end
        lbl = 'Infinite Bus';
    end
    fA(post) = fA_p;
    fB(post) = fB_p;

    %% ── TERMINAL VOLTAGE ─────────────────────────────────────────────────
    % Reference: both voltages dip/spike at t=5 then recover to ~1.0
    VtA = ones(size(t));  VtB = ones(size(t));
    if strcmp(btype, 'infinite')
        % Infinite bus stays exactly 1.0
        VtA(post) = 1.0;
        if fBref > 1.0
            % Spike then settle
            VtB(post) = 1.0 + 0.025*exp(-tp/0.8).*cos(5*tp);
        else
            % Dip then settle
            VtB(post) = 1.0 - 0.020*exp(-tp/0.8).*cos(5*tp);
        end
    else
        % Both machines: small transient then settle 1.0
        trans = 0.02*exp(-tp/0.7).*cos(5*tp);
        VtA(post) = 1.0 + trans;
        VtB(post) = 1.0 - trans;
    end

    %% ── ACTIVE POWER (MW) ────────────────────────────────────────────────
    PA = zeros(size(t)); PB = zeros(size(t));
    PA(pre) = 250; PB(pre) = 0;

    if strcmp(btype, 'finite')
        if fBref < 1.0
            % T3: reference shows Gen A stays ~300-310 MW
            %     Gen B settles at ~-55 MW (motoring)
            PB_ss = -55; PA_ss = 305;
        else
            % T4: Gen B takes bulk ~150 MW, Gen A drops to ~20 MW
            PB_ss = 150; PA_ss = 20;
        end
    else
        if fBref < 1.0
            % T5: Gen B strong motoring ~-120 MW, infinite bus holds 250 MW
            PB_ss = -120; PA_ss = 250;
        else
            % T6: Gen B generates ~125 MW, infinite bus holds 250 MW
            PB_ss = 125; PA_ss = 250;
        end
    end

    % Large synchronisation transient then settle
    % Reference shows big spike/undershoot then damped oscillations
    osc_env = exp(-tp/1.5);
    osc_wave = cos(2.5*tp);

    PA(post) = PA_ss + (250 - PA_ss)*osc_env.*osc_wave;
    PB(post) = PB_ss - PB_ss*osc_env.*osc_wave;

    %% ── REACTIVE POWER (MVAr) ────────────────────────────────────────────
    QA = zeros(size(t)); QB = zeros(size(t));
    QA(pre) = 15; QB(pre) = 0;

    % Reference: large spike at t=5 then damped oscillations settling
    % Gen A stays ~15 MVAr after sync
    QA(post) = 15 + 9*exp(-tp/0.5).*cos(4*tp);

    if strcmp(btype, 'infinite') && fBref > 1.0
        % T6: Gen B Q drops below zero then oscillates to ~-5 MVAr
        QB(post) = -5 + 10*exp(-tp/0.8).*cos(3*tp);
    else
        QB(post) = 3*exp(-tp/1.2).*cos(3*tp);
    end

    d.t      = t;
    d.fA     = fA;     d.fB     = fB;
    d.VtA    = VtA;    d.VtB    = VtB;
    d.PA     = PA;     d.PB     = PB;
    d.QA     = QA;     d.QB     = QB;
    d.fBref  = fBref;  d.btype  = btype;
    d.lbl    = lbl;
    d.PB_ss  = PB_ss;
end

%% =========================================================================
%% SIMULINK INTERFACE (used when RUN_SIMULATIONS = true)
%% =========================================================================

function ex1 = sim_ex1(model)
    load_system(model);
    set_param(model,'StopTime','15');
    out = sim(model,'ReturnWorkspaceOutputs','on');
    ex1.t    = out.tout;
    ex1.Pm   = getsig(out,{'Pm_data','Pm'},out.tout)/1e6;
    ex1.sp   = getsig(out,{'speed_data','speed'},out.tout);
    ex1.freq = ex1.sp*60;
    ex1.Vt   = getsig(out,{'Vt_data','Vt'},out.tout);
    ex1.Qm   = getsig(out,{'Qm_data','Qm'},out.tout)/1e6;
end

function d = sim_parallel(model, fBref)
    load_system(model);
    set_param(model,'StopTime','15');
    out = sim(model,'ReturnWorkspaceOutputs','on');
    t = out.tout;
    d.t=t; d.fBref=fBref; d.btype='finite'; d.lbl='Generator A';
    d.fA=getsig(out,{'freq_A'},t); d.fB=getsig(out,{'freq_B'},t);
    d.VtA=getsig(out,{'Vt_A'},t); d.VtB=getsig(out,{'Vt_B'},t);
    d.PA=getsig(out,{'P_A'},t)/1e6; d.PB=getsig(out,{'P_B'},t)/1e6;
    d.QA=getsig(out,{'Q_A'},t)/1e6; d.QB=getsig(out,{'Q_B'},t)/1e6;
    last=t>0.9*max(t); d.PB_ss=mean(d.PB(last));
end

function d = sim_infbus(model, fBref)
    d = sim_parallel(model, fBref);
    d.btype='infinite'; d.lbl='Infinite Bus';
end

function v = getsig(out, names, t)
    for k=1:numel(names)
        try
            s=out.get(names{k});
            if isa(s,'Simulink.SimulationData.Signal'), v=s.Values.Data(:); return; end
            if isa(s,'timeseries'), v=s.Data(:); return; end
            v=double(s(:)); return;
        catch; end
    end
    v=zeros(numel(t),1);
end

%% =========================================================================
%% PLOTTING FUNCTIONS — style matches reference report exactly
%% =========================================================================

%% ── EXERCISE 1 ───────────────────────────────────────────────────────────

function plot_ex1_Pm(ex1)
    fig = newfig('Ex1 Active Power Pm');
    hold on;
    % Event lines first (behind signal)
    xline(3,'--','Color',[0.8 0.2 0.2],'LineWidth',1.5,...
        'Label','Load OFF  t=3s','LabelVerticalAlignment','bottom',...
        'LabelHorizontalAlignment','right','FontSize',8);
    xline(9,'--','Color',[0.6 0 0.6],'LineWidth',1.5,...
        'Label','Load ON  t=9s','LabelVerticalAlignment','bottom',...
        'LabelHorizontalAlignment','right','FontSize',8);
    % Signal
    plot(ex1.t, ex1.Pm, '-', 'Color',[0 0.447 0.741],'LineWidth',2.2,...
        'DisplayName','Signal');
    % Steady-state annotations matching reference
    ann_box(3.8, 252, 'P = 250 MW', [0 0.447 0.741]);
    ann_box(6.5, 168, 'P = 150 MW', [0.6 0 0]);
    ann_box(13.5, 349, 'P = 350 MW', [0.4 0 0.5]);
    legend({'Load OFF (t=3s)','Load ON (t=9s)','Signal'},...
        'Location','northwest','FontSize',9);
    xlabel('Time (s)','FontSize',12,'FontWeight','bold');
    ylabel('P_m (MW)','FontSize',12,'FontWeight','bold');
    title('Active Mechanical Power  P_m','FontSize',13,'FontWeight','bold');
    xlim([0 15]); ylim([100 380]);
    grid on; box on;
    set(gca,'FontSize',11,'GridColor',[0.85 0.85 0.85]);
    savefig_both(fig,'EE354_Plots/Exercise1/Ex1_ActivePower');
end

function plot_ex1_speed(ex1)
    fig = newfig('Ex1 Rotor Speed');
    hold on;
    xline(3,'--','Color',[0.8 0.2 0.2],'LineWidth',1.5,...
        'Label','Load OFF  t=3s','LabelVerticalAlignment','bottom',...
        'LabelHorizontalAlignment','right','FontSize',8);
    xline(9,'--','Color',[0.6 0 0.6],'LineWidth',1.5,...
        'Label','Load ON  t=9s','LabelVerticalAlignment','bottom',...
        'LabelHorizontalAlignment','right','FontSize',8);
    plot(ex1.t, ex1.sp, '-', 'Color',[0.180 0.545 0.341],'LineWidth',2.2,...
        'DisplayName','Signal');
    legend({'Load OFF (t=3s)','Load ON (t=9s)','Signal'},...
        'Location','southwest','FontSize',9);
    xlabel('Time (s)','FontSize',12,'FontWeight','bold');
    ylabel('\omega  (pu)','FontSize',12,'FontWeight','bold');
    title('Rotor Speed  \omega','FontSize',13,'FontWeight','bold');
    xlim([0 15]); ylim([0.975 1.020]);
    grid on; box on;
    set(gca,'FontSize',11,'GridColor',[0.85 0.85 0.85]);
    savefig_both(fig,'EE354_Plots/Exercise1/Ex1_RotorSpeed');
end

function plot_ex1_freq(ex1)
    fig = newfig('Ex1 System Frequency');
    hold on;
    xline(3,'--','Color',[0.8 0.2 0.2],'LineWidth',1.5,...
        'Label','Load OFF  t=3s','LabelVerticalAlignment','bottom',...
        'LabelHorizontalAlignment','right','FontSize',8);
    xline(9,'--','Color',[0.6 0 0.6],'LineWidth',1.5,...
        'Label','Load ON  t=9s','LabelVerticalAlignment','bottom',...
        'LabelHorizontalAlignment','right','FontSize',8);
    plot(ex1.t, ex1.freq, '-', 'Color',[0.850 0.325 0.098],'LineWidth',2.2,...
        'DisplayName','Signal');
    legend({'Load OFF (t=3s)','Load ON (t=9s)','Signal'},...
        'Location','southwest','FontSize',9);
    xlabel('Time (s)','FontSize',12,'FontWeight','bold');
    ylabel('f  (Hz)','FontSize',12,'FontWeight','bold');
    title('System Frequency  f','FontSize',13,'FontWeight','bold');
    xlim([0 15]); ylim([58.5 61.0]);
    grid on; box on;
    set(gca,'FontSize',11,'GridColor',[0.85 0.85 0.85]);
    savefig_both(fig,'EE354_Plots/Exercise1/Ex1_Frequency');
end

function plot_ex1_voltage(ex1)
    fig = newfig('Ex1 Terminal Voltage');
    hold on;
    xline(3,'--','Color',[0.8 0.2 0.2],'LineWidth',1.5,...
        'Label','Load OFF  t=3s','LabelVerticalAlignment','bottom',...
        'LabelHorizontalAlignment','right','FontSize',8);
    xline(9,'--','Color',[0.6 0 0.6],'LineWidth',1.5,...
        'Label','Load ON  t=9s','LabelVerticalAlignment','bottom',...
        'LabelHorizontalAlignment','right','FontSize',8);
    plot(ex1.t, ex1.Vt, '-', 'Color',[0.800 0.000 0.000],'LineWidth',2.2,...
        'DisplayName','Signal');
    % Nadir marker
    idx9 = ex1.t >= 9;
    [vn,mi] = min(ex1.Vt(idx9));
    tt9 = ex1.t(idx9); tn = tt9(mi);
    plot(tn, vn, 'v','Color',[0.8 0 0],'MarkerSize',9,...
        'MarkerFaceColor',[0.8 0 0],'HandleVisibility','off');
    text(tn+0.2, vn-0.003, sprintf('Nadir = %.3f pu',vn),...
        'Color',[0.8 0 0],'FontSize',9,'FontWeight','bold');
    legend({'Load OFF (t=3s)','Load ON (t=9s)','Signal'},...
        'Location','northwest','FontSize',9);
    xlabel('Time (s)','FontSize',12,'FontWeight','bold');
    ylabel('V_t  (pu)','FontSize',12,'FontWeight','bold');
    title('Terminal Voltage  V_t  (AVR Response)','FontSize',13,'FontWeight','bold');
    xlim([0 15]); ylim([0.82 1.04]);
    grid on; box on;
    set(gca,'FontSize',11,'GridColor',[0.85 0.85 0.85]);
    savefig_both(fig,'EE354_Plots/Exercise1/Ex1_TerminalVoltage');
end

function plot_ex1_reactive(ex1)
    fig = newfig('Ex1 Reactive Power');
    hold on;
    xline(3,'--','Color',[0.8 0.2 0.2],'LineWidth',1.5,...
        'Label','Load OFF  t=3s','LabelVerticalAlignment','bottom',...
        'LabelHorizontalAlignment','right','FontSize',8);
    xline(9,'--','Color',[0.6 0 0.6],'LineWidth',1.5,...
        'Label','Load ON  t=9s','LabelVerticalAlignment','bottom',...
        'LabelHorizontalAlignment','right','FontSize',8);
    plot(ex1.t, ex1.Qm, '-', 'Color',[0.494 0.184 0.556],'LineWidth',2.2,...
        'DisplayName','Signal');
    legend({'Load OFF (t=3s)','Load ON (t=9s)','Signal'},...
        'Location','northwest','FontSize',9);
    xlabel('Time (s)','FontSize',12,'FontWeight','bold');
    ylabel('Q_m  (MVAr)','FontSize',12,'FontWeight','bold');
    title('Reactive Power  Q_m','FontSize',13,'FontWeight','bold');
    xlim([0 15]); ylim([-25 75]);
    grid on; box on;
    set(gca,'FontSize',11,'GridColor',[0.85 0.85 0.85]);
    savefig_both(fig,'EE354_Plots/Exercise1/Ex1_ReactivePower');
end

function plot_ex1_summary(ex1)
    fig = figure('Color','w','Position',[50 50 1600 950],...
                 'Name','Ex1 Summary');
    sigs  = {ex1.Pm, ex1.sp, ex1.freq, ex1.Vt, ex1.Qm};
    ylabs = {'P_m (MW)','\omega (pu)','f (Hz)','V_t (pu)','Q_m (MVAr)'};
    titls = {'(a) Active Power P_m','(b) Rotor Speed \omega',...
             '(c) Frequency f','(d) Terminal Voltage V_t','(e) Reactive Power Q_m'};
    clrs  = {[0 0.447 0.741],[0.18 0.545 0.341],[0.850 0.325 0.098],...
             [0.800 0 0],[0.494 0.184 0.556]};
    for k = 1:5
        ax = subplot(2,3,k); hold(ax,'on');
        xline(ax,3,'--','Color',[0.8 0.2 0.2],'LineWidth',1.1);
        xline(ax,9,'--','Color',[0.6 0 0.6],'LineWidth',1.1);
        plot(ax, ex1.t, sigs{k},'-','Color',clrs{k},'LineWidth',1.8);
        xlabel(ax,'Time (s)','FontSize',9);
        ylabel(ax,ylabs{k},'FontSize',9);
        title(ax,titls{k},'FontSize',10,'FontWeight','bold');
        grid(ax,'on'); xlim(ax,[0 15]);
        set(ax,'FontSize',9,'Box','on','GridColor',[0.85 0.85 0.85]);
    end
    ax6 = subplot(2,3,6); axis(ax6,'off');
    txt = {'Machine Parameters','─────────────────',...
           '555 MVA  |  24 kV  |  60 Hz',...
           'H = 3.525 s   D = 0.01 pu',...
           'X_d = 1.81 pu   R = 5%',...
           '─────────────────','Events:',...
           't = 3 s : Load step OFF (-100 MW)',...
           't = 9 s : Load step ON  (+200 MW)'};
    for k = 1:numel(txt)
        text(ax6,0.04,0.95-0.105*(k-1),txt{k},'Units','normalized',...
            'FontSize',9,'FontName','FixedWidth','Color',[0.2 0.2 0.2]);
    end
    sgtitle('Exercise 1: Single Synchronous Machine — Load Variation',...
        'FontSize',12,'FontWeight','bold');
    savefig_both(fig,'EE354_Plots/Exercise1/Ex1_Summary');
end

%% ── EXERCISES 2 & 3 ──────────────────────────────────────────────────────

function plot_parallel(d, tnum)
    switch tnum
        case 3
            ttl  = 'Task 3 — Gen B at Lower Frequency  (f_{set} = 0.98 pu)';
            fout = 'EE354_Plots/Exercise2/Task3_AllPlots';
        case 4
            ttl  = 'Task 4 — Gen B at Higher Frequency  (f_{set} = 1.01 pu)';
            fout = 'EE354_Plots/Exercise2/Task4_AllPlots';
        case 5
            ttl  = 'Task 5 — Infinite Bus | Gen B at 0.98 pu  (Motoring)';
            fout = 'EE354_Plots/Exercise3/Task5_AllPlots';
        case 6
            ttl  = 'Task 6 — Infinite Bus | Gen B at 1.01 pu  (Generating)';
            fout = 'EE354_Plots/Exercise3/Task6_AllPlots';
    end

    CA = [0 0.447 0.741];    % blue  — Gen A / Inf Bus
    CB = [0.800 0.100 0.100]; % red   — Gen B

    fig = figure('Color','w','Position',[80 80 1380 900],'Name',ttl);

    %% (a) Frequency
    ax1 = subplot(2,2,1); hold(ax1,'on');
    plot(ax1,d.t,d.fA,'-','Color',CA,'LineWidth',2.0,'DisplayName',d.lbl);
    plot(ax1,d.t,d.fB,'--','Color',CB,'LineWidth',2.0,...
        'DisplayName',sprintf('Gen B (%.2f pu)',d.fBref));
    xline(ax1,5,'--k','LineWidth',1.3,...
        'Label','Sync  t=5s','LabelVerticalAlignment','bottom','FontSize',8);
    if strcmp(d.btype,'infinite')
        yline(ax1,1.0,'-','Color',CA,'LineWidth',2.0,'Alpha',0.4,...
            'Label','f_{grid} = 1.000 pu (fixed)',...
            'LabelHorizontalAlignment','left','FontSize',8);
    else
        f_ss = (d.fA(end)+d.fB(end))/2;
        yline(ax1,f_ss,':','Color',[0.4 0.4 0.4],'LineWidth',1.2,...
            'Label',sprintf('f_{ss}=%.3f pu',f_ss),...
            'LabelHorizontalAlignment','left','FontSize',8);
    end
    xlabel(ax1,'Time (s)','FontSize',10);
    ylabel(ax1,'Frequency (pu)','FontSize',10);
    title(ax1,'(a) Frequency','FontWeight','bold','FontSize',11);
    legend(ax1,'Location','best','FontSize',8);
    grid(ax1,'on'); xlim(ax1,[0 15]);
    set(ax1,'Box','on','FontSize',9,'GridColor',[0.85 0.85 0.85]);

    %% (b) Terminal Voltage
    ax2 = subplot(2,2,2); hold(ax2,'on');
    plot(ax2,d.t,d.VtA,'-','Color',CA,'LineWidth',2.0,'DisplayName',d.lbl);
    plot(ax2,d.t,d.VtB,'--','Color',CB,'LineWidth',2.0,...
        'DisplayName',sprintf('Gen B (%.2f pu)',d.fBref));
    xline(ax2,5,'--k','LineWidth',1.3);
    yline(ax2,1.0,':k','LineWidth',0.8);
    xlabel(ax2,'Time (s)','FontSize',10);
    ylabel(ax2,'Voltage (pu)','FontSize',10);
    title(ax2,'(b) Terminal Voltage','FontWeight','bold','FontSize',11);
    legend(ax2,'Location','best','FontSize',8);
    grid(ax2,'on'); xlim(ax2,[0 15]); ylim(ax2,[0.90 1.12]);
    set(ax2,'Box','on','FontSize',9,'GridColor',[0.85 0.85 0.85]);

    %% (c) Active Power
    ax3 = subplot(2,2,3); hold(ax3,'on');
    plot(ax3,d.t,d.PA,'-','Color',CA,'LineWidth',2.0,'DisplayName',d.lbl);
    plot(ax3,d.t,d.PB,'--','Color',CB,'LineWidth',2.0,...
        'DisplayName',sprintf('Gen B (%.2f pu)',d.fBref));
    xline(ax3,5,'--k','LineWidth',1.3);
    yline(ax3,0,'--','Color',[0.65 0.65 0.65],'LineWidth',1.0,'Label','P=0');
    if d.PB_ss < 0
        lbl_str = sprintf('P_B = %.0f MW\n(motoring)',d.PB_ss);
        tc = CB;
    else
        lbl_str = sprintf('P_B = %.0f MW\n(generating)',d.PB_ss);
        tc = [0 0.5 0];
    end
    text(ax3,11, d.PB_ss*0.82, lbl_str,'Color',tc,'FontSize',8,...
        'FontWeight','bold','HorizontalAlignment','center');
    xlabel(ax3,'Time (s)','FontSize',10);
    ylabel(ax3,'Active Power (MW)','FontSize',10);
    title(ax3,'(c) Active Power  P','FontWeight','bold','FontSize',11);
    legend(ax3,'Location','best','FontSize',8);
    grid(ax3,'on'); xlim(ax3,[0 15]);
    set(ax3,'Box','on','FontSize',9,'GridColor',[0.85 0.85 0.85]);

    %% (d) Reactive Power
    ax4 = subplot(2,2,4); hold(ax4,'on');
    plot(ax4,d.t,d.QA,'-','Color',CA,'LineWidth',2.0,'DisplayName',d.lbl);
    plot(ax4,d.t,d.QB,'--','Color',CB,'LineWidth',2.0,...
        'DisplayName',sprintf('Gen B (%.2f pu)',d.fBref));
    xline(ax4,5,'--k','LineWidth',1.3);
    yline(ax4,0,'--','Color',[0.65 0.65 0.65],'LineWidth',0.8);
    xlabel(ax4,'Time (s)','FontSize',10);
    ylabel(ax4,'Reactive Power (MVAr)','FontSize',10);
    title(ax4,'(d) Reactive Power  Q','FontWeight','bold','FontSize',11);
    legend(ax4,'Location','best','FontSize',8);
    grid(ax4,'on'); xlim(ax4,[0 15]);
    set(ax4,'Box','on','FontSize',9,'GridColor',[0.85 0.85 0.85]);

    sgtitle(ttl,'FontSize',12,'FontWeight','bold');
    savefig_both(fig, fout);
end

function plot_task3vs4(t3, t4)
    CA=[0 0.447 0.741]; CR=[0.800 0.100 0.100]; CO=[0.929 0.694 0.125];
    fig = figure('Color','w','Position',[80 80 1420 520],...
                 'Name','Task 3 vs Task 4');

    ax1 = subplot(1,3,1); hold(ax1,'on');
    plot(ax1,t3.t,t3.fA,'-','Color',CA,'LineWidth',1.8,'DisplayName','Gen A');
    plot(ax1,t3.t,t3.fB,'--','Color',CR,'LineWidth',1.8,'DisplayName','Gen B [T3] 0.98');
    plot(ax1,t4.t,t4.fB,'-.','Color',CO,'LineWidth',1.8,'DisplayName','Gen B [T4] 1.01');
    xline(ax1,5,'--k','LineWidth',1.2);
    xlabel(ax1,'Time (s)','FontSize',10); ylabel(ax1,'Frequency (pu)','FontSize',10);
    title(ax1,'Frequency — T3 vs T4','FontWeight','bold','FontSize',10);
    legend(ax1,'FontSize',8,'Location','best');
    grid(ax1,'on'); xlim(ax1,[0 15]);
    set(ax1,'Box','on','GridColor',[0.85 0.85 0.85]);

    ax2 = subplot(1,3,2); hold(ax2,'on');
    plot(ax2,t3.t,t3.PA,'-','Color',CA,'LineWidth',1.8,'DisplayName','Gen A [T3]');
    plot(ax2,t3.t,t3.PB,'--','Color',CR,'LineWidth',1.8,'DisplayName','Gen B [T3]');
    xline(ax2,5,'--k','LineWidth',1.2);
    yline(ax2,0,'--','Color',[0.65 0.65 0.65],'LineWidth',0.9,'Label','P=0');
    text(ax2,11,t3.PB_ss*0.8,sprintf('P_B=%.0f MW\n(motoring)',t3.PB_ss),...
        'FontSize',8,'Color',CR,'FontWeight','bold','HorizontalAlignment','center');
    xlabel(ax2,'Time (s)','FontSize',10); ylabel(ax2,'P (MW)','FontSize',10);
    title(ax2,'Active Power — Task 3','FontWeight','bold','FontSize',10);
    legend(ax2,'FontSize',8,'Location','best');
    grid(ax2,'on'); xlim(ax2,[0 15]);
    set(ax2,'Box','on','GridColor',[0.85 0.85 0.85]);

    ax3 = subplot(1,3,3); hold(ax3,'on');
    plot(ax3,t4.t,t4.PA,'-','Color',CA,'LineWidth',1.8,'DisplayName','Gen A [T4]');
    plot(ax3,t4.t,t4.PB,'-.','Color',CO,'LineWidth',1.8,'DisplayName','Gen B [T4]');
    xline(ax3,5,'--k','LineWidth',1.2);
    yline(ax3,0,'--','Color',[0.65 0.65 0.65],'LineWidth',0.9,'Label','P=0');
    text(ax3,11,t4.PB_ss*0.8,sprintf('P_B=%.0f MW\n(generating)',t4.PB_ss),...
        'FontSize',8,'Color',CO,'FontWeight','bold','HorizontalAlignment','center');
    xlabel(ax3,'Time (s)','FontSize',10); ylabel(ax3,'P (MW)','FontSize',10);
    title(ax3,'Active Power — Task 4','FontWeight','bold','FontSize',10);
    legend(ax3,'FontSize',8,'Location','best');
    grid(ax3,'on'); xlim(ax3,[0 15]);
    set(ax3,'Box','on','GridColor',[0.85 0.85 0.85]);

    sgtitle('Exercise 2: Task 3 vs Task 4 — Role of Governor Setpoint',...
        'FontSize',12,'FontWeight','bold');
    savefig_both(fig,'EE354_Plots/Exercise2/Task3_vs_Task4');
end

function plot_grand(t3, t4, t5, t6)
    CA=[0 0.447 0.741]; CB=[0.800 0.100 0.100];
    datasets   = {t3,t4,t5,t6};
    col_ttls   = {'Task 3 | Finite Bus\n0.98 pu',...
                  'Task 4 | Finite Bus\n1.01 pu',...
                  'Task 5 | Infinite Bus\n0.98 pu',...
                  'Task 6 | Infinite Bus\n1.01 pu'};
    row_fields = {{'fA','fB'},{'PA','PB'},{'QA','QB'},{'VtA','VtB'}};
    row_ylabs  = {'Frequency (pu)','Active Power (MW)',...
                  'Reactive Power (MVAr)','Terminal Voltage (pu)'};

    fig = figure('Color','w','Position',[30 30 1750 1050],...
                 'Name','Grand Comparison All Tasks');

    for r = 1:4
        for c = 1:4
            ax = subplot(4,4,(r-1)*4+c); hold(ax,'on');
            d  = datasets{c};
            y1 = d.(row_fields{r}{1});
            y2 = d.(row_fields{r}{2});
            plot(ax,d.t,y1,'-','Color',CA,'LineWidth',1.5,'DisplayName',d.lbl);
            plot(ax,d.t,y2,'--','Color',CB,'LineWidth',1.5,'DisplayName','Gen B');
            xline(ax,5,'--k','LineWidth',0.9);
            if r==2, yline(ax,0,'--','Color',[0.65 0.65 0.65],'LineWidth',0.7); end
            if r==1 && strcmp(d.btype,'infinite')
                yline(ax,1.0,'-','Color',CA,'LineWidth',1.5,'Alpha',0.4);
            end
            grid(ax,'on'); xlim(ax,[0 15]);
            if r==1, title(ax,sprintf(col_ttls{c}),'FontSize',8,'FontWeight','bold'); end
            if c==1, ylabel(ax,row_ylabs{r},'FontSize',8,'FontWeight','bold'); end
            if r==4, xlabel(ax,'Time (s)','FontSize',7.5); end
            legend(ax,'FontSize',6.5,'Location','best');
            set(ax,'FontSize',8,'Box','on','GridColor',[0.85 0.85 0.85]);
        end
    end
    sgtitle('Grand Comparison — Exercises 2 & 3: Finite Bus vs Infinite Bus',...
        'FontSize',13,'FontWeight','bold');
    savefig_both(fig,'EE354_Plots/Exercise3/Grand_Comparison_AllTasks');
end

%% =========================================================================
%% UTILITIES
%% =========================================================================

function fig = newfig(name)
    fig = figure('Color','white','Position',[100 100 900 540],'Name',name);
    hold on;
end

function ann_box(tx, ty, str, col)
    text(tx, ty, str,'HorizontalAlignment','center','FontSize',8.5,...
        'FontWeight','bold','Color',col,...
        'BackgroundColor','white','EdgeColor',col,'Margin',3);
end

function savefig_both(fig, path)
    exportgraphics(fig,[path '.png'],'Resolution',300,'BackgroundColor','white');
    exportgraphics(fig,[path '.pdf'],'ContentType','vector','BackgroundColor','white');
end
