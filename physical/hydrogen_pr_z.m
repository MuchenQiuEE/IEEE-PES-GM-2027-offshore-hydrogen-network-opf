function Z = hydrogen_pr_z(params, T_k, P_pa)
%HYDROGEN_PR_Z Peng-Robinson gas compressibility factor for hydrogen.

R = params.h2.R_universal_j_mol_k;
Tc = params.h2.critical_temperature_k;
Pc = params.h2.critical_pressure_pa;
omega = params.h2.acentric_factor;

kappa = 0.37464 + 1.54226 * omega - 0.26992 * omega^2;
alpha = (1 + kappa * (1 - sqrt(T_k / Tc)))^2;
a = 0.45724 * R^2 * Tc^2 / Pc * alpha;
b = 0.07780 * R * Tc / Pc;

A = a * P_pa / (R^2 * T_k^2);
B = b * P_pa / (R * T_k);

coeff = [1, -(1 - B), A - 3*B^2 - 2*B, -(A*B - B^2 - B^3)];
r = roots(coeff);
r = real(r(abs(imag(r)) < 1e-8));
if isempty(r)
    error('Peng-Robinson cubic returned no real root.');
end

Z = max(r);
if Z <= 0
    error('Peng-Robinson returned non-positive gas root.');
end

end

