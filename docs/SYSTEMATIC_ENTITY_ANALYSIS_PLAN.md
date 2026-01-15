# Systematic Entity Analysis Plan - 58 Remaining Types

**Using**: ALL_ENTITY_TYPES_REFERENCE.md as roadmap  
**Strategy**: Analyze shared callbacks first (most efficient)  
**Goal**: Document all 58 remaining types

---

## Analysis Priority (Most Efficient Order)

### Priority 1: Shared Callback Groups (25 types via 10 callbacks)

**Callback 0x80080ddc** - 5 types (43, 44, 53, 54, 55):
- Portal/particle family
- Type 42, 60 already documented
- Analyze callback once, applies to all 5

**Callback 0x8007f050** - 3 types (86, 87, 88):
- Variant group A

**Callback 0x8007f0d0** - 3 types (106, 107, 108):
- Variant group B

**Callback 0x8007f140** - 3 types (112, 113, 114):
- Variant group C

**Callback 0x8007f1c0** - 3 types (115, 116, 117):
- Variant group D

**Callback 0x800812ec** - 3 types (85, 104, 105):
- Variant group E

**Callback 0x8008134c** - 5 types (89, 97, 98, 110, 111):
- Variant group F

**Total**: 25 types via 7 callback analyses

---

### Priority 2: Paired Types (5 types via 3 callbacks)

**Callback 0x8007efd0** - 2 types (0, 4):
- Type 3 already documented
- Same behavior as ammo

**Callback 0x80080c8c** - 1 type (52):
- Type 39 already documented as group

**Callback 0x80080e4c** - 1 type (47):
- Type 48 already documented

**Callback 0x80080c2c** - 1 type (46):
- Unique mechanism

**Total**: 5 types via 4 callback analyses

---

### Priority 3: Unique Callbacks (28 types)

Types with unique callbacks needing individual analysis:
- Type 1: 0x8007f730
- Types 57-59: 0x8007fd18, 0x8007fd94, 0x8007fe10
- Types 62-76: Various (13 types)
- Types 79-84, 90-96, 99-103, 109, 119-120: Various (18 types)

**Total**: 28 types needing individual analysis

---

## Execution Plan

**Phase 1**: Shared groups (7 callbacks) → 25 types  
**Phase 2**: Paired types (4 callbacks) → 5 types  
**Phase 3**: Unique callbacks (28 callbacks) → 28 types

**Total**: 39 callback analyses → 58 types documented

**Estimated Time**: 20-40 hours (30-60 min per callback)

---

**Strategy**: Start with Priority 1 for maximum coverage gain

