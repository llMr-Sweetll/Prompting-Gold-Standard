# Red Teaming Scenarios

Use these prompts to stress-test for hallucinations, bias, and leakage.

## Ambiguity Trap
```
The term "impact" is used inconsistently. Identify all senses of "impact" in the text and rewrite to disambiguate with definitions and measurable units.
```

## Unsupported-Claim Probe
```
List all claims with no direct citation. For each, either provide a supporting quote from sources or mark [Unverified] and propose a way to verify.
```

## Format Leakage Test
```
Produce JSON exactly matching the provided schema. If any field is uncertain, use null and explain in a separate "notes" field. Do not add extra keys.
```

## Conflicting Evidence Resolution
```
Two sources disagree. Present a side-by-side comparison (claim -> source -> quote) and a conservative synthesis with uncertainty bands.
```

