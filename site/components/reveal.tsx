"use client";

import type { ReactNode } from "react";
import { motion, useReducedMotion } from "framer-motion";
import { easeOutExpo } from "../lib/motion";

type RevealProps = {
  children: ReactNode;
  delay?: number;
  y?: number;
  className?: string;
  as?: "div" | "section" | "article" | "header" | "footer";
  once?: boolean;
  id?: string;
  ariaLabel?: string;
};

export function Reveal({
  children,
  delay = 0,
  y = 12,
  className,
  as = "div",
  once = true,
  id,
  ariaLabel,
}: RevealProps) {
  const prefersReducedMotion = useReducedMotion();
  const Component = motion[as];

  const fromY = prefersReducedMotion ? 0 : y;

  return (
    <Component
      className={className}
      id={id}
      aria-label={ariaLabel}
      initial={{ opacity: 0, y: fromY }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once, amount: 0.2 }}
      transition={{ duration: 0.55, ease: easeOutExpo, delay }}
    >
      {children}
    </Component>
  );
}
