function fig4c
% periodic driver: udot = b0 + u^2 until u = 1, then u = 0
% 2 uncoupled periodic responders
%   vidot = bi + vi^2 + g0*(u-vi) until vi = 1, then vi = 0
% driving period T0 = b0^-.5*atan(b0^-.5) is scanned
% responder periods drawn from normal with mean T0 and std p*T0
% response strengths are 1/mean(T0)
% deviation score = (1/T)*int_0^T dt |v1-v2| with T post-relaxation time

T0s = linspace(2,20,50);
p = .1;
g0 = 1/mean(T0s);
vreset = 0;
vmax = 1;
V0 = [0;0;0];

opt = odeset('events',@(t,V)max_fun(t,V,vmax));
opt2 = optimoptions('fsolve','display','none');
lw = 1; lw2 = 2; fs = 15; ms = 6;

for z = 1:1000
    z
    for l = 1:length(T0s)
        T0 = T0s(l);
        T1 = max(0,T0*(1+p*randn));
        T2 = max(0,T0*(1+p*randn));
        b0 = fsolve(@(b)period_fun(b,T0),1/T0^2,opt2);
        b1 = fsolve(@(b)period_fun(b,T1),1/T1^2,opt2);
        b2 = fsolve(@(b)period_fun(b,T2),1/T2^2,opt2);
        T = 20*T0;
        trelax = 10*T0;
        
        t = []; V = []; V0i = V0; tmax = 0; te = 0;
        while tmax < T
            [ti,Vi,te,Ve,j] = ...
                ode45(@(t,V)qif_fun(t,V,b0,b1,b2,g0),...
                [te(end) T],V0i,opt);
            if ~isempty(j)
                t = [t; ti];
                V = [V; Vi];
                V0i = Vi(end,:);
                V0i(j) = vreset;
                tmax = t(end);
            else
                tmax = T;
            end
        end
        
        v1 = V(:,2);
        v2 = V(:,3);
        dv = abs(v1-v2);
        tr = t(t > trelax);
        Tr = tr(end)-tr(1);
        dvr = dv(t > trelax);
        dt = diff(tr);
        dvbar = (dvr(2:end)+dvr(1:end-1))/2;
        d(l,z) = dt'*dvbar/Tr;
        
        %     figure(1); clf
        %     h = plot(t,V,'-');
        %     xlim([.8*T T])
        %     ylim([vreset-.1 vmax+.1])
        %     xlabel('t')
        %     legend({'u (driver)','v (responder)','w (responder)'},...
        %         'location','e')
        %     title(['T_0 = ' num2str(T0)])
        %     set(gca,'fontsize',fs)
        %     drawnow
        %     pause
    end
end

figure(1); clf
plot(T0s,mean(d,2),'k-','linewidth',lw2)
xlabel('period, T_0')
ylabel('deviation score')
set(gca,'fontsize',fs)

save('../../dat/fig4c.mat')

function F = period_fun(b,T)
F = T - atan(1./sqrt(b))./sqrt(b);

function dVdt = qif_fun(t,V,b0,b1,b2,g0)
u = V(1);
v1 = V(2);
v2 = V(3);
dudt = b0 + u.^2;
dv1dt = b1 + v1.^2 + g0.*(u-v1);
dv2dt = b2 + v2.^2 + g0.*(u-v2);
dVdt = [dudt; dv1dt; dv2dt];

function [value,isterminal,direction] = max_fun(t,V,vmax)
value = V - vmax;
isterminal = ones(2+1,1);
direction = ones(2+1,1);

