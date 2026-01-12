# ABYSS DIVER — Complete Game Design Document v0.0.0.1

---

## 1. Core Vision

> **"From humble net to legendary harpoon — conquer the depths, one catch at a time."**

| Aspect | Detail |
|--------|--------|
| **Genre** | Roguelite Collector / Resource Management |
| **Theme** | Deep sea diving, treasure hunting, survival |
| **Core Loop** | Dive → Collect → Survive → Upgrade → Repeat |

---

## 2. Entity Taxonomy

### 2.1 Collectibles (Evolving Rewards)

| Tier | Entity | Value | Spawn Score | Capture Method |
|------|--------|-------|-------------|----------------|
| **T1** | Pearl | 10 | 0+ | Auto (Touch) |
| **T2** | Small Fish | 25 | 50+ | Net/Touch |
| **T3** | Medium Fish | 50 | 150+ | Hook Required |
| **T4** | Large Fish | 100 | 300+ | Harpoon Required |
| **T5** | Treasure Chest | 250 | 500+ | Drone Required |

### 2.2 Enemies (Evolving Threats)

| Tier | Entity | Behavior | Spawn Score |
|------|--------|----------|-------------|
| **T1** | Sea Mine | Falls straight | 0+ |
| **T2** | Drifting Mine | Horizontal drift | 100+ |
| **T3** | Jellyfish | Slow tracking | 200+ |
| **T4** | Shark | Fast, aggressive pursuit | 400+ |
| **T5** | Angler Boss | Mini-boss, area denial | 750+ |

---

## 3. Equipment Progression

### 3.1 Tool Evolution Tree

```
[Bare Hands] (Start)
     ↓
[Collector Net] (Score 50) — Auto-collect T1-T2
     ↓
[Grappling Hook] (Score 150) — Pull T1-T3
     ↓
[Harpoon Gun] (Score 350) — Stun + Collect T1-T4
     ↓
[Capture Drone] (Score 600) — Auto-collect all tiers
```

### 3.2 Passive Equipment (Shop Purchases)

| Equipment | Cost | Effect |
|-----------|------|--------|
| **Oxygen Tank+** | 500 | +20% survival time |
| **Pressure Suit** | 800 | Survive 1 hit |
| **Sonar** | 600 | Enemies glow when close |
| **Magnet Belt** | 400 | +50% collection range |

---

## 4. Economy System

### 4.1 Dual Currency

| Currency | Source | Use |
|----------|--------|-----|
| **Pearls** | In-run collection | Temporary power-ups |
| **Abyss Shards** | End-of-run conversion | Permanent upgrades |

### 4.2 Conversion Rate
```
Abyss Shards = Total Pearls Collected × (1 + Depth Layer Bonus)
```

---

## 5. Meta-Progression (Shop Screen)

| Category | Items |
|----------|-------|
| **Starting Gear** | Net, Hook, Harpoon (unlock order) |
| **Passive Buffs** | Speed+, Range+, Luck+ |
| **Companions** | Helper Fish, Drone Bot |

---

## 6. UI/UX Overhaul

### 6.1 Required Screens
1. **Title Screen** — Animated ocean background, "DIVE" button
2. **Shop Screen** — Between runs, spend Abyss Shards
3. **HUD** — Score, Depth Layer, Equipment Icon, Oxygen Bar
4. **Game Over** — Stats summary, "Pearls Earned", "Abyss Shards"

### 6.2 Visual Polish
- Equipment icon with durability/level indicator
- Depth meter (vertical bar, left side)
- Enemy warning indicators at screen edges
- Collection particles (sparkle on catch)

---

## 7. Architecture Principles

### 7.1 System Modularity
Every feature = isolated system with clear signals:
- `CollectibleSystem` — Manages all collectible types
- `EnemySystem` — Manages all enemy types  
- `EquipmentSystem` — Manages tool state and evolution
- `EconomySystem` — Manages currencies and shop

### 7.2 Clean Code Rules
- No hardcoded values (use constants/exports)
- Remove unused assets after each phase
- Document all public functions
- Signal-based communication only

---

## 8. Implementation Phases

### Phase B1: Entity Expansion
- [ ] Rename `Coin` → `Collectible` (base class)
- [ ] Add entity subtypes (Pearl, SmallFish, MediumFish)
- [ ] Add enemy subtypes (Jellyfish, Shark)

### Phase B2: Equipment System
- [ ] Create `EquipmentSystem.gd`
- [ ] Implement tool tiers (Net → Hook → Harpoon)
- [ ] Capture requirements based on tool tier

### Phase B3: Economy & Shop
- [ ] Create `EconomySystem.gd` (dual currency)
- [ ] Create Shop UI screen
- [ ] Implement permanent upgrades

### Phase B4: UI/UX Polish
- [ ] Redesign HUD with equipment/depth indicators
- [ ] Add transition animations between screens
- [ ] Implement collection particles

---

*Document Version: 0.0.0.1*
*Last Updated: 2026-01-12*
