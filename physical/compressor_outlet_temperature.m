function T_out_k = compressor_outlet_temperature(params, T_in_k, p_in_pa, p_out_pa)
%COMPRESSOR_OUTLET_TEMPERATURE Simplified isentropic outlet temperature.

k = params.h2.kappa;
eta_iso = params.compressor.isentropic_efficiency;
ratio = max(p_out_pa / max(p_in_pa, 1), params.compressor.pressure_ratio_min);
ratio = min(ratio, params.compressor.pressure_ratio_max);

T_out_k = T_in_k * (1 + (ratio^((k - 1) / k) - 1) / eta_iso);

end
