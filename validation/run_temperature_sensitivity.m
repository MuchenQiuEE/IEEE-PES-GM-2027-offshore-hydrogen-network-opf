function result = run_temperature_sensitivity(results_dir)
%RUN_TEMPERATURE_SENSITIVITY Compare inlet and averaging assumptions.

params0 = h2_params();
h2case = build_synthetic_h2_case(params0);
env0 = load_seabed_temperature_profile(params0, h2case);

Tin_cases = params0.pipeline.inlet_temperature_sensitivity_c;
methods = params0.pipeline.temperature_average_sensitivity_methods;

rows = {};
for m = 1:numel(methods)
    for i = 1:numel(Tin_cases)
        params = params0;
        params.pipeline.inlet_temperature_mode = 'fixed';
        params.pipeline.fixed_inlet_temperature_c = Tin_cases(i);
        params.pipeline.temperature_average_method = char(methods(m));

        pipe = precompute_pipeline_constraints(params, h2case, env0);
        for l = 1:h2case.pipeline.count
            rows{end+1,1} = { ...
                string(methods(m)), Tin_cases(i), string(h2case.pipeline.names(l)), ...
                mean(pipe.temperature_gas_k(l,:) - 273.15), ...
                mean(pipe.temperature_outlet_k(l,:) - 273.15), ...
                mean(pipe.limit_dynamic_kg_h(l,:)), ...
                mean(pipe.compressor_specific_energy_kwh_kg(l,:)), ...
                pipe.limit_static_kg_h(l)}; %#ok<AGROW>
        end
    end
end

result = cell2table(vertcat(rows{:}), 'VariableNames', { ...
    'temperature_average_method', 'Tin_c', 'pipeline', ...
    'mean_Tgas_c', 'mean_Tout_c', 'mean_capacity_kg_h', ...
    'mean_compressor_kwh_kg', 'static_capacity_kg_h'});

writetable(result, fullfile(results_dir, 'sensitivity_temperature_inlet.csv'));
end

