function summary = summarize_h2_results(results_dir, scenario, params, h2case, env, pipe, model, result)
%SUMMARIZE_H2_RESULTS Export hourly result tables and summary metrics.

if result.status.exitflag <= 0
    summary = struct();
    return;
end

T = params.meta.T;
hour = env.time.hour(:);
vars = result.vars;
summary = result.summary;

system_table = table(hour, ...
    col(sum(vars.p_el_mw, 1)), ...
    col(sum(vars.h_prod_kg, 1)), ...
    col(sum(vars.wind_curt_mw, 1)), ...
    col(vars.external_supply_kg), ...
    col(vars.unserved_kg), ...
    col(sum(vars.storage_soc_kg, 1)), ...
    'VariableNames', {'hour', 'electrolyser_power_mw', 'h2_production_kg', ...
    'wind_curtailment_mw', 'external_supply_kg', 'unserved_kg', 'storage_soc_kg'});

for l = 1:h2case.pipeline.count
    system_table.(sprintf('pipe%d_flow_kg', l)) = col(vars.pipe_flow_kg(l,:));
    system_table.(sprintf('pipe%d_utilization', l)) = col(summary.pipeline_utilization(l,:));
end

writetable(system_table, fullfile(results_dir, sprintf('post_system_%s.csv', scenario)));

pipe_table = table(hour, 'VariableNames', {'hour'});
for l = 1:h2case.pipeline.count
    pipe_table.(sprintf('pipe%d_Tin_c', l)) = (pipe.temperature_inlet_k(l,:).' - 273.15);
    pipe_table.(sprintf('pipe%d_Tout_c', l)) = (pipe.temperature_outlet_k(l,:).' - 273.15);
    pipe_table.(sprintf('pipe%d_theta_seabed_c', l)) = env.theta_seabed_c(l,:).';
    pipe_table.(sprintf('pipe%d_Tgas_avg_c', l)) = (pipe.temperature_gas_k(l,:).' - 273.15);
    pipe_table.(sprintf('pipe%d_chi', l)) = pipe.heat_exchange_chi(l,:).';
    pipe_table.(sprintf('pipe%d_Z', l)) = pipe.Z(l,:).';
    pipe_table.(sprintf('pipe%d_mu_pa_s', l)) = pipe.viscosity_pa_s(l,:).';
    pipe_table.(sprintf('pipe%d_Re', l)) = pipe.reynolds(l,:).';
    pipe_table.(sprintf('pipe%d_f_darcy', l)) = pipe.friction_factor(l,:).';
    pipe_table.(sprintf('pipe%d_limit_kg_h', l)) = pipe.limit_dynamic_kg_h(l,:).';
    pipe_table.(sprintf('pipe%d_comp_kwh_kg', l)) = ...
        pipe.compressor_specific_energy_kwh_kg(l,:).';
end

function y = col(x)
y = reshape(x, [], 1);
end

writetable(pipe_table, fullfile(results_dir, sprintf('post_pipeline_%s.csv', scenario)));

summary_table = table( ...
    string(scenario), result.objective_value, ...
    summary.compressor_energy_mwh, summary.external_supply_kg, ...
    summary.wind_curtailment_mwh, summary.unserved_demand_kg, ...
    sum(summary.pipeline_binding_hours), ...
    'VariableNames', {'scenario', 'objective', 'compressor_energy_mwh', ...
    'external_supply_kg', 'wind_curtailment_mwh', 'unserved_demand_kg', ...
    'pipeline_binding_hours'});
writetable(summary_table, fullfile(results_dir, sprintf('post_summary_%s.csv', scenario)));

save(fullfile(results_dir, sprintf('post_summary_%s.mat', scenario)), ...
    'summary', 'model', 'result');

end
