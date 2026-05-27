function pipe = precompute_pipeline_constraints(params, h2case, env)
%PRECOMPUTE_PIPELINE_CONSTRAINTS Temperature-driven H2 pipe coefficients.
%
% This is the reduced-order physical layer described in the article idea:
% seabed temperature is mapped to representative gas temperature, then to
% Z, viscosity, Reynolds number, Darcy friction factor, pressure-flow
% coefficient, dynamic capacity, and compressor specific energy.

nPipe = h2case.pipeline.count;
T = params.meta.T;
dt_h = params.meta.dt_h;

assert(size(env.theta_seabed_c, 1) == nPipe, ...
    'env.theta_seabed_c must have one row per pipeline.');
assert(size(env.theta_seabed_c, 2) == T, ...
    'env.theta_seabed_c must have params.meta.T columns.');

pipe.temperature_gas_k = zeros(nPipe, T);
pipe.temperature_inlet_k = zeros(nPipe, T);
pipe.temperature_outlet_k = zeros(nPipe, T);
pipe.temperature_seabed_k = env.theta_seabed_c + 273.15;
pipe.heat_exchange_chi = zeros(nPipe, T);
pipe.compressor_outlet_temperature_k = nan(nPipe, T);
pipe.Z = zeros(nPipe, T);
pipe.density_kg_m3 = zeros(nPipe, T);
pipe.viscosity_pa_s = zeros(nPipe, T);
pipe.reynolds = zeros(nPipe, T);
pipe.friction_factor = zeros(nPipe, T);
pipe.pressure_flow_K = zeros(nPipe, T);
pipe.limit_dynamic_kg_s = zeros(nPipe, T);
pipe.limit_dynamic_kg_h = zeros(nPipe, T);
pipe.compressor_specific_energy_kwh_kg = zeros(nPipe, T);
pipe.pressure_ratio_ref = zeros(nPipe, T);

for l = 1:nPipe
    L_m = h2case.pipeline.length_km(l) * 1000;
    D_m = h2case.pipeline.diameter_m(l);
    eps_m = h2case.pipeline.roughness_m(l);
    A_m2 = pi * D_m^2 / 4;
    m_ref_kg_s = max(1e-6, params.pipeline.reference_flow_fraction * ...
        h2case.pipeline.design_flow_kg_s(l));

    p_rep_pa = 0.5 * (h2case.pipeline.upstream_pressure_max_bar(l) + ...
        h2case.pipeline.downstream_pressure_min_bar(l)) * 1e5;
    pmax_pa = h2case.pipeline.upstream_pressure_max_bar(l) * 1e5;
    pmin_pa = h2case.pipeline.downstream_pressure_min_bar(l) * 1e5;
    psuction_pa = h2case.pipeline.source_pressure_bar(l) * 1e5;

    for t = 1:T
        theta_s_k = env.theta_seabed_c(l, t) + 273.15;
        [T_in_k, inlet_meta] = pipeline_inlet_temperature(params, h2case, env, l, t);
        [T_avg_k, T_out_k, chi] = gas_temperature_from_seabed( ...
            T_in_k, theta_s_k, m_ref_kg_s, params.h2.cp_j_kg_k, ...
            h2case.pipeline.heat_transfer_w_m2_k(l), D_m, L_m, ...
            params.pipeline.temperature_average_method);

        Z = hydrogen_pr_z(params, T_avg_k, p_rep_pa);
        rho = p_rep_pa / (Z * params.h2.R_specific_j_kg_k * T_avg_k);
        mu = hydrogen_viscosity_sutherland(params, T_avg_k);
        v_ref = m_ref_kg_s / max(rho * A_m2, 1e-12);
        Re = rho * v_ref * D_m / mu;
        f = colebrook_white(Re, eps_m, D_m);

        K = 16 * f * L_m * Z * params.h2.R_specific_j_kg_k * T_avg_k / ...
            (pi^2 * D_m^5);
        mmax_kg_s = sqrt(max(pmax_pa^2 - pmin_pa^2, 0) / max(K, 1e-12));

        p_out_ref_pa = sqrt(pmin_pa^2 + K * m_ref_kg_s^2);
        [e_kwh_kg, ratio] = compressor_specific_energy( ...
            params, T_avg_k, psuction_pa, p_out_ref_pa);

        pipe.temperature_gas_k(l, t) = T_avg_k;
        pipe.temperature_inlet_k(l, t) = T_in_k;
        pipe.temperature_outlet_k(l, t) = T_out_k;
        pipe.heat_exchange_chi(l, t) = chi;
        if isfield(inlet_meta, 'compressor_outlet_k')
            pipe.compressor_outlet_temperature_k(l, t) = inlet_meta.compressor_outlet_k;
        end
        pipe.Z(l, t) = Z;
        pipe.density_kg_m3(l, t) = rho;
        pipe.viscosity_pa_s(l, t) = mu;
        pipe.reynolds(l, t) = Re;
        pipe.friction_factor(l, t) = f;
        pipe.pressure_flow_K(l, t) = K;
        pipe.limit_dynamic_kg_s(l, t) = mmax_kg_s;
        pipe.limit_dynamic_kg_h(l, t) = mmax_kg_s * 3600 * dt_h;
        pipe.compressor_specific_energy_kwh_kg(l, t) = e_kwh_kg;
        pipe.pressure_ratio_ref(l, t) = ratio;
    end
end

function mu = hydrogen_viscosity_sutherland(params, T_k)
%HYDROGEN_VISCOSITY_SUTHERLAND Temperature-dependent H2 viscosity.

mu0 = params.h2.viscosity_mu0_pa_s;
T0 = params.h2.viscosity_T0_k;
C = params.h2.sutherland_C_k;
mu = mu0 * (T_k / T0)^(3/2) * (T0 + C) / (T_k + C);

end

pipe.static_temperature_c = max(env.theta_seabed_c, [], 2);
pipe.limit_static_kg_h = zeros(nPipe, 1);
pipe.compressor_static_specific_energy_kwh_kg = zeros(nPipe, 1);
pipe.static_index = zeros(nPipe, 1);
for l = 1:nPipe
    [~, idx] = max(env.theta_seabed_c(l, :));
    pipe.static_index(l) = idx;
    pipe.limit_static_kg_h(l) = pipe.limit_dynamic_kg_h(l, idx);
    pipe.compressor_static_specific_energy_kwh_kg(l) = ...
        pipe.compressor_specific_energy_kwh_kg(l, idx);
end

pipe.meta.pressure_flow_constraint = ...
    'p_from^2 - p_to^2 >= K(l,t) * m(l,t)^2; dispatch uses precomputed mmax.';
pipe.meta.reduced_order_note = ...
    'Reference flow updates K offline; optimization only uses hourly capacity and compressor coefficients.';
pipe.meta.inlet_temperature_mode = params.pipeline.inlet_temperature_mode;
pipe.meta.temperature_average_method = params.pipeline.temperature_average_method;

end
