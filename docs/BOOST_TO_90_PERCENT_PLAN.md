# Boost All Systems to 90% Plan

**Current Status**: 95% overall, but some systems at 60-80%  
**Objective**: Bring all systems to 90%+ coverage  
**Time Estimate**: 15-20 hours

---

## Systems Needing Boost

| System | Current | Target | Gap | Priority |
|--------|---------|--------|-----|----------|
| Boss AI | 60% | 90% | +30% | HIGH |
| Projectiles | 70% | 90% | +20% | HIGH |
| Checkpoint | 70% | 90% | +20% | MEDIUM |
| Combat | 75% | 90% | +15% | MEDIUM |
| Enemy AI | 75% | 90% | +15% | LOW (already good) |
| Audio IDs | 80% | 90% | +10% | LOW |

---

## 1. Boss AI (60% → 90%) - 10-12 hours

**Current**: All 5 bosses identified, Joe-Head-Joe 100%, others estimated

**To 90% Needs**:
- Detailed attack patterns for each boss
- Phase transition mechanics
- Damage windows and vulnerabilities
- Boss-specific mechanics

**Method**: 
- Play each boss fight (2-3h total gameplay)
- Document observed patterns
- Extract from C code where possible

**Deliverables**:
- Update each boss doc with verified patterns
- Add attack timing charts
- Document phase transitions
- Add strategy guides

---

## 2. Projectiles (70% → 90%) - 3-4 hours

**Current**: Spawn system complete, damage system partial

**To 90% Needs**:
- Projectile collision detection details
- Exact damage values
- Projectile lifetime/despawn
- Hitbox sizes

**Method**:
- Analyze projectile tick callbacks in C code
- Extract damage calculation code
- Document collision masks

**Deliverables**:
- Projectile collision system doc
- Damage values table
- Lifetime/despawn mechanics

---

## 3. Checkpoint (70% → 90%) - 2-3 hours

**Current**: Save/restore complete, some gaps

**To 90% Needs**:
- Respawn position calculation
- Death counter integration
- Checkpoint entity details
- Ma-Bird entity documentation

**Method**:
- Analyze RespawnAfterDeath function
- Document Ma-Bird entity type
- Extract respawn coordinate system

**Deliverables**:
- Complete respawn flow
- Ma-Bird entity doc
- Death/checkpoint integration

---

## 4. Combat (75% → 90%) - 2-3 hours

**Current**: System understood, values missing

**To 90% Needs**:
- Enemy HP values (per type)
- Projectile damage values
- Invincibility frame durations
- Knockback velocities

**Method**:
- Extract from entity callback code
- Search for HP initialization
- Document damage constants

**Deliverables**:
- Enemy HP table
- Damage values reference
- Combat constants doc

---

## 5. Enemy AI (75% → 90%) - 3-4 hours

**Current**: 41 types, patterns documented

**To 90% Needs**:
- 10-15 more specific enemy behaviors
- Enemy movement speeds
- Attack patterns for aggressive enemies
- State machine details

**Method**:
- Analyze 10-15 more entity callbacks
- Extract movement constants
- Document attack behaviors

**Deliverables**:
- 10-15 more enemy type docs
- Movement speed reference
- Attack pattern catalog

---

## 6. Audio IDs (80% → 90%) - 1-2 hours

**Current**: 35 sound IDs extracted

**To 90% Needs**:
- 10-15 more sound IDs
- Context for existing IDs
- Sound trigger conditions

**Method**:
- Search for more PlaySoundEffect calls
- Analyze calling contexts
- Cross-reference with gameplay

**Deliverables**:
- 45-50 total sound IDs
- Sound context table
- Trigger condition doc

---

## Execution Strategy

### Phase 1: Quick Wins (5-6 hours)

1. Checkpoint system (+20%) - 2-3h
2. Audio IDs (+10%) - 1-2h
3. Combat values (+15%) - 2-3h

**Result**: 3 systems to 90%

### Phase 2: Medium Effort (6-8 hours)

4. Projectiles (+20%) - 3-4h
5. Enemy AI (+15%) - 3-4h

**Result**: 2 more systems to 90%

### Phase 3: Boss Details (10-12 hours)

6. Boss AI (+30%) - Requires gameplay or deep analysis

**Result**: All systems at 90%

---

## Total Impact

**Systems at 90%+**: Currently 10 → Target 16 (all systems)  
**Overall**: 95% → 96-97% (quality improvement)  
**Time**: 15-25 hours total

---

**Recommendation**: Execute Phases 1-2 (12-14 hours) to get 5/6 systems to 90%, defer Boss AI detailed verification for gameplay session.

