# HRVAS-Python Roadmap

This document correlates the high-level goals of the project with the current implementation status.
AI Agents should check this file to understand "what is next" when starting a new session.

## Current Focus (Active Phase)
**Phase 1: Foundation & Core Porting**
- [x] Project Structure Setup
- [x] Basic Configuration System (`hrvas.config`)
- [x] Initial Data Structures (Dataclasses for results)
- [/] Porting Time Domain Analysis
    - [x] Basic statistical metrics (SDNN, RMSSD)
    - [x] Geometric methods (Triangular Index) base implementation
- [x] Porting Preprocessing (Artifact Detection, Detrending)

## Backlog (Future Phases)

### Phase 2: Validation & Benchmarking
- [ ] Validation against known reference results
- [ ] Comprehensive Test Suite coverage

### Phase 3: Advanced Analysis
- [ ] Porting Frequency Domain Analysis
- [ ] Nonlinear Analysis (Poincare, DFA, Sample Entropy)
- [ ] Time-Frequency Analysis
- [ ] Batch Processing capabilities

### Phase 4: Documentation & Release
- [ ] Comprehensive API Documentation
- [ ] Usage Examples / Jupyter Notebooks
- [ ] PyPI Release preparation

### Phase 5: Application Layer
- [ ] REST API or CLI interface
- [ ] Web/Desktop GUI (Long term)

## Change Log / Milestones
- **2024-01-xx**: Initial repo setup and standards definition.
