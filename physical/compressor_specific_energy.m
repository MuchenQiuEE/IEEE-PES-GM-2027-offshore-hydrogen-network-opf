function [specific_kwh_kg, ratio] = compressor_specific_energy(params, T_in_k, p_suction_pa, p_discharge_pa)
%COMPRESSOR_SPECIFIC_ENERGY Simplified isentropic compression electricity.

k = params.h2.kappa;
R = params.h2.R_specific_j_kg_k;
eta_iso = params.compressor.isentropic_efficiency;
eta_motor = params.compressor.motor_efficiency;
sizing = params.compressor.motor_sizing_factor;

ratio = max(p_discharge_pa / max(p_suction_pa, 1), params.compressor.pressure_ratio_min);
ratio = min(ratio, params.compressor.pressure_ratio_max);

ideal_j_kg = k / (k - 1) * R * T_in_k * (ratio^((k - 1) / k) - 1);
motor_j_kg = ideal_j_kg / eta_iso * sizing / eta_motor;
specific_kwh_kg = motor_j_kg / 3.6e6;

end

