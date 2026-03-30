# Geometric Embeddings Experiments

Phase 0: Concept Validation (2-3 weeks)

## Goal
Quantitative comparison of Euclidean vs Hyperbolic vs Spherical embeddings on standard semantic tasks.

## Datasets
- **WordNet** (hierarchical relations)
- **BATS** (analogy relations)
- **SimLex-999** (similarity)

## Evaluation Metrics
- Mean rank (MR)
- Mean average precision (MAP)
- Spearman's correlation (ρ)
- Training time

## Success Criteria
- Hyperbolic embeddings achieve at least **20% lower mean rank** than Euclidean on WordNet
- Or spherical embeddings show statistically significant improvement on any task
- If no significant improvement, project pauses

## Directory Structure
```
shared/experiments/geom_embed/
├── configs/          # Experiment configurations
├── scripts/          # Training/evaluation scripts
├── results/          # Experimental results
└── visualization/    # Visualization scripts (optional)
```

## Baseline Models
1. Euclidean (standard baseline)
2. Poincaré ball (hyperbolic)
3. Unit sphere (spherical)

## Implementation
- Python 3.11+
- PyTorch 2.3+
- geoopt for Riemannian optimization
- Scripts designed to run locally or on Colab