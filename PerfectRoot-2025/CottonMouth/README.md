# CottonMouth (400 pts - MISC)

## Challenge Description
> A swift stream of linear equations stands between you and the flag. Stay quick, stay precise, and don't let the timer sink its fangs into you.

**Server:** `nc challenges2.perfectroot.wiki 9018`

## TL;DR
Automated solver for 25+ linear equations using Python's `sympy` library with proper handling of implicit multiplication.

## Initial Analysis
Connected to see:
```
  1) 73 - 1 + 80 - 8r + 53 = 101, Solve for r
```

The challenge presents linear equations that must be solved quickly. Manual solving would be too slow.

## Solution

### Step 1: Understand the Pattern
- Equations with implicit multiplication (e.g., `8r` means `8*r`)
- Single variable to solve for
- Time-sensitive (requires automation)

### Step 2: Build the Solver
```python
from sympy import symbols, Eq, solve
from sympy.parsing.sympy_parser import parse_expr, standard_transformations, implicit_multiplication_application
import socket, time

def solve_equation(equation_str, var_name):
    # Preprocess to handle edge cases
    equation_str = preprocess_equation(equation_str, var_name)
    
    left, right = equation_str.split('=')
    var = symbols(var_name)
    
    transformations = (standard_transformations + (implicit_multiplication_application,))
    
    left_expr = parse_expr(left.strip(), local_dict={var_name: var}, transformations=transformations)
    right_expr = parse_expr(right.strip(), local_dict={var_name: var}, transformations=transformations)
    
    equation = Eq(left_expr, right_expr)
    solution = solve(equation, var)
    
    return int(solution[0])
```

### Step 3: Key Bug Fix
The challenge had a tricky edge case with variables like `1j` being interpreted as complex numbers (imaginary unit) in Python. Solution:
```python
def preprocess_equation(equation_str, var_name):
    # Convert '1j' to '1*j' to prevent complex number interpretation
    pattern = r'(\d)(' + var_name + r')'
    equation_str = re.sub(pattern, r'\1*\2', equation_str)
    return equation_str
```

### Step 4: Automate
Full solver script connects via socket, parses equations, solves them, and submits answers automatically.

## Flag
```
r00t{sl33k_c0770n_m0u7h_h47_b33n_unr4v3ll3d}
```

## Key Takeaways
- **Automation is essential** for time-based challenges
- **Edge cases matter** - The `1j` complex number interpretation was the key bug
- **sympy is powerful** for symbolic mathematics
- Always test your parser with various input formats

## Tools Used
- Python 3
- `sympy` - Symbolic mathematics
- `socket` - Network communication
- `re` - Regular expressions for preprocessing
