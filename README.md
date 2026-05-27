# IEEE PES GM 2027 Offshore Hydrogen MATLAB Code

This folder implements the first code version for:

`Optimal Operation of Offshore Hydrogen Networks Considering Seabed Temperature-Driven Dynamic Pipeline Flow Constraints`

## Structure

- `main.m` runs the full workflow.
- `data/` contains global parameters and seabed-temperature inputs.
- `case/` contains the synthetic test system and North Sea case interface stubs.
- `physical/` maps seabed temperature to gas temperature, real-gas properties, Darcy friction factor, pressure-flow coefficient, capacity, and compressor specific energy.
- `opf/` builds and solves the reduced-order system dispatch LP.
- `post/` exports hourly and scenario-comparison results.
- `validation/` writes physical-layer and dispatch consistency checks.

## Current Model Scope

The first version follows the reduced-order approach in the article idea:

1. Use seabed temperature as exogenous input.
2. Compute pipe outlet temperature by an exponential heat-exchange model.
3. Compute representative pipe gas temperature from the length average of
   the exponential temperature profile.
4. Compute hydrogen compressibility with Peng-Robinson EOS.
5. Compute viscosity, Reynolds number, and Darcy friction factor with Colebrook-White.
6. Compute hourly pipe pressure-flow coefficient and maximum H2 transport capacity.
7. Run system dispatch using precomputed pipe limits and compressor energy coefficients.

The optimization layer does not solve a full nonlinear non-isothermal gas-flow problem. This is intentional: the reference flow is used offline to update coefficients, while the dispatch model remains a tractable LP.

## Version 2 Thermal Boundary

The default pipe inlet temperature is no longer set equal to seabed
temperature. The default assumption is:

```matlab
params.pipeline.inlet_temperature_mode = 'fixed';
params.pipeline.fixed_inlet_temperature_c = 60;
params.pipeline.temperature_average_method = 'length_average';
```

This represents a post-compression or aftercooling thermal boundary at the
pipe inlet. Seabed temperature is the external heat-transfer boundary.

The model also supports:

- `seabed_equilibrium`: legacy prototype assumption, `T_in = T_seabed`.
- `fixed`: fixed pipe inlet temperature, default 60 degC.
- `aftercooler`: compressor outlet temperature capped by an aftercooler setpoint.
- `compressor_outlet`: simplified isentropic compressor outlet temperature.

The representative pipe gas temperature can be switched between:

- `length_average`: length average of the exponential profile, recommended.
- `endpoint_average`: legacy `(T_in + T_out)/2`, retained for comparison.

Additional validation outputs:

- `sensitivity_temperature_inlet.csv`
- `sensitivity_physical_decomposition.csv`
- `chen_like_single_pipe_validation.csv`

## Parameters To Revisit Before Paper Submission

- Hydrogen viscosity correlation: current code uses a Sutherland-style approximation. For final results, replace or validate with CoolProp/NIST tables.
- Peng-Robinson EOS: transparent and consistent with the article idea, but high-pressure H2 may need validation against a property library.
- Pipe heat-transfer coefficient: currently a first-pass engineering value. It should be calibrated or supported by the final reference set.
- Pipe inlet temperature: default 60 degC follows Chen-like non-isothermal validation logic, but final paper results should include 35/60/90 degC sensitivity.
- Static conservative temperature: current rule uses the maximum seabed temperature in the study horizon. The paper should justify whether max, seasonal high, or another conservative percentile is most appropriate.
- Synthetic demand/wind/topology: only a placeholder until the real North Sea case is supplied.
