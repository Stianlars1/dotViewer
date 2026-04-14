"use client";

import { useEffect, useRef, useState } from "react";

const DURATION = 1400;

function easeOutExpo(t: number): number {
  return t === 1 ? 1 : 1 - Math.pow(2, -10 * t);
}

interface AnimatedStatProps {
  value: number;
  className?: string;
}

export function AnimatedStat({ value, className }: AnimatedStatProps) {
  const ref = useRef<HTMLDivElement>(null);
  const [display, setDisplay] = useState<string>(String(value));
  const animated = useRef(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    const prefersReduced = window.matchMedia(
      "(prefers-reduced-motion: reduce)",
    ).matches;
    if (prefersReduced) return;

    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting && !animated.current) {
            animated.current = true;
            observer.disconnect();

            const start = performance.now();

            function tick(now: number) {
              const elapsed = now - start;
              const progress = Math.min(elapsed / DURATION, 1);
              const eased = easeOutExpo(progress);
              const current = Math.round(eased * value);
              setDisplay(String(current));

              if (progress < 1) {
                requestAnimationFrame(tick);
              }
            }

            setDisplay("0");
            requestAnimationFrame(tick);
          }
        }
      },
      { threshold: 0.3 },
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, [value]);

  return (
    <div ref={ref} className={className} style={{ fontVariantNumeric: "tabular-nums" }}>
      {display}
    </div>
  );
}
