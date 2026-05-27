# IEEE PES GM 2027 MATLAB Model Background - V2

This note summarizes the current MATLAB code status, model assumptions,
temporary parameters, and key diagnostic findings. It is intended as context
for future conversations.

## Project Location

Current target code directory:

```text
D:\OneDrive - Newcastle University\NCL Research\papers\IEEE PES GM 2027\Code\Matlab
```

Local working mirror:

```text
C:\Users\56263\Documents\New project\IEEE_PES_GM_2027_Matlab
```

Main entry:

```text
main.m
```

Folder structure:

```text
data/
case/
physical/
opf/
post/
validation/
results/
```

## Article Modeling Idea

The paper studies:

```text
Optimal Operation of Offshore Hydrogen Networks Considering
Seabed Temperature-Driven Dynamic Pipeline Flow Constraints
```

The intended reduced-order modeling chain is:

```text
seabed temperature
  -> representative pipe gas temperature
  -> hydrogen real-gas / transport properties
  -> Reynolds number and Darcy friction factor
  -> pressure-flow coefficient
  -> dynamic maximum hydrogen transport capacity
  -> offshore hydrogen system dispatch
```

The optimization layer does not solve a full nonlinear non-isothermal gas
flow problem. Instead, temperature-dependent pipe limits and compressor
coefficients are precomputed offline and then passed into a linear dispatch
model.

## Chen et al. Reference Takeaways

Reference:

```text
D. Chen, C. Wan, Y. Song, C. Guo, and M. Shahidehpour,
"Non-Isothermal Optimal Power and Gas Flow",
IEEE Transactions on Power Systems, 2021.
DOI: 10.1109/TPWRS.2021.3084941
```

Important Chen results:

- Single-pipeline pressure error from isothermal assumption: about `10.2%`.
- Small IEGS operation cost increase under non-isothermal OPGF: about `2.28%`.
- OPGF nodal pressure error: about `7.4%`.
- NGU penetration sensitivity: operation cost error increases from `0.94%`
  to `2.77%`.
- Large system operation cost difference: about `1.27%`.

Interpretation:

Chen's system impact is not caused mainly by ambient temperature daily
variation. It is caused by compressed high-temperature gas entering the pipe,
exchanging heat with the surrounding environment, and changing the pressure
feasible region. Chen gives a single-pipe validation condition with:

```text
D = 0.5 m
L = 100 km
T_in = 60 degC
p_in = 2.3 MPa
m_out = 20 kg/s
```

## V2 Thermal Model

The V1 assumption `T_in = T_seabed` was judged physically weak when a
compressor exists upstream. V2 decouples pipe inlet temperature from seabed
temperature.

Current default:

```matlab
params.pipeline.inlet_temperature_mode = 'fixed';
params.pipeline.fixed_inlet_temperature_c = 60.0;
params.pipeline.temperature_average_method = 'length_average';
```

Supported inlet temperature modes:

```text
seabed_equilibrium  legacy prototype: T_in = T_seabed
fixed               fixed pipe inlet temperature, default 60 degC
aftercooler         compressor outlet temperature capped by aftercooler setpoint
compressor_outlet   simplified isentropic compressor outlet temperature
```

Supported representative temperature methods:

```text
length_average      recommended main model
endpoint_average    legacy (T_in + T_out)/2, kept for comparison
```

### Heat-Exchange Formulas

The dimensionless heat-transfer strength is:

```text
chi_l,t = U_l pi D_l L_l / (m_l^ref c_p,H2)
```

`chi` is dimensionless.

Outlet temperature:

```text
T_l,t^out = T_l,t^sea + (T_l^in - T_l,t^sea) exp(-chi_l,t)
```

Recommended representative pipe gas temperature:

```text
T_l,t^g = T_l,t^sea
        + (T_l^in - T_l,t^sea) [1 - exp(-chi_l,t)] / chi_l,t
```

Interpretation:

- `T_out` describes the pipe outlet gas temperature and is useful for physical
  explanation, Chen-like validation, and future multi-segment networks.
- `T_g` is the representative gas temperature used to compute `Z`, viscosity,
  Reynolds number, Darcy friction factor, pressure-flow coefficient, pipe
  capacity, and compressor specific energy.

## Pressure-Flow Model

The pipe pressure-flow relationship is represented as:

```text
p_i^2 - p_j^2 = K_l,t m_l,t^2
```

with:

```text
K_l,t = 16 f_l,t L_l Z_l,t R_H2 T_l,t^g / (pi^2 D_l^5)
```

Therefore:

```text
m_l,t^max = sqrt((p_i,max^2 - p_j,min^2) / K_l,t)
```

Approximate sensitivity:

```text
m_max proportional to 1 / sqrt(f Z T_g)
```

So temperature affects capacity through:

1. Direct absolute-temperature term `T_g` in `K`.
2. Compressibility factor `Z(P,T)`.
3. Viscosity `mu(T) -> Re -> f`.
4. Compressor specific energy.

Current decomposition shows:

- Direct `T_g` term is dominant.
- `mu/Re/f` is secondary.
- `Z` is very small in current pressure-temperature range.

## Current Synthetic Case

This is not the final North Sea case. It is a simple placeholder.

Nodes:

```text
OWF_A
OWF_B
ONSHORE_H2
```

Wind:

```text
Wind A capacity = 900 MW
Wind B capacity = 700 MW
Wind profiles = synthetic sinusoidal profiles
```

Electrolysers:

```text
EL A pmax = 650 MW
EL B pmax = 520 MW
specific energy = 50 kWh/kg
```

Pipelines:

```text
Pipe 1 length = 165 km
Pipe 2 length = 230 km
Pipe 1 diameter = 0.90 m
Pipe 2 diameter = 1.20 m
roughness = 4.572e-5 m
U = 5 W/(m^2 K)
design flow = 10.5 / 18.5 kg/s
source pressure = 30 bar
pipe inlet pressure max = 80 bar
pipe outlet pressure min = 40 bar
```

Demand and storage:

```text
onshore demand base = 52,000 kg/h
total daily demand = about 1.1232e6 kg/day
storage capacity = 380,000 kg
initial storage SOC = 190,000 kg
storage charge/discharge max = 65,000 kg/h
external supply max = 100,000 kg/h
```

Synthetic seabed temperature:

```text
Pipe 1: about 11.69 to 12.11 degC
Pipe 2: about 10.36 to 10.66 degC
```

These are small day-scale variations, not seasonal representative days.

## Current V2 Results

After V2 thermal-model changes, the target directory was verified by running
`main.m` in MATLAB.

Three dispatch cases:

```text
Case 1 static
Case 2 partial dynamic
Case 3 full dynamic
```

Current system-level results:

```text
Static objective:   5.662306e6
Partial objective:  5.662305e6
Dynamic objective:  5.662304e6

Compressor electricity:
Static   56.862 MWh
Partial  56.841 MWh
Dynamic  56.830 MWh
```

The system-level differences are very small.

## Why Current System Differences Are Small

The current synthetic case does not use pipe capacity.

Pipe utilization in Case 1 static:

```text
Pipe 1 max flow = 13,000 kg/h = 3.61 kg/s
Pipe 1 static capacity = about 300,298 kg/h
Pipe 1 max utilization = about 4.33%

Pipe 2 max flow = 10,400 kg/h = 2.89 kg/s
Pipe 2 static capacity = about 537,204 kg/h
Pipe 2 max utilization = about 1.94%
```

The actual max flows equal electrolyser limits:

```text
650 MW / 50 kWh/kg = 13,000 kg/h
520 MW / 50 kWh/kg = 10,400 kg/h
```

Therefore, the active constraints are:

```text
wind / electrolyser / external hydrogen supply
```

not pipe capacity.

The objective is also dominated by external hydrogen:

```text
external hydrogen = 707,219 kg
external H2 cost = 8 $/kg
external H2 cost contribution = about 5.66 million $

compressor electricity = about 56.86 MWh
electricity price = 80 $/MWh
compressor cost contribution = about 4,549 $
```

Thus compressor cost is less than 0.1% of the objective. Even real physical
changes in compressor energy only create tiny objective changes.

## Sensitivity Findings

### Seabed Temperature Sensitivity

Using V2 with fixed `T_in = 60 degC` and `length_average`:

```text
0 -> 10 degC:
capacity about -1.87%
compressor specific energy about +3.48%
viscosity about +2.39%
friction factor about +0.26%

10 -> 20 degC:
capacity about -1.78%
compressor specific energy about +3.49%
viscosity about +2.35%
friction factor about +0.26%

Per 1 degC:
capacity about -0.18%
compressor specific energy about +0.35%
viscosity about +0.24%
friction factor about +0.026%
```

### Inlet Temperature and Temperature-Average Method

Using `T_in = 60 degC` as baseline:

`length_average`:

```text
T_in = 35 degC:
mean T_gas about 12.1 degC
capacity about +0.18%
compressor energy about -0.34%

T_in = 60 degC:
mean T_gas about 13.0 degC
baseline

T_in = 90 degC:
mean T_gas about 14.2 degC
capacity about -0.21%
compressor energy about +0.41%
```

`endpoint_average`:

```text
T_in = 35 degC:
mean T_gas about 23.1 degC
capacity about +2.25%
compressor energy about -4.18%

T_in = 60 degC:
mean T_gas about 35.6 degC
baseline

T_in = 90 degC:
mean T_gas about 50.6 degC
capacity about -2.52%
compressor energy about +5.03%
```

Interpretation:

- `endpoint_average` gives larger and more visually attractive results.
- `length_average` is physically more defensible for exponential cooling.
- Because current `chi` is very large, `length_average` makes inlet temperature
  effects small.

## Current `chi` Values

Current V2 `chi` values:

```text
Pipe 1 chi about 25.89
Pipe 2 chi about 27.31
```

`chi` is dimensionless:

```text
chi = U pi D L / (m_ref c_p)
```

The large value is caused by:

```text
long pipe length
U = 5 W/(m^2 K)
low reference flow m_ref = 0.6 * design_flow
```

For Pipe 1:

```text
U = 5 W/(m^2 K)
D = 0.9 m
L = 165 km
m_ref = 6.3 kg/s
c_p = 14300 J/(kg K)
chi about 25.9
```

If `m_ref` were closer to static capacity:

```text
Pipe 1 static capacity about 83.7 kg/s
chi would reduce to about 1.95
```

If only `U` changes for Pipe 1:

```text
U = 5.0 -> chi about 25.9
U = 2.0 -> chi about 10.4
U = 1.0 -> chi about 5.2
U = 0.5 -> chi about 2.6
U = 0.2 -> chi about 1.0
```

Conclusion:

```text
chi = 26-27 is not a formula error, but it likely represents a strong
heat-transfer / low-flow case. It should not be treated as a final calibrated
baseline without sensitivity analysis.
```

## Parameter Audit

### Standard or Near-Standard Physical Parameters

```text
H2 molar mass = 0.00201588 kg/mol
H2 specific gas constant = 4124.48 J/(kg K)
H2 cp = 14300 J/(kg K)
H2 kappa = 1.4
PR Tc = 33.145 K
PR Pc = 1.2964 MPa
PR acentric factor = -0.219
```

These are mostly physical constants or common engineering values, but final
paper should cite property data or engineering references.

### Approximate or Temporary Physical Correlations

```text
viscosity mu0 = 8.76e-6 Pa s
viscosity reference temperature = 293.15 K
Sutherland constant = 72 K
```

These are currently a Sutherland-style approximation. For final paper results,
validate or replace with NIST/CoolProp/property-table values.

### Major Temporary Assumptions

```text
U = 5 W/(m^2 K)
reference flow fraction = 0.6
fixed inlet temperature = 60 degC
compressor inlet temperature = 10 degC
compressor pressure ratio cap = 3
external H2 cost = 8 $/kg
compressor electricity cost = 80 $/MWh
wind curtailment penalty = 0 $/MWh
storage capacity = 380,000 kg
storage initial SOC = 190,000 kg
storage charge/discharge max = 65,000 kg/h
external supply max = 100,000 kg/h
synthetic wind profiles
synthetic demand profile
synthetic seabed temperature profile
```

### Literature-Supported but Still Need Justification

```text
pipe diameters 0.9 m / 1.2 m
pressure limits 80 / 40 bar
roughness 4.572e-5 m
compressor efficiency 0.85
motor efficiency 0.96
motor sizing factor 1.1
electrolyser specific energy 50 kWh/kg
```

Likely sources:

- Bødal et al. for North Sea H2 pipeline size and 80/40 bar style pressure
  assumptions.
- Thawani et al. for X52 steel roughness.
- NETL H2 pipeline cost model for compressor efficiencies and engineering
  defaults.
- Electrolyser literature or manufacturer assumptions for 50 kWh/kg.

## Key Next Steps

The model physics is now more defensible, but the synthetic case must be
redesigned to show system impact.

Recommended next steps:

1. Redesign synthetic case so pipe utilization reaches `85-100%` in peak
   periods.
2. Use seasonal representative days:

   ```text
   winter cold seabed
   summer warm seabed
   extreme warm shallow seabed
   ```

3. Recalibrate `m_ref` so `chi` is not artificially inflated by very low flow.
4. Add sensitivity for:

   ```text
   U = 0.5 / 1 / 2 / 5 W/(m^2 K)
   T_in = 35 / 60 / 90 degC
   temperature_average_method = length_average / endpoint_average
   pressure limits = 80/40 and alternatives
   ```

5. Consider raising offshore wind/electrolyser capacity or reducing pipe
   diameter/pressure margin so dynamic pipe constraints affect dispatch.
6. Keep `length_average` as main model; use `endpoint_average` as conservative
   or legacy comparison only.
7. Report not only operation cost, but:

   ```text
   compressor energy
   dynamic pipe capacity
   pipe utilization
   binding hours
   external H2 supply
   wind curtailment
   storage behavior
   ```

## Important Generated Result Files

```text
results/three_case_comparison.csv
results/physics_validation_summary.csv
results/sensitivity_physical_decomposition.csv
results/sensitivity_temperature_inlet.csv
results/chen_like_single_pipe_validation.csv
results/post_pipeline_static.csv
results/post_system_static.csv
```

