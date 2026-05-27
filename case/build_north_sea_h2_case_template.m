function h2case = build_north_sea_h2_case_template(params, northSeaData)
%BUILD_NORTH_SEA_H2_CASE_TEMPLATE Interface placeholder for the real case.
%
% Required output fields match build_synthetic_h2_case.m:
%   node, wind, electrolyser, pipeline, demand, storage, external_supply
%
% northSeaData can contain coordinates, candidate hubs, pipe routes, wind
% profiles, demand series, and CMEMS grid mappings. Keeping this as a
% separate loader prevents the physical and OPF layers from depending on
% the synthetic benchmark.

if nargin < 2 || isempty(northSeaData)
    error(['North Sea case data not supplied yet. Provide topology, ' ...
        'pipeline parameters, wind profiles, demand, and CMEMS mapping.']);
end

% Deliberately not implemented until the real North Sea data is provided.
% Start from build_synthetic_h2_case.m and populate the same fields.
h2case = struct();
h2case.meta.source = 'north_sea_template';
h2case.meta.params_stage = params.meta.stage;

error('build_north_sea_h2_case_template is an interface stub.');
end

