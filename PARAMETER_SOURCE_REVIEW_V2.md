# Parameter Source Review - V2

This note extracts non-synthetic temporary assumptions from the current model
and checks whether the uploaded references provide directly usable values. If
not, it records suggested external sources or recommended sensitivity treatment.

Uploaded reference folder:

```text
D:\OneDrive - Newcastle University\NCL Research\papers\IEEE PES GM 2027\参考例文
```

## Scope

Synthetic topology, synthetic wind profiles, synthetic demand, synthetic
storage size, and synthetic external supply capacity are excluded here. This
review focuses on temporary or weakly supported parameters outside the
synthetic case itself.

## Summary Table

| Parameter | Current Value | Uploaded Reference Evidence | Recommended Treatment |
|---|---:|---|---|
| Dispatch horizon | `24 h` | Bødal uses representative periods with hourly resolution, including seasonal weeks and peak 24 h periods. | Keep `1 h`; for paper use seasonal representative days/weeks rather than one synthetic day. |
| H2 `cp` | `14300 J/(kg K)` | Kuczyński discusses real-gas properties with Peng-Robinson but does not provide a simple constant `cp` to directly copy. | Keep for first version; validate with NIST/CoolProp property table or cite an H2 property database. |
| H2 viscosity correlation | Sutherland `mu0=8.76e-6`, `C=72 K` | Kuczyński supports real-gas property calculation concept; no direct Sutherland constants found. | Replace/validate with NIST/CoolProp values or use property table. |
| Heat-transfer coefficient `U` | `5 W/(m^2 K)` | Chen gives exponential heat-transfer model but no direct `U`. Kuczyński provides an overall heat-transfer coefficient formulation including internal convection, wall/insulation/ground conduction, and external ground coefficient. | Do not treat `5` as final. Either compute `U` from Kuczyński-style resistance model or run sensitivity `0.5/1/2/5`. |
| Reference flow fraction | `0.6 * design_flow` | No direct reference found. Bødal linepacking capacity uses 50% pipe utilization for a specific linepacking estimate, but this is not the same as thermal reference flow. | Replace with design/operating reference flow tied to pipe utilization, e.g. 50% or 80% of dynamic capacity, and test sensitivity. |
| Static temperature rule | `max seabed temp` | No direct rule in uploaded refs. | Keep as conservative case, but compare with seasonal high / percentile. |
| Fixed pipe inlet temperature | `60 degC` | Chen single-pipeline validation directly uses inlet temperature `60 degC`, inlet pressure `2.3 MPa`, outlet mass flow `20 kg/s`, `D=0.5 m`, `L=100 km`. Chen also notes natural gas highest temperature of `90 degC` in GERG-88. | Use `60 degC` as Chen-like baseline; run `35/60/90 degC` sensitivity. |
| Aftercooler setpoint | `35 degC` | No uploaded reference directly supports 35 degC. NETL uses compressor entering H2 temperature default equal to ground/pipeline temperature `53 degF`, but this is not an aftercooler outlet standard. | Treat `35 degC` as scenario assumption only. Prefer sensitivity or remove from main model unless aftercooler reference is added. |
| Compressor pressure-ratio cap | `3.0` | NETL does not specify a pressure-ratio cap as a default; it uses inlet/outlet pressures. Bødal uses `80/40 bar`; NETL default pipeline inlet/outlet pressures are `1000/705 psig`. | Compute ratio from pressure boundaries. Keep cap only as numerical safety, not as a cited engineering value. |
| Compressor inlet temperature | `10 degC` | NETL default is `53 degF` for ground/pipeline temperature and compressor entering H2 temperature. `53 degF = 11.67 degC`. | Replace `10 degC` with `11.67 degC` if using NETL default, or use seabed/ground temperature scenario. |
| Compressor isentropic efficiency | `0.85` | NETL directly gives default `85%`. | Keep and cite NETL. |
| Specific heat ratio | `1.4` | NETL directly gives default `1.4`. | Keep and cite NETL. |
| Compressor motor sizing factor | `1.1` | NETL directly gives default `1.1`. | Keep and cite NETL. |
| Compressor motor efficiency | `0.96` | NETL directly gives default `96%`. | Keep and cite NETL. |
| Pipeline inlet pressure | `80 bar` | Bødal uses max/min pressures `80/40 bar` for H2 linepacking; NETL default pipeline inlet pressure is `1000 psig` ≈ `68.9 barg`. | `80 bar` is defensible via Bødal for North Sea system analysis. |
| Pipeline outlet pressure | `40 bar` | Bødal uses `80/40 bar`; NETL default outlet is `705 psig` ≈ `48.6 barg`. | `40 bar` is defensible via Bødal; optionally test NETL-like `~69/49 barg`. |
| Source/compressor suction pressure | `30 bar` | No direct uploaded value. Chen uses `2.3 MPa` inlet pressure for a natural-gas pipe validation, but not compressor suction. | Keep as scenario assumption or derive from electrolyser/outlet pressure; sensitivity recommended. |
| Electrolyser specific energy | `50 kWh/kg` | Bødal models electrolysis investments but PDF text extraction did not reveal a direct kWh/kg efficiency. | Use external DOE/NREL/electrolyser references; 50 kWh/kg is reasonable for modern alkaline/PEM. |
| Compressor electricity price | `$80/MWh` | Bødal uses relative electricity price multipliers, not a directly extracted $/MWh baseline in the PDF text. | Use scenario electricity price, preferably from market data or Bødal baseline if extracted from dataset. |
| External H2 cost | `$8/kg` | Bødal uses H2 price sensitivity multipliers; no direct $/kg value extracted. DOE/NREL PEM electrolysis cost studies show broad ranges. | Replace with scenario range, e.g. `$2-$8/kg`; avoid letting one arbitrary value dominate objective. |
| Wind curtailment penalty | `$0/MWh` | No direct reference; Bødal discusses curtailment opportunity qualitatively. | Keep as reported metric or add opportunity value based on electricity/H2 price. |
| Storage charge/discharge efficiency | `0.98/0.98` | Uploaded refs do not directly provide H2 storage charge/discharge efficiency. External literature suggests salt-cavern hydrogen losses can be small, but injection/extraction compression can matter. | Treat `0.98` as mass-retention efficiency only; if energy-based storage is modelled, use separate compression/extraction terms. |

## Directly Usable Values From Uploaded References

### Chen et al. 2021

Use for non-isothermal thermal validation and inlet-temperature baseline:

```text
D = 0.5 m
L = 100 km
T_in = 60 degC
p_in = 2.3 MPa
m_out = 20 kg/s
gas maximum temperature noted from GERG-88 = 90 degC
```

Model implication:

```text
T_in = 60 degC can be used as a Chen-like baseline,
but final paper should show sensitivity at 35/60/90 degC.
```

### Bødal et al. 2024

Use for North Sea-style system assumptions:

```text
small H2 pipeline = 4.7 GW, diameter = 900 mm
large H2 pipeline = 13 GW, diameter = 1200 mm
linepacking pressure bounds = 80/40 bar
representative operation = seasonal weekly periods plus peak daily periods, hourly resolution
linepacking estimate at 50% pipeline utilization
```

Model implication:

```text
0.90 m / 1.20 m diameters and 80/40 bar pressure limits are defensible.
Seasonal representative periods are better than one day of small temperature variation.
```

### NETL Hydrogen Pipeline Cost Model 2024

Use for compressor and engineering defaults:

```text
ground / compressor entering H2 temperature = 53 degF = 11.67 degC
pipeline inlet pressure = 1000 psig
pipeline outlet pressure = 705 psig
compressor isentropic efficiency = 85%
specific heat ratio = 1.4
compressor motor sizing factor = 1.1
compressor motor efficiency = 96%
pipe roughness default for commercial steel = 0.00015 ft = 0.04572 mm
capacity factor appears as a main input; default commonly used in the manual context is 90%
```

Model implication:

```text
Compressor defaults should use NETL values directly.
Compressor inlet temperature should be changed from 10 degC to 11.67 degC if using NETL default.
NETL pressure case can be used as an alternative to Bødal 80/40 bar.
```

### Thawani et al. 2023

Use for hydraulic pressure-loss model and roughness:

```text
Darcy-Weisbach and Colebrook-White equations used for analytical model
X52 steel roughness = 0.04572 mm
MDPE roughness = 0.0015 mm
pipe diameters considered = 0.01 m to 1 m
```

Model implication:

```text
Current roughness 4.572e-5 m is directly supported.
Colebrook-White + Darcy-Weisbach chain is supported.
```

### Kuczyński et al. 2019

Use for thermodynamic/thermal formulation:

```text
Peng-Robinson equation of state for gas thermodynamic parameters
outlet pressure example = 24 bar(g)
mass-flow range example = 0.3 to 3.0 kg/s
assumed gas/ambient temperatures = 5 and 25 degC in studied examples
pipeline burial depth example = 1 m
overall heat-transfer coefficient calculated from thermal resistances
```

Model implication:

```text
Use Kuczyński to justify PR EOS and replacing a fixed U with a calculated
overall heat-transfer coefficient. Do not directly copy our U=5 from this paper.
```

## Parameters That Should Not Remain Single-Point Assumptions

These should become sensitivity dimensions or be recalibrated:

```text
U = 0.5 / 1 / 2 / 5 W/(m^2 K)
T_in = 35 / 60 / 90 degC
m_ref = 50% / 80% / 100% of expected operating or capacity flow
pressure case = Bødal 80/40 bar vs NETL 1000/705 psig
source pressure / compressor suction = scenario variable
external H2 price = low/medium/high, e.g. 2/5/8 $/kg
compressor electricity price = market/scenario value
storage efficiency = mass-retention case vs energy-based storage case
```

## External Sources Checked

External checks were used only when the uploaded references did not provide a
direct value.

- NIST hydrogen gas property page gives hydrogen dynamic viscosity around
  `8.95 uPa s` at 300 K, supporting the order of magnitude of the current
  viscosity parameter.
- DOE/NREL PEM electrolysis records indicate projected high-volume hydrogen
  production costs span roughly `$2-$7/kg`, depending on technology and input
  assumptions.
- DOE technical targets for PEM/alkaline electrolysis frame energy efficiency
  and cost targets; 50 kWh/kg is a reasonable first-order electrolyser specific
  energy assumption.
- External salt-cavern hydrogen storage sources suggest low long-term leakage
  can support high mass-retention efficiency, but injection/extraction energy
  should not be hidden inside a simple 0.98 charge/discharge factor.

## Recommended Immediate Parameter Updates

| Current Parameter | Suggested Next Setting |
|---|---|
| `params.compressor.inlet_temperature_c = 10` | Change to `11.67` if using NETL default. |
| `params.pipeline.default_heat_transfer_w_m2_k = 5` | Keep only as high case; add `0.5/1/2/5` sensitivity. |
| `params.pipeline.reference_flow_fraction = 0.6` | Replace with reference flow tied to expected utilization or dynamic capacity; test `0.5/0.8/1.0`. |
| `params.pipeline.fixed_inlet_temperature_c = 60` | Keep as baseline, but always report `35/60/90`. |
| `params.cost.external_h2_usd_per_kg = 8` | Replace by low/medium/high H2 price scenario. |
| `params.cost.compressor_electricity_usd_per_mwh = 80` | Replace by electricity price scenario, preferably matched to Bødal/market assumptions. |
| `params.storage.charge_efficiency = 0.98`, `discharge_efficiency = 0.98` | Re-label as mass retention or separate storage compression/extraction energy. |

