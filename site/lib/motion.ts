import type { Transition, Variants } from "framer-motion";

export const easeOutExpo = [0.22, 1, 0.36, 1] as const;
export const easeStandard = [0.25, 0.1, 0.25, 1] as const;

export const springSoft: Transition = { type: "spring", stiffness: 280, damping: 26, mass: 0.8 };
export const springPop: Transition = { type: "spring", stiffness: 420, damping: 20, mass: 0.7 };
export const springLively: Transition = { type: "spring", stiffness: 520, damping: 24, mass: 0.6 };

export const revealVariants: Variants = {
  hidden: { opacity: 0, y: 12 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.55, ease: easeOutExpo },
  },
};

export const revealStaggerContainer: Variants = {
  hidden: { opacity: 1 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.05, delayChildren: 0.05 },
  },
};

export const wordRevealVariants: Variants = {
  hidden: { opacity: 0, y: 8 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.45, ease: easeOutExpo },
  },
};

export const hoverLift = {
  whileHover: { y: -1 },
  whileTap: { y: 0, scale: 0.985 },
  transition: springLively,
} as const;

export const viewportOnce = { once: true, amount: 0.25 } as const;
