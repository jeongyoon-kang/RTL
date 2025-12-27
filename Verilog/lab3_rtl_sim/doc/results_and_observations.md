# Lab 3: Results and Observations

## Overview

This document provides detailed analysis and observations from the delta cycle case studies. Each case demonstrates the critical differences between blocking (`=`) and non-blocking (`<=`) assignments in Verilog testbenches, and their interaction with the DUT through delta cycles.

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

3. **Two Possible Scenarios**:
   - **Scenario A** (TB executes first):
     - TB sets `i_valid_tb = 1` in Active Region
     - DUT reads `i_valid = 1` in Active Region
     - DUT updates `r_valid[0] <= 1` in NBA Region
     - **Result**: `r_valid[0]` becomes 1 at the **same clock edge**

   - **Scenario B** (DUT executes first):
     - DUT reads `i_valid = 0` in Active Region (old value)
     - TB sets `i_valid_tb = 1` in Active Region
     - DUT updates `r_valid[0] <= 0` in NBA Region
     - **Result**: `r_valid[0]` becomes 0, then 1 at the **next clock edge**

4. **Simulator Dependency**: The actual behavior depends on which scenario the simulator chooses. Different simulators (Vivado, ModelSim, Icarus) or different versions may produce different results.

#### Delta Cycle Timeline (T=10ns, first data):

**Scenario A** (TB first):
```
T=10ns (posedge clk)
├─ Active Region
│  ├─ TB: i_valid_tb = 1 (blocking, immediate)
│  └─ DUT: reads i_valid = 1
├─ NBA Region
│  └─ DUT: r_valid[0] <= 1 (update)
└─ Result: r_valid[0] = 1
```

**Scenario B** (DUT first):
```
T=10ns (posedge clk)
├─ Active Region
│  ├─ DUT: reads i_valid = 0
│  └─ TB: i_valid_tb = 1 (blocking, immediate)
├─ NBA Region
│  └─ DUT: r_valid[0] <= 0 (update)
└─ Result: r_valid[0] = 0

T=20ns (next posedge clk)
├─ Active Region
│  └─ DUT: reads i_valid = 1
├─ NBA Region
│  └─ DUT: r_valid[0] <= 1 (update)
└─ Result: r_valid[0] = 1
```

### Case 1B: Non-blocking Assignment (Race-Free)

![Case 1B Waveform](images/case1b_waveform.png)

#### Key Observations:

1. **No Race Condition**: The testbench uses non-blocking assignment (`<=`) which schedules updates to the NBA Region, avoiding race conditions.

2. **Predictable Behavior**: The execution order is **well-defined** because reads and writes happen in different regions.

3. **Deterministic Scenario**:
   - TB evaluates RHS in Active Region, schedules update to NBA
   - DUT reads in Active Region (always sees old value)
   - Both TB and DUT update in NBA Region (after all reads complete)
   - **Result**: Consistent behavior across all simulators

4. **One Clock Cycle Delay**: Input changes are visible to the DUT at the **next clock edge**, providing setup time for proper operation.

#### Delta Cycle Timeline (T=10ns, first data):

```
T=10ns (posedge clk)
├─ Active Region
│  ├─ DUT: reads i_valid = 0 (old value)
│  └─ TB: evaluates RHS of i_valid_tb <= 1
├─ NBA Region
│  ├─ TB: i_valid_tb update to 1
│  └─ DUT: r_valid[0] <= 0 (update)
└─ Result: i_valid_tb = 1, r_valid[0] = 0

T=20ns (next posedge clk)
├─ Active Region
│  └─ DUT: reads i_valid = 1 (updated value)
├─ NBA Region
│  └─ DUT: r_valid[0] <= 1 (update)
└─ Result: r_valid[0] = 1
```

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

TBD - Analysis pending simulation results.

---

## Case 3: Initial Block Assignment

### Test Description

TBD - Analysis pending simulation results.

---

## Case 4: Clocked Always Block

### Test Description

TBD - Analysis pending simulation results.

---

## Summary

The key lesson from these case studies is that **assignment type matters** in Verilog testbenches:

- **Non-blocking (`<=`)**: Separates read and write operations into different delta cycle regions, ensuring predictable, race-free behavior
- **Blocking (`=`)**: Executes immediately in Active Region, creating potential race conditions when TB and DUT share clock edges

**Best Practice**: Use non-blocking assignments for all clocked signal updates in testbenches to ensure portable, simulator-independent behavior.
