clear; clc;

%% =========================================================
% main.m - Offshore hydrogen network operation with
% seabed-temperature-driven dynamic pipeline constraints
%
% Case 1: static
%   Every H2 pipeline uses a conservative static limit computed from the
%   maximum seabed temperature in the study horizon.
%
% Case 2: partial
%   Only the first bottleneck pipeline uses hourly temperature-aware limits.
%   Other pipelines keep the static conservative limit.
%
% Case 3: dynamic
%   All pipelines use hourly seabed-temperature-aware limits.
%% =========================================================

%% 0) Paths
root_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(root_dir, 'data'));
addpath(fullfile(root_dir, 'case'));
addpath(fullfile(root_dir, 'physical'));
addpath(fullfile(root_dir, 'opf'));
addpath(fullfile(root_dir, 'post'));
addpath(fullfile(root_dir, 'validation'));

results_dir = fullfile(root_dir, 'results');
if ~exist(results_dir, 'dir'), mkdir(results_dir); end

%% 1) Parameters, case, and environmental inputs
params = h2_params();
h2case = build_synthetic_h2_case(params);
env = load_seabed_temperature_profile(params, h2case);

%% 2) Pipeline physical layer
pipe = precompute_pipeline_constraints(params, h2case, env);

save(fullfile(results_dir, 'pipeline_physical_layer.mat'), ...
    'params', 'h2case', 'env', 'pipe');

fprintf('=== Pipeline physical layer finished ===\n');
fprintf('Dynamic capacity range: %.2f ~ %.2f kg/h\n', ...
    min(pipe.limit_dynamic_kg_h(:)), max(pipe.limit_dynamic_kg_h(:)));
fprintf('Static conservative capacities:\n');
for l = 1:h2case.pipeline.count
    fprintf('  %s: %.2f kg/h at %.2f degC\n', ...
        h2case.pipeline.names(l), pipe.limit_static_kg_h(l), ...
        pipe.static_temperature_c(l));
end

run_physics_validation(results_dir, params, h2case, env, pipe);
run_physical_decomposition(results_dir, params, h2case, env);

%% 3) Three dispatch cases
scenarios = {'static', 'partial', 'dynamic'};
labels = {'Case1 Static', 'Case2 Partial Dynamic', 'Case3 Full Dynamic'};
results_all = struct();

for s = 1:numel(scenarios)
    scenario = scenarios{s};
    fprintf('\n========================================\n');
    fprintf('  Running %s: %s\n', upper(scenario), labels{s});
    fprintf('========================================\n');

    model = build_h2_dispatch_lp(params, h2case, env, pipe, scenario);
    result = solve_h2_dispatch(model);

    results_all.(scenario).model = model;
    results_all.(scenario).result = result;

    if result.status.exitflag <= 0
        warning('%s failed: %s', scenario, result.status.message);
        continue;
    end

    fprintf('Objective value:          %.2f\n', result.objective_value);
    fprintf('Compressor electricity:   %.2f MWh\n', result.summary.compressor_energy_mwh);
    fprintf('External hydrogen supply: %.2f kg\n', result.summary.external_supply_kg);
    fprintf('Wind curtailment:         %.2f MWh\n', result.summary.wind_curtailment_mwh);
    fprintf('Unserved demand:          %.2f kg\n', result.summary.unserved_demand_kg);

    save(fullfile(results_dir, sprintf('dispatch_result_%s.mat', scenario)), ...
        'params', 'h2case', 'env', 'pipe', 'model', 'result');

    summarize_h2_results(results_dir, scenario, params, h2case, env, pipe, model, result);
end

%% 4) Three-case comparison
comparison = compare_h2_scenarios(results_all, labels);
save(fullfile(results_dir, 'three_case_comparison.mat'), 'comparison');
writetable(comparison.table, fullfile(results_dir, 'three_case_comparison.csv'));

fprintf('\n========================================\n');
fprintf('  THREE-SCENARIO COMPARISON\n');
fprintf('========================================\n');
disp(comparison.table);

run_dispatch_validation(results_dir, results_all);

run_temperature_sensitivity(results_dir);
chen_like_single_pipe_validation(results_dir);
