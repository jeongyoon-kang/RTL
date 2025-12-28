# Lab 3: Results and Observations

## Overview

This document provides detailed analysis and observations from the delta cycle case studies. Each case demonstrates the critical differences between blocking (`=`) and non-blocking (`<=`) assignments in Verilog testbenches, and their interaction with the DUT through delta cycles.

---

## Background Exercises: Understanding `@(posedge clk)` Placement

### Overview

Before diving into delta cycle race condition analysis, we first explore how `@(posedge clk)` placement affects stimulus timing. Both examples use **non-blocking assignments (`<=`)** to drive DUT inputs (race-free), so the focus is purely on **timing behavior**.

### Background Example 1 (basic1): `@(posedge clk)` INSIDE for-loop

**Testbench Pattern:**
```verilog
for (i = 0; i < 5; i = i + 1) begin
    @(posedge clk);          // Wait for clock edge INSIDE loop
    i_valid_tb <= 1'b1;      // Non-blocking assignment
    i_data_tb <= test_values[i];
end
```

**Expected Behavior:**
- Each iteration waits for a clock edge, then schedules signal updates
- Total time: **5 clock cycles** (one per iteration)
- Each test value is applied on a separate clock edge

**Timing Diagram:**
```
clk:      _/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_
          T0  T1  T2  T3  T4  T5
               ↓   ↓   ↓   ↓   ↓
i_data:   X   D0  D1  D2  D3  D4   (updates at each posedge)
i_valid:  0    1   1   1   1   1
```

**Observations:**
- [ ] Waveform screenshot: `images/basic1.png`
- [ ] Confirm 5 separate clock cycles for 5 values
- [ ] Each `test_values[i]` appears on different clock edge
- [ ] This is the **CORRECT** pattern for sequential stimulus

![alt text](images/basic1.png)

---

### Background Example 2 (basic2): `@(posedge clk)` OUTSIDE for-loop

**Testbench Pattern:**
```verilog
for (i = 0; i < 5; i = i + 1) begin
    i_valid_tb <= 1'b1;      // Non-blocking assignment
    i_data_tb <= test_values[i];  // Loop runs in ZERO time!
end
@(posedge clk);              // Wait for clock edge OUTSIDE (after loop)
```

**Expected Behavior:**
- Loop completes **instantly** (same simulation time) - all 5 iterations at T0
- Each `<=` schedules an update, but later schedules overwrite earlier ones
- Only the **LAST value** (`test_values[4]`) is captured!
- Total time: **1 clock cycle**

**Timing Diagram:**
```
clk:      _/‾\_/‾\_
          T0  T1
               ↓
i_data:   X   D4   (only LAST value visible!)
i_valid:  0    1

At T0: Loop schedules D0, D1, D2, D3, D4 (all at same time)
       But each <= to same signal overwrites previous schedule
       Only D4 remains when NBA region executes
```

**Observations:**
- [ ] Waveform screenshot: `images/basic2.png`
- [ ] Confirm only 1 clock cycle used despite 5 iterations
- [ ] Confirm only `test_values[4]` (0x0000000A) appears in waveform
- [ ] This is a **COMMON BUG** - loop appears to work but loses data!

![alt text](images/basic2.png)


---

### Comparison: basic1 vs basic2

| Aspect | basic1 (inside loop) | basic2 (outside loop) |
|--------|---------------------|----------------------|
| **`@(posedge clk)` location** | Inside for-loop | Outside for-loop |
| **Clock cycles used** | 5 cycles | 1 cycle |
| **Data captured by DUT** | All 5 values | Only last value (D4) |
| **Loop execution time** | 5 clock periods | 0 time (instant) |
| **Common use case** | Sequential stimulus | ⚠️ Usually a BUG! |

### Key Learning

This background exercise demonstrates that **`@(posedge clk)` placement fundamentally changes timing behavior**, even when using non-blocking assignments correctly:

1. **basic1 (inside loop)**: Proper sequential stimulus generation
   - Each value gets its own clock cycle
   - DUT can process each value separately

2. **basic2 (outside loop)**: Common mistake leading to data loss
   - Loop runs instantly, scheduling multiple updates to same signal
   - Only the last scheduled value survives to NBA region
   - **4 out of 5 values are LOST!**

**Important**: This is NOT a race condition issue (both use non-blocking assignments). This is a **timing/scheduling** issue caused by misunderstanding when `@(posedge clk)` executes relative to the loop.

---

## Case 1: Assignment After @(posedge clk)

### Test Description

Both Case 1A and Case 1B drive input signals **after** waiting for the clock edge using a for loop in an initial block:

```verilog
for (i = 0; i < 5; i = i + 1) begin
    @(posedge clk);
    // Assignment happens HERE (after clock edge)
    i_valid_tb = 1'b1;   // Case 1A: Blocking
    // OR
    i_valid_tb <= 1'b1;  // Case 1B: Non-blocking
end
```

### Case 1A: Blocking Assignment (Race Condition)

![Case 1A Waveform](images/case1a_waveform.png)

#### Key Observations:

1. **Race Condition Present**: The testbench uses blocking assignment (`=`) which executes immediately in the Active Region, creating a race condition with the DUT.

2. **Unpredictable Behavior**: Since both the TB and DUT execute in the Active Region at the same clock edge, the execution order is **undefined by IEEE 1364 standard**.

3. **Simulator Dependency**: The actual behavior depends on which scenario the simulator chooses. Different simulators (Vivado, ModelSim, Icarus) or different versions may produce different results.

#### Delta Cycle Analysis (T=30ns, first data after reset):

```
═══════════════════════════════════════════════════════════════════════════════
                         TIME T=30ns: posedge clk occurs
═══════════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────────┐
│ ACTIVE REGION                                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│ Both blocks are triggered and ready to execute:                             │
│                                                                             │
│   TB initial block              DUT always block                            │
│   ──────────────────            ─────────────────                           │
│   @(posedge clk);               always @(posedge clk)                       │
│   i_valid_tb = 1'b1;  ←─?─→     r_valid[0] <= i_valid;                      │
│   i_data_tb = 0x02;             r_power_of_2 <= i_data * i_data;            │
│                                                                             │
│ ⚠️  Which block executes first? → UNDEFINED by IEEE standard!               │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ SCENARIO A: TB executes first                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Step 1: TB runs                                                           │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ i_valid_tb = 1'b1;  → i_valid changes 0→1 IMMEDIATELY        │          │
│   │ i_data_tb = 0x02;   → i_data changes 0→2 IMMEDIATELY         │          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
│   Step 2: DUT runs (after TB finished)                                      │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ r_valid[0] <= i_valid;  → read i_valid (sees 1'b1 - NEW!)    │          │
│   │                         → [SCHEDULE TO NBA]: r_valid[0] = 1  │          │
│   │ r_power_of_2 <= 2*2;    → read i_data (sees 0x02 - NEW!)     │          │
│   │                         → [SCHEDULE TO NBA]: r_power_of_2 = 4│          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
│   Result: DUT captures NEW values at SAME clock edge (no delay!)            │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ SCENARIO B: DUT executes first                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Step 1: DUT runs                                                          │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ r_valid[0] <= i_valid;  → read i_valid (sees 1'b0 - OLD!)    │          │
│   │                         → [SCHEDULE TO NBA]: r_valid[0] = 0  │          │
│   │ r_power_of_2 <= 0*0;    → read i_data (sees 0x00 - OLD!)     │          │
│   │                         → [SCHEDULE TO NBA]: r_power_of_2 = 0│          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
│   Step 2: TB runs (after DUT finished)                                      │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ i_valid_tb = 1'b1;  → i_valid changes 0→1 (but too late!)    │          │
│   │ i_data_tb = 0x02;   → i_data changes 0→2 (but too late!)     │          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
│   Result: DUT captures OLD values, sees NEW at NEXT clock edge              │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ 🚨 THIS IS THE RACE CONDITION!                                              │
│    Same code, same time T=30ns, but different results depending on          │
│    which block the simulator chooses to run first!                          │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ NBA REGION (after Active region completes)                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   All scheduled non-blocking updates execute now:                           │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ r_valid[0] ← ???    (1 if Scenario A, 0 if Scenario B)       │          │
│   │ r_power_of_2 ← ???  (4 if Scenario A, 0 if Scenario B)       │          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Comparison of Scenarios:

| Aspect | Scenario A (TB first) | Scenario B (DUT first) |
|--------|----------------------|------------------------|
| **i_valid when DUT reads** | 1 (NEW) | 0 (OLD) |
| **i_data when DUT reads** | 0x02 (NEW) | 0x00 (OLD) |
| **r_valid[0] after NBA** | 1 | 0 |
| **r_power_of_2 after NBA** | 4 | 0 |
| **First valid output** | T=30ns | T=40ns |

### Case 1B: Non-blocking Assignment (Race-Free)

![Case 1B Waveform](images/case1b_waveform.png)

#### Key Observations:

1. **No Race Condition**: The testbench uses non-blocking assignment (`<=`) which schedules updates to the NBA Region, avoiding race conditions.

2. **Predictable Behavior**: The execution order is **well-defined** because reads and writes happen in different regions.

3. **One Clock Cycle Delay**: Input changes are visible to the DUT at the **next clock edge**, providing setup time for proper operation.

#### Delta Cycle Analysis (T=30ns, first data after reset):

```
═══════════════════════════════════════════════════════════════════════════════
                         TIME T=30ns: posedge clk occurs
═══════════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────────┐
│ ACTIVE REGION                                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│ Both blocks are triggered and ready to execute:                             │
│                                                                             │
│   TB initial block              DUT always block                            │
│   ──────────────────            ─────────────────                           │
│   @(posedge clk);               always @(posedge clk)                       │
│   i_valid_tb <= 1'b1; ←─?─→     r_valid[0] <= i_valid;                      │
│   i_data_tb <= 0x02;            r_power_of_2 <= i_data * i_data;            │
│                                                                             │
│ Order still UNDEFINED, but it DOESN'T MATTER with non-blocking!             │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ SCENARIO A: TB executes first (same result as B!)                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Step 1: TB runs                                                           │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ i_valid_tb <= 1'b1; → [SCHEDULE TO NBA]: i_valid = 1         │          │
│   │                       (i_valid is STILL 0 now!)              │          │
│   │ i_data_tb <= 0x02;  → [SCHEDULE TO NBA]: i_data = 0x02       │          │
│   │                       (i_data is STILL 0 now!)               │          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
│   Step 2: DUT runs (after TB finished)                                      │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ r_valid[0] <= i_valid;  → read i_valid (sees 1'b0 - OLD)     │          │
│   │                         → [SCHEDULE TO NBA]: r_valid[0] = 0  │          │
│   │ r_power_of_2 <= 0*0;    → read i_data (sees 0x00 - OLD)      │          │
│   │                         → [SCHEDULE TO NBA]: r_power_of_2 = 0│          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ SCENARIO B: DUT executes first (same result as A!)                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Step 1: DUT runs                                                          │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ r_valid[0] <= i_valid;  → read i_valid (sees 1'b0 - OLD)     │          │
│   │                         → [SCHEDULE TO NBA]: r_valid[0] = 0  │          │
│   │ r_power_of_2 <= 0*0;    → read i_data (sees 0x00 - OLD)      │          │
│   │                         → [SCHEDULE TO NBA]: r_power_of_2 = 0│          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
│   Step 2: TB runs (after DUT finished)                                      │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ i_valid_tb <= 1'b1; → [SCHEDULE TO NBA]: i_valid = 1         │          │
│   │ i_data_tb <= 0x02;  → [SCHEDULE TO NBA]: i_data = 0x02       │          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ ✅ NO RACE CONDITION!                                                        │
│    Both scenarios produce IDENTICAL results because:                        │
│    - TB only SCHEDULES updates (doesn't change values immediately)          │
│    - DUT always reads OLD values in Active Region                           │
│    - Updates happen together in NBA Region (after all reads)                │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ NBA REGION (after Active region completes)                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   All scheduled non-blocking updates execute now:                           │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ i_valid_tb ← 1      (TB's scheduled update)                  │          │
│   │ i_data_tb ← 0x02    (TB's scheduled update)                  │          │
│   │ r_valid[0] ← 0      (DUT's scheduled update - read OLD)      │          │
│   │ r_power_of_2 ← 0    (DUT's scheduled update - read OLD)      │          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
│   Result: i_valid=1, i_data=0x02, but DUT captured OLD values (0, 0)        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════════
                         TIME T=40ns: next posedge clk
═══════════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────────┐
│ ACTIVE REGION                                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   DUT runs:                                                                 │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ r_valid[0] <= i_valid;  → read i_valid (sees 1'b1 - NEW!)    │          │
│   │                         → [SCHEDULE TO NBA]: r_valid[0] = 1  │          │
│   │ r_power_of_2 <= 2*2;    → read i_data (sees 0x02 - NEW!)     │          │
│   │                         → [SCHEDULE TO NBA]: r_power_of_2 = 4│          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ NBA REGION                                                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ r_valid[0] ← 1      (DUT finally captures valid!)            │          │
│   │ r_power_of_2 ← 4    (DUT finally captures data!)             │          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
│   Result: Consistent one-cycle delay, predictable across all simulators     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Why Non-blocking Avoids Race Conditions:

| Aspect | Scenario A (TB first) | Scenario B (DUT first) |
|--------|----------------------|------------------------|
| **i_valid when DUT reads** | 0 (OLD) | 0 (OLD) |
| **i_data when DUT reads** | 0x00 (OLD) | 0x00 (OLD) |
| **r_valid[0] after NBA** | 0 | 0 |
| **r_power_of_2 after NBA** | 0 | 0 |
| **First valid output** | T=40ns | T=40ns |

**Key Insight**: Both scenarios produce **identical results** because non-blocking assignments separate READ (Active Region) from WRITE (NBA Region)!

### Comparison: Case 1A vs Case 1B

| Aspect | Case 1A (Blocking) | Case 1B (Non-blocking) |
|--------|-------------------|----------------------|
| **Assignment Type** | `i_valid_tb = 1'b1` | `i_valid_tb <= 1'b1` |
| **Execution Region** | Active (immediate) | Active (RHS eval) + NBA (update) |
| **Race Condition** | YES | NO |
| **Behavior** | Simulator-dependent | Well-defined |
| **First Valid Capture** | T=10ns or T=20ns (unpredictable) | T=20ns (predictable) |
| **Portability** | Poor (different simulators may differ) | Excellent (consistent across simulators) |
| **Setup Time** | May violate (same-cycle update possible) | Guaranteed (one-cycle delay) |

### Signal Path Analysis

Both `i_valid` and `i_data` paths are affected by the race condition in Case 1A:

#### i_valid Path (Direct):
```verilog
// DUT
always @(posedge clk) begin
    r_valid[0] <= i_valid;  // Direct register path
end
```
- **Case 1A**: Race condition clearly visible in waveform (timing varies)
- **Case 1B**: Consistent one-cycle delay

#### i_data Path (Through Combinational Logic):
```verilog
// DUT
assign power_of_2 = i_data * i_data;  // Combinational

always @(posedge clk) begin
    r_power_of_2 <= power_of_2;  // Register combinational result
end
```
- **Case 1A**: Race condition exists but may be less visible in waveform
  - Combinational logic (`power_of_2`) evaluates in Active Region
  - Same race condition as i_valid, but manifestation may differ
  - Simulator-dependent behavior
- **Case 1B**: Consistent behavior
  - Combinational logic evaluates with old `i_data` value
  - Updates propagate to register at next clock edge

**Important Note**: The presence of combinational logic does **not** eliminate the race condition with blocking assignments. Both direct and combinational paths suffer from the same Active Region execution order uncertainty. The race affects **which value** gets processed, not the timing of register updates.

### Recommendations

1. **Always use non-blocking assignments (`<=`) in testbenches** when driving clocked DUT inputs from clocked always blocks or after `@(posedge clk)`.

2. **Blocking assignments (`=`) are only safe** in initial blocks for initialization or when there's guaranteed separation from DUT clock edges.

3. **Test across multiple simulators** if blocking assignments are used, as behavior may vary.

4. **Understand delta cycle regions**:
   - Active Region: Blocking assignments execute, non-blocking RHS evaluated
   - NBA Region: Non-blocking assignments update
   - Proper separation prevents race conditions

---

## Case 2: Assignment Before @(posedge clk)

### Test Description

Both Case 2A and Case 2B drive input signals **before** waiting for the clock edge using a for loop in an initial block:

```verilog
for (i = 0; i < 5; i = i + 1) begin
    // Assignment happens HERE (before clock edge)
    i_valid_tb = 1'b1;   // Case 2A: Blocking
    // OR
    i_valid_tb <= 1'b1;  // Case 2B: Non-blocking
    @(posedge clk);      // Then wait for clock
end
```

### Case 2A: Blocking Assignment (Still Has Race Condition!)

![Case 2A Waveform](images/case2a_waveform.png)

#### Key Observations:

1. **Race Condition Present**: Despite assigning "before" the `@(posedge clk)`, this pattern **still creates a race condition**.

2. **Common Misconception**: Many designers think "assign before @(posedge clk)" is safe with blocking assignments. **This is FALSE** - the race occurs on every iteration after the first.

3. **Why Race Occurs**: After `@(posedge clk)` completes, the loop continues immediately at the **same simulation time** as the clock edge!

#### Delta Cycle Analysis (T=40ns, second iteration):

```
═══════════════════════════════════════════════════════════════════════════════
                         TIME T=40ns: posedge clk occurs
═══════════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────────┐
│ Why does the race occur on EVERY iteration?                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   TB Pattern (Case 2A):           What actually happens:                    │
│   ─────────────────────           ──────────────────────                    │
│   for (i = 0; i < 5; i++) begin                                             │
│       i_valid_tb = 1;   ──┐                                                 │
│       i_data_tb = val;    │       All execute at SAME TIME                  │
│       @(posedge clk); ────┘       as the clock edge!                        │
│   end                                                                       │
│                                                                             │
│   After @(posedge clk) at T=30ns completes, loop continues:                 │
│   → i=1: i_valid_tb = 1 executes at T=40ns (same time as next posedge!)     │
│   → DUT also triggers at T=40ns                                             │
│   → RACE CONDITION!                                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ ACTIVE REGION                                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│ Both blocks are triggered and ready to execute:                             │
│                                                                             │
│   TB initial block              DUT always block                            │
│   ──────────────────            ─────────────────                           │
│   i_valid_tb = 1'b1;  ←─?─→     always @(posedge clk)                       │
│   i_data_tb = 0x03;             r_valid[0] <= i_valid;                      │
│   @(posedge clk);               r_power_of_2 <= i_data * i_data;            │
│                                                                             │
│ ⚠️  Which block executes first? → UNDEFINED by IEEE standard!               │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ SCENARIO A: TB executes first                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Step 1: TB runs                                                           │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ i_valid_tb = 1'b1;  → i_valid changes to 1 IMMEDIATELY       │          │
│   │ i_data_tb = 0x03;   → i_data changes to 3 IMMEDIATELY        │          │
│   │ @(posedge clk);     → TB now waits for NEXT clock edge       │          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
│   Step 2: DUT runs (after TB finished)                                      │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ r_valid[0] <= i_valid;  → read i_valid (sees 1'b1 - NEW!)    │          │
│   │                         → [SCHEDULE TO NBA]: r_valid[0] = 1  │          │
│   │ r_power_of_2 <= 3*3;    → read i_data (sees 0x03 - NEW!)     │          │
│   │                         → [SCHEDULE TO NBA]: r_power_of_2 = 9│          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
│   Result: DUT captures NEW values at SAME clock edge                        │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ SCENARIO B: DUT executes first                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Step 1: DUT runs                                                          │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ r_valid[0] <= i_valid;  → read i_valid (sees 1'b1 - previous)│          │
│   │                         → [SCHEDULE TO NBA]: r_valid[0] = 1  │          │
│   │ r_power_of_2 <= 2*2;    → read i_data (sees 0x02 - previous) │          │
│   │                         → [SCHEDULE TO NBA]: r_power_of_2 = 4│          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
│   Step 2: TB runs (after DUT finished)                                      │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ i_valid_tb = 1'b1;  → i_valid stays 1 (already 1)            │          │
│   │ i_data_tb = 0x03;   → i_data changes 2→3 (but too late!)     │          │
│   │ @(posedge clk);     → TB now waits for NEXT clock edge       │          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
│   Result: DUT captures PREVIOUS i_data, sees NEW at NEXT clock edge         │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ 🚨 THIS IS THE RACE CONDITION!                                              │
│    "Assign before @(posedge clk)" does NOT help!                            │
│    The assignment still executes at the SAME TIME as the clock edge!        │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ NBA REGION (after Active region completes)                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   All scheduled non-blocking updates execute now:                           │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ r_valid[0] ← 1      (both scenarios - valid was already 1)   │          │
│   │ r_power_of_2 ← ???  (9 if Scenario A, 4 if Scenario B)       │          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Comparison of Scenarios:

| Aspect | Scenario A (TB first) | Scenario B (DUT first) |
|--------|----------------------|------------------------|
| **i_data when DUT reads** | 0x03 (NEW) | 0x02 (PREVIOUS) |
| **r_power_of_2 after NBA** | 9 (3²) | 4 (2²) |
| **Data captured** | Current iteration | Previous iteration |

---

### Case 2B: Non-blocking Assignment (Race-Free)

![Case 2B Waveform](images/case2b_waveform.png)

#### Key Observations:

1. **No Race Condition**: Non-blocking assignments schedule updates to NBA Region, ensuring consistent behavior.

2. **Predictable Timing**: The DUT always sees the previous value during the current clock edge.

3. **Safe Pattern**: This is equivalent to Case 1B in terms of safety.

#### Delta Cycle Analysis (T=40ns, second iteration):

```
═══════════════════════════════════════════════════════════════════════════════
                         TIME T=40ns: posedge clk occurs
═══════════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────────┐
│ ACTIVE REGION                                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│ Both blocks are triggered and ready to execute:                             │
│                                                                             │
│   TB initial block              DUT always block                            │
│   ──────────────────            ─────────────────                           │
│   i_valid_tb <= 1'b1; ←─?─→     always @(posedge clk)                       │
│   i_data_tb <= 0x03;            r_valid[0] <= i_valid;                      │
│   @(posedge clk);               r_power_of_2 <= i_data * i_data;            │
│                                                                             │
│ Order still UNDEFINED, but it DOESN'T MATTER with non-blocking!             │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ SCENARIO A: TB executes first (same result as B!)                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Step 1: TB runs                                                           │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ i_valid_tb <= 1'b1; → [SCHEDULE TO NBA]: i_valid = 1         │          │
│   │ i_data_tb <= 0x03;  → [SCHEDULE TO NBA]: i_data = 0x03       │          │
│   │                       (i_data is STILL 0x02 now!)            │          │
│   │ @(posedge clk);     → TB now waits for NEXT clock edge       │          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
│   Step 2: DUT runs (after TB finished)                                      │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ r_valid[0] <= i_valid;  → read i_valid (sees 1'b1)           │          │
│   │                         → [SCHEDULE TO NBA]: r_valid[0] = 1  │          │
│   │ r_power_of_2 <= 2*2;    → read i_data (sees 0x02 - PREVIOUS) │          │
│   │                         → [SCHEDULE TO NBA]: r_power_of_2 = 4│          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ SCENARIO B: DUT executes first (same result as A!)                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Step 1: DUT runs                                                          │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ r_valid[0] <= i_valid;  → read i_valid (sees 1'b1)           │          │
│   │                         → [SCHEDULE TO NBA]: r_valid[0] = 1  │          │
│   │ r_power_of_2 <= 2*2;    → read i_data (sees 0x02 - PREVIOUS) │          │
│   │                         → [SCHEDULE TO NBA]: r_power_of_2 = 4│          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
│   Step 2: TB runs (after DUT finished)                                      │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ i_valid_tb <= 1'b1; → [SCHEDULE TO NBA]: i_valid = 1         │          │
│   │ i_data_tb <= 0x03;  → [SCHEDULE TO NBA]: i_data = 0x03       │          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ ✅ NO RACE CONDITION!                                                        │
│    Both scenarios produce IDENTICAL results because:                        │
│    - TB only SCHEDULES updates (doesn't change values immediately)          │
│    - DUT always reads PREVIOUS values in Active Region                      │
│    - Updates happen together in NBA Region (after all reads)                │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ NBA REGION (after Active region completes)                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   All scheduled non-blocking updates execute now:                           │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ i_valid_tb ← 1      (TB's scheduled update)                  │          │
│   │ i_data_tb ← 0x03    (TB's scheduled update - NEW value)      │          │
│   │ r_valid[0] ← 1      (DUT's scheduled update)                 │          │
│   │ r_power_of_2 ← 4    (DUT's scheduled update - used PREVIOUS) │          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
│   Result: DUT captured PREVIOUS value (0x02), will see NEW (0x03) next cycle│
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Why Non-blocking Avoids Race Conditions:

| Aspect | Scenario A (TB first) | Scenario B (DUT first) |
|--------|----------------------|------------------------|
| **i_data when DUT reads** | 0x02 (PREVIOUS) | 0x02 (PREVIOUS) |
| **r_power_of_2 after NBA** | 4 (2²) | 4 (2²) |
| **Behavior** | Consistent | Consistent |

**Key Insight**: Both scenarios produce **identical results** - DUT always processes the PREVIOUS iteration's data!

---

### Comparison: Case 2A vs Case 2B

| Aspect | Case 2A (Blocking) | Case 2B (Non-blocking) |
|--------|-------------------|----------------------|
| **Assignment Location** | Before `@(posedge clk)` | Before `@(posedge clk)` |
| **Race Condition** | YES (same as Case 1A) | NO |
| **Common Misconception** | "Should be safe because assign comes first" | Correctly understood as safe |
| **Reality** | Race on every iteration | Race-free |
| **Data DUT captures** | Current OR previous (random) | Always previous (consistent) |

**Important**: The order of assignment relative to `@(posedge clk)` in the **source code** does NOT prevent race conditions with blocking assignments. The race occurs because both TB and DUT execute in the same Active Region at the same clock edge.

---

## Case 3: Delay Effects - Inactive Region and Time Delays

### Test Description

Case 3 explores alternative methods to avoid race conditions when using blocking assignments: **zero delays (`#0`)** and **real time delays (`#1`, `#2`, etc.)**. This case demonstrates the critical difference between these two approaches.

**Important Distinction:**
- **`#0` (Zero Delay)**: Moves execution to the **Inactive Region** within the **same simulation time**
- **`#n` where n > 0 (Non-zero Delay)**: Moves execution to a **different simulation time** entirely (NOT Inactive Region!)

```verilog
// Case 3A: Blocking without delay
@(posedge clk);
signal = value;      // Active Region, same time as DUT - RACE!

// Case 3B: Blocking with #0 delay (Inactive Region)
@(posedge clk);
#0;                  // Move to Inactive Region (same simulation time!)
signal = value;      // Executes after Active Region, before NBA - STILL RACE!

// Case 3C: Blocking with #1 delay (Different Simulation Time)
@(posedge clk);
#1;                  // Move to DIFFERENT simulation time (T+1ns)
signal = value;      // Executes at T+1ns, completely separate from DUT - SAFE
```

### Case 3A: Blocking Without Delay (Race Condition)

![Case 3A Waveform](images/case3a_waveform.png)

#### Key Observations:

1. **Same Race as Case 1A**: This is identical to Case 1A - blocking assignment after `@(posedge clk)` creates a race condition.

2. **Active Region Conflict**: Both testbench and DUT execute in the Active Region at time T (e.g., 10ns), with undefined execution order.

#### Delta Cycle Timeline (T=10ns, first data):

```
T=10ns (posedge clk)
├─ Active Region
│  ├─ TB: i_valid_tb = 1 (blocking, immediate)  ← RACE!
│  └─ DUT: reads i_valid (undefined order)      ← RACE!
├─ NBA Region
│  └─ DUT: r_valid[0] <= ? (depends on race outcome)
└─ Result: Simulator-dependent behavior
```

### Case 3B: Blocking With #0 Delay (Inactive Region - STILL RACE!)

![Case 3B Waveform](images/case3b_waveform.png)

#### Key Observations:

1. **Still Has Race Condition**: The `#0` delay moves execution to the **Inactive Region**, but this is still within the **same simulation time**!

2. **Why #0 Doesn't Help**:
   - DUT reads inputs in **Active Region** (before Inactive Region)
   - By the time TB's blocking assignment executes in Inactive Region, DUT has already read the old values
   - The race condition still exists because of execution order uncertainty

3. **Common Misconception**: Many designers think `#0` creates "safe" separation. **This is FALSE** - it only changes delta cycle region, not simulation time.

4. **False Sense of Security**: Code "looks" safer but behavior is still problematic.

#### Delta Cycle Timeline (T=10ns, first data):

```
T=10ns (posedge clk)
├─ Active Region
│  ├─ DUT: reads i_valid = 0 (old value)
│  └─ DUT: schedules r_valid[0] <= 0
├─ Inactive Region (#0 delay executes here)
│  └─ TB: i_valid_tb = 1 (blocking, but TOO LATE!)
│         DUT already read i_valid in Active Region!
├─ NBA Region
│  └─ DUT: r_valid[0] <= 0 (update with OLD value)
└─ Result: r_valid[0] = 0, i_valid_tb = 1

T=20ns (next posedge clk)
├─ Active Region
│  └─ DUT: reads i_valid = 1 (finally sees updated value)
├─ NBA Region
│  └─ DUT: r_valid[0] <= 1 (update)
└─ Result: r_valid[0] = 1
```

**Key Point**: The DUT **always** reads in Active Region, which happens **before** Inactive Region. So `#0` doesn't prevent the race - it just changes when TB writes, not when DUT reads!

### Case 3C: Blocking With #1 Delay (Different Simulation Time - SAFE)

![Case 3C Waveform](images/case3c_waveform.png)

#### Key Observations:

1. **No Race Condition**: The `#1` delay moves the blocking assignment to a **completely different simulation time** (T+1ns), avoiding any conflict with DUT.

2. **Time Separation**: DUT reads inputs at T=10ns, while testbench updates inputs at T=11ns - no overlap possible!

3. **Predictable Behavior**: This pattern produces consistent results across all simulators.

4. **Not Recommended**: While this works, it requires choosing arbitrary delay values and is less elegant than non-blocking assignments.

#### Delta Cycle Timeline (T=10ns, first data):

```
T=10ns (posedge clk)
├─ Active Region
│  └─ DUT: reads i_valid = 0 (old value, no race - TB hasn't assigned yet)
├─ NBA Region
│  └─ DUT: r_valid[0] <= 0 (update)
└─ Result: r_valid[0] = 0

═══ Time advances to T=11ns (completely different simulation time!) ═══

T=11ns (after #1 delay)
├─ Active Region
│  └─ TB: i_valid_tb = 1 (blocking at different time)
└─ Result: i_valid_tb = 1 (no race, DUT already finished at T=10ns)

T=20ns (next posedge clk)
├─ Active Region
│  └─ DUT: reads i_valid = 1 (updated value)
├─ NBA Region
│  └─ DUT: r_valid[0] <= 1 (update)
└─ Result: r_valid[0] = 1
```

### Comparison: Case 3A vs Case 3B vs Case 3C

| Aspect | Case 3A (No Delay) | Case 3B (#0 Delay) | Case 3C (#1 Delay) |
|--------|-------------------|-------------------|-------------------|
| **Assignment Type** | Blocking `=` | Blocking `=` | Blocking `=` |
| **Delay** | None | `#0` | `#1` (1ns) |
| **Execution Region** | Active | Inactive | Active (at T+1ns) |
| **Simulation Time** | T=10ns | T=10ns (same!) | T=11ns (different!) |
| **Race Condition** | YES | YES (still!) | NO |
| **Behavior** | Simulator-dependent | Simulator-dependent | Consistent |

### Why #0 Doesn't Work but #1 Does

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ T=10ns (posedge clk)                                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   #0 delay (Inactive Region) - STILL SAME TIME!                             │
│   ┌───────────────────────────────────────────────────────────────────┐     │
│   │ Active Region    →  Inactive Region  →  NBA Region  →  Monitor    │     │
│   │ (DUT reads here)    (#0 executes)      (NBA updates)              │     │
│   │      ↑                    ↑                                       │     │
│   │      │                    │                                       │     │
│   │  DUT reads OLD      TB writes NEW                                 │     │
│   │  value here!        value here...                                 │     │
│   │                     but TOO LATE!                                 │     │
│   └───────────────────────────────────────────────────────────────────┘     │
│                                                                             │
│   ALL of this happens at T=10ns - same simulation time!                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ #1 delay - DIFFERENT SIMULATION TIME                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   T=10ns: DUT reads and updates (TB not involved yet)                       │
│   ════════════════════════════════════════════════                          │
│   T=11ns: TB writes (DUT already finished at T=10ns)                        │
│                                                                             │
│   Complete time separation = NO RACE!                                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Recommendations

1. **Preferred Solution**: Use non-blocking assignments (`<=`) as shown in Case 1B and 2B
   - No need to choose arbitrary delay values
   - Self-documenting intent (sequential behavior)
   - Industry standard practice

2. **Time Delays (`#1`, `#2`, etc.)**: Can work but not recommended **for driving clocked DUT inputs**
   - Requires choosing arbitrary delay values
   - Can cause timing issues if clock period changes
   - Less clear intent than non-blocking assignments
   - **Note**: Time delays are acceptable in other contexts (e.g., adding delays between unrelated events, modeling propagation delays)

3. **Zero Delays (`#0`)**: **Do NOT use for race avoidance** - they don't solve the problem!
   - Only moves to Inactive Region (same simulation time)
   - DUT already executed in Active Region before Inactive Region
   - Creates false sense of security

**Key Learning**:
- `#0` moves to a different **delta cycle region** but stays at the same **simulation time** → DOES NOT avoid race
- `#n` (n > 0) moves to a different **simulation time** entirely → AVOIDS race
- **Non-blocking assignments are the proper, industry-standard solution** for driving clocked DUT inputs in synchronous testbenches

---

## Case 4: Monitor Region - System Task Execution Timing

### Test Description

Case 4 explores the **Monitor Region** of delta cycles by comparing three system tasks: `$display`, `$strobe`, and `$monitor`. All three are used for printing debug information, but they execute in different delta cycle regions, leading to different observed values.

### System Task Comparison

| System Task | Execution Region | Calling Method | Behavior |
|------------|-----------------|----------------|----------|
| **`$display`** | Active Region | Manual (each time) | Prints immediately, may see values before NBA updates |
| **`$strobe`** | Monitor Region | Manual (each time) | Prints after NBA updates, sees final values |
| **`$monitor`** | Monitor Region | Setup once | Automatically prints on signal changes, sees final values |

### Case 4A: Using `$display` (Active Region)

![Case 4A Console Output](images/case4a_console.png)

#### Key Observations:

1. **Executes in Active Region**: `$display` runs in the same delta cycle region where blocking assignments execute and non-blocking RHS are evaluated.

2. **Timing Issue**: May print values **before** non-blocking assignment updates in the NBA region.

3. **Example Output** (hypothetical):
```
[DISPLAY] Time=30, i_valid=0, r_valid[0]=0   ← Printed in Active Region
// NBA Region updates: i_valid ← 1, r_valid[0] ← 0
// $display already printed, doesn't see NBA updates!
```

#### Delta Cycle Timeline:

```
T=30ns (posedge clk)
├─ Active Region
│  ├─ DUT: reads i_valid = 0 (old value)
│  ├─ DUT: schedules r_valid[0] <= 0
│  ├─ TB: evaluates i_valid_tb <= 1 (schedules for NBA)
│  └─ $display: prints "i_valid=0, r_valid[0]=0"  ← OLD VALUES
├─ NBA Region
│  ├─ TB: i_valid_tb updates to 1
│  └─ DUT: r_valid[0] updates to 0
└─ Monitor Region
   └─ (no $display here)
```

### Case 4B: Using `$strobe` (Monitor Region)

![Case 4B Console Output](images/case4b_console.png)

#### Key Observations:

1. **Executes in Monitor Region**: `$strobe` waits until **after** all NBA updates complete.

2. **Sees Final Values**: Always prints the final values for that simulation time, after all blocking and non-blocking assignments.

3. **Example Output** (hypothetical):
```
// Active Region: evaluate assignments
// NBA Region: update assignments
[STROBE] Time=30, i_valid=1, r_valid[0]=0   ← Printed AFTER NBA updates
```

#### Delta Cycle Timeline:

```
T=30ns (posedge clk)
├─ Active Region
│  ├─ DUT: reads i_valid = 0 (old value)
│  ├─ DUT: schedules r_valid[0] <= 0
│  └─ TB: evaluates i_valid_tb <= 1 (schedules for NBA)
├─ NBA Region
│  ├─ TB: i_valid_tb updates to 1
│  └─ DUT: r_valid[0] updates to 0
└─ Monitor Region
   └─ $strobe: prints "i_valid=1, r_valid[0]=0"  ← FINAL VALUES
```

### Case 4C: Using `$monitor` (Monitor Region, Automatic)

![Case 4C Console Output](images/case4c_console.png)

#### Key Observations:

1. **Executes in Monitor Region**: Like `$strobe`, executes after NBA updates.

2. **Automatic Printing**: Set up **once** in an `initial` block, then automatically prints whenever any monitored signal changes.

3. **Continuous Monitoring**: No need to call it repeatedly - it tracks signals throughout simulation.

4. **Example Output** (hypothetical):
```
[MONITOR] Time=0, i_valid=0, i_data=00000000, r_valid[0]=0
[MONITOR] Time=30, i_valid=1, i_data=00000002, r_valid[0]=0   ← Auto-print on change
[MONITOR] Time=40, i_valid=1, i_data=00000003, r_valid[0]=1   ← Auto-print on change
[MONITOR] Time=50, i_valid=1, i_data=00000005, r_valid[0]=1
...
```

#### Delta Cycle Timeline:

```
T=30ns (posedge clk)
├─ Active Region
│  ├─ DUT: reads i_valid = 0, schedules r_valid[0] <= 0
│  └─ TB: evaluates i_valid_tb <= 1, i_data_tb <= 2
├─ NBA Region
│  ├─ TB: i_valid_tb updates to 1, i_data_tb updates to 2
│  └─ DUT: r_valid[0] updates to 0
└─ Monitor Region
   └─ $monitor: detects change, prints "i_valid=1, i_data=2, r_valid[0]=0"
```

### Comparison: $display vs $strobe vs $monitor

| Aspect | $display | $strobe | $monitor |
|--------|---------|---------|----------|
| **Region** | Active | Monitor | Monitor |
| **Timing** | Before NBA | After NBA | After NBA |
| **Values Seen** | May be old | Always final | Always final |
| **Usage** | Manual call | Manual call | Set once, auto |
| **Use Case** | Quick debug | Verify final values | Continuous tracking |
| **Example** | `always @(posedge clk) $display(...)` | `always @(posedge clk) $strobe(...)` | `initial $monitor(...)` |

### Recommendations

1. **Use `$display`** for:
   - Quick debugging during development
   - Printing intermediate values explicitly
   - When you need Active Region values (rare)

2. **Use `$strobe`** for:
   - Verifying final values after all assignments
   - Testbench assertions and checks
   - When you need to see NBA-updated values

3. **Use `$monitor`** for:
   - Continuous signal tracking throughout simulation
   - Generating comprehensive logs
   - Monitoring signals without cluttering code with print statements

**Key Learning**: Understanding when system tasks execute in delta cycles helps you choose the right tool for debugging and verification. `$strobe` and `$monitor` are safer for verifying behavior because they always see final values after all NBA updates.

---

## Summary

### Lab Overview: Comprehensive Delta Cycle Study

This lab explored **all four delta cycle regions** through systematic case studies:

1. **Background**: Understanding `@(posedge clk)` placement in for-loops
2. **Case 1 & 2**: Active vs NBA Region - blocking vs non-blocking assignments
3. **Case 3**: Inactive Region - time delays to avoid races (not recommended)
4. **Case 4**: Monitor Region - system task execution timing

### Critical Finding: All Blocking Cases Have Race Conditions

**Cases 1A, 2A, 3A, and 3B all exhibit race conditions** despite different coding patterns:

- **Case 1A**: `@(posedge clk); signal = value;` → **RACE**
- **Case 2A**: `signal = value; @(posedge clk);` → **RACE** (common misconception that this is safe!)
- **Case 3A**: `@(posedge clk); signal = value;` (no delay) → **RACE**
- **Case 3B**: `@(posedge clk); #0; signal = value;` → **STILL RACE** (`#0` only moves to Inactive Region, same time!)

**The pattern doesn't matter** - any blocking assignment that executes at the same simulation time as a DUT clock edge creates a race condition. Even `#0` doesn't help because it stays at the same simulation time!

### Why Race Conditions Occur

When both testbench and DUT use blocking assignments or trigger on the same clock edge:
1. Both execute in the **Active Region** at the same simulation time
2. The **execution order is undefined** by the IEEE 1364 standard
3. Different simulators may produce different results
4. The same simulator may produce different results across versions

**Understanding Active Region Execution Order:**
- **Within a single `always`/`initial` block**: Statements execute **sequentially** (top-to-bottom order is guaranteed)
- **Between different `always`/`initial` blocks**: Execution order is **UNDEFINED** (this is the root cause of race conditions)

Example:
```verilog
// Testbench initial block
initial begin
    @(posedge clk);
    signal_a = 1;  // Executes sequentially AFTER @(posedge clk)
    signal_b = 2;  // Executes sequentially AFTER signal_a = 1
end

// DUT always block
always @(posedge clk) begin
    reg_a <= signal_a;  // Reads signal_a in Active Region
    reg_b <= signal_b;  // Reads signal_b in Active Region
end

// PROBLEM: Which executes first in Active Region?
//   - TB's "signal_a = 1" or DUT's "read signal_a"?
//   - ORDER IS UNDEFINED! → RACE CONDITION
```

### Solutions to Avoid Race Conditions

The lab demonstrated **three methods** to avoid race conditions:

1. **Non-blocking assignments (`<=`)** - **RECOMMENDED**
   - Separates read and write into different delta cycle regions
   - Cases 1B, 2B demonstrate this
   - Industry standard, self-documenting

2. **Time delays (`#1`, `#2`, etc.)** - **Works but NOT recommended**
   - Moves assignment to different simulation time
   - Case 3C demonstrates this
   - Requires arbitrary delay values, less portable

3. **Zero delays (`#0`)** - **DOES NOT WORK**
   - Only moves to Inactive Region (same simulation time!)
   - DUT already read in Active Region
   - Case 3B demonstrates this failure
   - False sense of security

### Delta Cycle Regions - Complete Summary

| Region | What Happens | Examples |
|--------|--------------|----------|
| **Active** | Blocking assigns execute immediately<br>Non-blocking RHS evaluated<br>`$display` prints<br>**Sequential within block, UNDEFINED between blocks** | `signal = value;`<br>`signal <= value;` (RHS only)<br>`$display(...)`<br>**Race risk here!** |
| **Inactive** | Zero-delay events (`#0`)<br>**Does NOT help race conditions!**<br>Case 3B shows this | `#0;` |
| **NBA** | Non-blocking LHS updates<br>Final values established<br>**Deterministic ordering** | `signal <= value;` (LHS update) |
| **Monitor** | `$strobe` and `$monitor` execute<br>See final values | `$strobe(...)`<br>`$monitor(...)` |

### Best Practices

1. **Always use non-blocking assignments (`<=`)** for clocked signals in testbenches
   - Cases 1B, 2B show correct usage
   - Ensures predictable, race-free behavior

2. **Avoid blocking assignments (`=`)** when driving DUT inputs from clocked contexts
   - Cases 1A, 2A, 3A show the problems

3. **Use `$strobe` or `$monitor` for verification**
   - Case 4B, 4C show they see final values after NBA
   - Safer than `$display` (Case 4A) which sees Active Region values

4. **Understand delta cycle regions**:
   - Active Region: Where race conditions occur
   - NBA Region: Where non-blocking updates happen
   - Monitor Region: Where final values are visible

5. **Avoid time delays for race avoidance**
   - Case 3C shows `#1` works, but it's not the right solution
   - Case 3B shows `#0` does NOT work (same simulation time!)
   - Non-blocking assignments are clearer and more maintainable

**Golden Rule**: Use non-blocking assignments (`<=`) for all clocked signal updates in testbenches to ensure portable, simulator-independent behavior.
