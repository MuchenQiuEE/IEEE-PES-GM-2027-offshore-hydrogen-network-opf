function env = load_seabed_temperature_profile(params, h2case)
%LOAD_SEABED_TEMPERATURE_PROFILE Synthetic placeholder for CMEMS input.
%
% Future interface:
%   env = load_cmems_seabed_temperature_profile(params, h2case)
% should return the same fields, especially theta_seabed_c [nPipe x T].

T = params.meta.T;
hour = (0:T-1).';
nPipe = h2case.pipeline.count;

theta = zeros(nPipe, T);
theta(1, :) = 9.5 + 0.20*sin(2*pi*(hour - 5)/24) + 0.05*cos(2*pi*hour/8);
theta(2, :) = 8.7 + 0.15*sin(2*pi*(hour - 7)/24) + 0.04*cos(2*pi*hour/10);

% Add a representative warm-season offset to make the conference-scale
% synthetic case expose the temperature effect more clearly.
theta = theta + [2.4; 1.8];

env.time.hour = hour.';
env.theta_seabed_c = theta;
env.pipeline_names = h2case.pipeline.names(:);
env.source = params.environment.source;
env.note = 'Synthetic representative warm-season day; replace with CMEMS bottom temperature for North Sea case.';

end

