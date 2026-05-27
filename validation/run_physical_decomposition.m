function decomp = run_physical_decomposition(results_dir, params, h2case, env)
%RUN_PHYSICAL_DECOMPOSITION Decompose temperature impact on pipe capacity.

temps_c = [0, 5, 10, 15, 20];
T = params.meta.T;
nPipe = h2case.pipeline.count;
nTemp = numel(temps_c);

cap = zeros(nPipe, nTemp);
Tgas = zeros(nPipe, nTemp);
Z = zeros(nPipe, nTemp);
f = zeros(nPipe, nTemp);
mu = zeros(nPipe, nTemp);
comp = zeros(nPipe, nTemp);

for i = 1:nTemp
    env_i = env;
    env_i.theta_seabed_c = temps_c(i) * ones(nPipe, T);
    pipe_i = precompute_pipeline_constraints(params, h2case, env_i);
    cap(:,i) = mean(pipe_i.limit_dynamic_kg_h, 2);
    Tgas(:,i) = mean(pipe_i.temperature_gas_k, 2);
    Z(:,i) = mean(pipe_i.Z, 2);
    f(:,i) = mean(pipe_i.friction_factor, 2);
    mu(:,i) = mean(pipe_i.viscosity_pa_s, 2);
    comp(:,i) = mean(pipe_i.compressor_specific_energy_kwh_kg, 2);
end

ref = find(temps_c == 10, 1);
rows = {};
for l = 1:nPipe
    for i = 1:nTemp
        direct_T_pct = -0.5 * (Tgas(l,i) / Tgas(l,ref) - 1) * 100;
        Z_pct = -0.5 * (Z(l,i) / Z(l,ref) - 1) * 100;
        f_pct = -0.5 * (f(l,i) / f(l,ref) - 1) * 100;
        rows{end+1,1} = { ...
            string(h2case.pipeline.names(l)), temps_c(i), ...
            (cap(l,i) / cap(l,ref) - 1) * 100, ...
            direct_T_pct, Z_pct, f_pct, ...
            (mu(l,i) / mu(l,ref) - 1) * 100, ...
            (comp(l,i) / comp(l,ref) - 1) * 100}; %#ok<AGROW>
    end
end

decomp = cell2table(vertcat(rows{:}), 'VariableNames', { ...
    'pipeline', 'seabed_temperature_c', 'capacity_change_pct', ...
    'direct_T_contribution_pct_approx', 'Z_contribution_pct_approx', ...
    'friction_contribution_pct_approx', 'mu_change_pct', ...
    'compressor_energy_change_pct'});

writetable(decomp, fullfile(results_dir, 'sensitivity_physical_decomposition.csv'));
end

