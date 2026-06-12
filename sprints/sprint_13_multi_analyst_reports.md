# Sprint 13 - Multi-Analyst Reports

## Goal

Build the Bull, Bear, Centrist, and Lead Analyst report generation flow.

## Checklist

- [x] Add prompt builders for Bull Analyst, Bear Analyst, Centrist Analyst, and Lead Analyst.
- [x] Add final report assembly from all expert outputs.
- [x] Request and parse structured JSON.
- [x] Include asset data, chart data, news context, optional note, and screenshot context when available.
- [x] Add AI Report UI with Lead Analyst conclusion first.
- [x] Show each expert's risk assessment on their card.
- [x] Add per-report educational disclaimer.

## Acceptance Criteria

- Reports avoid buy/sell commands, price targets, and guarantees.
- Lead Analyst conclusion is balanced and uncertainty-aware.
- Partial failures produce useful error states.
- Every report includes the required educational disclaimer.
