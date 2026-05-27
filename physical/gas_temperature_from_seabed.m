function [T_avg_k, T_out_k, chi] = gas_temperature_from_seabed(T_in_k, T_seabed_k, m_ref_kg_s, cp_j_kg_k, U_w_m2_k, D_m, L_m, average_method)
%GAS_TEMPERATURE_FROM_SEABED Exponential pipe heat-exchange model.
%
% T_out is the outlet temperature. T_avg is the representative pipe gas
% temperature used by the pressure-flow and property calculations.

if nargin < 8 || isempty(average_method)
    average_method = 'length_average';
end

chi = U_w_m2_k * pi * D_m * L_m / max(m_ref_kg_s * cp_j_kg_k, 1e-12);
T_out_k = T_seabed_k + (T_in_k - T_seabed_k) * exp(-chi);

switch lower(string(average_method))
    case "length_average"
        if abs(chi) < 1e-8
            factor = 1 - chi/2;
        else
            factor = (1 - exp(-chi)) / chi;
        end
        T_avg_k = T_seabed_k + (T_in_k - T_seabed_k) * factor;
    case "endpoint_average"
        T_avg_k = 0.5 * (T_in_k + T_out_k);
    otherwise
        error('Unknown temperature average method: %s', average_method);
end

end
