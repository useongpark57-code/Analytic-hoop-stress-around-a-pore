%% ANALYTICAL SCF DEMO (plane stress, isolated circular hole)
% Run this script directly. No FEM, optimization, or toolbox is required.
% Remote stresses are prescribed in MPa; tension is positive.
% theta = 0 is the positive x direction, measured counterclockwise.
% Kirsch solution: infinite elastic plate, traction-free circular hole.
clear; clc; close all;

%% LOAD CASES: each row is [sigma_xx, sigma_yy, tau_xy] in MPa
S = 100;
s = S * [ 1  0  0;       % Uniaxial tension
         -1  0  0;       % Uniaxial compression
          0  0  1;       % Pure shear
          1  0.5  0.3;   % General 2D: biaxial tension + shear
         -1 -0.5  0.3];  % General 2D: biaxial compression + shear
load_name = {'Uniaxial tension', 'Uniaxial compression', ...
             'Pure shear', 'Combined tension', 'Combined compression'};
% Combined cases include biaxial normal loading and shear.

%% SETTINGS (same stress matrix and smoothing as the main TO code)
M = [1 -1/2 0; -1/2 1 0; 0 0 3];
eps1 = 1e-10; eps2 = 1e-10; % In squared stress units (MPa^2 here)
theta = linspace(0,360,1441);
n = size(s,1);
vms = zeros(n,1); sigma_theta_max = zeros(n,1);
psi = zeros(n,1); SCF_mod = nan(n,1);
sigma_theta = zeros(n,length(theta));

%% ANALYTICAL STRESS AND AMPLIFICATION
for i = 1:n
    sx = s(i,1); sy = s(i,2); txy = s(i,3);
    vms(i) = sqrt(s(i,:) * M * s(i,:)');
    % Superpose the hoop stresses from the three remote components.
    hoop_x = sx*(1 - 2*cosd(2*theta));
    hoop_y = sy*(1 + 2*cosd(2*theta));
    hoop_xy = -4*txy*sind(2*theta);
    sigma_theta(i,:) = hoop_x + hoop_y + hoop_xy;
    sigma_theta_max(i) = sx + sy + 2*sqrt((sx-sy)^2 + 4*txy^2);
    % The main code also regularizes the square root using eps2.
    sigma_theta_max_reg = sx + sy + 2*sqrt((sx-sy)^2 + 4*txy^2 + eps2);
    psi(i) = 0.5*(sigma_theta_max_reg + vms(i)) ...
           + 0.5*sqrt((sigma_theta_max_reg - vms(i))^2 + eps1);
    if vms(i) > 0, SCF_mod(i) = psi(i)/vms(i); end
end
% psi = sigma_crit in the paper, with relaxed_scf = 1 in the main code.
% psi is NOT max(abs(sigma_theta)): compressive peaks are not used that way.
% Zero remote stress has undefined amplification (NaN); smoothing may leave
% a tiny positive psi. Fixed eps1/eps2 matter only near zero stress here.

%% PRINT RESULTS
results = table(s(:,1),s(:,2),s(:,3),vms,sigma_theta_max,psi,SCF_mod, ...
    'VariableNames',{'sigma_xx','sigma_yy','tau_xy','VMS_nominal', ...
                     'Hoop_max','Sigma_crit','Amplification'}, ...
    'RowNames',load_name);
disp(results);

%% FIGURE 1: HOOP STRESS AROUND THE HOLE
figure(1); set(gcf,'Color','w','Name','Analytical hoop stress', ...
    'Position',[100 100 1100 650]);
ymin = min([0; sigma_theta(:)]); ymax = max([sigma_theta(:); psi]);
padding = 0.08*max(ymax-ymin,1);
for i = 1:n
    subplot(2,ceil(n/2),i);
    h1 = plot(theta,sigma_theta(i,:),'b-','LineWidth',1.5); hold on;
    h2 = plot([0 360],vms(i)*[1 1],'k--','LineWidth',1.2);
    h4 = plot([0 360],sigma_theta_max(i)*[1 1],'m:','LineWidth',1.2);
    plot([0 360],[0 0],':','Color',[0.6 0.6 0.6]);
    % Draw sigma_crit last with a thin dashed line and sparse open circles.
    marker_theta = 0:90:360;
    h3 = plot(marker_theta,psi(i)*ones(size(marker_theta)),'r--o', ...
        'MarkerSize',3,'LineWidth',0.7);
    hold off; grid on; xlim([0 360]); ylim([ymin-padding ymax+padding]);
    set(gca,'XTick',0:90:360);
    xlabel('\theta (deg)'); ylabel('Stress (MPa)');
    title(sprintf('%s | K_{eff} = %.2f',load_name{i},SCF_mod(i)));
    legend([h1 h2 h4 h3],{'Hoop stress','Nominal VMS', ...
        'Maximum hoop stress','\sigma_{crit} (circles)'}, ...
        'Location','best');
end

%% FIGURE 2: COMPARE LOAD CASES
figure(2); set(gcf,'Color','w','Name','Stress amplification', ...
    'Position',[150 150 1100 430]);
subplot(1,2,1);
bar([vms sigma_theta_max psi]); grid on;
set(gca,'XTick',1:n,'XTickLabel',load_name,'XTickLabelRotation',30);
ylabel('Stress (MPa)'); title('Nominal, maximum hoop, and augmented stress');
legend('Nominal VMS','Maximum hoop stress','\sigma_{crit}','Location','best');
subplot(1,2,2);
bar(SCF_mod); hold on; plot([0.5 n+0.5],[1 1],'k--');
for i = 1:n
    if isfinite(SCF_mod(i))
        text(i,SCF_mod(i),sprintf('%.2f',SCF_mod(i)), ...
            'HorizontalAlignment','center','VerticalAlignment','bottom');
    end
end
hold off; grid on;
set(gca,'XTick',1:n,'XTickLabel',load_name,'XTickLabelRotation',30);
ylim([0 max([1; SCF_mod(isfinite(SCF_mod))])+0.5]);
ylabel('K_{eff} = \sigma_{crit} / \sigma_{vm}');
title('Effective amplification');
