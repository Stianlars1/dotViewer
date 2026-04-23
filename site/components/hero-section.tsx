"use client";

import type { ReactNode } from "react";
import Link from "next/link";
import { motion, useReducedMotion } from "framer-motion";
import { ImageLightbox } from "./image-lightbox";
import { TrackedDownloadLink } from "./tracked-download-link";
import { LogoAnimated } from "./logo-animated";
import { easeOutExpo } from "../lib/motion";
import styles from "./hero-section.module.css";

type HeroSectionProps = {
  appStoreHref: string | null;
  downloadHref: string;
  eyebrow: string;
  titlePieces: HeroTitlePiece[];
  lede: ReactNode;
  meta: string[];
  heroImage: {
    src: string;
    alt: string;
    width: number;
    height: number;
  };
};

export type HeroTitlePiece =
  | { kind: "text"; value: string }
  | { kind: "mono"; value: string }
  | { kind: "break" };

const WORD_STAGGER = 0.03;

export function HeroSection({
  appStoreHref,
  downloadHref,
  eyebrow,
  titlePieces,
  lede,
  meta,
  heroImage,
}: HeroSectionProps) {
  const prefersReducedMotion = useReducedMotion();
  const fromY = prefersReducedMotion ? 0 : 10;

  const words = flattenPiecesToWords(titlePieces);

  return (
    <section className={styles.hero} aria-labelledby="hero-title">
      <div className={styles.logoWrap} aria-hidden="true">
        <LogoAnimated size={104} priority />
      </div>

      <motion.div
        className={styles.eyebrow}
        initial={{ opacity: 0, y: fromY }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.45, ease: easeOutExpo, delay: 0.05 }}
      >
        <span className={styles.eyebrowDot} /> {eyebrow}
      </motion.div>

      <h1 id="hero-title" className={styles.title}>
        {words.map((word, index) => {
          if (word.kind === "break") {
            return <br key={`br-${index}`} aria-hidden="true" />;
          }
          const classes = [
            word.kind === "mono" ? styles.mono : styles.word,
            word.trailingSpace ? styles.spaced : "",
          ]
            .filter(Boolean)
            .join(" ");
          return (
            <motion.span
              key={`word-${index}`}
              className={classes}
              initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{
                duration: 0.5,
                ease: easeOutExpo,
                delay: 0.18 + index * WORD_STAGGER,
              }}
            >
              {word.value}
            </motion.span>
          );
        })}
      </h1>

      <motion.p
        className={styles.lede}
        initial={{ opacity: 0, y: fromY }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, ease: easeOutExpo, delay: 0.38 }}
      >
        {lede}
      </motion.p>

      <motion.div
        className={styles.ctaRow}
        initial={{ opacity: 0, y: fromY }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, ease: easeOutExpo, delay: 0.5 }}
      >
        <Link className={styles.primary} href={downloadHref}>
          Get the free DMG
        </Link>
        {appStoreHref ? (
          <TrackedDownloadLink
            assetKind="app_store"
            className={styles.ghost}
            releaseTag={null}
            source="home_page_hero_app_store"
            targetUrl={appStoreHref}
          >
            Buy on App Store
          </TrackedDownloadLink>
        ) : (
          <a className={styles.ghost} href="#install">
            See install options
          </a>
        )}
      </motion.div>

      <motion.div
        className={styles.meta}
        initial={{ opacity: 0, y: fromY }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, ease: easeOutExpo, delay: 0.62 }}
        aria-label="Distribution facts"
      >
        {meta.map((item) => (
          <span key={item}>
            <CheckIcon />
            {item}
          </span>
        ))}
      </motion.div>

      <motion.div
        className={styles.preview}
        initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 20, scale: prefersReducedMotion ? 1 : 0.985 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ duration: 0.7, ease: easeOutExpo, delay: 0.55 }}
      >
        <div className={styles.previewGlow} aria-hidden="true" />
        <div className={styles.previewFrame}>
          <span className={styles.previewSheen} aria-hidden="true" />
          <span className={styles.previewRing} aria-hidden="true" />
          <div className={styles.previewInner}>
            <ImageLightbox
              src={heroImage.src}
              alt={heroImage.alt}
              width={heroImage.width}
              height={heroImage.height}
              priority
              sizes="(max-width: 1100px) 100vw, 1060px"
              caption="dotViewer preview"
            />
          </div>
        </div>
      </motion.div>
    </section>
  );
}

function flattenPiecesToWords(pieces: HeroTitlePiece[]) {
  type Word =
    | { kind: "text"; value: string; trailingSpace: boolean }
    | { kind: "mono"; value: string; trailingSpace: boolean }
    | { kind: "break" };

  const punctuationOnly = /^[.,;:!?)\]]+$/;
  const output: Word[] = [];

  pieces.forEach((piece, pieceIndex) => {
    if (piece.kind === "break") {
      output.push({ kind: "break" });
      return;
    }

    const isLast = pieceIndex === pieces.length - 1;
    const nextPiece = pieces[pieceIndex + 1];
    const nextStartsWithPunct =
      nextPiece && nextPiece.kind !== "break"
        ? punctuationOnly.test(nextPiece.value.trimStart().charAt(0))
        : false;

    if (piece.kind === "mono") {
      output.push({
        kind: "mono",
        value: piece.value,
        trailingSpace: !isLast && !nextStartsWithPunct,
      });
      return;
    }

    const tokens = piece.value.split(/\s+/).filter(Boolean);
    tokens.forEach((token, tokenIndex) => {
      const tokenIsLast = tokenIndex === tokens.length - 1;
      const trailingSpace = !(
        (isLast && tokenIsLast) ||
        (tokenIsLast && nextStartsWithPunct)
      );
      output.push({ kind: "text", value: token, trailingSpace });
    });
  });

  return output;
}

function CheckIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2.25"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M20 6L9 17l-5-5" />
    </svg>
  );
}
