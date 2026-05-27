function comparison = compare_h2_scenarios(results_all, labels)
%COMPARE_H2_SCENARIOS Build compact three-scenario comparison.

names = fieldnames(results_all);
n = numel(names);

objective = nan(n, 1);
compressor_mwh = nan(n, 1);
external_kg = nan(n, 1);
curtail_mwh = nan(n, 1);
unserved_kg = nan(n, 1);
binding_hours = nan(n, 1);

for k = 1:n
    r = results_all.(names{k}).result;
    if isfield(r, 'status') && r.status.exitflag > 0
        objective(k) = r.objective_value;
        compressor_mwh(k) = r.summary.compressor_energy_mwh;
        external_kg(k) = r.summary.external_supply_kg;
        curtail_mwh(k) = r.summary.wind_curtailment_mwh;
        unserved_kg(k) = r.summary.unserved_demand_kg;
        binding_hours(k) = sum(r.summary.pipeline_binding_hours);
    end
end

comparison.table = table(string(labels(:)), objective, compressor_mwh, ...
    external_kg, curtail_mwh, unserved_kg, binding_hours, ...
    'VariableNames', {'scenario', 'objective', 'compressor_energy_mwh', ...
    'external_supply_kg', 'wind_curtailment_mwh', 'unserved_demand_kg', ...
    'pipeline_binding_hours'});

if n >= 3 && all(~isnan(objective(1:3)))
    comparison.static_to_partial_saving = objective(1) - objective(2);
    comparison.partial_to_dynamic_saving = objective(2) - objective(3);
    comparison.static_to_dynamic_saving = objective(1) - objective(3);
    comparison.static_to_dynamic_saving_pct = ...
        comparison.static_to_dynamic_saving / max(objective(1), 1e-9) * 100;
else
    comparison.static_to_partial_saving = NaN;
    comparison.partial_to_dynamic_saving = NaN;
    comparison.static_to_dynamic_saving = NaN;
    comparison.static_to_dynamic_saving_pct = NaN;
end

end

