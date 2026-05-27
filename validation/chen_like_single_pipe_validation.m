function result = chen_like_single_pipe_validation(results_dir)
%CHEN_LIKE_SINGLE_PIPE_VALIDATION Thermal sanity check inspired by Chen et al.
%
% Chen's single-pipeline validation uses D = 0.5 m, L = 100 km,
% T_in = 60 degC, p_in = 2.3 MPa, and outlet flow = 20 kg/s. This script
% only checks the exponential heat-transfer temperature calculation.

params = h2_params();
T_in_k = 60 + 273.15;
T_sea_k = 10 + 273.15;
m_ref_kg_s = 20;
cp = params.h2.cp_j_kg_k;
U = params.pipeline.default_heat_transfer_w_m2_k;
D = 0.5;
L = 100e3;

methods = ["length_average", "endpoint_average"];
rows = {};
for i = 1:numel(methods)
    [Tavg, Tout, chi] = gas_temperature_from_seabed(T_in_k, T_sea_k, ...
        m_ref_kg_s, cp, U, D, L, char(methods(i)));
    rows{end+1,1} = {string(methods(i)), chi, T_in_k - 273.15, ...
        T_sea_k - 273.15, Tout - 273.15, Tavg - 273.15}; %#ok<AGROW>
end

result = cell2table(vertcat(rows{:}), 'VariableNames', { ...
    'temperature_average_method', 'chi', 'Tin_c', 'surrounding_c', ...
    'Tout_c', 'Tgas_representative_c'});
writetable(result, fullfile(results_dir, 'chen_like_single_pipe_validation.csv'));
end

