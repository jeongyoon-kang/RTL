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

// Testbench
@(posedge clk);
i_valid = 1'b1;      // Active region: executed immediately
i_data <= 8'h42;     // NBA region: scheduled for later delta cycle

// DUT
always @(posedge clk) begin
    r_valid <= i_valid;   // NBA region: reads i_valid, schedules update
    r_data <= i_data;     // NBA region: reads i_data, schedules update
end
```

**Execution sequence at time T:**
1. **Active region**: `i_valid = 1'b1;` executes → `i_valid` changes immediately
2. **Active region**: DUT reads `i_valid` (sees new value `1'b1`), reads `i_data` (sees old value)
3. **NBA region**: `i_data` updates to `8'h42`
4. **NBA region**: `r_valid` and `r_data` update with values read in Active region

This ordering can cause unexpected behavior! The DUT sees different values for `i_valid` and `i_data` even though they were "assigned" at the same time in the testbench.

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

## Case Studies

We will explore four scenarios where the choice of blocking vs non-blocking in the testbench affects timing.

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

### Case 3: Initial Block Initialization

**Scenario**: Initialize signals and start stimulus in an `initial` block.

```verilog
// Case 3A: Blocking
initial begin
    i_valid = 1'b0;
    i_data = 8'h00;
    repeat(2) @(posedge clk);  // Wait for reset
    i_valid = 1'b1;             // Start stimulus
    i_data = 8'h05;
end

// Case 3B: Non-blocking
initial begin
    i_valid <= 1'b0;
    i_data <= 8'h00;
    repeat(2) @(posedge clk);  // Wait for reset
    i_valid <= 1'b1;            // Start stimulus
    i_data <= 8'h05;
end
```

**Expected Behavior:**
- **Case 3A (Blocking)**: Immediate assignments. Stimulus changes occur in Active region.
- **Case 3B (Non-blocking)**: Scheduled assignments. Stimulus changes occur in NBA region.

This is the scenario where real-world issues often appear in testbenches!

---

### Case 4: Continuous Clock-Synchronous Toggling

**Scenario**: Testbench also uses a clocked `always` block to drive inputs.

```verilog
// Case 4A: Blocking (DANGER - Race Condition!)
always @(posedge clk) begin
    i_valid = ~i_valid;  // Active region
end

// DUT
always @(posedge clk) begin
    r_valid[0] <= i_valid;  // Active region reads i_valid, NBA updates r_valid[0]
end

// Case 4B: Non-blocking (Correct)
always @(posedge clk) begin
    i_valid <= ~i_valid;  // NBA region
end
```

**Expected Behavior:**
- **Case 4A (Blocking)**: Race condition! Both TB and DUT trigger on the same clock edge. TB's blocking assignment happens in Active region, but order relative to DUT reading the signal is undefined.
- **Case 4B (Non-blocking)**: Both TB and DUT use NBA region. Updates happen in a well-defined order.

**Race Condition Explanation:**
```
Time T (posedge clk):
Case 4A:
  Active: TB executes i_valid = ~i_valid  (which happens first?)
  Active: DUT reads i_valid                (does it see old or new value?)
  → Order is UNDEFINED by the standard!

Case 4B:
  Active: DUT reads i_valid (old value), schedules r_valid[0] <= old_value
  NBA:    i_valid updates to new value
  NBA:    r_valid[0] updates to old value
  → Deterministic behavior
```

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
# Case 1
make case1a  # Blocking after clock edge
make case1b  # Non-blocking after clock edge

# Case 2
make case2a  # Blocking before clock edge
make case2b  # Non-blocking before clock edge

# Case 3
make case3a  # Blocking in initial block
make case3b  # Non-blocking in initial block

# Case 4
make case4a  # Blocking in always block (race condition)
make case4b  # Non-blocking in always block
```

### Viewing Waveforms

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

### Case 3: Initial Block Initialization

#### Case 3A - Blocking Assignment
**Observations:**
- [ ] Waveform screenshot: `results/case3a.png`
- [ ] Timing analysis:
- [ ] Key findings:

#### Case 3B - Non-blocking Assignment
**Observations:**
- [ ] Waveform screenshot: `results/case3b.png`
- [ ] Timing analysis:
- [ ] Key findings:

#### Comparison and Conclusion:
- [ ] Differences observed:
- [ ] Explanation based on delta cycles:

---

### Case 4: Continuous Clock-Synchronous Toggling

#### Case 4A - Blocking Assignment (Race Condition)
**Observations:**
- [ ] Waveform screenshot: `results/case4a.png`
- [ ] Timing analysis:
- [ ] Race condition symptoms:

#### Case 4B - Non-blocking Assignment (Correct)
**Observations:**
- [ ] Waveform screenshot: `results/case4b.png`
- [ ] Timing analysis:
- [ ] Key findings:

#### Comparison and Conclusion:
- [ ] Differences observed:
- [ ] Race condition explanation:
- [ ] Why non-blocking resolves the issue:

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
