function params = h2_params()
%H2_PARAMS Parameter set for the GM 2027 offshore H2 network model.
%
% The values below are deliberately separated from the synthetic case so a
% future North Sea case can replace topology, distances, demand, wind, and
% CMEMS temperature without touching the physical or dispatch model.

%% Run metadata
params.meta.project = 'IEEE PES GM 2027 offshore hydrogen';
params.meta.stage = 'v1_synthetic_temperature_driven_pipeline_constraints';
params.meta.T = 24;
params.meta.dt_h = 1.0;

%% Units
params.units.temperature = 'degC';
params.units.pressure = 'Pa';
params.units.mass_flow = 'kg/s in physical layer; kg/h in dispatch layer';
params.units.energy = 'MWh';

%% Hydrogen constants
params.h2.molar_mass_kg_mol = 2.01588e-3;
params.h2.R_universal_j_mol_k = 8.314462618;
params.h2.R_specific_j_kg_k = params.h2.R_universal_j_mol_k / params.h2.molar_mass_kg_mol;
params.h2.cp_j_kg_k = 14300;
params.h2.kappa = 1.40;

% Peng-Robinson EOS constants for hydrogen. PR is used here as a transparent
% engineering approximation; for the final paper case, CoolProp/NIST values
% can be injected through a property table if higher accuracy is required.
params.h2.critical_temperature_k = 33.145;
params.h2.critical_pressure_pa = 1.2964e6;
params.h2.acentric_factor = -0.219;

% Sutherland-style viscosity correlation around ambient gas temperatures.
% This is a placeholder engineering correlation for the first code version.
params.h2.viscosity_mu0_pa_s = 8.76e-6;
params.h2.viscosity_T0_k = 293.15;
params.h2.sutherland_C_k = 72.0;

%% Pipeline and thermal assumptions
params.pipeline.default_heat_transfer_w_m2_k = 5.0;
params.pipeline.reference_flow_fraction = 0.60;
params.pipeline.static_temperature_rule = 'max_seabed_temperature';
params.pipeline.static_reference_flow_rule = 'design_flow_fraction';
params.pipeline.allow_reverse_flow = false;
params.pipeline.inlet_temperature_mode = 'fixed';
params.pipeline.fixed_inlet_temperature_c = 60.0;
params.pipeline.aftercooler_setpoint_c = 35.0;
params.pipeline.temperature_average_method = 'length_average';
params.pipeline.temperature_average_sensitivity_methods = ...
    ["length_average", "endpoint_average"];
params.pipeline.inlet_temperature_sensitivity_c = [35, 60, 90];

% Conservative bounds for sanity checking.
params.range.seabed_temperature_c = [-2, 25];
params.range.pipeline_pressure_bar = [20, 120];
params.range.h2_velocity_m_s = [0, 35];
params.range.reynolds = [1, 1e9];
params.range.friction_factor = [0.005, 0.08];

%% Compressor assumptions
params.compressor.isentropic_efficiency = 0.85;  % NETL-style default
params.compressor.motor_efficiency = 0.96;
params.compressor.motor_sizing_factor = 1.10;
params.compressor.pressure_ratio_min = 1.0;
params.compressor.pressure_ratio_max = 3.0;
params.compressor.inlet_temperature_source = 'pipeline_gas_temperature';
params.compressor.inlet_temperature_c = 10.0;

%% Electrolyser, storage, and costs
params.electrolyser.specific_energy_kwh_per_kg = 50.0;
params.cost.compressor_electricity_usd_per_mwh = 80.0;
params.cost.external_h2_usd_per_kg = 8.0;
params.cost.unserved_h2_usd_per_kg = 1e5;
params.cost.wind_curtailment_usd_per_mwh = 0.0;

params.storage.charge_efficiency = 0.98;
params.storage.discharge_efficiency = 0.98;
params.storage.final_soc_at_least_initial = true;

%% Solver
params.solver.preferred = 'linprog';
params.solver.yalmip_solver = 'gurobi';
params.solver.verbose = false;

%% Interface for future real North Sea data
params.case.source = 'synthetic';
params.case.future_loader = 'build_north_sea_h2_case';
params.environment.source = 'synthetic_seasonal_representative_day';
params.environment.future_loader = 'load_cmems_seabed_temperature_profile';

end
