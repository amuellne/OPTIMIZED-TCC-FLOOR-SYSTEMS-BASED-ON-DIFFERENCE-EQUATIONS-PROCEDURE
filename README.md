# OPTIMIZED-TCC-FLOOR-SYSTEMS-BASED-ON-DIFFERENCE-EQUATIONS-PROCEDURE
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
