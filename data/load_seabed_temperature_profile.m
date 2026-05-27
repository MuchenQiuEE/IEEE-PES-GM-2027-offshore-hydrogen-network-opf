function env = load_seabed_temperature_profile(params, h2case)
%LOAD_SEABED_TEMPERATURE_PROFILE Synthetic placeholder for CMEMS input.
%
% Future interface:
%   env = load_cmems_seabed_temperature_profile(params, h2case)
% should return the same fields, especially theta_seabed_c [nPipe x T].

T = params.meta.T;
hour = (0:T-1).';
nPipe = h2case.pipeline.count;

if isfield(params, 'environment') && isfield(params.environment, 'synthetic_profile_mode')
    mode = lower(string(params.environment.synthetic_profile_mode));
else
    mode = "warm_day_small_variation";
end

theta = zeros(nPipe, T);
switch mode
    case "warm_day_small_variation"
        theta(1, :) = 9.5 + 0.20*sin(2*pi*(hour - 5)/24) + 0.05*cos(2*pi*hour/8);
        theta(2, :) = 8.7 + 0.15*sin(2*pi*(hour - 7)/24) + 0.04*cos(2*pi*hour/10);
        theta = theta + [2.4; 1.8];
        note = 'Synthetic warm day with small hourly seabed-temperature variation.';

    case "stress_seasonal_extreme"
        % Stress-test profile: 24 operational stages represent ordered
        % seasonal/extreme seabed states, not real hourly temperature changes.
        % This deliberately amplifies the environmental signal to test whether
        % the physical and dispatch layers respond when pipe constraints bind.
        theta(1, :) = linspace(2, 22, T);   % shallow/wide seasonal range
        theta(2, :) = linspace(4, 18, T);   % deeper/milder seasonal range
        note = 'Stress-test seasonal/extreme seabed temperature profile; replace with CMEMS seasonal days for paper results.';

    otherwise
        error('Unknown synthetic seabed temperature mode: %s', mode);
end

env.time.hour = hour.';
env.theta_seabed_c = theta;
env.pipeline_names = h2case.pipeline.names(:);
env.source = params.environment.source;
env.note = note;
env.synthetic_profile_mode = mode;

end
