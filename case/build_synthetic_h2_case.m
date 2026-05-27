function h2case = build_synthetic_h2_case(params)
%BUILD_SYNTHETIC_H2_CASE Minimal offshore wind-to-hydrogen test system.
%
% Replace this function with build_north_sea_h2_case.m when the real North
% Sea topology is available. The rest of the model expects the same fields.

T = params.meta.T;
dt_h = params.meta.dt_h;

%% Nodes
h2case.node.names = ["OWF_A"; "OWF_B"; "ONSHORE_H2"];
h2case.node.count = numel(h2case.node.names);
h2case.node.offshore = [1; 2];
h2case.node.onshore = 3;

%% Offshore wind and electrolysers
h2case.wind.names = ["Wind_A"; "Wind_B"];
h2case.wind.node = [1; 2];
h2case.wind.count = numel(h2case.wind.names);
h2case.wind.capacity_mw = [900; 700];

hour = (0:T-1).';
profile_a = 0.58 + 0.22*sin(2*pi*(hour - 4)/24) + 0.08*sin(2*pi*hour/8);
profile_b = 0.52 + 0.18*sin(2*pi*(hour - 7)/24) + 0.06*cos(2*pi*hour/6);
h2case.wind.availability_mw = max(0.15, min(0.95, [profile_a, profile_b])) ...
    .* h2case.wind.capacity_mw.';

h2case.electrolyser.names = ["EL_A"; "EL_B"];
h2case.electrolyser.node = [1; 2];
h2case.electrolyser.count = numel(h2case.electrolyser.names);
h2case.electrolyser.pmax_mw = [650; 520];
h2case.electrolyser.pmin_mw = [0; 0];

%% Pipelines
h2case.pipeline.names = ["Pipe_A_to_Shore"; "Pipe_B_to_Shore"];
h2case.pipeline.count = numel(h2case.pipeline.names);
h2case.pipeline.from_node = [1; 2];
h2case.pipeline.to_node = [3; 3];
h2case.pipeline.length_km = [165; 230];
h2case.pipeline.diameter_m = [0.30; 0.30];
h2case.pipeline.roughness_m = [4.572e-5; 4.572e-5]; % X52 steel, 0.04572 mm
h2case.pipeline.heat_transfer_w_m2_k = ...
    params.pipeline.default_heat_transfer_w_m2_k * ones(h2case.pipeline.count, 1);
h2case.pipeline.design_flow_kg_s = [3.6; 2.9];
h2case.pipeline.source_pressure_bar = [30; 30];
h2case.pipeline.upstream_pressure_max_bar = [69; 69];
h2case.pipeline.downstream_pressure_min_bar = [49; 49];

%% Hydrogen demand
h2case.demand.node = 3;
h2case.demand.count = 1;
base_demand_kg_h = 52000;
demand_shape = 0.90 + 0.12*sin(2*pi*(hour - 9)/24) + 0.04*cos(2*pi*hour/12);
h2case.demand.profile_kg_h = base_demand_kg_h * max(0.75, demand_shape);
h2case.demand.total_kg = sum(h2case.demand.profile_kg_h) * dt_h;

%% Storage
h2case.storage.names = "Onshore_Storage";
h2case.storage.count = 1;
h2case.storage.node = 3;
h2case.storage.capacity_kg = 380000;
h2case.storage.initial_soc_kg = 0.50 * h2case.storage.capacity_kg;
h2case.storage.charge_max_kg_h = 65000;
h2case.storage.discharge_max_kg_h = 65000;

%% External supply keeps the synthetic model feasible; high cost makes it a
% last-resort balancing source rather than the preferred supply route.
h2case.external_supply.node = 3;
h2case.external_supply.max_kg_h = 100000;

end
