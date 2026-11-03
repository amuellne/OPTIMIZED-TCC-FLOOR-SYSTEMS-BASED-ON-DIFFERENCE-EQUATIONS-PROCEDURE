%%-------------------------------------------------------------------------
% ALGORITHM FOR OPTIMIZED TCC FLOOR SYSTEMS BASED ON DIFFERENCE EQUATIONS
% PROCEDURE 
%%-------------------------------------------------------------------------
%
% REFERENCE:     Alex Muellner; Alireza Fadai.
%                'Optimization algorithm for cost- and resource-efficient
%                timber-concrete-composite floor systems'.
%                Manuscript in preparation for publication in MDPI
%                buildings, 2026.
%
% DESCRIPTION:   This algorithm is designed to identify optimized variants
%                of TCC floor systems with a contiuous compound, employing 
%                a brute-force approach based on the difference equations
%                procedure.
%                The program is structured around the main file
%                'Mainfile.m', which interacts with several additional
%                function files. The boundary conditions are defined in
%                'Mainfile.m'. The individual calculations of the internal
%                forces and deflections, based on the difference equation
%                procedure, are then carried out in the respective function
%                files. The resulting values are subsequently transferred
%                back to 'Mainfile.m' for further processing and plotting.
%
% AUTHOR:        Alex Muellner
% INSTITUTION:   Department of Structural Design and Timber Engineering,
%                Vienna University of Technology (TU Wien)
%
% VERSION:       1.0
% DATE:          2026-11-02
%
% COPYRIGHT:     Copyright (c) 2026 Alex Muellner
%                All rights reserved.
%
% LICENSE:       GNU GPL-3.0
%
% REQUIREMENTS:  MATLAB R2024b or later (backward compatibility not 
%                guaranteed). No additional toolboxes or libraries needed.
%
% NOTES:         Version 1.0 is explicitly designed for a uniformly
%                distributed load comprising a varying structural self
%                weight gk, a fixed load due to finishes gk,fi and one
%                leading live load qk. Deviations from this loading 
%                configuration can be implemented in the respective 
%                function files.
%                The plot properties in Version 1.0 are explicitly defined
%                for a specific example presented in the reference 
%                publication and must be manually adjusted to accommodate
%                varying boundary conditions.
%
%%-------------------------------------------------------------------------

close all;
clear all;
clc;

tic_total = tic;
tic_minimum = tic;

%% Latex interpreter-------------------------------------------------------

list_factory = fieldnames(get(groot,'factory'));
index_interpreter = find(contains(list_factory,'Interpreter'));
for i = 1:length(index_interpreter)
    default_name = strrep(list_factory{index_interpreter(i)},'factory','default');
    set(groot, default_name,'latex');
end

%% General Plot properties-------------------------------------------------

Color_blue = [0    0.3922    0.6588];
Color_blue_shaded = [0.8392    0.9373    1.0000];
Color_brown = [0.6431    0.4235    0.1569];
Color_brown_shaded = [0.9608    0.8902    0.8078];
Color_red = [0.6118    0.0392    0.1490];
Color_red_shaded = [1.0000    0.9098    0.9294];

Color_green = [0.1098       0.9098       0.1098];
Color_purple = [0.4471    0.2392    0.5804];
Color_gray = [0.8000    0.8000    0.8000];
Color_yellow = [1      0.82745      0.36078];

Linewidth = 1.1;

fig1handle = figure(1);
fig1handle.PaperUnits = 'normalized';
fig1handle.Color = [1,1,1];

fig1handle.Position(1)=400; % Left
fig1handle.Position(2)=400; % Bottom
fig1handle.Position(3)=940; % Width
fig1handle.Position(4)=700; % Height

ax1handle=axes;

%% Economical or ecological assessment properties--------------------------

CalculationType = 1; % 1=Calculation costs, 2=Calculation OI3_con-indices

Mesh_size = 100; % Bi-directional mesh size within the brute force computation (e.g. 100=fast - overall routine time about 5-10 sec., 200=medium fast - overall routine time about 20-30 sec., 1000=slow - overall routine time about 500-600 sec.)

%% Plot properties results-------------------------------------------------

IllustrationType = 3; % 1=only feasibility boundary, 2=only proof-related curves, 3=feasibility boundary and proof-related curves

%% System parameters and boundary conditions-------------------------------

% General parameters
params.E_comp = 10000; % Comparative elastic modulus [MPa]

params.psi0 = 0.7; % Combination factor [-]
params.psi2 = 0.3; % Combination factor [-]

% System parameters
params.l = 8; % Span [m]

% Paramters timber component
params.b_t = 14; % Timber width [cm]
h_t_min = 10; % Minimum timber height [cm]
h_t_max = 150; % Maximum timber height [cm]
params.Delta_e = 2.5; % Formwork height resp. distance between the concrete and timber component [cm]

params.E_t_t0 = 11500; % Elastic modulus timber at t=0 [MPa]

params.kmod = 0.8; % Modification factor [-]
params.kdef = 0.6; % Deformation factor [-]
params.kcr = 0.5; % Crack factor [-]
params.k37a = 1.25; % Increasing factor [-]

params.fmk = 24; % Bending tensile strength timber [MPa]
params.ft0k = 14; % Tensile strength timber [MPa]
params.fvk = 4; % Shear strength timber [MPa]
params.gamma_M_t = 1.3; % Partial safety factor timber [-]

% Parameters concrete component
params.b_c = 100; % Concrete width [cm]
params.h_c = 10; % Concrete height [cm]

params.E_c_t0 = 33000; % Elastic modulus concrete at t=0 [MPa]

params.phi_end_c = 3.5; % End creep coefficient concrete [-]

params.alpha_cc = 1.0; % Coefficient taking account of long-term effects on the compressive strength of concrete [-]
params.fck = 25; % Compressive strength concrete [MPa]
params.gamma_M_c = 1.5; % Partial safety factor concrete [-]

params.alpha_ct = 1.0; % Coefficient taking account of long-term effects on the tensile strength of concrete [-]
params.fctk = 2.2; % Tensile strength concrete [MPa]

params.Delta_epsilon = 0.0003; % Differential shrinkage factor concrete [-]

% Parameters shear connectors
params.sc_arrangement = 3; % Shear connector arrangement 1=linear (phi_c_ser = 0), 2=constant (phi_c_ser = 1), 3=variable (0 <= phi_c_ser <= 1)
params.phi_c_ser = 1; % Joint stiffness ratio if params.sc_arrangement = 3 (params.phi_c_ser = 0:0.1:1 possible)

s_min = 8; % Minimum distance between the shear connectors [cm]
s_max = 20; % Maximum distance between the shear connectors [cm]

params.Kser_t0 = 200; % SLS Slip modulus at t=0 [kN/cm]
params.Ku_Kser = 2/3; % Relation Ku/Kser [-]

params.FvRk = 13; % Characteristic connection shear strength [kN]
params.gamma_M_sc = 1.25; % Partial safety factor shear connectors [-]

% Paramters Costs
CO_sc = 4; % Costs shear connectors [€/pc]
CO_t = 990; % Costs timber [€/m3]
CO_c = 90; % Costs concrete [€/m3]
CO_re = 16; % Costs reinforcement [€/m2]
CO_fl = 50; % Costs floor construction [€/m2]

% Parameters load regime
params.unitweight_c = 25; % Unit weight concrete [kN/m3]
params.unitweight_t = 4.2; % Unit weight timber [kN/m3]
params.gk_fi = 3; % Load due to finishes area [kN/m2]
params.qk = 3; % Live load area [kN/m2]

% Parameters OI3_con-index
PENRT_sc = 0.744; % Primary energy non-renewable total shear connectors [MJ/pc]
GWP_sc = 0.0446; % Global warming potential shear connectors [kg/pc]
AP_sc = 0.000156; % Acidification potential shear connectors [kg/pc]

PENRT_t = 3.95; % Primary energy non-renewable total timber [MJ/kg]
GWP_t = -1.58; % Global warming potential timber [kg/kg]
AP_t = 0.00141; % Acidification potential timber [kg/kg]

PENRT_c_re = 1.14; % Primary energy non-renewable total reinforced concrete [MJ/kg]
GWP_c_re = 0.128; % Global warming potential reinforced concrete [kg/kg]
AP_c_re = 0.000304; % Acidification potential reinforced concrete [kg/kg]

PENRT_fl = 300; % Primary energy non-renewable total floor construction [MJ/m2]
GWP_fl = 22.5; % Global warming potential floor construction [kg/m2]
AP_fl = 0.085; % Acidification potential floor construction [kg/m2]

% Parameters overall system - vibration
params.h_screed = 8; % Screed height [cm]
params.b_ceiling = 5*params.b_c/100; % Ceiling width [m]

params.flim = 8; % Frequency limit [Hz]
params.wlim = 0.25; % Deflection limit [mm]
params.alim = 0.05; % Acceleration limit [m/s2]

params.f1min = 4.5; % Minimum frequency [Hz]
params.zeta = 0.03; % Damping ratio [-]

%% Preliminary calculations------------------------------------------------

% Parameters shear connectors
c_ser_min = params.Kser_t0/s_max; % Minimum joint stiffness [kN/cm2]
c_ser_max = params.Kser_t0/s_min; % Maximum joint stiffness [kN/cm2]

params.phi_c_ser_flipped = (1-params.phi_c_ser); % Flipped joint stiffness ratio if params.sc_arrangement = 3

if params.sc_arrangement == 1
    k0 = 1.0833; % Slope of a reference system
elseif params.sc_arrangement == 2
    k0 = 2;
elseif params.sc_arrangement == 3 && params.phi_c_ser_flipped == 0
    k0 = 2;   
elseif params.sc_arrangement == 3 && params.phi_c_ser_flipped == 0.1
    k0 = 1.9083;
elseif params.sc_arrangement == 3 && params.phi_c_ser_flipped == 0.2
    k0 = 1.8167;
elseif params.sc_arrangement == 3 && params.phi_c_ser_flipped == 0.3
    k0 = 1.725;
elseif params.sc_arrangement == 3 && params.phi_c_ser_flipped == 0.4
    k0 = 1.6333;
elseif params.sc_arrangement == 3 && params.phi_c_ser_flipped == 0.5
    k0 = 1.5417;
elseif params.sc_arrangement == 3 && params.phi_c_ser_flipped == 0.6
    k0 = 1.45;
elseif params.sc_arrangement == 3 && params.phi_c_ser_flipped == 0.7
    k0 = 1.3583;
elseif params.sc_arrangement == 3 && params.phi_c_ser_flipped == 0.8
    k0 = 1.2666;
elseif params.sc_arrangement == 3 && params.phi_c_ser_flipped == 0.9
    k0 = 1.1749;
elseif params.sc_arrangement == 3 && params.phi_c_ser_flipped == 1
    k0 = 1.0833;
else
end

% Paramters Costs
CO_t = CO_t*10^-6; % Costs timber [€/cm3]Function_t_0_A(para
CO_c = CO_c*10^-6; % Costs concrete [€/cm3]
CO_re = CO_re*10^-4; % Costs reinforcement [€/cm2]
CO_fl = CO_fl*10^-4; % Costs floor construction [€/cm2]

% Brute force boundary conditions
Delta_h_t = h_t_max-h_t_min;
Delta_c_ser = c_ser_max-c_ser_min;

%% Main computation with difference equations procedure (brute force)------

%% Calculation overall proof (feasibilty boundary)-------------------------

% Calculate related full spectrum of results-------------------------------
Results_overall = nan(Mesh_size+1,Mesh_size+1);
for j = 0:Mesh_size
    count=0;
    for i = Mesh_size:-1:0
        % Parameters for function(s)
        params.h_t = h_t_min+i*(Delta_h_t/Mesh_size);
        params.c_ser = c_ser_min+j*(Delta_c_ser/Mesh_size);
        % Access to function(s)
        out = Function_t0_A(params);
        out2 = Function_t0_B(params);
        out3 = Function_tinf_A(params);
        out4 = Function_tinf_B(params);
        % Results from function(s)
        Proof_sc_t0 = out.Proof_sc_t0;
        Proof_sc_tinf = out3.Proof_sc_tinf;
        Proof_c_comp_t0 = out.Proof_c_comp_t0;
        Proof_c_comp_tinf = out3.Proof_c_comp_tinf;
        Proof_ovsyst_w_t0 = out2.Proof_ovsyst_w_t0;
        Proof_ovsyst_w_tinf = out4.Proof_ovsyst_w_tinf;
        Proof_t_long_t0 = out.Proof_t_long_t0;
        Proof_t_long_tinf = out3.Proof_t_long_tinf;
        Proof_ovsyst_vib_t0 = out2.Proof_ovsyst_vib_t0;
        Proof_t_shear_tinf = out3.Proof_t_shear_tinf;
        if  CalculationType == 1 && (Proof_sc_t0 <= 1) && (Proof_sc_tinf <= 1) && (Proof_c_comp_t0 <= 1) && (Proof_c_comp_tinf <= 1) && (Proof_ovsyst_w_t0 <= 1) && (Proof_ovsyst_w_tinf <= 1) && (Proof_t_long_t0 <= 1) && (Proof_t_long_tinf <= 1) && (Proof_ovsyst_vib_t0 <= 1) && (Proof_t_shear_tinf <= 1); 
            Results_overall(i+1,j+1) = CO_sc*k0*params.l/4*params.c_ser+CO_t*params.b_t*params.l*100*params.h_t+CO_c*params.b_c*params.h_c*params.l*100+CO_re*params.b_c*params.l*100+CO_fl*params.b_c*params.l*100+CO_t*params.b_c*params.Delta_e*params.l*100;
        elseif CalculationType == 2 && (Proof_sc_t0 <= 1) && (Proof_sc_tinf <= 1) && (Proof_c_comp_t0 <= 1) && (Proof_c_comp_tinf <= 1) && (Proof_ovsyst_w_t0 <= 1) && (Proof_ovsyst_w_tinf <= 1) && (Proof_t_long_t0 <= 1) && (Proof_t_long_tinf <= 1) && (Proof_ovsyst_vib_t0 <= 1) && (Proof_t_shear_tinf <= 1);
            Results_overall(i+1,j+1) = 1/3*(0.1*(PENRT_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+PENRT_c_re*params.unitweight_c*params.h_c+PENRT_t*params.unitweight_t*params.Delta_e+PENRT_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+PENRT_fl-500)+0.5*(GWP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+GWP_c_re*params.unitweight_c*params.h_c+GWP_t*params.unitweight_t*params.Delta_e+GWP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+GWP_fl+50)+400*(AP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+AP_c_re*params.unitweight_c*params.h_c+AP_t*params.unitweight_t*params.Delta_e+AP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+AP_fl-0.21));
        else    
            break;
        end
    end

    % Cut to resultline----------------------------------------------------
    Results_overall_Line = zeros (3,Mesh_size+1);

    for i=1:size(Results_overall,1)

        k=0;

        for j=1:size(Results_overall,1)

            if k==0
                if isnan(Results_overall(j,i))

                else
                Results_overall_Line(1,i)=Results_overall(j,i);
                Results_overall_Line(2,i)=(j-1)*(h_t_max-h_t_min)/Mesh_size+h_t_min;
                Results_overall_Line(3,i)=(i-1)*(c_ser_max-c_ser_min)/Mesh_size+c_ser_min;
                    k=1;
                end
            end

        end
        k=0;
    end

end

%% Calculation and output of minimum---------------------------------------

% Calculation minimum------------------------------------------------------
minValue = min(Results_overall(:));
[row, column] = find(Results_overall == minValue);

Minimum = [(column-1)*Delta_c_ser/Mesh_size+c_ser_min, (row-1)*Delta_h_t/Mesh_size+h_t_min, minValue];

Time_minimum = toc(tic_minimum);

% Print minimum------------------------------------------------------------
fprintf('Minimum:\n');
fprintf('Joint stiffness c_{ser} = %.2f kN/cm2\n', Minimum(1));
fprintf('Timber height h_{t}     = %.2f cm\n', Minimum(2));
if CalculationType == 1
fprintf('Overall costs CO_{ov}   = %.2f €\n', Minimum(3));
elseif CalculationType == 2
fprintf('OI3_{con}-index         = %.2f pts\n', Minimum(3));   
end
fprintf('Time to find minimum    = %.2f sec\n', Time_minimum);

% Plot minimum-------------------------------------------------------------
plot3(Minimum(1,1),Minimum(1,2),Minimum(1,3),'o','Color','b','MarkerSize',7.5,'MarkerFaceColor','#D9FFFF');

hold on;

%% Calculation and output Proof shear connectors - resistance shear t=0----

% Calculate related full spectrum of results-------------------------------
Results = nan(Mesh_size+1,Mesh_size+1);
for j = 0:Mesh_size
    count=0;
    for i = Mesh_size:-1:0
        % Parameters for function(s)
        params.h_t = h_t_min+i*(Delta_h_t/Mesh_size);
        params.c_ser = c_ser_min+j*(Delta_c_ser/Mesh_size);
        % Access to function(s)
        out = Function_t0_A(params);
        % Results from function(s)
        Proof_sc_t0 = out.Proof_sc_t0;
        if  CalculationType == 1 && (Proof_sc_t0 <= 1); 
            Results(i+1,j+1) = CO_sc*k0*params.l/4*params.c_ser+CO_t*params.b_t*params.l*100*params.h_t+CO_c*params.b_c*params.h_c*params.l*100 + CO_re*params.b_c*params.l*100 + CO_fl*params.b_c*params.l*100+CO_t*params.b_c*params.Delta_e*params.l*100;
        elseif CalculationType == 2 && (Proof_sc_t0 <= 1);
            Results(i+1,j+1) = 1/3*(0.1*(PENRT_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+PENRT_c_re*params.unitweight_c*params.h_c+PENRT_t*params.unitweight_t*params.Delta_e+PENRT_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+PENRT_fl-500)+0.5*(GWP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+GWP_c_re*params.unitweight_c*params.h_c+GWP_t*params.unitweight_t*params.Delta_e+GWP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+GWP_fl+50)+400*(AP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+AP_c_re*params.unitweight_c*params.h_c+AP_t*params.unitweight_t*params.Delta_e+AP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+AP_fl-0.21));
        else     
            break;
        end
    end

    % Cut to resultline----------------------------------------------------
    Results_Line = zeros (3,Mesh_size+1);

    for i=1:size(Results,1)

        k=0;

        for j=1:size(Results,1)

            if k==0
                if isnan(Results(j,i))

                else
                Results_Line(1,i)=Results(j,i);
                Results_Line(2,i)=(j-1)*(h_t_max-h_t_min)/Mesh_size+h_t_min;
                Results_Line(3,i)=(i-1)*(c_ser_max-c_ser_min)/Mesh_size+c_ser_min;
                    k=1;
                end
            end

        end
        k=0;
    end

end

% Plot resultline----------------------------------------------------------
if IllustrationType == 2 || IllustrationType == 3
p1=plot3(Results_Line(3,:),Results_Line(2,:),Results_Line(1,:),'r','LineWidth',Linewidth);
elseif IllustrationType == 1
end

%% Calculation and output Proof shear connectors - resistance shear t=inf--

% Calculate related full spectrum of results-------------------------------
Results = nan(Mesh_size+1,Mesh_size+1);
for j = 0:Mesh_size
    count=0;
    for i = Mesh_size:-1:0
        % Parameters for function(s)
        params.h_t = h_t_min+i*(Delta_h_t/Mesh_size);
        params.c_ser = c_ser_min+j*(Delta_c_ser/Mesh_size);
        % Access to function(s)
        out3 = Function_tinf_A(params);
        % Results from function(s)
        Proof_sc_tinf = out3.Proof_sc_tinf;
        if  CalculationType == 1 && (Proof_sc_tinf <= 1); 
            Results(i+1,j+1) = CO_sc*k0*params.l/4*params.c_ser+CO_t*params.b_t*params.l*100*params.h_t+CO_c*params.b_c*params.h_c*params.l*100 + CO_re*params.b_c*params.l*100 + CO_fl*params.b_c*params.l*100+CO_t*params.b_c*params.Delta_e*params.l*100;
        elseif CalculationType == 2 && (Proof_sc_tinf <= 1);
            Results(i+1,j+1) = 1/3*(0.1*(PENRT_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+PENRT_c_re*params.unitweight_c*params.h_c+PENRT_t*params.unitweight_t*params.Delta_e+PENRT_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+PENRT_fl-500)+0.5*(GWP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+GWP_c_re*params.unitweight_c*params.h_c+GWP_t*params.unitweight_t*params.Delta_e+GWP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+GWP_fl+50)+400*(AP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+AP_c_re*params.unitweight_c*params.h_c+AP_t*params.unitweight_t*params.Delta_e+AP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+AP_fl-0.21));
        else
            break;
        end
    end

    % Cut to resultline----------------------------------------------------
    Results_Line = zeros (3,Mesh_size+1);

    for i=1:size(Results,1)

        k=0;

        for j=1:size(Results,1)

            if k==0
                if isnan(Results(j,i))

                else
                Results_Line(1,i)=Results(j,i);
                Results_Line(2,i)=(j-1)*(h_t_max-h_t_min)/Mesh_size+h_t_min;
                Results_Line(3,i)=(i-1)*(c_ser_max-c_ser_min)/Mesh_size+c_ser_min;
                    k=1;
                end
            end

        end
        k=0;
    end

end

% Plot resultline----------------------------------------------------------
if IllustrationType == 2 || IllustrationType == 3
p2=plot3(Results_Line(3,:),Results_Line(2,:),Results_Line(1,:),'--r','LineWidth',Linewidth);
elseif IllustrationType == 1
end

%% Calculation and output Proof concrete - stress compression t=0----------

% Calculate related full spectrum of results-------------------------------
Results = nan(Mesh_size+1,Mesh_size+1);
for j = 0:Mesh_size
    count=0;
    for i = Mesh_size:-1:0
        % Parameters for function(s)
        params.h_t = h_t_min+i*(Delta_h_t/Mesh_size);
        params.c_ser = c_ser_min+j*(Delta_c_ser/Mesh_size);
        % Access to function(s)
        out = Function_t0_A(params);
        % Results from function(s)
        Proof_c_comp_t0 = out.Proof_c_comp_t0;
        if  CalculationType == 1 && (Proof_c_comp_t0 <= 1); 
            Results(i+1,j+1) = CO_sc*k0*params.l/4*params.c_ser+CO_t*params.b_t*params.l*100*params.h_t+CO_c*params.b_c*params.h_c*params.l*100 + CO_re*params.b_c*params.l*100 + CO_fl*params.b_c*params.l*100+CO_t*params.b_c*params.Delta_e*params.l*100;
        elseif CalculationType == 2 && (Proof_c_comp_t0 <= 1);
            Results(i+1,j+1) = 1/3*(0.1*(PENRT_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+PENRT_c_re*params.unitweight_c*params.h_c+PENRT_t*params.unitweight_t*params.Delta_e+PENRT_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+PENRT_fl-500)+0.5*(GWP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+GWP_c_re*params.unitweight_c*params.h_c+GWP_t*params.unitweight_t*params.Delta_e+GWP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+GWP_fl+50)+400*(AP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+AP_c_re*params.unitweight_c*params.h_c+AP_t*params.unitweight_t*params.Delta_e+AP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+AP_fl-0.21));
        else
            break;
        end
    end

    % Cut to resultline----------------------------------------------------
    Results_Line = zeros (3,Mesh_size+1);

    for i=1:size(Results,1)

        k=0;

        for j=1:size(Results,1)

            if k==0
                if isnan(Results(j,i))

                else
                Results_Line(1,i)=Results(j,i);
                Results_Line(2,i)=(j-1)*(h_t_max-h_t_min)/Mesh_size+h_t_min;
                Results_Line(3,i)=(i-1)*(c_ser_max-c_ser_min)/Mesh_size+c_ser_min;
                    k=1;
                end
            end

        end
        k=0;
    end

end

% Plot resultline----------------------------------------------------------
if IllustrationType == 2 || IllustrationType == 3
p3=plot3(Results_Line(3,:),Results_Line(2,:),Results_Line(1,:),'color',Color_yellow,'LineWidth',Linewidth);
elseif IllustrationType == 1
end

%% Calculation and output Proof concrete - stress compression t=inf--------

% Calculate related full spectrum of results-------------------------------
Results = nan(Mesh_size+1,Mesh_size+1);
for j = 0:Mesh_size
    count=0;
    for i = Mesh_size:-1:0
        % Parameters for function(s)
        params.h_t = h_t_min+i*(Delta_h_t/Mesh_size);
        params.c_ser = c_ser_min+j*(Delta_c_ser/Mesh_size);
        % Access to function(s)
        out3 = Function_tinf_A(params);
        % Results from function(s)
        Proof_c_comp_tinf = out3.Proof_c_comp_tinf;
        if  CalculationType == 1 && (Proof_c_comp_tinf <= 1); 
            Results(i+1,j+1) = CO_sc*k0*params.l/4*params.c_ser+CO_t*params.b_t*params.l*100*params.h_t+CO_c*params.b_c*params.h_c*params.l*100 + CO_re*params.b_c*params.l*100 + CO_fl*params.b_c*params.l*100+CO_t*params.b_c*params.Delta_e*params.l*100;
        elseif CalculationType == 2 && (Proof_c_comp_tinf <= 1);
            Results(i+1,j+1) = 1/3*(0.1*(PENRT_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+PENRT_c_re*params.unitweight_c*params.h_c+PENRT_t*params.unitweight_t*params.Delta_e+PENRT_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+PENRT_fl-500)+0.5*(GWP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+GWP_c_re*params.unitweight_c*params.h_c+GWP_t*params.unitweight_t*params.Delta_e+GWP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+GWP_fl+50)+400*(AP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+AP_c_re*params.unitweight_c*params.h_c+AP_t*params.unitweight_t*params.Delta_e+AP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+AP_fl-0.21));
        else
            break;
        end
    end

    % Cut to resultline----------------------------------------------------
    Results_Line = zeros (3,Mesh_size+1);

    for i=1:size(Results,1)

        k=0;

        for j=1:size(Results,1)

            if k==0
                if isnan(Results(j,i))

                else
                Results_Line(1,i)=Results(j,i);
                Results_Line(2,i)=(j-1)*(h_t_max-h_t_min)/Mesh_size+h_t_min;
                Results_Line(3,i)=(i-1)*(c_ser_max-c_ser_min)/Mesh_size+c_ser_min;
                    k=1;
                end
            end

        end
        k=0;
    end

end

% Plot resultline----------------------------------------------------------
if IllustrationType == 2 || IllustrationType == 3
p4=plot3(Results_Line(3,:),Results_Line(2,:),Results_Line(1,:),'--','color',Color_yellow,'LineWidth',Linewidth);
elseif IllustrationType == 1
end

%% Calculation and output Proof timber - stress longitudinal t=0-----------

% Calculate related full spectrum of results-------------------------------
Results = nan(Mesh_size+1,Mesh_size+1);
for j = 0:Mesh_size
    count=0;
    for i = Mesh_size:-1:0
        % Parameters for function(s)
        params.h_t = h_t_min+i*(Delta_h_t/Mesh_size);
        params.c_ser = c_ser_min+j*(Delta_c_ser/Mesh_size);
        % Access to function(s)
        out = Function_t0_A(params);
        % Results from function(s)
        Proof_t_long_t0 = out.Proof_t_long_t0;
        if  CalculationType == 1 && (Proof_t_long_t0 <= 1); 
            Results(i+1,j+1) = CO_sc*k0*params.l/4*params.c_ser+CO_t*params.b_t*params.l*100*params.h_t+CO_c*params.b_c*params.h_c*params.l*100 + CO_re*params.b_c*params.l*100 + CO_fl*params.b_c*params.l*100+CO_t*params.b_c*params.Delta_e*params.l*100;
        elseif CalculationType == 2 && (Proof_t_long_t0 <= 1);
            Results(i+1,j+1) = 1/3*(0.1*(PENRT_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+PENRT_c_re*params.unitweight_c*params.h_c+PENRT_t*params.unitweight_t*params.Delta_e+PENRT_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+PENRT_fl-500)+0.5*(GWP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+GWP_c_re*params.unitweight_c*params.h_c+GWP_t*params.unitweight_t*params.Delta_e+GWP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+GWP_fl+50)+400*(AP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+AP_c_re*params.unitweight_c*params.h_c+AP_t*params.unitweight_t*params.Delta_e+AP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+AP_fl-0.21));
        else
            break;
        end
    end

    % Cut to resultline----------------------------------------------------
    Results_Line = zeros (3,Mesh_size+1);

    for i=1:size(Results,1)

        k=0;

        for j=1:size(Results,1)

            if k==0
                if isnan(Results(j,i))

                else
                Results_Line(1,i)=Results(j,i);
                Results_Line(2,i)=(j-1)*(h_t_max-h_t_min)/Mesh_size+h_t_min;
                Results_Line(3,i)=(i-1)*(c_ser_max-c_ser_min)/Mesh_size+c_ser_min;
                    k=1;
                end
            end

        end
        k=0;
    end

end

% Plot resultline----------------------------------------------------------
if IllustrationType == 2 || IllustrationType == 3
p5=plot3(Results_Line(3,:),Results_Line(2,:),Results_Line(1,:),'m','LineWidth',Linewidth);
elseif IllustrationType == 1
end

%% Calculation and output Proof timber - stress longitudinal t=inf---------

% Calculate related full spectrum of results-------------------------------
Results = nan(Mesh_size+1,Mesh_size+1);
for j = 0:Mesh_size
    count=0;
    for i = Mesh_size:-1:0
        % Parameters for function(s)
        params.h_t = h_t_min+i*(Delta_h_t/Mesh_size);
        params.c_ser = c_ser_min+j*(Delta_c_ser/Mesh_size);
        % Access to function(s)
        out3 = Function_tinf_A(params);
        % Results from function(s)
        Proof_t_long_tinf = out3.Proof_t_long_tinf;
        if  CalculationType == 1 && (Proof_t_long_tinf <= 1); 
            Results(i+1,j+1) = CO_sc*k0*params.l/4*params.c_ser+CO_t*params.b_t*params.l*100*params.h_t+CO_c*params.b_c*params.h_c*params.l*100 + CO_re*params.b_c*params.l*100 + CO_fl*params.b_c*params.l*100+CO_t*params.b_c*params.Delta_e*params.l*100;
        elseif CalculationType == 2 && (Proof_t_long_tinf <= 1);
            Results(i+1,j+1) = 1/3*(0.1*(PENRT_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+PENRT_c_re*params.unitweight_c*params.h_c+PENRT_t*params.unitweight_t*params.Delta_e+PENRT_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+PENRT_fl-500)+0.5*(GWP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+GWP_c_re*params.unitweight_c*params.h_c+GWP_t*params.unitweight_t*params.Delta_e+GWP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+GWP_fl+50)+400*(AP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+AP_c_re*params.unitweight_c*params.h_c+AP_t*params.unitweight_t*params.Delta_e+AP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+AP_fl-0.21));
        else
            break;
        end
    end

    % Cut to resultline----------------------------------------------------
    Results_Line = zeros (3,Mesh_size+1);

    for i=1:size(Results,1)

        k=0;

        for j=1:size(Results,1)

           if k==0
                if isnan(Results(j,i))

                else
                Results_Line(1,i)=Results(j,i);
                Results_Line(2,i)=(j-1)*(h_t_max-h_t_min)/Mesh_size+h_t_min;
                Results_Line(3,i)=(i-1)*(c_ser_max-c_ser_min)/Mesh_size+c_ser_min;
                    k=1;
                end
            end

        end
        k=0;
    end

end

% Plot resultline----------------------------------------------------------
if IllustrationType == 2 || IllustrationType == 3
p6=plot3(Results_Line(3,:),Results_Line(2,:),Results_Line(1,:),'--m','LineWidth',Linewidth);
elseif IllustrationType == 1
end

%% Calculation and output Proof timber - stress shear t=0------------------

% Calculate related full spectrum of results-------------------------------
Results = nan(Mesh_size+1,Mesh_size+1);
for j = 0:Mesh_size
    count=0;
    for i = Mesh_size:-1:0
        % Parameters for function(s)
        params.h_t = h_t_min+i*(Delta_h_t/Mesh_size);
        params.c_ser = c_ser_min+j*(Delta_c_ser/Mesh_size);
        % Access to function(s)
        out = Function_t0_A(params);
        % Results from function(s)
        Proof_t_shear_t0 = out.Proof_t_shear_t0;
        if  CalculationType == 1 && (Proof_t_shear_t0 <= 1); 
            Results(i+1,j+1) = CO_sc*k0*params.l/4*params.c_ser+CO_t*params.b_t*params.l*100*params.h_t+CO_c*params.b_c*params.h_c*params.l*100 + CO_re*params.b_c*params.l*100 + CO_fl*params.b_c*params.l*100+CO_t*params.b_c*params.Delta_e*params.l*100;
        elseif CalculationType == 2 && (Proof_t_shear_t0 <= 1);
            Results(i+1,j+1) = 1/3*(0.1*(PENRT_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+PENRT_c_re*params.unitweight_c*params.h_c+PENRT_t*params.unitweight_t*params.Delta_e+PENRT_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+PENRT_fl-500)+0.5*(GWP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+GWP_c_re*params.unitweight_c*params.h_c+GWP_t*params.unitweight_t*params.Delta_e+GWP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+GWP_fl+50)+400*(AP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+AP_c_re*params.unitweight_c*params.h_c+AP_t*params.unitweight_t*params.Delta_e+AP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+AP_fl-0.21));
        else
            break;
        end
    end

    % Cut to resultline----------------------------------------------------
    Results_Line = zeros (3,Mesh_size+1);

    for i=1:size(Results,1)

        k=0;

        for j=1:size(Results,1)

            if k==0
                if isnan(Results(j,i))

                else
                Results_Line(1,i)=Results(j,i);
                Results_Line(2,i)=(j-1)*(h_t_max-h_t_min)/Mesh_size+h_t_min;
                Results_Line(3,i)=(i-1)*(c_ser_max-c_ser_min)/Mesh_size+c_ser_min;
                    k=1;
                end
            end

        end
        k=0;
    end

end

% Plot resultline----------------------------------------------------------
if IllustrationType == 2 || IllustrationType == 3
p7=plot3(Results_Line(3,:),Results_Line(2,:),Results_Line(1,:),'color',Color_green,'LineWidth',Linewidth);
elseif IllustrationType == 1
end

%% Calculation and output Proof timber - stress shear t=inf----------------

% Calculate related full spectrum of results-------------------------------
Results = nan(Mesh_size+1,Mesh_size+1);
for j = 0:Mesh_size
    count=0;
    for i = Mesh_size:-1:0
        % Parameters for function(s)
        params.h_t = h_t_min+i*(Delta_h_t/Mesh_size);
        params.c_ser = c_ser_min+j*(Delta_c_ser/Mesh_size);
        % Access to function(s)
        out3 = Function_tinf_A(params);
        % Results from function(s)
        Proof_t_shear_tinf = out3.Proof_t_shear_tinf;
        if  CalculationType == 1 && (Proof_t_shear_tinf <= 1); 
            Results(i+1,j+1) = CO_sc*k0*params.l/4*params.c_ser+CO_t*params.b_t*params.l*100*params.h_t+CO_c*params.b_c*params.h_c*params.l*100 + CO_re*params.b_c*params.l*100 + CO_fl*params.b_c*params.l*100+CO_t*params.b_c*params.Delta_e*params.l*100;
        elseif CalculationType == 2 && (Proof_t_shear_tinf <= 1);
            Results(i+1,j+1) = 1/3*(0.1*(PENRT_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+PENRT_c_re*params.unitweight_c*params.h_c+PENRT_t*params.unitweight_t*params.Delta_e+PENRT_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+PENRT_fl-500)+0.5*(GWP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+GWP_c_re*params.unitweight_c*params.h_c+GWP_t*params.unitweight_t*params.Delta_e+GWP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+GWP_fl+50)+400*(AP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+AP_c_re*params.unitweight_c*params.h_c+AP_t*params.unitweight_t*params.Delta_e+AP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+AP_fl-0.21));
        else
            break;
        end
    end

    % Cut to resultline----------------------------------------------------
    Results_Line = zeros (3,Mesh_size+1);

    for i=1:size(Results,1)

        k=0;

        for j=1:size(Results,1)

            if k==0
                if isnan(Results(j,i))

                else
                Results_Line(1,i)=Results(j,i);
                Results_Line(2,i)=(j-1)*(h_t_max-h_t_min)/Mesh_size+h_t_min;
                Results_Line(3,i)=(i-1)*(c_ser_max-c_ser_min)/Mesh_size+c_ser_min;
                    k=1;
                end
            end

        end
        k=0;
    end

end

% Plot resultline----------------------------------------------------------
if IllustrationType == 2 || IllustrationType == 3
p8=plot3(Results_Line(3,:),Results_Line(2,:),Results_Line(1,:),'--','color',Color_green,'LineWidth',Linewidth);
elseif IllustrationType == 1
end

%% Calculation and output Proof overall system - deflection t=0------------

% Calculate related full spectrum of results-------------------------------
Results = nan(Mesh_size+1,Mesh_size+1);
for j = 0:Mesh_size
    count=0;
    for i = Mesh_size:-1:0
        % Parameters for function(s)
        params.h_t = h_t_min+i*(Delta_h_t/Mesh_size);
        params.c_ser = c_ser_min+j*(Delta_c_ser/Mesh_size);
        % Access to function(s)
        out = Function_t0_A(params);
        out2 = Function_t0_B(params);
        % Results from function(s)
        Proof_ovsyst_w_t0 = out2.Proof_ovsyst_w_t0;      
        if  CalculationType == 1 && (Proof_ovsyst_w_t0 <= 1); 
            Results(i+1,j+1) = CO_sc*k0*params.l/4*params.c_ser+CO_t*params.b_t*params.l*100*params.h_t+CO_c*params.b_c*params.h_c*params.l*100 + CO_re*params.b_c*params.l*100 + CO_fl*params.b_c*params.l*100+CO_t*params.b_c*params.Delta_e*params.l*100;
        elseif CalculationType == 2 && (Proof_ovsyst_w_t0 <= 1);
            Results(i+1,j+1) = 1/3*(0.1*(PENRT_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+PENRT_c_re*params.unitweight_c*params.h_c+PENRT_t*params.unitweight_t*params.Delta_e+PENRT_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+PENRT_fl-500)+0.5*(GWP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+GWP_c_re*params.unitweight_c*params.h_c+GWP_t*params.unitweight_t*params.Delta_e+GWP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+GWP_fl+50)+400*(AP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+AP_c_re*params.unitweight_c*params.h_c+AP_t*params.unitweight_t*params.Delta_e+AP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+AP_fl-0.21));
        else
            break;
        end
    end

    % Cut to resultline----------------------------------------------------
    Results_Line = zeros (3,Mesh_size+1);

    for i=1:size(Results,1)

        k=0;

        for j=1:size(Results,1)

            if k==0
                if isnan(Results(j,i))

                else
                Results_Line(1,i)=Results(j,i);
                Results_Line(2,i)=(j-1)*(h_t_max-h_t_min)/Mesh_size+h_t_min;
                Results_Line(3,i)=(i-1)*(c_ser_max-c_ser_min)/Mesh_size+c_ser_min;
                    k=1;
                end
            end

        end
        k=0;
    end

end

% Plot resultline----------------------------------------------------------
if IllustrationType == 2 || IllustrationType == 3
p9=plot3(Results_Line(3,:),Results_Line(2,:),Results_Line(1,:),'k','LineWidth',Linewidth);
elseif IllustrationType == 1
end

%% Calculation and output Proof overall system - deflection t=inf----------

% Calculate related full spectrum of results-------------------------------
Results = nan(Mesh_size+1,Mesh_size+1);
for j = 0:Mesh_size
    count=0;
    for i = Mesh_size:-1:0
        % Parameters for function(s)
        params.h_t = h_t_min+i*(Delta_h_t/Mesh_size);
        params.c_ser = c_ser_min+j*(Delta_c_ser/Mesh_size);
        % Access to function(s)
        out4 = Function_tinf_B(params);
        % Results from function(s)
        Proof_ovsyst_w_tinf = out4.Proof_ovsyst_w_tinf;      
        if  CalculationType == 1 && (Proof_ovsyst_w_tinf <= 1); 
            Results(i+1,j+1) = CO_sc*k0*params.l/4*params.c_ser+CO_t*params.b_t*params.l*100*params.h_t+CO_c*params.b_c*params.h_c*params.l*100 + CO_re*params.b_c*params.l*100 + CO_fl*params.b_c*params.l*100+CO_t*params.b_c*params.Delta_e*params.l*100;
        elseif CalculationType == 2 && (Proof_ovsyst_w_tinf <= 1);
            Results(i+1,j+1) = 1/3*(0.1*(PENRT_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+PENRT_c_re*params.unitweight_c*params.h_c+PENRT_t*params.unitweight_t*params.Delta_e+PENRT_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+PENRT_fl-500)+0.5*(GWP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+GWP_c_re*params.unitweight_c*params.h_c+GWP_t*params.unitweight_t*params.Delta_e+GWP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+GWP_fl+50)+400*(AP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+AP_c_re*params.unitweight_c*params.h_c+AP_t*params.unitweight_t*params.Delta_e+AP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+AP_fl-0.21));
        else
            break;
        end
    end

    % Cut to resultline----------------------------------------------------
    Results_Line = zeros (3,Mesh_size+1);

    for i=1:size(Results,1)

        k=0;

        for j=1:size(Results,1)

            if k==0
                if isnan(Results(j,i))

                else
                Results_Line(1,i)=Results(j,i);
                Results_Line(2,i)=(j-1)*(h_t_max-h_t_min)/Mesh_size+h_t_min;
                Results_Line(3,i)=(i-1)*(c_ser_max-c_ser_min)/Mesh_size+c_ser_min;
                    k=1;
                end
            end

        end
        k=0;
    end

end

% Plot resultline----------------------------------------------------------
if IllustrationType == 2 || IllustrationType == 3
p10=plot3(Results_Line(3,:),Results_Line(2,:),Results_Line(1,:),'--k','LineWidth',Linewidth);
elseif IllustrationType == 1
end

%% Calculation and output Proof overall system - vibration t=0-------------

% Calculate related full spectrum of results-------------------------------
Results = nan(Mesh_size+1,Mesh_size+1);
for j = 0:Mesh_size
    count=0;
    for i = Mesh_size:-1:0
        % Parameters for function(s)
        params.h_t = h_t_min+i*(Delta_h_t/Mesh_size);
        params.c_ser = c_ser_min+j*(Delta_c_ser/Mesh_size);
        % Access to function(s)
        out2 = Function_t0_B(params);
        % Results from function(s)
        Proof_ovsyst_vib_t0 = out2.Proof_ovsyst_vib_t0;
        if  CalculationType == 1 && (Proof_ovsyst_vib_t0 <= 1); 
            Results(i+1,j+1) = CO_sc*k0*params.l/4*params.c_ser+CO_t*params.b_t*params.l*100*params.h_t+CO_c*params.b_c*params.h_c*params.l*100 + CO_re*params.b_c*params.l*100 + CO_fl*params.b_c*params.l*100+CO_t*params.b_c*params.Delta_e*params.l*100;
        elseif CalculationType == 2 && (Proof_ovsyst_vib_t0 <= 1);
            Results(i+1,j+1) = 1/3*(0.1*(PENRT_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+PENRT_c_re*params.unitweight_c*params.h_c+PENRT_t*params.unitweight_t*params.Delta_e+PENRT_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+PENRT_fl-500)+0.5*(GWP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+GWP_c_re*params.unitweight_c*params.h_c+GWP_t*params.unitweight_t*params.Delta_e+GWP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+GWP_fl+50)+400*(AP_t*params.unitweight_t*params.h_t*params.b_t/(100*(params.b_c/100))+AP_c_re*params.unitweight_c*params.h_c+AP_t*params.unitweight_t*params.Delta_e+AP_sc*k0*params.l/4*params.c_ser/(params.b_c/100*params.l)+AP_fl-0.21));
        else
            break;
        end
    end

    % Cut to resultline----------------------------------------------------
    Results_Line = zeros (3,Mesh_size+1);

    for i=1:size(Results,1)

        k=0;

        for j=1:size(Results,1)

            if k==0
                if isnan(Results(j,i))

                else
                Results_Line(1,i)=Results(j,i);
                Results_Line(2,i)=(j-1)*(h_t_max-h_t_min)/Mesh_size+h_t_min;
                Results_Line(3,i)=(i-1)*(c_ser_max-c_ser_min)/Mesh_size+c_ser_min;
                    k=1;
                end
            end

        end
        k=0;
    end

end

% Plot resultline----------------------------------------------------------
if IllustrationType == 2 || IllustrationType == 3
p11=plot3(Results_Line(3,:),Results_Line(2,:),Results_Line(1,:),'color',Color_gray,'LineWidth',Linewidth);
elseif IllustrationType == 1
end

%% Output overall proof (feasibilty boundary)------------------------------

% Plot resultline----------------------------------------------------------
if IllustrationType == 1 || IllustrationType == 3
p12=plot3(Results_overall_Line(3,:),Results_overall_Line(2,:),Results_overall_Line(1,:),'-','Color','k','LineWidth',Linewidth+0.5);
elseif IllustrationType == 2
end
   
%% Overall plot------------------------------------------------------------

% Generate plot values for full solution set-------------------------------
x=c_ser_min:.1:c_ser_max;
y=h_t_min:.5:h_t_max;

[X,Y] = meshgrid(x,y);

if CalculationType == 1
    Z = CO_sc*k0*params.l/4.*X+CO_t*params.b_t*params.l*100.*Y+CO_c*params.b_c*params.h_c*params.l*100 + CO_re*params.b_c*params.l*100 + CO_fl*params.b_c*params.l*100 + CO_t*params.b_c*params.Delta_e*params.l*100;
elseif CalculationType == 2
    Z = 1/3*(0.1*(PENRT_t*params.unitweight_t.*Y*params.b_t/(100*(params.b_c/100))+PENRT_c_re*params.unitweight_c*params.h_c+PENRT_t*params.unitweight_t*params.Delta_e+PENRT_sc*k0*params.l/4.*X/(params.b_c/100*params.l)+PENRT_fl-500)+0.5*(GWP_t*params.unitweight_t.*Y*params.b_t/(100*(params.b_c/100))+GWP_c_re*params.unitweight_c*params.h_c+GWP_t*params.unitweight_t*params.Delta_e+GWP_sc*k0*params.l/4.*X/(params.b_c/100*params.l)+GWP_fl+50)+400*(AP_t*params.unitweight_t.*Y*params.b_t/(100*(params.b_c/100))+AP_c_re*params.unitweight_c*params.h_c+AP_t*params.unitweight_t*params.Delta_e+AP_sc*k0*params.l/4.*X/(params.b_c/100*params.l)+AP_fl-0.21));
end

% Generate plot values for feasible and infeasible solution sets-----------
z_line = Results_overall_Line(1,:);
y_line = Results_overall_Line(2,:);
x_line = Results_overall_Line(3,:);

Yline = interp1(x_line,y_line,X,'linear',NaN);

mask_below = Y <= Yline+0.5;
mask_above = Y > Yline-0.5;

Z_upper = Z;
Z_upper(~mask_above) = NaN;

Z_lower = Z;
Z_lower(~mask_below) = NaN;

% Plot infeasible solution set---------------------------------------------
h_lower = surf(ax1handle,X,Y,Z_lower);

set(h_lower,...
    'FaceColor',[0.6 0.6 0.6],...
    'EdgeColor','none');

% Plot feasible solution set-----------------------------------------------
h_upper = surf(ax1handle,X,Y,Z_upper,Z_upper);

set(h_upper,...
    'FaceColor','interp',...
    'EdgeColor','none');

% Set colormap properties--------------------------------------------------
colormap(ax1handle,parula);
view(-37.5, 30);
alpha 1;
grid on;

% Set axis properties------------------------------------------------------
xlim([c_ser_min c_ser_max]);
ylim([h_t_min h_t_max]);

kticks = [floor(c_ser_min)+1:1:floor(c_ser_max)-1];
kticks = vertcat(c_ser_min,transpose(kticks),c_ser_max);
xticks(kticks);

hticks = [h_t_min:10:h_t_max];
yticks(hticks);

if CalculationType == 1
    zmin=800;
    zmax=3000;
    zticks(800:200:3000);
    zlim([zmin zmax]);
    xlabel({'Joint stiffness $c_{ser}$ [kN/cm$^2$]';' based on $K_{ser}$(t=0)'},'rotation', 21, 'Position', [17.0,-8,zmin]);
    ylabel('Timber height $h_{t}$ [cm]','rotation',-32, 'Position', [8,75,zmin]);
    zlabel('Overall Costs $CO_{ov}$ [Euro]');
elseif CalculationType == 2
    zmin=14.5;
    zmax=20;
    zticks(14:0.5:20);
    zlim([zmin zmax]);
    xlabel({'Joint stiffness $c_{ser}$ [kN/cm$^2$]';' based on $K_{ser}$(t=0)'},'rotation', 21, 'Position', [17.0,-8,zmin]);
    ylabel('Timber height $h_{t}$ [cm]','rotation',-32, 'Position', [8,75,zmin]);
    zlabel('$OI3_{con}$-index [pts]');
end

% Set legend properties----------------------------------------------------
if IllustrationType == 1
leg1=legend([p12],'\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,Feasibility boundary\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,\,','Location','eastoutside','FontSize',9);
elseif IllustrationType == 2
leg1=legend([p1 p2 p3 p4 p5 p6 p7 p8 p9 p10 p11],'Shear connectors - resistance shear $t=0$',...
    'Shear connectors - resistance shear $t=\infty$',...
    'Concrete - stress compression $t=0$',...
    'Concrete - stress compression $t=\infty$',...
    'Timber - stress longitudinal $t=0$',...
    'Timber - stress longitudinal $t=\infty$',...
    'Timber - stress shear $t=0$',...
    'Timber - stress shear $t=\infty$',...
    'Overall system - deflection $t=0$',...
    'Overall system - deflection $t=\infty$',...
    'Overall system - vibration $t=0$',...
    'Location','eastoutside','FontSize',9);
elseif IllustrationType == 3
leg1=legend([p1 p2 p3 p4 p5 p6 p7 p8 p9 p10 p11 p12],'Shear connectors - resistance shear $t=0$',...
    'Shear connectors - resistance shear $t=\infty$',...
    'Concrete - stress compression $t=0$',...
    'Concrete - stress compression $t=\infty$',...
    'Timber - stress longitudinal $t=0$',...
    'Timber - stress longitudinal $t=\infty$',...
    'Timber - stress shear $t=0$',...
    'Timber - stress shear $t=\infty$',...
    'Overall system - deflection $t=0$',...
    'Overall system - deflection $t=\infty$',...
    'Overall system - vibration $t=0$',...
    'Feasibility boundary',...
    'Location','eastoutside','FontSize',9);
end
leg1.NumColumns = 1;
leg1.ItemTokenSize = [15,15];

Time_overall = toc(tic_total);
Time_plot = Time_overall-Time_minimum;

fprintf('Time to plot            = %.2f sec\n', Time_plot);
fprintf('Overall time            = %.2f sec\n', Time_overall);

clearvars -except Minimum;