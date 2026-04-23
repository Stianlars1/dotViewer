"use client";

import { useEffect, useRef } from "react";
import Image from "next/image";
import {
  motion,
  useMotionValue,
  useReducedMotion,
  useSpring,
  useTransform,
} from "framer-motion";
import { springPop, springSoft } from "../lib/motion";
import styles from "./logo-animated.module.css";

type LogoAnimatedProps = {
  size?: number;
  className?: string;
  interactive?: boolean;
  priority?: boolean;
  ariaLabel?: string;
};

const POINTER_RANGE_PX = 420;

export function LogoAnimated({
  size = 120,
  className,
  interactive = true,
  priority = false,
  ariaLabel = "dotViewer",
}: LogoAnimatedProps) {
  const prefersReducedMotion = useReducedMotion();
  const rootRef = useRef<HTMLDivElement | null>(null);

  const pointerX = useMotionValue(0);
  const pointerY = useMotionValue(0);

  const pointerXSpring = useSpring(pointerX, {
    stiffness: 140,
    damping: 22,
    mass: 0.5,
  });
  const pointerYSpring = useSpring(pointerY, {
    stiffness: 140,
    damping: 22,
    mass: 0.5,
  });

  const motiveX = useTransform(pointerXSpring, (value) => value * 6);
  const motiveY = useTransform(pointerYSpring, (value) => value * 6);
  const ringX = useTransform(pointerXSpring, (value) => value * 12);
  const ringY = useTransform(pointerYSpring, (value) => value * 12);
  const focalX = useTransform(pointerXSpring, (value) => value * 22);
  const focalY = useTransform(pointerYSpring, (value) => value * 22);

  useEffect(() => {
    if (!interactive || prefersReducedMotion) return;

    const last = { x: 0, y: 0, valid: false };

    const apply = (clientX: number, clientY: number) => {
      const el = rootRef.current;
      if (!el) return;
      const rect = el.getBoundingClientRect();
      const centerX = rect.left + rect.width / 2;
      const centerY = rect.top + rect.height / 2;
      const nx = (clientX - centerX) / POINTER_RANGE_PX;
      const ny = (clientY - centerY) / POINTER_RANGE_PX;
      pointerX.set(Math.max(-1, Math.min(1, nx)));
      pointerY.set(Math.max(-1, Math.min(1, ny)));
    };

    const handleMove = (event: PointerEvent) => {
      last.x = event.clientX;
      last.y = event.clientY;
      last.valid = true;
      apply(event.clientX, event.clientY);
    };

    const handleScrollOrResize = () => {
      if (!last.valid) return;
      apply(last.x, last.y);
    };

    const handleWindowLeave = () => {
      pointerX.set(0);
      pointerY.set(0);
    };

    window.addEventListener("pointermove", handleMove, { passive: true });
    window.addEventListener("pointerdown", handleMove, { passive: true });
    window.addEventListener("scroll", handleScrollOrResize, { passive: true });
    window.addEventListener("resize", handleScrollOrResize);
    document.documentElement.addEventListener("pointerleave", handleWindowLeave);

    return () => {
      window.removeEventListener("pointermove", handleMove);
      window.removeEventListener("pointerdown", handleMove);
      window.removeEventListener("scroll", handleScrollOrResize);
      window.removeEventListener("resize", handleScrollOrResize);
      document.documentElement.removeEventListener("pointerleave", handleWindowLeave);
    };
  }, [interactive, prefersReducedMotion, pointerX, pointerY]);

  const enableIdle = !prefersReducedMotion;

  return (
    <div
      ref={rootRef}
      className={`${styles.root} ${className ?? ""}`.trim()}
      style={{ ["--logo-size" as string]: `${size}px` }}
      role="img"
      aria-label={ariaLabel}
    >
      <motion.div
        className={`${styles.layer} ${styles.motive}`}
        initial={{ opacity: 0, scale: 0.86, rotate: -6 }}
        animate={{ opacity: 1, scale: 1.25, rotate: 0 }}
        transition={{ ...springSoft, delay: 0.04 }}
        style={{ x: motiveX, y: motiveY }}
      >
        <motion.div
          style={{ position: "absolute", inset: 0 }}
          animate={enableIdle ? { rotate: [0, 360] } : { rotate: 0 }}
          transition={
            enableIdle
              ? { duration: 90, ease: "linear", repeat: Infinity }
              : undefined
          }
        >
          <Image
            src="/brand/logo-layers/motive2.png"
            alt=""
            fill
            sizes={`${size}px`}
            priority={priority}
          />
        </motion.div>
      </motion.div>

      <motion.div
        className={`${styles.layer} ${styles.ring}`}
        initial={{ opacity: 0, scale: 0.92, rotate: -22 }}
        animate={{ opacity: 1, scale: 1, rotate: 0 }}
        transition={{ ...springSoft, delay: 0.22 }}
        style={{ x: ringX, y: ringY }}
      >
        <Image
          src="/brand/logo-layers/ring.png"
          alt=""
          fill
          sizes={`${size}px`}
          priority={priority}
        />
      </motion.div>

      <motion.div
        className={`${styles.layer} ${styles.focal}`}
        initial={{ opacity: 0, scale: 0.78, y: -10 }}
        animate={
          enableIdle
            ? { opacity: 1, scale: [1, 1.035, 1], y: 0 }
            : { opacity: 1, scale: 1, y: 0 }
        }
        transition={
          enableIdle
            ? {
                opacity: { ...springPop, delay: 0.38 },
                y: { ...springPop, delay: 0.38 },
                scale: {
                  duration: 3.2,
                  ease: "easeInOut",
                  repeat: Infinity,
                  delay: 0.9,
                },
              }
            : { ...springPop, delay: 0.38 }
        }
        style={{ x: focalX, y: focalY }}
      >
        <Image
          src="/brand/logo-layers/focal.png"
          alt=""
          fill
          sizes={`${size}px`}
          priority={priority}
        />
      </motion.div>
    </div>
  );
}
