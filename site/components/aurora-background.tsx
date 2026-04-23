"use client";

import { motion, useReducedMotion } from "framer-motion";
import styles from "./aurora-background.module.css";

type AuroraBackgroundProps = {
  className?: string;
};

export function AuroraBackground({ className }: AuroraBackgroundProps) {
  const prefersReducedMotion = useReducedMotion();
  const still = Boolean(prefersReducedMotion);

  return (
    <div
      className={`${styles.root} ${className ?? ""}`.trim()}
      aria-hidden="true"
    >
      <div className={styles.stage}>
        <motion.div
          className={`${styles.orb} ${styles.orbBlue}`}
          animate={
            still
              ? undefined
              : {
                  x: [0, 60, -40, 0],
                  y: [0, -30, 40, 0],
                  scale: [1, 1.08, 0.96, 1],
                }
          }
          transition={{
            duration: 26,
            ease: "easeInOut",
            repeat: Infinity,
            repeatType: "mirror",
          }}
        />
        <motion.div
          className={`${styles.orb} ${styles.orbCyan}`}
          animate={
            still
              ? undefined
              : {
                  x: [0, -50, 30, 0],
                  y: [0, 40, -20, 0],
                  scale: [1, 0.94, 1.06, 1],
                }
          }
          transition={{
            duration: 32,
            ease: "easeInOut",
            repeat: Infinity,
            repeatType: "mirror",
          }}
        />
        <motion.div
          className={`${styles.orb} ${styles.orbViolet}`}
          animate={
            still
              ? undefined
              : {
                  x: [0, 40, -60, 0],
                  y: [0, 30, -10, 0],
                  scale: [1, 1.05, 0.95, 1],
                }
          }
          transition={{
            duration: 38,
            ease: "easeInOut",
            repeat: Infinity,
            repeatType: "mirror",
          }}
        />
        <motion.div
          className={`${styles.orb} ${styles.orbMint}`}
          animate={
            still
              ? undefined
              : {
                  x: [0, -30, 50, 0],
                  y: [0, -40, 20, 0],
                  scale: [1, 1.02, 0.98, 1],
                }
          }
          transition={{
            duration: 44,
            ease: "easeInOut",
            repeat: Infinity,
            repeatType: "mirror",
          }}
        />
      </div>
      <div className={styles.shine} />
      <div className={styles.grain} />
    </div>
  );
}
