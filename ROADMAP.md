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
    - [ ] Validation against MATLAB results
- [ ] Porting Frequency Domain Analysis
- [ ] Porting Preprocessing (Detrending, Filtering)

## Backlog (Future Phases)

### Phase 2: Advanced Analysis
- [ ] Nonlinear Analysis (Poincare, DFA, Sample Entropy)
- [ ] Time-Frequency Analysis
- [ ] Batch Processing capabilities

### Phase 3: Documentation & Release
- [ ] Comprehensive API Documentation
- [ ] Usage Examples / Jupyter Notebooks
- [ ] PyPI Release preparation

### Phase 4: Application Layer
- [ ] REST API or CLI interface
- [ ] Web/Desktop GUI (Long term)

## Change Log / Milestones
- **2024-01-xx**: Initial repo setup and standards definition.
