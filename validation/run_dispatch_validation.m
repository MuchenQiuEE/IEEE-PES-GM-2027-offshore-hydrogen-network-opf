function run_dispatch_validation(results_dir, results_all)
%RUN_DISPATCH_VALIDATION Check solved dispatch scenarios for consistency.

names = fieldnames(results_all);
status = strings(numel(names), 1);
max_balance_residual = nan(numel(names), 1);
max_bound_violation = nan(numel(names), 1);

for k = 1:numel(names)
    model = results_all.(names{k}).model;
    result = results_all.(names{k}).result;

    if result.status.exitflag <= 0
        status(k) = "failed";
        continue;
    end

    x = pack_solution(model, result.vars);
    max_balance_residual(k) = max(abs(model.Aeq * x - model.beq));
    violations = [model.lb - x; x - model.ub];
    if ~isempty(model.A)
        violations = [violations; model.A * x - model.b]; %#ok<AGROW>
    end
    max_bound_violation(k) = max(violations);
    status(k) = "ok";

    assert(max_balance_residual(k) < 1e-5, 'Mass balance residual too large.');
    assert(max_bound_violation(k) < 1e-5, 'Constraint violation too large.');
end

validation_table = table(string(names), status, max_balance_residual, ...
    max_bound_violation, 'VariableNames', {'scenario', 'status', ...
    'max_balance_residual', 'max_bound_violation'});
writetable(validation_table, fullfile(results_dir, 'dispatch_validation_summary.csv'));

end

function x = pack_solution(model, vars)
idx = model.idx;
x = zeros(idx.nVar, 1);
x(idx.p_el) = vars.p_el_mw;
x(idx.h_prod) = vars.h_prod_kg;
x(idx.wind_curt) = vars.wind_curt_mw;
x(idx.pipe_flow) = vars.pipe_flow_kg;
x(idx.storage_charge) = vars.storage_charge_kg;
x(idx.storage_discharge) = vars.storage_discharge_kg;
x(idx.storage_soc) = vars.storage_soc_kg;
x(idx.external_supply) = vars.external_supply_kg;
x(idx.unserved) = vars.unserved_kg;
end

