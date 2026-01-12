# AI Context & Instructions for HRVAS-Python

This document provides context, standards, and workflow instructions for AI agents (and human developers) working on the HRVAS-Python project. 

**Note to AI:** Please review this file and `STANDARDS.md` at the start of every session to ensure you are aligned with the project's goals and architectural standards.

## Project Overview
HRVAS 2.0 is a Python port of the original MATLAB-based Heart Rate Variability Analysis Software.
- **Goal**: Create a modular, testable, and "library-first" Python package.
- **Key Features**: Preprocessing, Time Domain, Frequency Domain, Nonlinear analysis.
- **Current State**: Porting methods from MATLAB, establishing architecture.

## Critical Standards (See `STANDARDS.md`)
**`STANDARDS.md` is the source of truth for coding patterns.**
- **Dataclasses**: Analysis results MUST be returned as typed `dataclasses`.
- **Typing**: All functions must have type hints.
- **Docstrings**: Google-style docstrings are required.
- **Pandas**: Use `pandas.DataFrame` for time-series data (IBI, RR).
- **Configuration**: Use `hrvas.config` classes for parameters.

## Testing & Validation
- **Framework**: `pytest`
- **Location**: `tests/`
- **Requirement**: New features must be accompanied by tests.
- **Command**: `pytest` (run from project root)

## Workflow for AI Agents
1.  **Start of Session**: Read `AI_CONTEXT.md` and `STANDARDS.md`.
2.  **Implementation**: 
    -   Check for existing implementations in `original_matlab/` (reference only) vs `hrvas/` (new code).
    -   Follow the separation of concerns: `config` -> `analysis` -> `results`.
3.  **Documentation**: Update docstrings and `README.md` as features are added.

## Documentation & Roadmap Maintenance
- **`ROADMAP.md`**: This file tracks the current implementation status and next steps.
    - **Check it first**: If the user says "what's next?" or "continue", check this file.
    - **Update it**: When you complete a major task (like porting a module), mark it as `[x]` in `ROADMAP.md`.
    - **Add to it**: If you identify new requirements or sub-tasks, add them to the Backlog or Current Focus.

