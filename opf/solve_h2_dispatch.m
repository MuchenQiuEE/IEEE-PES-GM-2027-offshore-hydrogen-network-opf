function result = solve_h2_dispatch(model)
%SOLVE_H2_DISPATCH Solve dispatch LP with linprog or YALMIP fallback.

if exist('linprog', 'file') == 2
    opts = optimoptions('linprog', 'Display', 'none');
    [x, fval, exitflag, output] = linprog(model.f, model.A, model.b, ...
        model.Aeq, model.beq, model.lb, model.ub, opts);
    status.exitflag = exitflag;
    status.message = output.message;
    status.solver = 'linprog';
elseif exist('sdpvar', 'file') == 2
    [x, fval, status] = solve_with_yalmip(model);
else
    error('No supported LP solver found. Install Optimization Toolbox or YALMIP.');
end

result.status = status;
if status.exitflag > 0
    result.objective_value = fval;
    result.vars = unpack_solution(model, x);
    result.summary = summarize_solution(model, result.vars);
else
    result.objective_value = NaN;
    result.vars = struct();
    result.summary = struct();
end

end

function [xval, fval, status] = solve_with_yalmip(model)
n = numel(model.f);
x = sdpvar(n, 1);
constraints = [model.lb <= x <= model.ub, ...
    model.Aeq * x == model.beq];
if ~isempty(model.A)
    constraints = [constraints, model.A * x <= model.b];
end

solver_name = model.params.solver.yalmip_solver;
options = sdpsettings('verbose', double(model.params.solver.verbose), ...
    'solver', solver_name);
diagnostics = optimize(constraints, model.f.' * x, options);

xval = value(x);
fval = value(model.f.' * x);
status.exitflag = double(diagnostics.problem == 0);
status.message = diagnostics.info;
status.solver = ['yalmip_', solver_name];
end

function vars = unpack_solution(model, x)
idx = model.idx;
vars.p_el_mw = reshape(x(idx.p_el(:)), size(idx.p_el));
vars.h_prod_kg = reshape(x(idx.h_prod(:)), size(idx.h_prod));
vars.wind_curt_mw = reshape(x(idx.wind_curt(:)), size(idx.wind_curt));
vars.pipe_flow_kg = reshape(x(idx.pipe_flow(:)), size(idx.pipe_flow));
vars.storage_charge_kg = reshape(x(idx.storage_charge(:)), size(idx.storage_charge));
vars.storage_discharge_kg = reshape(x(idx.storage_discharge(:)), size(idx.storage_discharge));
vars.storage_soc_kg = reshape(x(idx.storage_soc(:)), size(idx.storage_soc));
vars.external_supply_kg = reshape(x(idx.external_supply(:)), size(idx.external_supply));
vars.unserved_kg = reshape(x(idx.unserved(:)), size(idx.unserved));
end

function summary = summarize_solution(model, vars)
params = model.params;
pipe = model.pipe;
comp_coeff = model.pipe_comp_coeff_kwh_kg;

summary.wind_curtailment_mwh = sum(vars.wind_curt_mw, 'all') * params.meta.dt_h;
summary.h2_production_kg = sum(vars.h_prod_kg, 'all');
summary.external_supply_kg = sum(vars.external_supply_kg, 'all');
summary.unserved_demand_kg = sum(vars.unserved_kg, 'all');
summary.final_storage_soc_kg = vars.storage_soc_kg(:, end);

comp_mwh = 0;
for l = 1:model.h2case.pipeline.count
    comp_mwh = comp_mwh + sum( ...
        vars.pipe_flow_kg(l,:) .* comp_coeff(l,:) / 1000);
end
summary.compressor_energy_mwh = comp_mwh;

summary.pipeline_utilization = zeros(model.h2case.pipeline.count, params.meta.T);
for l = 1:model.h2case.pipeline.count
    for t = 1:params.meta.T
        switch model.scenario
            case "static"
                limit = pipe.limit_static_kg_h(l);
            case "partial"
                if l == 1
                    limit = pipe.limit_dynamic_kg_h(l,t);
                else
                    limit = pipe.limit_static_kg_h(l);
                end
            case "dynamic"
                limit = pipe.limit_dynamic_kg_h(l,t);
        end
        summary.pipeline_utilization(l,t) = vars.pipe_flow_kg(l,t) / max(limit, 1e-9);
    end
end
summary.pipeline_binding_hours = sum(summary.pipeline_utilization >= 0.999, 2);
summary.max_pipeline_utilization = max(summary.pipeline_utilization, [], 2);
end
