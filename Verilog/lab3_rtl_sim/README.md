# Lab 3: RTL Simulation Timing - Understanding Delta Cycles and Assignment Types

## Objective

The goal of this lab is to understand how Verilog simulators handle timing through **delta cycles** and how **blocking (`=`)** versus **non-blocking (`<=`)** assignments affect signal update ordering, especially when interacting with clock edges (`@(posedge clk)`).

By the end of this lab, you will be able to:
- Understand the concept of delta cycles in Verilog simulation
- Identify timing differences between blocking and non-blocking assignments
- Recognize and avoid race conditions in testbenches
- Write correct stimulus generation code for synchronous designs

## Background

### Delta Cycles in Verilog Simulation

Verilog simulators do not update all signals instantaneously at a given simulation time. Instead, they process events in multiple **delta cycles** within the same simulation time step. This ensures deterministic behavior and proper ordering of signal updates.

#### Event Processing Regions (IEEE 1364 Standard)

Within a single simulation time, events are processed in the following order:

1. **Active Region**
   - Evaluate RHS of blocking assignments and execute the assignment immediately
   - Evaluate RHS of non-blocking assignments and schedule LHS update for NBA region
   - Execute `$display` statements
   - Evaluate inputs and update outputs of primitives
   - **CRITICAL**: Within a single `always`/`initial` block, statements execute sequentially (top-to-bottom)
   - **CRITICAL**: Execution order **between different** `always`/`initial` blocks is **UNDEFINED** by IEEE standard
   - This undefined ordering between blocks is what causes race conditions!

2. **Inactive Region**
   - Process explicit zero-delay (`#0`) events

3. **NBA Region (Non-Blocking Assignment)**
   - Update LHS of non-blocking assignments that were scheduled in the Active region
   - This happens in a separate delta cycle from the Active region

4. **Monitor Region**
   - Execute `$monitor` and `$strobe` statements

#### Key Insight: Delta Cycle Ordering

```verilog
// At time T, posedge clk occurs

// Testbench (initial block)
@(posedge clk);
i_valid = 1'b1;      // Active region: executed immediately
i_data <= 8'h42;     // NBA region: scheduled for later delta cycle

// DUT (always block)
always @(posedge clk) begin
    r_valid <= i_valid;   // Active region: reads i_valid, schedules NBA update
    r_data <= i_data;     // Active region: reads i_data, schedules NBA update
end
```

**Execution sequence at time T:**

⚠️ **CRITICAL**: The testbench's `initial` block and DUT's `always` block are **different blocks**. As stated above, execution order **between different blocks is UNDEFINED** by IEEE standard!

```
═══════════════════════════════════════════════════════════════════════════════
                          TIME T: posedge clk occurs
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
│   i_valid = 1'b1;     ←─?─→     r_valid <= i_valid;                         │
│   i_data <= 8'h42;              r_data <= i_data;                           │
│                                                                             │
│ ⚠️  Which block executes first? → UNDEFINED by IEEE standard!               │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ SCENARIO A: TB executes first                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Step 1: TB runs                                                           │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ i_valid = 1'b1;    → i_valid changes 0→1 IMMEDIATELY         │          │
│   │ i_data <= 8'h42;   → [SCHEDULE TO NBA]: i_data = 8'h42       │          │
│   │                      (i_data is STILL old value now!)        │          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
│   Step 2: DUT runs (after TB finished)                                      │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ r_valid <= i_valid; → read i_valid (sees 1'b1 - NEW!)        │          │
│   │                      → [SCHEDULE TO NBA]: r_valid = 1'b1     │          │
│   │ r_data <= i_data;   → read i_data (sees OLD value)           │          │
│   │                      → [SCHEDULE TO NBA]: r_data = OLD       │          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
│   Result: DUT captures NEW i_valid, but OLD i_data                          │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ SCENARIO B: DUT executes first                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Step 1: DUT runs                                                          │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ r_valid <= i_valid; → read i_valid (sees 1'b0 - OLD!)        │          │
│   │                      → [SCHEDULE TO NBA]: r_valid = 1'b0     │          │
│   │ r_data <= i_data;   → read i_data (sees OLD value)           │          │
│   │                      → [SCHEDULE TO NBA]: r_data = OLD       │          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
│   Step 2: TB runs (after DUT finished)                                      │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ i_valid = 1'b1;    → i_valid changes 0→1 (but too late!)     │          │
│   │ i_data <= 8'h42;   → [SCHEDULE TO NBA]: i_data = 8'h42       │          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
│   Result: DUT captures OLD i_valid AND OLD i_data                           │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ 🚨 THIS IS THE RACE CONDITION!                                              │
│    Same code, same time T, but different results depending on               │
│    which block the simulator chooses to run first!                          │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ NBA REGION (after Active region completes)                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   All scheduled non-blocking updates execute now:                           │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ i_data ← 8'h42      (TB's scheduled update)                  │          │
│   │ r_valid ← ???       (depends on Scenario A or B!)            │          │
│   │ r_data ← OLD        (both scenarios read old value)          │          │
│   └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

This is why **mixing blocking (`=`) and non-blocking (`<=`) assignments in testbenches can cause unpredictable behavior** - the DUT may see different values depending on simulator implementation!

### Blocking vs Non-Blocking Assignments

| Assignment Type | Syntax | Execution | Typical Use Case |
|----------------|---------|-----------|------------------|
| Blocking | `=` | Immediate (Active region) | Combinational logic, testbench procedural code |
| Non-Blocking | `<=` | Scheduled (NBA region) | Sequential logic (flip-flops) |

**Golden Rule for RTL Design:**
- Use `<=` in `always @(posedge clk)` blocks (sequential logic)
- Use `=` in `always @(*)` blocks (combinational logic)

**For Testbenches:**
- The choice between `=` and `<=` affects delta cycle timing
- Mixing them carelessly can cause race conditions with the DUT

## Design Under Test (DUT)

The DUT (`rtl/basic.v`) is a simple 3-stage pipeline that computes the 8th power of input data:

- **Stage 0**: Computes `power_of_2 = i_data * i_data` (x²)
- **Stage 1**: Computes `power_of_4 = r_power_of_2 * r_power_of_2` (x⁴)
- **Stage 2**: Computes `power_of_8 = r_power_of_4 * r_power_of_4` (x⁸)

A valid signal (`i_valid`) propagates through the pipeline along with the data.

```verilog
// DUT uses non-blocking assignments (correct for sequential logic)
always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        r_valid[0] <= 1'b0;
    else
        r_valid[0] <= i_valid;
end

always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        r_power_of_2 <= 'b0;
    else
        r_power_of_2 <= power_of_2;
end
```

---

## Background Exercises: Understanding `@(posedge clk)` Placement

Before diving into delta cycle analysis, it's important to understand how `@(posedge clk)` placement affects stimulus timing. Both examples use **non-blocking assignments (`<=`)** to drive DUT inputs (race-free).

### Background Example 1 (basic1): `@(posedge clk)` INSIDE for-loop

**Pattern:**
```verilog
for (i = 0; i < N; i = i + 1) begin
    @(posedge clk);          // Wait for clock edge INSIDE loop
    i_valid <= 1'b1;         // Non-blocking assignment
    i_data <= data[i];
end
```

**Behavior:**
- Each iteration waits for a clock edge, then updates signals
- Total iterations: N clock cycles
- First data appears at the **1st clock edge** after loop starts

**Timing Diagram:**
```
clk:     _/‾\_/‾\_/‾\_/‾\_/‾\_
         T0  T1  T2  T3  T4
              ↓   ↓   ↓   ↓
i_data:  X   D0  D1  D2  D3   (updates at each posedge)
```

---

### Background Example 2 (basic2): `@(posedge clk)` OUTSIDE for-loop

**Pattern:**
```verilog
for (i = 0; i < N; i = i + 1) begin
    i_valid <= 1'b1;         // Non-blocking assignment
    i_data <= data[i];
end
@(posedge clk);              // Wait for clock edge OUTSIDE (after loop)
```

**Behavior:**
- Loop completes instantly (same simulation time) - only last value is scheduled!
- `@(posedge clk)` waits once after ALL iterations
- **Only the LAST data value is captured!**

**Timing Diagram:**
```
clk:     _/‾\_/‾\_
         T0  T1
              ↓
i_data:  X   D(N-1)   (only last value visible!)

Loop executes D0, D1, D2... D(N-1) all at T0
But each <= overwrites the previous schedule
Only D(N-1) actually updates at NBA region
```

---

### Key Comparison: basic1 vs basic2

| Aspect | basic1 (inside loop) | basic2 (outside loop) |
|--------|---------------------|----------------------|
| **`@(posedge clk)` location** | Inside for-loop | Outside for-loop |
| **Clock cycles used** | N cycles | 1 cycle |
| **Data captured** | All N values | Only last value |
| **Common use case** | Sequential stimulus | ⚠️ Usually a BUG! |

### Important Learning

This background exercise demonstrates that **`@(posedge clk)` placement fundamentally changes timing behavior**, even when using non-blocking assignments correctly.

- **basic1**: Proper sequential stimulus generation
- **basic2**: Common mistake - loop runs instantly, only last value matters

---

## Case Studies

We will explore four key scenarios covering all delta cycle regions:

### Case 1: Assignment After Clock Edge

**Scenario**: Drive input signals immediately after waiting for a clock edge.

```verilog
// Case 1A: Blocking
@(posedge clk);
i_valid = 1'b1;      // Active region
i_data = 8'h05;      // Active region

// Case 1B: Non-blocking
@(posedge clk);
i_valid <= 1'b1;     // Scheduled to NBA region
i_data <= 8'h05;     // Scheduled to NBA region
```

**Expected Behavior:**
- **Case 1A (Blocking)**: Input changes occur in Active region, same delta cycle as DUT reads inputs. DUT may see new input values immediately.
- **Case 1B (Non-blocking)**: Input changes occur in NBA region, after DUT has read the old values. DUT sees new inputs on the next clock edge.

**Delta Cycle Analysis:**
```
Time T (posedge clk):
Case 1A:
  Active: i_valid = 1, i_data = 5 → changes immediately
  Active: DUT reads i_valid (sees 1), schedules r_valid[0] <= 1
  NBA:    r_valid[0] updates to 1

Case 1B:
  Active: DUT reads i_valid (sees old value 0), schedules r_valid[0] <= 0
  NBA:    i_valid updates to 1
  NBA:    r_valid[0] updates to 0
Time T+1 (next posedge clk):
  Active: DUT reads i_valid (sees 1), schedules r_valid[0] <= 1
```

---

### Case 2: Assignment Before Clock Edge

**Scenario**: Drive input signals before waiting for a clock edge.

```verilog
// Case 2A: Blocking
i_valid = 1'b1;
i_data = 8'h05;
@(posedge clk);      // Wait for clock edge

// Case 2B: Non-blocking
i_valid <= 1'b1;
i_data <= 8'h05;
@(posedge clk);      // Wait for clock edge
```

**Expected Behavior:**
- **Case 2A (Blocking)**: Inputs change immediately, then wait for clock. Inputs are stable before clock edge (good setup time).
- **Case 2B (Non-blocking)**: Inputs are scheduled for NBA region. When do they update relative to the `@(posedge clk)` wait?

**Key Question**: When does the NBA update occur if there's a `@(posedge clk)` on the next line?

---

### Case 3: Delay Effects - Inactive Region and Time Delays

**Scenario**: Use delays to avoid race conditions with blocking assignments.

**Important Distinction:**
- **`#0` (Zero Delay)**: Moves execution to the **Inactive Region** within the **same simulation time**
- **`#n` where n > 0 (Non-zero Delay)**: Moves execution to a **different simulation time** entirely (NOT Inactive Region!)

```verilog
// Case 3A: Blocking without delay
@(posedge clk);
signal = value;      // Executes in Active region - RACE!

// Case 3B: Blocking with #0 delay (Inactive Region)
@(posedge clk);
#0;                  // Move to Inactive region (same simulation time)
signal = value;      // Executes after Active region, before NBA - STILL RACE!

// Case 3C: Blocking with #1 delay (Different Simulation Time)
@(posedge clk);
#1;                  // Move to DIFFERENT simulation time (T+1ns)
signal = value;      // Executes at T+1ns, completely separate from DUT's T+0ns - SAFE
```

**Expected Behavior:**
- **Case 3A (Without delay)**: Race condition - blocking assignment in Active region, same delta cycle as DUT
- **Case 3B (With #0 delay)**: Still potential race - executes in Inactive region but still same simulation time, before NBA updates
- **Case 3C (With #1 delay)**: No race - assignment happens at completely different simulation time (T+1ns)

**Delta Cycle Analysis:**
```
Case 3A (T=10ns, posedge clk):
  Active: signal = value (immediate)
  Active: DUT reads signal (RACE - order undefined!)
  NBA:    DUT registers update

Case 3B (T=10ns, posedge clk):
  Active:   DUT reads signal (order with TB undefined)
  Inactive: signal = value (#0 delay executes here)
  NBA:      DUT registers update
  Note: DUT already read signal in Active region, so #0 doesn't help much!

Case 3C (T=10ns, posedge clk):
  Active: DUT reads signal (old value - TB hasn't assigned yet)
  NBA:    DUT registers update
  --- Time advances to T=11ns ---
  Active: signal = value (completely different time, no race!)
```

**Key Learnings:**
1. **`#0` is NOT the same as `#1`**: `#0` stays in the same simulation time (Inactive region), while `#1` moves to a different time
2. **`#0` doesn't fully solve race conditions**: The DUT reads inputs in Active region, which happens before Inactive region
3. **`#n` (n > 0) avoids races by time separation**: The assignment happens at a completely different simulation time
4. **Non-blocking assignments are still preferred**: They don't require arbitrary delay values and represent the industry-standard practice for synchronous testbenches

---

### Case 4: Monitor Region - System Task Execution Timing

**Scenario**: Compare execution timing of `$display`, `$strobe`, and `$monitor`.

```verilog
// Case 4A: $display (Active Region)
always @(posedge clk) begin
    $display("i_valid=%b, r_valid=%b", i_valid, r_valid[0]);
    // Executes in Active region - may print BEFORE NBA updates!
end

// Case 4B: $strobe (Monitor Region)
always @(posedge clk) begin
    $strobe("i_valid=%b, r_valid=%b", i_valid, r_valid[0]);
    // Executes in Monitor region - prints AFTER NBA updates!
end

// Case 4C: $monitor (Monitor Region, Automatic)
initial begin
    $monitor("i_valid=%b, r_valid=%b", i_valid, r_valid[0]);
    // Set up ONCE - automatically prints on signal changes
    // Executes in Monitor region
end
```

**Expected Behavior:**
- **Case 4A ($display)**: Prints in Active region, may show values **before** non-blocking assignment updates
- **Case 4B ($strobe)**: Prints in Monitor region, shows values **after** all NBA updates
- **Case 4C ($monitor)**: Also prints in Monitor region, but **automatically** on any monitored signal change

**Delta Cycle Timeline:**
```
T=10ns (posedge clk):
├─ Active Region
│  ├─ DUT: reads i_valid (old value 0)
│  ├─ DUT: schedules r_valid[0] <= 0
│  └─ Case 4A: $display prints "i_valid=0, r_valid=0" (old r_valid)
├─ NBA Region
│  ├─ TB: i_valid updates to 1
│  └─ DUT: r_valid[0] updates to 0
└─ Monitor Region
   ├─ Case 4B: $strobe prints "i_valid=1, r_valid=0" (new i_valid, new r_valid)
   └─ Case 4C: $monitor prints "i_valid=1, r_valid=0" (automatic)
```

**Key Comparison:**

| System Task | Region | Usage | When to Use |
|------------|--------|-------|-------------|
| **`$display`** | Active | Manual call each time | Quick debug, immediate values |
| **`$strobe`** | Monitor | Manual call each time | Verify final values after NBA |
| **`$monitor`** | Monitor | Set once, auto-print | Continuous signal tracking |

---

## Tasks

For each case study:

1. **Implement the testbench variants** (Case XA with blocking, Case XB with non-blocking)
2. **Run simulations** and generate waveforms
3. **Analyze the waveforms** to observe:
   - When do input signals change?
   - When do DUT internal registers (`r_valid[0]`, `r_power_of_2`) update?
   - Is there any difference in behavior between blocking and non-blocking?
4. **Record your observations** in the Results section below

## Instructions

### Running Simulations

```bash
# Background: Understand @(posedge clk) placement
make basic1   # @(posedge clk) BEFORE assignment
make basic2   # Assignment BEFORE @(posedge clk)

# Case 1: Active vs NBA Region
make case1a   # Blocking after clock edge (RACE)
make case1b   # Non-blocking after clock edge (SAFE)

# Case 2: Assignment Location
make case2a   # Blocking before clock edge (STILL RACE!)
make case2b   # Non-blocking before clock edge (SAFE)

# Case 3: Delay Effects - Inactive Region and Time Delays
make case3a   # Blocking without delay (RACE)
make case3b   # Blocking with #0 delay - Inactive Region (STILL RACE)
make case3c   # Blocking with #1 delay - Different Time (SAFE)

# Case 4: Monitor Region - System Tasks
make case4a   # Using $display (Active Region)
make case4b   # Using $strobe (Monitor Region)
make case4c   # Using $monitor (Monitor Region, Auto)
```

### Viewing Waveforms

**Option 1: Using Vivado (Recommended)**
```bash
vivado -source open_waveform.tcl
```

Or manually in Vivado GUI:
1. Open Vivado
2. Flow Navigator → Open Static Simulation → Open Simulation Waveform
3. Or: File → Open Waveform → Select `dump.vcd`

**Option 2: Using GTKWave**
```bash
gtkwave dump.vcd
```

**Signals to observe:**
- `clk` - Clock signal
- `i_valid`, `i_data` - Input signals driven by testbench
- `r_valid[0]`, `r_power_of_2` - First stage registers in DUT
- `o_valid`, `o_data` - Output signals

---

## Results and Observations

### Case 1: Assignment After Clock Edge

#### Case 1A - Blocking Assignment
**Observations:**
- [ ] Waveform screenshot: `results/case1a.png`
- [ ] Timing analysis:
- [ ] Key findings:

#### Case 1B - Non-blocking Assignment
**Observations:**
- [ ] Waveform screenshot: `results/case1b.png`
- [ ] Timing analysis:
- [ ] Key findings:

#### Comparison and Conclusion:
- [ ] Differences observed:
- [ ] Explanation based on delta cycles:

---

### Case 2: Assignment Before Clock Edge

#### Case 2A - Blocking Assignment
**Observations:**
- [ ] Waveform screenshot: `results/case2a.png`
- [ ] Timing analysis:
- [ ] Key findings:

#### Case 2B - Non-blocking Assignment
**Observations:**
- [ ] Waveform screenshot: `results/case2b.png`
- [ ] Timing analysis:
- [ ] Key findings:

#### Comparison and Conclusion:
- [ ] Differences observed:
- [ ] Explanation based on delta cycles:

---

### Case 3: Delay Effects - Inactive Region and Time Delays

#### Case 3A - Blocking Without Delay
**Observations:**
- [ ] Waveform screenshot: `results/case3a.png`
- [ ] Timing analysis:
- [ ] Key findings:

#### Case 3B - Blocking With #0 Delay (Inactive Region)
**Observations:**
- [ ] Waveform screenshot: `results/case3b.png`
- [ ] Timing analysis:
- [ ] Does #0 avoid the race condition?
- [ ] Key findings:

#### Case 3C - Blocking With #1 Delay (Different Simulation Time)
**Observations:**
- [ ] Waveform screenshot: `results/case3c.png`
- [ ] Timing analysis:
- [ ] Key findings:

#### Comparison and Conclusion:
- [ ] Difference between #0 and #1:
- [ ] Why doesn't #0 fully solve the race condition?
- [ ] Why does #1 delay avoid race condition?
- [ ] Which region does #0 execute in? Which "region" does #1 execute in?

---

### Case 4: Monitor Region - System Task Timing

#### Case 4A - Using $display
**Observations:**
- [ ] Console output screenshot: `results/case4a_console.png`
- [ ] What values are printed?
- [ ] When does $display execute relative to NBA?

#### Case 4B - Using $strobe
**Observations:**
- [ ] Console output screenshot: `results/case4b_console.png`
- [ ] What values are printed?
- [ ] When does $strobe execute relative to NBA?

#### Case 4C - Using $monitor
**Observations:**
- [ ] Console output screenshot: `results/case4c_console.png`
- [ ] What values are printed?
- [ ] How is $monitor different from $display and $strobe?

#### Comparison and Conclusion:
- [ ] Differences between $display, $strobe, and $monitor:
- [ ] Which system task shows the "final" values after NBA updates?
- [ ] When to use each system task?

---

## Overall Conclusions

### Key Takeaways
1. **Delta Cycles Matter**:
   - [ ] Summary of how delta cycles affect signal ordering

2. **Blocking vs Non-blocking in Testbenches**:
   - [ ] When to use blocking in testbenches:
   - [ ] When to use non-blocking in testbenches:

3. **Race Conditions**:
   - [ ] How to identify race conditions:
   - [ ] How to avoid race conditions:

### Best Practices for Testbench Development
- [ ] Recommendation 1:
- [ ] Recommendation 2:
- [ ] Recommendation 3:

---

## References

- IEEE Std 1364-2005 (Verilog HDL Standard) - Section 5.4: Event Execution
- "Writing Testbenches: Functional Verification of HDL Models" by Janick Bergeron
- Sutherland HDL, Inc. - "Verilog and SystemVerilog Gotchas" by Stuart Sutherland
