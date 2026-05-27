function env = load_cmems_seabed_temperature_profile_template(params, h2case, cmemsData)
%LOAD_CMEMS_SEABED_TEMPERATURE_PROFILE_TEMPLATE Future CMEMS interface.
%
% Expected output:
%   env.theta_seabed_c(l,t) in degC, one row per pipeline and one column per
%   dispatch interval.
%
% Suggested mapping:
%   1) map each pipeline to representative midpoint or segmented grid cells;
%   2) extract bottom/near-seabed temperature from CMEMS;
%   3) aggregate segment values to pipeline-level representative temperature;
%   4) preserve raw metadata for traceability.

if nargin < 3 || isempty(cmemsData)
    error('CMEMS data not supplied yet.');
end

env = struct();
env.meta.params_stage = params.meta.stage;
env.meta.pipeline_names = h2case.pipeline.names(:);

error('load_cmems_seabed_temperature_profile_template is an interface stub.');
end

