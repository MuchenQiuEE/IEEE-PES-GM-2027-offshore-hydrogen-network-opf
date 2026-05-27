function mu = hydrogen_viscosity_sutherland(params, T_k)
%HYDROGEN_VISCOSITY_SUTHERLAND Temperature-dependent H2 dynamic viscosity.

mu0 = params.h2.viscosity_mu0_pa_s;
T0 = params.h2.viscosity_T0_k;
C = params.h2.sutherland_C_k;
mu = mu0 * (T_k / T0)^(3/2) * (T0 + C) / (T_k + C);

end

