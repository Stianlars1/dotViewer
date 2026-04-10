"use client";

import { useDeferredValue, useId, useState } from "react";
import styles from "./support-checker.module.css";
import {
  buildMatches,
  matchDescription,
  routingLimitationForMatch,
  visibleValues,
} from "../lib/support-checker-data";
import type { ProductStats, SupportedFileTypeRecord } from "../lib/product-stats";

type SupportCheckerProps = {
  issueRequestHref: string;
  issuesHref: string;
  stats: Pick<ProductStats, "extensions" | "fileTypes" | "filenameMappings">;
  supportedFileTypes: SupportedFileTypeRecord[];
};

const quickSamples = [".cue", "Dockerfile", "README.md", ".env.local", "yaml", ".1"];

export function SupportChecker({
  issueRequestHref,
  issuesHref,
  stats,
  supportedFileTypes,
}: SupportCheckerProps) {
  const [query, setQuery] = useState("");
  const deferredQuery = useDeferredValue(query);
  const headingId = useId();
  const inputId = useId();
  const helperId = useId();
  const statusId = useId();
  const matches = buildMatches(supportedFileTypes, deferredQuery);
  const topMatch = matches[0] ?? null;
  const exactMatch = matches.find((match) => match.exact) ?? null;
  const displayMatch = exactMatch ?? topMatch;
  const recordRoutingLimitations = displayMatch?.record.routingLimitations ?? [];
  const exactRoutingLimitation = routingLimitationForMatch(
    exactMatch,
    deferredQuery,
    recordRoutingLimitations,
  );
  const extensions = visibleValues(displayMatch?.record.extensions ?? [], ".");
  const filenames = visibleValues(displayMatch?.record.filenames ?? []);

  let tone: "idle" | "limited" | "possible" | "supported" | "unsupported" = "idle";
  if (deferredQuery.trim()) {
    if (exactRoutingLimitation) {
      tone = "limited";
    } else {
      tone = exactMatch ? "supported" : matches.length > 0 ? "possible" : "unsupported";
    }
  }

  return (
    <section aria-labelledby={headingId} className={styles.checker}>
      <div className={styles.checkerBackdrop} aria-hidden="true" />

      <div className={styles.checkerIntro}>
        <div className={styles.eyebrow}>Support checker</div>
        <h2 className={styles.title} id={headingId}>
          Check a file type before you install.
        </h2>
        <p className={styles.body}>
          Type an extension like <code>.cue</code>, an exact filename like{" "}
          <code>Dockerfile</code>, or a language name like <code>yaml</code>.
          The result below uses the same shipped support list and macOS routing
          caveats the site exposes in full further down the page.
        </p>
        <p className={styles.stats}>
          Static shipped coverage: <strong>{stats.fileTypes}</strong> file types,{" "}
          <strong>{stats.extensions}</strong> extensions, and{" "}
          <strong>{stats.filenameMappings}</strong> exact filename mappings.
        </p>
      </div>

      <div className={styles.shell}>
        <form
          className={styles.form}
          onSubmit={(event) => {
            event.preventDefault();
          }}
          role="search"
        >
          <label className={styles.label} htmlFor={inputId}>
            Type your file type
          </label>
          <div className={styles.inputWrap}>
            <span aria-hidden="true" className={styles.searchGlyph}>
              /
            </span>
            <input
              id={inputId}
              aria-describedby={`${helperId} ${statusId}`}
              autoComplete="off"
              className={styles.input}
              name="supportQuery"
              onChange={(event) => setQuery(event.currentTarget.value)}
              placeholder=".cue, README.md, yaml, Dockerfile…"
              spellCheck={false}
              type="search"
              value={query}
            />
          </div>
          <p className={styles.helper} id={helperId}>
            Search works against shipped extensions, exact filename mappings, and
            file type names.
          </p>

          <div className={styles.sampleRow}>
            {quickSamples.map((sample) => (
              <button
                className={styles.sample}
                key={sample}
                onClick={() => setQuery(sample)}
                type="button"
              >
                <code>{sample}</code>
              </button>
            ))}
          </div>
        </form>

        <div
          aria-live="polite"
          className={styles.result}
          data-tone={tone}
          id={statusId}
          role="status"
        >
          <div className={styles.resultHeader}>
            <span className={styles.resultBadge} data-tone={tone}>
              {tone === "limited" && "macOS limitation"}
              {tone === "supported" && "Supported"}
              {tone === "possible" && "Closest shipped matches"}
              {tone === "unsupported" && "Needs a new release"}
              {tone === "idle" && "Ready to check"}
            </span>
            <p className={styles.resultLead}>
              {tone === "idle" &&
                "Start with a real extension, filename, or language name and dotViewer will check the shipped list instantly."}
              {tone === "limited" &&
                (exactRoutingLimitation?.summary ??
                  "dotViewer ships this mapping, but macOS still keeps the system preview path for it.")}
              {tone === "supported" &&
                `${displayMatch?.record.displayName ?? "This file type"} is already in the shipped support list.`}
              {tone === "possible" &&
                `${matches.length} related shipped match${matches.length === 1 ? "" : "es"} found. Refine the query if you need an exact yes or no.`}
              {tone === "unsupported" &&
                "This query is not in the shipped support list, which means users cannot add it themselves yet."}
            </p>
            {displayMatch ? (
              <p className={styles.resultHint}>
                {tone === "limited"
                  ? exactRoutingLimitation?.details
                  : matchDescription(displayMatch)}
              </p>
            ) : null}
          </div>

          {displayMatch ? (
            <div className={styles.primaryResult}>
              <div className={styles.primaryMeta}>
                <h3>{displayMatch.record.displayName}</h3>
                <p>
                  {displayMatch.record.extensions.length} extension
                  {displayMatch.record.extensions.length === 1 ? "" : "s"}
                  {displayMatch.record.filenames.length > 0
                    ? ` • ${displayMatch.record.filenames.length} exact filename${
                        displayMatch.record.filenames.length === 1 ? "" : "s"
                      }`
                    : ""}
                </p>
              </div>

              {extensions.visible.length > 0 ? (
                <div className={styles.tokenBlock}>
                  <span>Extensions</span>
                  <div className={styles.tokens}>
                    {extensions.visible.map((value) => (
                      <code key={`${displayMatch.record.id}-ext-${value}`}>{value}</code>
                    ))}
                    {extensions.hiddenCount > 0 ? (
                      <span className={styles.moreToken}>
                        +{extensions.hiddenCount} more
                      </span>
                    ) : null}
                  </div>
                </div>
              ) : null}

              {filenames.visible.length > 0 ? (
                <div className={styles.tokenBlock}>
                  <span>Exact filenames</span>
                  <div className={styles.tokens}>
                    {filenames.visible.map((value) => (
                      <code key={`${displayMatch.record.id}-file-${value}`}>{value}</code>
                    ))}
                    {filenames.hiddenCount > 0 ? (
                      <span className={styles.moreToken}>
                        +{filenames.hiddenCount} more
                      </span>
                    ) : null}
                  </div>
                </div>
              ) : null}

              {recordRoutingLimitations.length > 0 ? (
                <div className={styles.routingNotes}>
                  <span>Routing caveats</span>
                  <ul>
                    {recordRoutingLimitations.map((limitation) => (
                      <li key={`${displayMatch.record.id}-${limitation.id}`}>
                        <div className={styles.routingNoteHeader}>
                          <strong>{limitation.title}</strong>
                          <div className={styles.routingNoteTokens}>
                            {limitation.matchedExtensions.map((extension) => (
                              <code
                                key={`${displayMatch.record.id}-${limitation.id}-${extension}`}
                              >
                                .{extension}
                              </code>
                            ))}
                          </div>
                        </div>
                        <p>{limitation.summary}</p>
                      </li>
                    ))}
                  </ul>
                </div>
              ) : null}
            </div>
          ) : null}

          {matches.length > 1 ? (
            <div className={styles.matchList}>
              <span>Other close matches</span>
              <ul>
                {matches.slice(1, 5).map((match) => (
                  <li key={`${match.record.id}-${match.kind}-${match.matchedValue}`}>
                    <strong>{match.record.displayName}</strong>
                    <span>{matchDescription(match)}</span>
                  </li>
                ))}
              </ul>
            </div>
          ) : null}

          {tone === "unsupported" ? (
            <div className={styles.actions}>
              <a className={styles.primaryAction} href={issueRequestHref}>
                Request support on GitHub
              </a>
              <a className={styles.secondaryAction} href={issuesHref}>
                Review open support issues
              </a>
            </div>
          ) : null}
        </div>
      </div>
    </section>
  );
}
