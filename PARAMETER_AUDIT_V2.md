# IEEE PES GM 2027 MATLAB Parameter Audit - V2

This file is the working parameter register for the offshore hydrogen
network model. Future parameter updates should be tracked here first, then
reflected in the MATLAB code.

## Classification

| Label | Meaning |
|---|---|
| Standard physical value | Physical constant or well-established property value. |
| Literature-supported assumption | Value is broadly supportable from cited papers/manuals, but must be justified in the paper. |
| Temporary synthetic assumption | Placeholder for the first synthetic case; should be replaced or stress-tested. |
| Modeling choice | Deliberate model setting rather than a physical constant. |
| Needs validation | Value/correlation is plausible but should be checked against a stronger source. |

## Global Time and Solver Settings

| Parameter | Current Value | Classification | Notes / Action |
|---|---:|---|---|
| Dispatch horizon `params.meta.T` | `24 h` | Temporary synthetic assumption | Representative day. Replace with seasonal representative days later. |
| Time step `params.meta.dt_h` | `1 h` | Modeling choice | Consistent with ISGT code style. |
| Primary LP solver | `linprog`, YALMIP fallback | Modeling choice | Current workflow runs in MATLAB. |
| YALMIP solver preference | `gurobi` | Modeling choice | Used only if `linprog` unavailable. |

## Hydrogen Physical Properties

| Parameter | Current Value | Classification | Notes / Action |
|---|---:|---|---|
| H2 molar mass | `0.00201588 kg/mol` | Standard physical value | Keep. |
| Universal gas constant | `8.314462618 J/(mol K)` | Standard physical value | Keep. |
| H2 specific gas constant | `4124.48 J/(kg K)` | Derived standard value | `R/M`. |
| H2 constant-pressure heat capacity `cp` | `14300 J/(kg K)` | Literature-supported assumption / Needs validation | Reasonable first value. Final paper can use property table or cited H2 data. |
| Specific heat ratio `kappa` | `1.4` | Literature-supported assumption | NETL-style default. |
| PR critical temperature `Tc` | `33.145 K` | Standard physical value | Keep. |
| PR critical pressure `Pc` | `1.2964 MPa` | Standard physical value | Keep. |
| PR acentric factor `omega` | `-0.219` | Standard physical value | Keep. |
| Viscosity reference `mu0` | `8.76e-6 Pa s` | Needs validation | Sutherland-style approximation. Validate with NIST/CoolProp/property table. |
| Viscosity reference temperature `T0` | `293.15 K` | Needs validation | Paired with `mu0`. |
| Sutherland constant `C` | `72 K` | Needs validation | Check H2-specific source. |

## Pipeline Thermal Model

| Parameter | Current Value | Classification | Notes / Action |
|---|---:|---|---|
| Default heat-transfer coefficient `U` | `5 W/(m^2 K)` | Temporary synthetic assumption | High-impact parameter. Add sensitivity `0.5/1/2/5`. |
| Reference flow fraction | `0.6 * design_flow` | Temporary synthetic assumption | Currently makes `chi` very large. Recalibrate. |
| Static temperature rule | `max_seabed_temperature` | Modeling choice | Conservative static case. Consider seasonal high or percentile. |
| Static reference flow rule | `design_flow_fraction` | Temporary synthetic assumption | Should align with design/operating point. |
| Reverse flow allowed | `false` | Modeling choice | Offshore-to-onshore unidirectional first version. |
| Inlet temperature mode | `fixed` | Modeling choice | V2 default. Avoids unphysical `T_in = T_seabed`. |
| Fixed pipe inlet temperature | `60 degC` | Literature-supported assumption / Temporary synthetic assumption | Inspired by Chen single-pipe validation. Use sensitivity. |
| Aftercooler setpoint | `35 degC` | Temporary synthetic assumption | Used only in `aftercooler` mode. |
| Temperature average method | `length_average` | Modeling choice | Recommended main model. |
| Alternative temperature average method | `endpoint_average` | Modeling choice | Legacy comparison only. |
| Inlet temperature sensitivity | `35/60/90 degC` | Modeling choice | Represents cooled / baseline / hot inlet cases. |

## Pipeline Heat-Exchange State

| Quantity | Current Typical Value | Classification | Notes / Action |
|---|---:|---|---|
| Pipe 1 `chi` | `25.89` | Derived from temporary assumptions | Very large because of high `U`, long `L`, low `m_ref`. |
| Pipe 2 `chi` | `27.31` | Derived from temporary assumptions | Same issue. |
| Pipe 1 `T_in` | `60 degC` | Temporary/literature-inspired boundary | Fixed inlet temperature. |
| Pipe 2 `T_in` | `60 degC` | Temporary/literature-inspired boundary | Fixed inlet temperature. |
| Pipe 1 static `T_out` | `~12.11 degC` | Derived | Strong cooling due to high `chi`. |
| Pipe 2 static `T_out` | `~10.66 degC` | Derived | Strong cooling due to high `chi`. |
| Pipe 1 static `T_gas` | `~13.96 degC` | Derived | Length-average representative temperature. |
| Pipe 2 static `T_gas` | `~12.47 degC` | Derived | Length-average representative temperature. |

## Compressor Model

| Parameter | Current Value | Classification | Notes / Action |
|---|---:|---|---|
| Isentropic efficiency | `0.85` | Literature-supported assumption | NETL-style default. |
| Motor efficiency | `0.96` | Literature-supported assumption | NETL-style default. |
| Motor sizing factor | `1.1` | Literature-supported assumption | NETL-style default. |
| Minimum pressure ratio | `1.0` | Modeling choice | Physical lower bound. |
| Maximum pressure ratio | `3.0` | Temporary synthetic assumption | Check engineering limits. |
| Compressor inlet temperature | `10 degC` | Temporary synthetic assumption | Used only in compressor outlet / aftercooler modes. |
| Compressor inlet temperature source | `pipeline_gas_temperature` | Modeling choice | Current power formula uses pipe representative temperature coefficient. |

## Electrolyser and Cost Parameters

| Parameter | Current Value | Classification | Notes / Action |
|---|---:|---|---|
| Electrolyser specific energy | `50 kWh/kg` | Literature-supported assumption | Reasonable first value. Add citation. |
| Compressor electricity price | `$80/MWh` | Temporary synthetic assumption | Replace with scenario price. |
| External H2 cost | `$8/kg` | Temporary synthetic assumption | Currently dominates objective. Needs scenario justification. |
| Unserved H2 penalty | `$100000/kg` | Modeling choice | Effectively enforces demand satisfaction. |
| Wind curtailment penalty | `$0/MWh` | Modeling choice | Curtailment is reported, not penalized. Consider opportunity value. |

## Storage Parameters

| Parameter | Current Value | Classification | Notes / Action |
|---|---:|---|---|
| Charge efficiency | `0.98` | Temporary synthetic assumption | Needs citation or sensitivity. |
| Discharge efficiency | `0.98` | Temporary synthetic assumption | Needs citation or sensitivity. |
| Final SOC at least initial | `true` | Modeling choice | Prevents storage depletion artifact. |
| Storage capacity | `380000 kg` | Temporary synthetic assumption | Synthetic placeholder. |
| Initial SOC | `190000 kg` | Temporary synthetic assumption | 50% of capacity. |
| Charge max | `65000 kg/h` | Temporary synthetic assumption | Synthetic placeholder. |
| Discharge max | `65000 kg/h` | Temporary synthetic assumption | Synthetic placeholder. |

## Synthetic Network Case

| Parameter | Current Value | Classification | Notes / Action |
|---|---:|---|---|
| Number of nodes | `3` | Temporary synthetic assumption | `OWF_A`, `OWF_B`, `ONSHORE_H2`. |
| Offshore nodes | `1, 2` | Temporary synthetic assumption | Synthetic topology. |
| Onshore node | `3` | Temporary synthetic assumption | Synthetic topology. |
| Wind A capacity | `900 MW` | Temporary synthetic assumption | Synthetic placeholder. |
| Wind B capacity | `700 MW` | Temporary synthetic assumption | Synthetic placeholder. |
| Wind profiles | synthetic sinusoidal | Temporary synthetic assumption | Replace with real wind data. |
| EL A max power | `650 MW` | Temporary synthetic assumption | Currently binds Pipe 1 flow. |
| EL B max power | `520 MW` | Temporary synthetic assumption | Currently binds Pipe 2 flow. |
| EL min power | `0 MW` | Modeling choice | No minimum load in first version. |

## Synthetic Pipeline Case

| Parameter | Pipe 1 | Pipe 2 | Classification | Notes / Action |
|---|---:|---:|---|---|
| Name | `Pipe_A_to_Shore` | `Pipe_B_to_Shore` | Temporary synthetic assumption | Synthetic labels. |
| From node | `1` | `2` | Temporary synthetic assumption | Offshore source nodes. |
| To node | `3` | `3` | Temporary synthetic assumption | Onshore demand node. |
| Length | `165 km` | `230 km` | Temporary synthetic assumption | Replace with North Sea route distances. |
| Diameter | `0.90 m` | `1.20 m` | Literature-supported assumption | Bødal-style small/large H2 pipeline sizes. |
| Roughness | `4.572e-5 m` | `4.572e-5 m` | Literature-supported assumption | Thawani X52 steel roughness assumption. |
| Heat-transfer coefficient | `5 W/(m^2 K)` | `5 W/(m^2 K)` | Temporary synthetic assumption | High impact; run sensitivity. |
| Design flow | `10.5 kg/s` | `18.5 kg/s` | Temporary synthetic assumption | Low relative to static capacity. Recalibrate. |
| Reference flow | `6.3 kg/s` | `11.1 kg/s` | Temporary synthetic assumption | `0.6 * design_flow`. Main cause of high `chi`. |
| Source pressure | `30 bar` | `30 bar` | Temporary synthetic assumption | Compressor/source pressure. |
| Pipe inlet max pressure | `80 bar` | `80 bar` | Literature-supported assumption | Bødal-style linepacking pressure. |
| Pipe outlet min pressure | `40 bar` | `40 bar` | Literature-supported assumption | Bødal-style linepacking pressure. |
| Static capacity | `~300,298 kg/h` | `~537,204 kg/h` | Derived from assumptions | Much larger than actual flow. |
| Case 1 actual max flow | `13,000 kg/h` | `10,400 kg/h` | Derived dispatch result | Bound by electrolyser, not pipe. |
| Max utilization | `4.33%` | `1.94%` | Derived dispatch result | Pipe constraints do not bind. |

## Demand and External Supply

| Parameter | Current Value | Classification | Notes / Action |
|---|---:|---|---|
| Demand node | `3` | Temporary synthetic assumption | Onshore node. |
| Base demand | `52000 kg/h` | Temporary synthetic assumption | Synthetic placeholder. |
| Demand profile | synthetic sinusoidal | Temporary synthetic assumption | Replace with real H2 demand scenario. |
| Daily demand | `~1.1232e6 kg/day` | Derived from synthetic profile | Current system needs external H2. |
| External supply node | `3` | Temporary synthetic assumption | Onshore supply fallback. |
| External supply max | `100000 kg/h` | Temporary synthetic assumption | Ensures feasibility. |

## Environmental Inputs

| Parameter | Pipe 1 | Pipe 2 | Classification | Notes / Action |
|---|---:|---:|---|---|
| Current seabed temperature range | `11.69-12.11 degC` | `10.36-10.66 degC` | Temporary synthetic assumption | Day-scale variation too small for final paper. |
| Environment source | synthetic representative warm-season day | synthetic representative warm-season day | Temporary synthetic assumption | Replace with CMEMS bottom temperature. |
| Future target | winter/summer/extreme seasonal days | winter/summer/extreme seasonal days | Modeling plan | Needed to show meaningful impact. |

## Current System-Level Result Diagnosis

| Quantity | Current Value | Interpretation |
|---|---:|---|
| Static objective | `5.662306e6` | Dominated by external H2 cost. |
| Partial objective | `5.662305e6` | Very close to static. |
| Dynamic objective | `5.662304e6` | Very close to static. |
| Static compressor energy | `56.862 MWh` | Small cost share. |
| Dynamic compressor energy | `56.830 MWh` | Difference only `0.032 MWh`. |
| External H2 supply | `707,219 kg` | Dominates objective at `$8/kg`. |
| Wind curtailment | `464.98 MWh` | Reported but not penalized. |
| Pipeline binding hours | `0` | Core reason system difference is tiny. |

## Parameters Most Urgently Needing Revision

| Priority | Parameter / Block | Reason |
|---|---|---|
| High | `design_flow_kg_s` and `m_ref` | Current values make `chi` very large and are inconsistent with static capacity. |
| High | Pipe sizing / pressure margins / electrolyser sizing | Current pipe utilization is only `2-4%`; dynamic pipe constraints never bind. |
| High | Heat-transfer coefficient `U` | Strongly controls `chi`, inlet temperature sensitivity, and cooling rate. |
| High | Seabed temperature profile | Current day-scale profile is too small; need seasonal representative days. |
| Medium | `T_in = 60 degC` | Good Chen-like baseline, but must include `35/60/90 degC` sensitivity. |
| Medium | External H2 cost | Dominates objective; may hide operational effects. |
| Medium | Wind curtailment penalty/opportunity value | Currently zero; may understate value of extra pipe capacity. |
| Medium | Storage size and rates | Synthetic values need scenario basis. |
| Medium | Pressure assumptions `30/80/40 bar` | Need final North Sea H2 engineering justification. |

## Literature Anchors To Use

| Topic | Candidate Source |
|---|---|
| Non-isothermal gas thermal model and `T_in = 60 degC` validation | Chen et al. 2021 TPWRS |
| North Sea H2 network, 900/1200 mm pipes, 80/40 bar style pressures | Bødal et al. 2024 Applied Energy |
| Steel pipe roughness / Darcy-Weisbach / Colebrook-White | Thawani et al. 2023 IJHE |
| Compressor efficiencies and engineering cost model defaults | NETL H2 Pipeline Cost Model 2024 |
| Real-gas EOS / H2 properties | Kuczyński et al. 2019; NIST/CoolProp for validation |

