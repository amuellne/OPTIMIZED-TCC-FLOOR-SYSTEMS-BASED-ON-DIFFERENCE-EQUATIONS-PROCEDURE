function out4 = Function_tinf_B(params)
%%-------------------------------------------------------------------------
% Difference equations procedure for t=inf and
% load combination qEd = 1.35*(gk_t+gk_fw+gk_c+gk_fi)+1.5*qk (determination
% of gamma)
%%-------------------------------------------------------------------------

%% Input parameters and preliminary calculations---------------------------

% General
l = params.l;                      
increments = 24; % Number of increments of span l [-]
m = increments/2; % Number of rows and columns in the equation system [-]
Delta_x = l/increments; % Increment spacing [m]     
Delta_e = params.Delta_e;               

b_c = params.b_c;                
h_c = params.h_c;               
b_t = params.b_t;
h_t = params.h_t;

E_c_t0 = params.E_c_t0;             
E_t_t0 = params.E_t_t0;
E_comp = params.E_comp;

Kser_t0 = params.Kser_t0;
Ku_Kser = params.Ku_Kser;

% Load regime
unitweight_c = params.unitweight_c;       
unitweight_t = params.unitweight_t;       

gk_t = unitweight_t*(b_t*h_t)*10^-4; % Self weight timber line [kN/m]
gk_fw = unitweight_t*(b_c*Delta_e)*10^-4; % Self weight formwork line [kN/m]
gk_c = unitweight_c*(b_c*h_c)*10^-4; % Self weight concrete line [kN/m]
gk_fi = params.gk_fi;
gk_fi = gk_fi*(params.b_c)/100; % Load due to finishes line [kN/m]

qk = params.qk;    
qk = qk*(params.b_c)/100; % Liveload line [kN/m]

qEd = 1.35*(gk_t+gk_fw+gk_c+gk_fi)+1.5*qk; % Design load line [kN/m]

% Shear connectors
c_l0 = params.c_ser; % Joint stiffness at l=0 [kN/cm2]

if params.sc_arrangement == 1
    slope_k = c_l0/(l/2);    
elseif params.sc_arrangement == 2
    slope_k = 0;
elseif params.sc_arrangement == 3
    slope_k = c_l0*params.phi_c_ser_flipped/(l/2);
end

c=zeros(m,1);

for i = 1:m
    c(i,1) = c_l0-i*Delta_x*slope_k; % Resulting joint stiffnesses at increments [kN/cm2]
end

% Cross-section properties
A_c = b_c*h_c; % Cross-section area concrete [cm2]
I_c = (b_c*h_c^3)/12; % Geometrical moment of inertia concrete [cm4]
n_c = E_c_t0/E_comp; % Additional factor concrete [-]

A_t = b_t*h_t; % Cross-section area timber [cm2]
I_t = (b_t*h_t^3)/12; % Geometrical moment of inertia timber [cm4]
n_t = E_t_t0/E_comp; % Additional factor timber [-]

e_s = h_c/2+Delta_e+h_t/2; % Distance of the centers of gravity of the concrete and the timber component [cm]

S_s = e_s*(n_c*A_c*n_t*A_t)/(n_c*A_c+n_t*A_t); % Resulting static moment [cm3]
I_s = n_c*I_c+n_t*I_t+e_s*S_s; % Resulting geometrical moment of inertia [cm4]

% alpha and beta_quadrat for equtation system
alpha = zeros(m,1);
beta_quadrat = zeros(m,1);

for i = 1:m
    alpha(i,1) = (c(i,1)/E_comp*10^1)*(e_s/(n_c*I_c+n_t*I_t));
    beta_quadrat(i,1) = alpha(i,1)*I_s/S_s;
end

%% Definition and solution of the equation system for t, M_t and M_c-------

% Moment vector
M_ = zeros(m, 1);

for i = 1:m
    M_(i,1)=qEd/2*(l*i*Delta_x-(i*Delta_x)^2);
end

% Normal force vector
N_ = zeros(m,1);

% Solution vector
B = zeros(m,1);

for i = 1:m
    if i<m
    B(i,1)=alpha(i,1)*(Delta_x*100)^2*M_(i,1);
    else
    B(i,1)=0.5*alpha(i,1)*(Delta_x*100)^2*M_(i,1);  
    end
end

% Solution matrix
A = zeros(m, m);

% Fill diagonal of solution matrix
for i = 1:m
    if i<m
    A(i,i)=2+beta_quadrat(i,1)*((Delta_x*100)^2);
    else
    A(i,i)=1+0.5*beta_quadrat(i,1)*((Delta_x*100)^2);
    end
end

% Fill lower subdiagonal of solution matrix
for i = 2:m
    A(i,i-1)=-1;
end
    
% Fill upper subdiagonal of solution matrix
for i = 2:m
    A(i-1,i)=-1;
end   

% Solve equation system
N_ = inv(A)*B*100;

% Extension for support point
M = zeros(m+1,1);

for i = 1:m
    M(i+1,1)=M_(i,1);
    N(i+1,1)=N_(i,1);
end

% Shear flow t
t_ = zeros(m,1);

for i = 1:m-1
    if i == 1
    t_(i,1)=(0+N_(i+1,1))/(2*Delta_x*100); 
    else
    t_(i,1)=(-N_(i-1,1)+N_(i+1,1))/(2*Delta_x*100);
    end
end

t0 = (4*N_(1,1)-N_(2,1))/(2*Delta_x*100);

t = zeros(m+1,1);

t(1,1) = t0;

for i = 1:m
    t(i+1,1)=t_(i,1);
end

t2_ = flipud(t).*-1;

for i = 1:m
    t2(i,1)=t2_(i+1,1);
end

t_full = [t;t2];

% Difference moment Delta_M
Delta_M_= M_-N_.*(e_s/100);

% Moment in the timber component M_t
M_t_= Delta_M_*(n_t*I_t)/(n_c*I_c+n_t*I_t);

% Moment in the concrete component M_c
M_c_= Delta_M_*(n_c*I_c)/(n_c*I_c+n_t*I_t);

%% Definition and solution of the equation system for w--------------------

% Deflection vector
w_ = zeros(m,1);

% Solution vector
Bw = zeros(m,1);

for i = 1:m
    if i<m
    Bw(i,1)= M_t_(i,1)*(Delta_x*100)^2/(E_comp*n_t*I_t)*100;
    else
    Bw(i,1)= 0.5*M_t_(i,1)*(Delta_x*100)^2/(E_comp*n_t*I_t)*100; 
    end
end

% Solution matrix
Aw = zeros(m, m);

% Fill diagonal of solution matrix
for i = 1:m
    if i<m
    Aw(i,i)=2;
    else
    Aw(i,i)=1;
    end
end

% Fill lower subdiagonal of solution matrix
for i = 2:m
    Aw(i,i-1)=-1;
end
    
% Fill upper subdiagonal of solution matrix
for i = 2:m
    Aw(i-1,i)=-1;
end   

% Solve equation system
w_ = inv(Aw)*Bw*10;

% Extension for support point
w = zeros(m+1,1);

for i = 1:m
    w(i+1,1)=w_(i,1);
end

%% Determination of gamma--------------------------------------------------

% Boundary conditions
A_t_mm2 = A_t*100;
I_t_mm4 = I_t*10^4;
N_t = max(N_)*1000;
M_t = max(M_t_)*10^6;
z_t_mm = h_t*10/2;
z_c_mm = h_c*10/2;
z_mm = z_t_mm + z_c_mm + Delta_e*10;
A_c_mm2 = A_c*100;

gamma = (E_t_t0*A_t_mm2*E_t_t0*I_t_mm4*N_t)/(E_c_t0*A_c_mm2*(E_t_t0*A_t_mm2*M_t*z_mm-E_t_t0*I_t_mm4*N_t));

%%-------------------------------------------------------------------------
% Difference equations procedure for t=inf and
% load combination qEdqs = (gk_t+gk_fw+gk_c+gk_fi)+params.psi2*qk+pslD 
%%-------------------------------------------------------------------------

%% Input parameters and preliminary calculations---------------------------

% General parameters
phi_end_c = params.phi_end_c;
kdef = params.kdef;
psi_t = 1;
psi_sc = 1;

switch phi_end_c
    case 3.5
    switch kdef
    case 0.6
    psi_c = 2.6-0.8*gamma^2;
    case 0.8
    psi_c = 2.3-0.5*gamma^2.6;
    end
    case 2.5
    switch kdef
    case 0.6
    psi_c = 2.0-0.5*gamma^1.9;
    case 0.8
    psi_c = 1.8-0.3*gamma^2.5;
    end
end

E_c_tinf = E_c_t0/(1+psi_c*phi_end_c); %N/mm2
E_t_tinf = E_t_t0/(1+psi_t*kdef); %N/mm2

Delta_epsilon = params.Delta_epsilon;

CpslD = z_mm*pi^2*(E_c_tinf*A_c_mm2*E_t_tinf*A_t_mm2*gamma)/(((l*1000)^2)*(E_c_tinf*A_c_mm2+E_t_tinf*A_t_mm2));
pslD = Delta_epsilon*CpslD;
qEdqs = (gk_t+gk_fw+gk_c+gk_fi)+params.psi2*qk+pslD;
qqs = (gk_t+gk_fw+gk_c+gk_fi)+params.psi2*qk;

CIslD = (pslD+qqs)/((E_c_tinf*A_c_mm2+E_t_tinf*A_t_mm2)/(E_c_tinf*A_c_mm2*gamma+E_t_tinf*A_t_mm2)*pslD+qqs);

E_c_tinf = E_c_t0/(1+psi_c*phi_end_c)*CIslD;
E_t_tinf = E_t_t0/(1+psi_t*kdef)*CIslD;

% Shear connectors
c_l0 = params.c_ser/(1+psi_sc*2*kdef)*CIslD;

if params.sc_arrangement == 1
    slope_k = c_l0/(l/2);    
elseif params.sc_arrangement == 2
    slope_k = 0;
elseif params.sc_arrangement == 3
    slope_k = c_l0*params.phi_c_ser_flipped/(l/2);
end

c=zeros(m,1);

for i = 1:m
    c(i,1) = c_l0-i*Delta_x*slope_k;
end

% Cross-section properties
A_c = b_c*h_c; % Cross-section area concrete [cm2]
I_c = (b_c*h_c^3)/12; % Geometrical moment of inertia concrete [cm4]
n_c = E_c_tinf/E_comp; % Additional factor concrete [-]

A_t = b_t*h_t; % Cross-section area timber [cm2]
I_t = (b_t*h_t^3)/12; % Geometrical moment of inertia timber [cm4]
n_t = E_t_tinf/E_comp; % Additional factor timber [-]

e_s = h_c/2+Delta_e+h_t/2; % Distance of the centers of gravity of the concrete and the timber component [cm]

S_s = e_s*(n_c*A_c*n_t*A_t)/(n_c*A_c+n_t*A_t); % Resulting static moment [cm3]
I_s = n_c*I_c+n_t*I_t+e_s*S_s; % Resulting geometrical moment of inertia [cm4]

% alpha and beta_quadrat for equtation system
alpha = zeros(m,1);
beta_quadrat = zeros(m,1);

for i = 1:m
    alpha(i,1) = (c(i,1)/E_comp*10^1)*(e_s/(n_c*I_c+n_t*I_t));
    beta_quadrat(i,1) = alpha(i,1)*I_s/S_s;
end

%% Definition and solution of the equation system for t, M_t and M_c-------

% Moment vector
M_ = zeros(m, 1);

for i = 1:m
    M_(i,1)=qEd/2*(l*i*Delta_x-(i*Delta_x)^2);
end

% Normal force vector
N_ = zeros(m,1);

% Solution vector
B = zeros(m,1);

for i = 1:m
    if i<m
    B(i,1)=alpha(i,1)*(Delta_x*100)^2*M_(i,1);
    else
    B(i,1)=0.5*alpha(i,1)*(Delta_x*100)^2*M_(i,1);  
    end
end

% Solution matrix
A = zeros(m, m);

% Fill diagonal of solution matrix
for i = 1:m
    if i<m
    A(i,i)=2+beta_quadrat(i,1)*((Delta_x*100)^2);
    else
    A(i,i)=1+0.5*beta_quadrat(i,1)*((Delta_x*100)^2);
    end
end

% Fill lower subdiagonal of solution matrix
for i = 2:m
    A(i,i-1)=-1;
end
    
% Fill upper subdiagonal of solution matrix
for i = 2:m
    A(i-1,i)=-1;
end   

% Solve equation system
N_ = inv(A)*B*100;

% Extension for support point
M = zeros(m+1,1);

for i = 1:m
    M(i+1,1)=M_(i,1);
    N(i+1,1)=N_(i,1);
end

% Shear flow t
t_ = zeros(m,1);

for i = 1:m-1
    if i == 1
    t_(i,1)=(0+N_(i+1,1))/(2*Delta_x*100); 
    else
    t_(i,1)=(-N_(i-1,1)+N_(i+1,1))/(2*Delta_x*100);
    end
end

t0 = (4*N_(1,1)-N_(2,1))/(2*Delta_x*100);

t = zeros(m+1,1);

t(1,1) = t0;

for i = 1:m
    t(i+1,1)=t_(i,1);
end

t2_ = flipud(t).*-1;

for i = 1:m
    t2(i,1)=t2_(i+1,1);
end

t_full = [t;t2];

% Difference moment Delta_M
Delta_M_= M_-N_.*(e_s/100);

% Moment in the timber component M_t
M_t_= Delta_M_*(n_t*I_t)/(n_c*I_c+n_t*I_t);

% Moment in the concrete component M_c
M_c_= Delta_M_*(n_c*I_c)/(n_c*I_c+n_t*I_t);

%% Definition and solution of the equation system for w--------------------

% Deflection vector
w_ = zeros(m,1);

% Solution vector
Bw = zeros(m,1);

for i = 1:m
    if i<m
    Bw(i,1)= M_t_(i,1)*(Delta_x*100)^2/(E_comp*n_t*I_t)*100;
    else
    Bw(i,1)= 0.5*M_t_(i,1)*(Delta_x*100)^2/(E_comp*n_t*I_t)*100; 
    end
end

% Solution matrix
Aw = zeros(m, m);

% Fill diagonal of solution matrix
for i = 1:m
    if i<m
    Aw(i,i)=2;
    else
    Aw(i,i)=1;
    end
end

% Fill lower subdiagonal of solution matrix
for i = 2:m
    Aw(i,i-1)=-1;
end
    
% Fill upper subdiagonal of solution matrix
for i = 2:m
    Aw(i-1,i)=-1;
end   

% Solve equation system
w_ = inv(Aw)*Bw*10;

% Extension for support point
w = zeros(m+1,1);

for i = 1:m
    w(i+1,1)=w_(i,1);
end

%% Post-processing calculations - Proof_ovsyst_w_tinf----------------------

% Boundary conditions
wlim = params.l*100/250;

% Proof
wnetfin = max(w);
eta_ovsyst_w_tinf = wnetfin/wlim;

out4.Proof_ovsyst_w_tinf = eta_ovsyst_w_tinf;

end