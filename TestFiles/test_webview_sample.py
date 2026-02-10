#!/usr/bin/env python3
"""Sample Python file for testing WKWebView preview (Experiment 3).

When view-based mode is active (QLIsDataBasedPreview=false),
previewing this file tests CopyableWebView's performKeyEquivalent
for intercepting Cmd+C and reading selection via JavaScript.
"""

def fibonacci(n: int) -> list[int]:
    """Generate Fibonacci sequence up to n terms."""
    if n <= 0:
        return []
    if n == 1:
        return [0]

    sequence = [0, 1]
    for _ in range(2, n):
        sequence.append(sequence[-1] + sequence[-2])
    return sequence


def is_prime(n: int) -> bool:
    """Check if a number is prime."""
    if n < 2:
        return False
    for i in range(2, int(n**0.5) + 1):
        if n % i == 0:
            return False
    return True


# Test: select this text with mouse, then try Cmd+C
PRIMES = [x for x in range(100) if is_prime(x)]
FIB_20 = fibonacci(20)

print(f"First 25 primes: {PRIMES}")
print(f"Fibonacci(20): {FIB_20}")
print(f"Sum of primes: {sum(PRIMES)}")
