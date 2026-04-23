"use client";

import Image, { type ImageProps } from "next/image";
import {
  createContext,
  useCallback,
  useContext,
  useId,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { flushSync } from "react-dom";
import styles from "./image-lightbox.module.css";

type LightboxPayload = {
  src: ImageProps["src"];
  alt: string;
  width: number;
  height: number;
  caption?: string;
  vtName: string;
};

type LightboxContextValue = {
  open: (payload: LightboxPayload, triggerEl: HTMLElement | null) => void;
  activeVtName: string | null;
};

const LightboxContext = createContext<LightboxContextValue | null>(null);

type DocWithVT = Document & {
  startViewTransition?: (callback: () => void | Promise<void>) => {
    finished: Promise<void>;
  };
};

export function LightboxProvider({ children }: { children: ReactNode }) {
  const [payload, setPayload] = useState<LightboxPayload | null>(null);
  const dialogRef = useRef<HTMLDialogElement | null>(null);
  const triggerRef = useRef<HTMLElement | null>(null);

  const runWithTransition = useCallback((update: () => void) => {
    const doc = document as DocWithVT;
    if (typeof doc.startViewTransition !== "function") {
      update();
      return;
    }
    doc.startViewTransition(() => {
      flushSync(update);
    });
  }, []);

  const open = useCallback(
    (next: LightboxPayload, triggerEl: HTMLElement | null) => {
      triggerRef.current = triggerEl;
      runWithTransition(() => setPayload(next));
    },
    [runWithTransition],
  );

  const close = useCallback(() => {
    runWithTransition(() => setPayload(null));
    const trigger = triggerRef.current;
    requestAnimationFrame(() => trigger?.focus());
  }, [runWithTransition]);

  useLayoutEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    if (payload && !dialog.open) {
      dialog.showModal();
    } else if (!payload && dialog.open) {
      dialog.close();
    }
  }, [payload]);

  const handleCancel = (event: React.SyntheticEvent<HTMLDialogElement>) => {
    event.preventDefault();
    close();
  };

  const handleDialogClick = (event: React.MouseEvent<HTMLDialogElement>) => {
    if (event.target === event.currentTarget) close();
  };

  const value = useMemo<LightboxContextValue>(
    () => ({
      open,
      activeVtName: payload?.vtName ?? null,
    }),
    [open, payload?.vtName],
  );

  return (
    <LightboxContext.Provider value={value}>
      {children}
      <dialog
        ref={dialogRef}
        className={styles.dialog}
        onCancel={handleCancel}
        onClick={handleDialogClick}
        aria-label={payload?.caption ?? payload?.alt ?? "Image preview"}
      >
        <div className={styles.frame}>
          <button
            type="button"
            className={styles.close}
            onClick={close}
            aria-label="Close preview"
          >
            <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
              <path
                d="M6 6l12 12M18 6L6 18"
                stroke="currentColor"
                strokeWidth="2.2"
                strokeLinecap="round"
              />
            </svg>
          </button>
          {payload ? (
            <Image
              src={payload.src}
              alt={payload.alt}
              width={payload.width}
              height={payload.height}
              sizes="95vw"
              style={{ viewTransitionName: payload.vtName }}
            />
          ) : null}
        </div>
        {payload?.caption ? (
          <span className={styles.caption}>{payload.caption}</span>
        ) : null}
      </dialog>
    </LightboxContext.Provider>
  );
}

type ImageLightboxProps = Omit<ImageProps, "onClick"> & {
  caption?: string;
};

export function ImageLightbox({
  caption,
  alt,
  src,
  width,
  height,
  ...imageProps
}: ImageLightboxProps) {
  const ctx = useContext(LightboxContext);
  const buttonRef = useRef<HTMLButtonElement | null>(null);
  const rawId = useId();
  const vtName = `lightbox-${rawId.replace(/[^a-zA-Z0-9_-]/g, "")}`;

  // The trigger owns its unique VT name UNLESS the dialog is currently showing
  // it (then the dialog takes over, so we clear it here to avoid duplicates).
  const isActive = ctx?.activeVtName === vtName;
  const triggerImgStyle = isActive ? undefined : { viewTransitionName: vtName };

  const handleClick = () => {
    if (!ctx) return;
    ctx.open(
      {
        src,
        alt,
        width:
          typeof width === "string" ? parseInt(width, 10) : (width as number),
        height:
          typeof height === "string" ? parseInt(height, 10) : (height as number),
        caption,
        vtName,
      },
      buttonRef.current,
    );
  };

  return (
    <button
      type="button"
      ref={buttonRef}
      className={styles.trigger}
      onClick={handleClick}
      aria-label={`Open larger preview: ${alt}`}
    >
      <Image
        src={src}
        alt={alt}
        width={width}
        height={height}
        {...imageProps}
        style={triggerImgStyle}
      />
    </button>
  );
}
