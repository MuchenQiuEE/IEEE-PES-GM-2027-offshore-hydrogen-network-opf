function [T_in_k, meta] = pipeline_inlet_temperature(params, h2case, env, l, t)
%PIPELINE_INLET_TEMPERATURE Pipe inlet thermal boundary condition.
%
% The default v2 assumption is a fixed post-compression/aftercooling
% temperature, rather than T_in = T_seabed. This keeps the dispatch model
% reduced-order while avoiding an unphysical inlet boundary.

mode = lower(string(params.pipeline.inlet_temperature_mode));
T_sea_k = env.theta_seabed_c(l,t) + 273.15;

switch mode
    case "seabed_equilibrium"
        T_in_k = T_sea_k;
        meta.mode = mode;
        meta.compressor_outlet_k = NaN;

    case "fixed"
        T_in_k = params.pipeline.fixed_inlet_temperature_c + 273.15;
        meta.mode = mode;
        meta.compressor_outlet_k = NaN;

    case "aftercooler"
        T_comp_in_k = params.compressor.inlet_temperature_c + 273.15;
        p_suction_pa = h2case.pipeline.source_pressure_bar(l) * 1e5;
        p_discharge_pa = h2case.pipeline.upstream_pressure_max_bar(l) * 1e5;
        T_comp_out_k = compressor_outlet_temperature(params, T_comp_in_k, ...
            p_suction_pa, p_discharge_pa);
        T_in_k = min(T_comp_out_k, params.pipeline.aftercooler_setpoint_c + 273.15);
        meta.mode = mode;
        meta.compressor_outlet_k = T_comp_out_k;

    case "compressor_outlet"
        T_comp_in_k = params.compressor.inlet_temperature_c + 273.15;
        p_suction_pa = h2case.pipeline.source_pressure_bar(l) * 1e5;
        p_discharge_pa = h2case.pipeline.upstream_pressure_max_bar(l) * 1e5;
        T_in_k = compressor_outlet_temperature(params, T_comp_in_k, ...
            p_suction_pa, p_discharge_pa);
        meta.mode = mode;
        meta.compressor_outlet_k = T_in_k;

    otherwise
        error('Unknown params.pipeline.inlet_temperature_mode: %s', mode);
end

end

function T_out_k = compressor_outlet_temperature(params, T_in_k, p_in_pa, p_out_pa)
%COMPRESSOR_OUTLET_TEMPERATURE Simplified isentropic outlet temperature.

k = params.h2.kappa;
eta_iso = params.compressor.isentropic_efficiency;
ratio = max(p_out_pa / max(p_in_pa, 1), params.compressor.pressure_ratio_min);
ratio = min(ratio, params.compressor.pressure_ratio_max);

T_out_k = T_in_k * (1 + (ratio^((k - 1) / k) - 1) / eta_iso);

end
