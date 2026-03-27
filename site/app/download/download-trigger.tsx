"use client";

import { useEffect, useRef } from "react";

type DownloadTriggerProps = {
  downloadUrl: string | null;
};

export function DownloadTrigger({ downloadUrl }: DownloadTriggerProps) {
  const hasStartedRef = useRef(false);

  useEffect(() => {
    if (!downloadUrl || hasStartedRef.current) {
      return;
    }

    hasStartedRef.current = true;

    const timer = window.setTimeout(() => {
      window.location.assign(downloadUrl);
    }, 700);

    return () => {
      window.clearTimeout(timer);
    };
  }, [downloadUrl]);

  return null;
}
