%% COMBINED TENSION: PORE FIELD AND BOUNDARY STRESS
% Infinite-plate Kirsch solution displayed in a square element-like window.
% This is not a finite square-element boundary-value solution.
% Plane stress; pore radius enlarged for illustration. Stress units: MPa.
clear; clc; close all;
sx = 100; sy = 50; txy = 30;
a = 1;
[x,y] = meshgrid(linspace(-5*a,5*a,501));
r = sqrt(x.^2+y.^2); theta = atan2(y,x);
q = (a./max(r,a)).^2;

%% KIRSCH SOLUTION OUTSIDE THE PORE
sigma_rr = (sx+sy)/2*(1-q) + (1-4*q+3*q.^2).* ...
    ((sx-sy)/2*cos(2*theta)+txy*sin(2*theta));
sigma_tt = (sx+sy)/2*(1+q) - (1+3*q.^2).* ...
    ((sx-sy)/2*cos(2*theta)+txy*sin(2*theta));
tau_rt = (1+2*q-3*q.^2).* ...
    ((sy-sx)/2*sin(2*theta)+txy*cos(2*theta));
vms_local = sqrt(sigma_rr.^2-sigma_rr.*sigma_tt+sigma_tt.^2+3*tau_rt.^2);
vms_local(r<a) = NaN;

%% BOUNDARY STRESS AND AUGMENTATION (same smoothing as main code)
deg = linspace(0,360,1441);
hoop = sx+sy-2*(sx-sy)*cosd(2*deg)-4*txy*sind(2*deg);
vms = sqrt(sx^2-sx*sy+sy^2+3*txy^2);
hoop_max = sx+sy+2*sqrt((sx-sy)^2+4*txy^2);
hoop_reg = sx+sy+2*sqrt((sx-sy)^2+4*txy^2+1e-10);
psi = 0.5*(hoop_reg+vms)+0.5*sqrt((hoop_reg-vms)^2+1e-10);
Keff = psi/vms;

%% TWO-PANEL FIGURE
figure('Color','w','Position',[100 100 1150 480]);
subplot(1,2,1);
sigma_tt(r<a) = NaN;
contourf(x/a,y/a,sigma_tt,40,'LineStyle','none'); hold on;
fill(cosd(deg),sind(deg),'w','EdgeColor',[.3 .3 .3]);
text(0,0,'Pore','HorizontalAlignment','center');
palette = [255 253 240; 255 239 180; 255 209 110; ...
           255 165 55; 240 115 15]/255;
% Arrows indicate the remote loading schematically, not tractions at r=5a.
edge = [-3 0 3]; arrow_color = [123 137 153]/255;
quiver(5*ones(1,3),edge,.6*ones(1,3),zeros(1,3),0,'Color',arrow_color);
quiver(-5*ones(1,3),edge,-.6*ones(1,3),zeros(1,3),0,'Color',arrow_color);
quiver(edge,5*ones(1,3),zeros(1,3),.6*ones(1,3),0,'Color',arrow_color);
quiver(edge,-5*ones(1,3),zeros(1,3),-.6*ones(1,3),0,'Color',arrow_color);
% Tangential arrow pairs meet outside the corners (positive shear).
quiver([-5.1 4.4 -4.4 5.1],[5.1 5.1 -5.1 -5.1], ...
    [.7 .7 -.7 -.7],[0 0 0 0],0,'Color',arrow_color);
quiver([-5.1 5.1 -5.1 5.1],[5.1 4.4 -4.4 -5.1], ...
    [0 0 0 0],[-.7 .7 -.7 .7],0,'Color',arrow_color);
text(-6,0,'\sigma_{xx}','HorizontalAlignment','center');
text(0,-6,'\sigma_{yy}','HorizontalAlignment','center');
text(5.5,5.8,'\tau_{xy}','HorizontalAlignment','left');
axis equal; xlim([-6.5 6.5]); ylim([-6.5 6.5]); axis off;
colormap(interp1(linspace(0,1,5),palette,linspace(0,1,256)));
caxis([-20 320]);
cb = colorbar; ylabel(cb,'MPa');
title('Analytical hoop stress around the pore');

subplot(1,2,2);
h1 = plot(deg,hoop,'-','Color',[86 143 172]/255,'LineWidth',1.5); hold on;
h2 = plot([0 360],[vms vms],'--','Color',[123 137 153]/255,'LineWidth',1);
h3 = plot([0 360],[hoop_max hoop_max],':','Color',[156 133 184]/255,'LineWidth',1.2);
h4 = plot(0:90:360,psi*ones(1,5),'--o','Color',[188 138 158]/255, ...
    'MarkerSize',3,'LineWidth',.7);
grid on; xlim([0 360]); ylim([-35 395]); xticks(0:90:360);
xlabel('\theta (deg)'); ylabel('Stress (MPa)');
title(sprintf('Pore boundary | K_{eff} = %.3f',Keff));
legend([h1 h2 h3 h4],{'Hoop stress','Nominal VMS', ...
    'Maximum hoop stress','\sigma_{crit}'},'Location','best');
sgtitle('Analytical hoop stress around a pore');
annotation('textbox',[.07 .005 .40 .09], 'String', ...
    'Remote stress: σ = [100  30; 30  50] MPa', ...
    'EdgeColor','none','HorizontalAlignment','center','FontSize',11);
fprintf('Nominal VMS = %.3f, maximum hoop = %.3f, sigma_crit = %.3f MPa; K_eff = %.3f\n', ...
    vms,hoop_max,psi,Keff);
exportgraphics(gcf,fullfile(fileparts(mfilename('fullpath')), ...
    'combined_tension_hoop_matlab.png'),'Resolution',250);




