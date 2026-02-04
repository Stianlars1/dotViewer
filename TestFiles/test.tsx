import React, { useState, useEffect } from 'react';

interface CounterProps {
  initialCount?: number;
  label: string;
}

const Counter: React.FC<CounterProps> = ({ initialCount = 0, label }) => {
  const [count, setCount] = useState<number>(initialCount);
  const [isActive, setIsActive] = useState(false);

  useEffect(() => {
    if (isActive) {
      const timer = setInterval(() => setCount(c => c + 1), 1000);
      return () => clearInterval(timer);
    }
  }, [isActive]);

  return (
    <div className="counter-wrapper">
      <h2>{label}</h2>
      <span className="count">{count}</span>
      <button onClick={() => setCount(c => c + 1)}>+1</button>
      <button onClick={() => setCount(0)}>Reset</button>
      <button onClick={() => setIsActive(!isActive)}>
        {isActive ? 'Pause' : 'Auto'}
      </button>
    </div>
  );
};

export default Counter;
