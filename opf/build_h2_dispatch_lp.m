function model = build_h2_dispatch_lp(params, h2case, env, pipe, scenario)
%BUILD_H2_DISPATCH_LP Build linear dispatch model for the H2 network.

scenario = lower(string(scenario));
assert(ismember(scenario, ["static", "partial", "dynamic"]), ...
    'scenario must be static, partial, or dynamic.');

T = params.meta.T;
dt_h = params.meta.dt_h;
nWind = h2case.wind.count;
nEl = h2case.electrolyser.count;
nPipe = h2case.pipeline.count;
nStorage = h2case.storage.count;
nNode = h2case.node.count;
nExt = 1;

idx = make_indices(T, nWind, nEl, nPipe, nStorage, nExt);
nVar = idx.nVar;

f = zeros(nVar, 1);
lb = zeros(nVar, 1);
ub = inf(nVar, 1);

%% Variable bounds and objective
for t = 1:T
    for w = 1:nWind
        ub(idx.p_el(w,t)) = h2case.electrolyser.pmax_mw(w);
        ub(idx.wind_curt(w,t)) = h2case.wind.availability_mw(t,w);
        f(idx.wind_curt(w,t)) = params.cost.wind_curtailment_usd_per_mwh * dt_h;
    end

    for l = 1:nPipe
        ub(idx.pipe_flow(l,t)) = scenario_pipeline_limit(pipe, scenario, l, t);
        comp_kwh_kg = scenario_compressor_coeff(pipe, scenario, l, t);
        f(idx.pipe_flow(l,t)) = ...
            params.cost.compressor_electricity_usd_per_mwh * ...
            comp_kwh_kg / 1000;
    end

    for s = 1:nStorage
        ub(idx.storage_charge(s,t)) = h2case.storage.charge_max_kg_h(s) * dt_h;
        ub(idx.storage_discharge(s,t)) = h2case.storage.discharge_max_kg_h(s) * dt_h;
        ub(idx.storage_soc(s,t)) = h2case.storage.capacity_kg(s);
    end

    ub(idx.external_supply(t)) = h2case.external_supply.max_kg_h * dt_h;
    f(idx.external_supply(t)) = params.cost.external_h2_usd_per_kg;

    ub(idx.unserved(t)) = 0; % enforce all demand through H2 supply or storage
    f(idx.unserved(t)) = params.cost.unserved_h2_usd_per_kg;
end

%% Equalities
rows = {};
rhs = [];

% Wind allocation and electrolyser conversion.
for t = 1:T
    for w = 1:nWind
        row = sparse(1, nVar);
        row(idx.p_el(w,t)) = 1;
        row(idx.wind_curt(w,t)) = 1;
        rows{end+1,1} = row; %#ok<AGROW>
        rhs(end+1,1) = h2case.wind.availability_mw(t,w); %#ok<AGROW>

        row = sparse(1, nVar);
        row(idx.h_prod(w,t)) = 1;
        row(idx.p_el(w,t)) = -1000 * dt_h / params.electrolyser.specific_energy_kwh_per_kg;
        rows{end+1,1} = row; %#ok<AGROW>
        rhs(end+1,1) = 0; %#ok<AGROW>
    end
end

% Storage state transitions.
for t = 1:T
    for s = 1:nStorage
        row = sparse(1, nVar);
        row(idx.storage_soc(s,t)) = 1;
        if t == 1
            prev_soc = h2case.storage.initial_soc_kg(s);
        else
            row(idx.storage_soc(s,t-1)) = -1;
            prev_soc = 0;
        end
        row(idx.storage_charge(s,t)) = -params.storage.charge_efficiency;
        row(idx.storage_discharge(s,t)) = 1 / params.storage.discharge_efficiency;
        rows{end+1,1} = row; %#ok<AGROW>
        rhs(end+1,1) = prev_soc; %#ok<AGROW>
    end
end

% Node mass balances in kg per interval.
for t = 1:T
    for n = 1:nNode
        row = sparse(1, nVar);

        for e = 1:nEl
            if h2case.electrolyser.node(e) == n
                row(idx.h_prod(e,t)) = row(idx.h_prod(e,t)) + 1;
            end
        end

        for l = 1:nPipe
            if h2case.pipeline.from_node(l) == n
                row(idx.pipe_flow(l,t)) = row(idx.pipe_flow(l,t)) - 1;
            end
            if h2case.pipeline.to_node(l) == n
                row(idx.pipe_flow(l,t)) = row(idx.pipe_flow(l,t)) + 1;
            end
        end

        for s = 1:nStorage
            if h2case.storage.node(s) == n
                row(idx.storage_charge(s,t)) = row(idx.storage_charge(s,t)) - 1;
                row(idx.storage_discharge(s,t)) = row(idx.storage_discharge(s,t)) + 1;
            end
        end

        if h2case.external_supply.node == n
            row(idx.external_supply(t)) = row(idx.external_supply(t)) + 1;
        end

        if h2case.demand.node == n
            row(idx.unserved(t)) = row(idx.unserved(t)) + 1;
            demand = h2case.demand.profile_kg_h(t) * dt_h;
        else
            demand = 0;
        end

        rows{end+1,1} = row; %#ok<AGROW>
        rhs(end+1,1) = demand; %#ok<AGROW>
    end
end

Aeq = vertcat(rows{:});
beq = rhs;

%% Inequalities
A = sparse(0, nVar);
b = zeros(0, 1);

if params.storage.final_soc_at_least_initial
    rowsI = cell(nStorage, 1);
    rhsI = zeros(nStorage, 1);
    for s = 1:nStorage
        row = sparse(1, nVar);
        row(idx.storage_soc(s,T)) = -1;
        rowsI{s} = row;
        rhsI(s) = -h2case.storage.initial_soc_kg(s);
    end
    A = vertcat(rowsI{:});
    b = rhsI;
end

model.f = f;
model.A = A;
model.b = b;
model.Aeq = Aeq;
model.beq = beq;
model.lb = lb;
model.ub = ub;
model.idx = idx;
model.pipe_comp_coeff_kwh_kg = build_pipe_comp_coeff_matrix(pipe, scenario, nPipe, T);
model.params = params;
model.h2case = h2case;
model.env = env;
model.pipe = pipe;
model.scenario = scenario;

end

function idx = make_indices(T, nWind, nEl, nPipe, nStorage, nExt)
cursor = 0;

idx.p_el = reshape(cursor + (1:nEl*T), nEl, T); cursor = cursor + nEl*T;
idx.h_prod = reshape(cursor + (1:nEl*T), nEl, T); cursor = cursor + nEl*T;
idx.wind_curt = reshape(cursor + (1:nWind*T), nWind, T); cursor = cursor + nWind*T;
idx.pipe_flow = reshape(cursor + (1:nPipe*T), nPipe, T); cursor = cursor + nPipe*T;
idx.storage_charge = reshape(cursor + (1:nStorage*T), nStorage, T); cursor = cursor + nStorage*T;
idx.storage_discharge = reshape(cursor + (1:nStorage*T), nStorage, T); cursor = cursor + nStorage*T;
idx.storage_soc = reshape(cursor + (1:nStorage*T), nStorage, T); cursor = cursor + nStorage*T;
idx.external_supply = reshape(cursor + (1:nExt*T), nExt, T); cursor = cursor + nExt*T;
idx.unserved = reshape(cursor + (1:nExt*T), nExt, T); cursor = cursor + nExt*T;
idx.nVar = cursor;
end

function limit = scenario_pipeline_limit(pipe, scenario, l, t)
switch scenario
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
    otherwise
        error('Unknown scenario.');
end
end

function comp_kwh_kg = scenario_compressor_coeff(pipe, scenario, l, t)
switch scenario
    case "static"
        comp_kwh_kg = pipe.compressor_static_specific_energy_kwh_kg(l);
    case "partial"
        if l == 1
            comp_kwh_kg = pipe.compressor_specific_energy_kwh_kg(l,t);
        else
            comp_kwh_kg = pipe.compressor_static_specific_energy_kwh_kg(l);
        end
    case "dynamic"
        comp_kwh_kg = pipe.compressor_specific_energy_kwh_kg(l,t);
    otherwise
        error('Unknown scenario.');
end
end

function coeff = build_pipe_comp_coeff_matrix(pipe, scenario, nPipe, T)
coeff = zeros(nPipe, T);
for l = 1:nPipe
    for t = 1:T
        coeff(l,t) = scenario_compressor_coeff(pipe, scenario, l, t);
    end
end
end
