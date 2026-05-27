function f = colebrook_white(Re, roughness_m, diameter_m)
%COLEBROOK_WHITE Darcy friction factor using Colebrook-White iteration.

if Re < 2300
    f = 64 / max(Re, 1);
    return;
end

rel = roughness_m / diameter_m;
f = 0.25 / (log10(rel/3.7 + 5.74 / Re^0.9))^2; % Swamee-Jain initial value

for k = 1:30
    f_old = f;
    rhs = -2 * log10(rel/3.7 + 2.51 / (Re * sqrt(f_old)));
    f = 1 / rhs^2;
    if abs(f - f_old) < 1e-10
        break;
    end
end

end

