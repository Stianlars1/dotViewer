import type { ReactNode } from "react";
import Image from "next/image";
import Link from "next/link";
import { AnimatedStat } from "../components/animated-stat";
import styles from "./page.module.css";
import { getProductStats, getSupportedFileTypes } from "../lib/product-stats";
import { TrackedDownloadLink } from "../components/tracked-download-link";
import {
  buildHomeSchema,
  CREATOR_NAME,
  CREATOR_URL,
  DBHOST_URL,
} from "../lib/structured-data";
import { getSiteConfig } from "../lib/site-config";
import { BorderBeam } from "@stianlarsen/border-beam";
import { NoWhitespace } from "../components/NoWhitespace";
import { SupportChecker } from "../components/support-checker";


function Code({ children }: { children: ReactNode }) {
  return <code>{children}</code>;
}


const comparisonPoints = [
  {
    id: "one-app",
    content:
      "Use one macOS app instead of separate markdown previewers, plain-text viewers, and syntax-highlighting plugins.",
  },
  {
    id: "developer-files",
    content: (
      <>
        Preview common developer files such as <Code>.gitignore</Code>,{" "}
        <Code>.env</Code>, <Code>.editorconfig</Code>, <Code>README.md</Code>,{" "}
        <Code>JSON</Code>, <Code>YAML</Code>, <Code>XML</Code>, <Code>INI</Code>
        , <Code>CSV</Code>, <Code>TSV</Code>, extensionless executable scripts,
        man pages, <Code>shell scripts</Code>, <Code>log files</Code>, and{" "}
        <Code>source code</Code> from the same Quick Look flow.
      </>
    ),
  },
  {
    id: "markdown-toggle",
    content:
      "Switch markdown between RAW and rendered views without changing tools or leaving Finder.",
  },
  {
    id: "built-in-controls",
    content:
      "Tune system-following themes, initial preview size, line numbers, width, copy behavior, supported file mappings, and markdown defaults from the built-in app instead of managing multiple utilities.",
  },
];

const limitations = [
  {
    id: "html-routing",
    content: (
      <>
        Some file types are still claimed by macOS system preview handlers. For
        example, <Code>.html</Code> stays with the native HTML Quick Look
        renderer.
      </>
    ),
  },
  {
    id: "ts-routing",
    content: (
      <>
        TypeScript <Code>.ts</Code> can still be routed by macOS as MPEG-2
        transport stream video in some situations, which is a platform routing
        limitation rather than a dotViewer bug.
      </>
    ),
  },
  {
    id: "macos-owned",
    content:
      "dotViewer improves Quick Look where third-party extensions are allowed. It does not override every system-owned preview path in macOS.",
  },
];

const installSteps = [
  {
    step: "01",
    title: "Download the latest DMG",
    body: (
      <>
        Use the stable{" "}
        <Link className={styles.inlineLink} href="/download">
          <Code>/download</Code>
        </Link>{" "}
        page and you always land on the current installer, checksum, and version
        history without hunting through release assets manually.
      </>
    ),
  },
  {
    step: "02",
    title: "Drag dotViewer into Applications",
    body: "Install it like a normal Mac app. One app, one DMG, no account wall, and no chain of separate Quick Look add-ons.",
  },
  {
    step: "03",
    title: "Launch once, then use Quick Look",
    body: "The first launch registers the extension. After that, select a supported file in Finder and press Space to preview it.",
  },
];

const faqs = [
  {
    id: "built-for",
    question: "What files is dotViewer built for?",
    answer: (
      <>
        dotViewer is built for the technical text files people keep checking in
        Finder: dotfiles, config files, markdown documents, <Code>CSV</Code> /{" "}
        <Code>TSV</Code> data, man pages, logs, extensionless executable
        scripts, plain text documents, and <Code>source code</Code>.
      </>
    ),
    schemaQuestion: "What files is dotViewer built for?",
    schemaAnswer:
      "dotViewer is built for the technical text files people keep checking in Finder: dotfiles, config files, markdown documents, logs, plain text documents, and source code.",
  },
  {
    id: "dotfiles",
    question: (
      <>
        Can dotViewer preview dotfiles like <Code>.gitignore</Code> and config
        files like <Code>JSON</Code>, <Code>YAML</Code>, <Code>XML</Code>, and{" "}
        <Code>INI</Code>?
      </>
    ),
    answer: (
      <>
        Yes. The app is designed around exactly that workflow, including common
        files such as <Code>.gitignore</Code>, <Code>.env</Code>,{" "}
        <Code>.editorconfig</Code>, <Code>package.json</Code>, <Code>YAML</Code>
        , <Code>XML</Code>, <Code>plist</Code>, <Code>TSV</Code>, man pages,{" "}
        <Code>log files</Code>, extensionless executable scripts, and many
        other text-based formats.
      </>
    ),
    schemaQuestion:
      "Can dotViewer preview dotfiles like .gitignore and config files like JSON, YAML, XML, and INI?",
    schemaAnswer:
      "Yes. The app is designed around exactly that workflow, including common files such as .gitignore, .env, .editorconfig, package.json, YAML, XML, plist, log files, and many other text-based formats.",
  },
  {
    id: "why-one-app",
    question:
      "Why use dotViewer instead of separate markdown or code preview extensions?",
    answer:
      "Because dotViewer is meant to be the all-in-one Quick Look upgrade. Instead of installing one utility for markdown, another for plain text, and another for syntax highlighting, you get a single macOS app with one settings surface and one install flow.",
    schemaQuestion:
      "Why use dotViewer instead of separate markdown or code preview extensions?",
    schemaAnswer:
      "Because dotViewer is meant to be the all-in-one Quick Look upgrade. Instead of installing one utility for markdown, another for plain text, and another for syntax highlighting, you get a single macOS app with one settings surface and one install flow.",
  },
  {
    id: "system-handlers",
    question:
      "Does it replace Finder's built-in Quick Look for every file type?",
    answer:
      "No. Some file types are owned by system handlers in macOS, and those still take priority. dotViewer is designed to improve the technical file cases where third-party Quick Look extensions can realistically help.",
    schemaQuestion:
      "Does it replace Finder's built-in Quick Look for every file type?",
    schemaAnswer:
      "No. Some file types are owned by system handlers in macOS, and those still take priority. dotViewer is designed to improve the technical file cases where third-party Quick Look extensions can realistically help.",
  },
  {
    id: "signed",
    question: "Is the app signed and notarized?",
    answer:
      "Yes. The public download flow is built around a Developer ID signed, notarized DMG so installation feels trustworthy and Gatekeeper-friendly for normal macOS users.",
    schemaQuestion: "Is the app signed and notarized?",
    schemaAnswer:
      "Yes. The public download flow is built around a Developer ID signed, notarized DMG so installation feels trustworthy and Gatekeeper-friendly for normal macOS users.",
  },
  {
    id: "pricing",
    question: "Is dotViewer free or paid?",
    answer:
      "Both distribution paths exist. The direct DMG on dotviewer.app is the free adoption path. There is also a paid App Store option for people who prefer store-managed installation and want to support ongoing development through a purchase.",
    schemaQuestion: "Is dotViewer free or paid?",
    schemaAnswer:
      "Both distribution paths exist. The direct DMG on dotviewer.app is the free adoption path. There is also a paid App Store option for people who prefer store-managed installation and want to support ongoing development through a purchase.",
  },
  {
    id: "tuning",
    question: "Can I tune the preview and app UI?",
    answer:
      "Yes. dotViewer includes system-following theme choices, initial preview window sizing, font sizing, content width controls, line-number and word-wrap options, markdown defaults, copy behavior, file type controls, and more inside the companion app.",
    schemaQuestion: "Can I tune the preview and app UI?",
    schemaAnswer:
      "Yes. dotViewer includes system-following theme choices, initial preview window sizing, font sizing, content width controls, line-number and word-wrap options, markdown defaults, copy behavior, file type controls, and more inside the companion app.",
  },
  {
    id: "custom-mappings",
    question: "Can I add my own file types in dotViewer?",
    answer: (
      <>
        Yes, but only for file types dotViewer already ships mappings for. You
        can override highlighting for supported extensions and exact filenames
        in the app, while a small number of shipped mappings still have
        macOS-owned preview paths. Sorry, but dotViewer cannot teach macOS Quick
        Look completely brand-new file types at runtime. If a file type is not
        in the shipped support list, it needs a dotViewer update and a GitHub
        issue request.
      </>
    ),
    schemaQuestion: "Can I add my own file types in dotViewer?",
    schemaAnswer:
      "Yes, but only for file types dotViewer already ships mappings for. You can override highlighting for supported extensions and exact filenames in the app, while a small number of shipped mappings still have macOS-owned preview paths. dotViewer cannot teach macOS Quick Look completely brand-new file types at runtime. If a file type is not in the shipped support list, it needs a dotViewer update and a GitHub issue request.",
  },
];

export default function HomePage() {
  const stats = getProductStats();
  const supportedFileTypes = getSupportedFileTypes();
  const routingCaveatCount = supportedFileTypes.reduce((count, type) => {
    return (
      count +
      type.routingLimitations.reduce((total, limitation) => {
        return total + limitation.matchedExtensions.length;
      }, 0)
    );
  }, 0);
  const config = getSiteConfig();
  const appStoreHref = config.appStoreUrl;
  const releasesHref = config.releasesUrl ?? "#install";
  const repoHref = config.repoUrl ?? releasesHref;
  const issuesHref = config.repoUrl ? `${config.repoUrl}/issues` : repoHref;
  const issueRequestHref = config.repoUrl
    ? `${config.repoUrl}/issues/new?title=${encodeURIComponent("File type support: ")}`
    : repoHref;
  const schema = buildHomeSchema(
    config,
    stats,
    faqs.map((item) => ({
      question: item.schemaQuestion,
      answer: item.schemaAnswer,
    })),
  );
  const proofStats = [
    { value: stats.fileTypes, label: "built-in file types" },
    { value: stats.extensions, label: "registered extensions" },
    { value: stats.filenameMappings, label: "filename mappings" },
    { value: stats.grammars, label: "highlight query files" },
  ];

  return (
    <div className={styles.page}>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }}
      />

      <div className={styles.backdrop} aria-hidden="true">
        <div className={styles.orbOne} />
        <div className={styles.orbTwo} />
      </div>

      <a className={styles.skipLink} href="#main-content">
        Skip to content
      </a>

      <header className={styles.header}>
        <div className={styles.shell}>
          <nav className={styles.nav} aria-label="Primary">
            <Link className={styles.brand} href="/">
              <Image
                className={styles.brandMark}
                src="/brand/dotviewer-icon-light.png"
                alt=""
                width={32}
                height={32}
                sizes="32px"
              />
              <span>dotViewer</span>
            </Link>

            <div className={styles.navLinks}>
              <a href="#previews">Previews</a>
              <a href="#controls">Controls</a>
              <a href="#coverage">Coverage</a>
              <a href="#install">Install</a>
              <a href="#faq">FAQ</a>
            </div>

            <Link className={styles.navCta} href="/download">
              Download
            </Link>
          </nav>
        </div>
      </header>

      <main className={styles.main} id="main-content">
        <div className={styles.shell}>
          <section className={styles.hero}>
            <div className={styles.heroInner}>
              <div className={styles.eyebrow}>
                Finder preview for technical files on macOS
                <BorderBeam
                  size={100}
                  colorFrom={"#1762ff"}
                  colorTo={"transparent"}
                />
              </div>

              <h1 className={styles.heroTitle}>
                Preview{" "}
                <NoWhitespace>
                  <span className={styles.code}>dotfiles</span>,{" "}
                </NoWhitespace>{" "}
                <NoWhitespace>
                  <span className={styles.code}> config files</span>,
                </NoWhitespace>{" "}
                <NoWhitespace>
                  <span className={styles.code}> markdown</span>,{" "}
                </NoWhitespace>{" "}
                <NoWhitespace>
                  <span className={styles.code}> logs</span>,{" "}
                </NoWhitespace>{" "}
                <NoWhitespace>
                  <span className={styles.code}> plain text</span>, and{" "}
                </NoWhitespace>
                <NoWhitespace>
                  <span className={styles.code}> code</span>
                </NoWhitespace>{" "}
                in Quick Look.
              </h1>

              <p className={styles.heroBody}>
                Preview <Code>.gitignore</Code>, <Code>.env</Code>,{" "}
                <Code>README.md</Code>, and hundreds more technical text files
                without opening a full editor. One native app, free direct DMG.
              </p>

              <div className={styles.heroActions}>
                <Link className={styles.primaryAction} href="/download">
                  Get the free DMG
                </Link>
                {appStoreHref ? (
                  <TrackedDownloadLink
                    assetKind="app_store"
                    className={styles.secondaryAction}
                    releaseTag={null}
                    source="home_page_hero_app_store"
                    targetUrl={appStoreHref}
                  >
                    Buy on App Store
                  </TrackedDownloadLink>
                ) : (
                  <a className={styles.secondaryAction} href={releasesHref}>
                    View releases
                  </a>
                )}
              </div>
            </div>
          </section>

          <section
            className={styles.showcaseSection}
            id="previews"
            aria-label="Actual product screenshots"
          >
            <div className={styles.heroGallery}>
              <figure className={styles.galleryLead}>
                <Image
                  src="/product/markdown-rendered-toc.jpeg"
                  alt="dotViewer rendered markdown preview with the table of contents open"
                  width={3680}
                  height={2224}
                  priority
                  sizes="(max-width: 1100px) 100vw, 70vw"
                />
                <figcaption>
                  Rendered markdown with table of contents
                </figcaption>
              </figure>

              <div className={styles.galleryStack}>
                <figure className={styles.galleryCard}>
                  <Image
                    src="/product/markdown-raw.jpeg"
                    alt="dotViewer markdown RAW preview with syntax highlighting"
                    width={1644}
                    height={1676}
                    sizes="(max-width: 1100px) 100vw, 28vw"
                  />
                  <figcaption>
                    RAW mode with syntax-highlighted source
                  </figcaption>
                </figure>

                <figure className={styles.galleryCard}>
                  <Image
                    src="/product/code-c.jpeg"
                    alt="dotViewer C source file preview in Quick Look"
                    width={1644}
                    height={770}
                    sizes="(max-width: 1100px) 100vw, 28vw"
                  />
                  <figcaption>
                    C source with line numbers and file badge
                  </figcaption>
                </figure>
              </div>
            </div>
          </section>

          <section className={styles.section} id="support-checker">
            <div className={styles.sectionIntro}>
              <div className={styles.kicker}>Support Checker</div>
              <h2 className={styles.sectionTitle}>
                Check if your file type is supported.
              </h2>
            </div>

            <SupportChecker
              issueRequestHref={issueRequestHref}
              issuesHref={issuesHref}
              stats={stats}
              supportedFileTypes={supportedFileTypes}
            />
          </section>

          <section className={styles.section}>
            <div className={styles.limitationsPanel}>
              <div className={styles.limitationsCopy}>
                <div className={styles.kicker}>Why dotViewer</div>
                <h2 className={styles.sectionTitle}>
                  One Quick Look app instead of separate markdown, code, and
                  text viewers.
                </h2>
                <p className={styles.sectionBody}>
                  Install one app and preview markdown, config files, dotfiles,
                  logs, plain text, and <Code>source code</Code> from the same
                  Quick Look flow.
                </p>
              </div>

              <ul className={styles.limitationsList}>
                {comparisonPoints.map((item) => (
                  <li key={item.id}>{item.content}</li>
                ))}
              </ul>
            </div>
          </section>

          <section className={styles.section}>
            <div className={styles.sectionIntro}>
              <div className={styles.kicker}>Preview Modes</div>
              <h2 className={styles.sectionTitle}>
                Real macOS previews for code, markdown, config files, and
                technical documents.
              </h2>
            </div>

            <div className={styles.featureRow}>
              <div className={styles.featureCopy}>
                <div className={styles.storyKicker}>Code and config files</div>
                <h3 className={styles.storyTitle}>
                  Preview{" "}
                  <NoWhitespace>
                    <Code>.gitignore</Code>,
                  </NoWhitespace>{" "}
                  <NoWhitespace>
                    <Code>.env</Code>,
                  </NoWhitespace>{" "}
                  <NoWhitespace>
                    <Code>shell scripts</Code>,
                  </NoWhitespace>{" "}
                  <NoWhitespace>
                    <Code>XML</Code>,
                  </NoWhitespace>{" "}
                  <NoWhitespace>
                    <Code>JSON</Code>,
                  </NoWhitespace>{" "}
                  <NoWhitespace>
                    <Code>YAML</Code>,
                  </NoWhitespace>{" "}
                  and{" "}
                  <NoWhitespace>
                    <Code>source code</Code>
                  </NoWhitespace>{" "}
                  with syntax-aware rendering.
                </h3>
                <p className={styles.storyBody}>
                  The preview stays in Quick Look, so a small inspection stays
                  small.
                </p>
              </div>

              <div className={styles.imagePair}>
                <figure className={styles.shotWide}>
                  <Image
                    src="/product/code-c.jpeg"
                    alt="C file preview in dotViewer"
                    width={1644}
                    height={770}
                    sizes="(max-width: 1100px) 100vw, 42vw"
                  />
                  <figcaption>
                    C source with language badge and copy action
                  </figcaption>
                </figure>

                <figure className={styles.shotWide}>
                  <Image
                    src="/product/code-swift.jpeg"
                    alt="Swift file preview in dotViewer"
                    width={2134}
                    height={1768}
                    sizes="(max-width: 1100px) 100vw, 42vw"
                  />
                  <figcaption>
                    Swift file with token-aware highlighting
                  </figcaption>
                </figure>
              </div>
            </div>

            <div className={styles.featureRow}>
              <div className={styles.imageStack}>
                <figure className={styles.shotLarge}>
                  <Image
                    src="/product/markdown-rendered-toc.jpeg"
                    alt="Rendered markdown preview with table of contents open in dotViewer"
                    width={3680}
                    height={2224}
                    sizes="(max-width: 1100px) 100vw, 46vw"
                  />
                  <figcaption>
                    Rendered mode with styled code blocks and TOC
                  </figcaption>
                </figure>

                <figure className={styles.shotLarge}>
                  <Image
                    src="/product/markdown-raw.jpeg"
                    alt="RAW markdown preview in dotViewer"
                    width={1644}
                    height={1676}
                    sizes="(max-width: 1100px) 100vw, 46vw"
                  />
                  <figcaption>
                    RAW markdown source inspection
                  </figcaption>
                </figure>
              </div>

              <div className={styles.featureCopy}>
                <div className={styles.storyKicker}>Markdown</div>
                <h3 className={styles.storyTitle}>
                  Preview markdown in source form or rendered form without
                  switching tools.
                </h3>
                <p className={styles.storyBody}>
                  Inspect the source or read the document, without leaving
                  Finder.
                </p>
              </div>
            </div>

            <div className={styles.featureRow}>
              <div className={styles.featureCopy}>
                <div className={styles.storyKicker}>Copy behavior</div>
                <h3 className={styles.storyTitle}>
                  Selection can copy automatically, because Quick Look needs
                  practical controls.
                </h3>
                <p className={styles.storyBody}>
                  Configurable copy makes the preview useful for real work, not
                  just passive viewing.
                </p>
              </div>

              <figure className={styles.shotHero}>
                <Image
                  src="/product/markdown-copy-toast.jpeg"
                  alt="dotViewer rendered markdown preview showing copied selection feedback"
                  width={3680}
                  height={2224}
                  sizes="(max-width: 1100px) 100vw, 48vw"
                />
                <figcaption>
                  Copy toast confirms clipboard action
                </figcaption>
              </figure>
            </div>
          </section>

          <section className={styles.section} id="controls">
            <div className={styles.sectionIntro}>
              <div className={styles.kicker}>App Controls</div>
              <h2 className={styles.sectionTitle}>
                One companion app for themes, typography, width, copy behavior,
                markdown defaults, and file type management.
              </h2>
              <p className={styles.sectionBody}>
                The companion app puts themes, layout, copy behavior, and file
                type management in one place.
              </p>
            </div>

            <div className={styles.controlGrid}>
              <figure className={styles.controlCard}>
                <Image
                  src="/product/settings-theme.jpeg"
                  alt="dotViewer theme selection settings"
                  width={2024}
                  height={1528}
                  sizes="(max-width: 1100px) 100vw, 31vw"
                />
                <figcaption>
                  System-following and fixed dark themes
                </figcaption>
              </figure>

              <figure className={styles.controlCard}>
                <Image
                  src="/product/settings-appearance.jpeg"
                  alt="dotViewer appearance and preview layout settings"
                  width={2024}
                  height={1528}
                  sizes="(max-width: 1100px) 100vw, 31vw"
                />
                <figcaption>
                  Font size, line numbers, width, and layout
                </figcaption>
              </figure>

              <figure className={styles.controlCard}>
                <Image
                  src="/product/settings-copy.jpeg"
                  alt="dotViewer copy behavior and preview UI settings"
                  width={2024}
                  height={1528}
                  sizes="(max-width: 1100px) 100vw, 31vw"
                />
                <figcaption>
                  Copy behavior, find-in-preview, and more
                </figcaption>
              </figure>
            </div>

            <div className={styles.appGrid}>
              <figure className={styles.appCard}>
                <Image
                  src="/product/file-types.jpeg"
                  alt="dotViewer file type registry screen"
                  width={2024}
                  height={1528}
                  sizes="(max-width: 1100px) 100vw, 46vw"
                />
                <figcaption>
                  Browse and override {stats.fileTypes} shipped file types
                </figcaption>
              </figure>

              <figure className={styles.appCard}>
                <Image
                  src="/product/status.jpeg"
                  alt="dotViewer status screen showing extension enabled and quick stats"
                  width={2024}
                  height={1528}
                  sizes="(max-width: 1100px) 100vw, 46vw"
                />
                <figcaption>
                  Extension status and mapping counts
                </figcaption>
              </figure>
            </div>
          </section>

          <section className={styles.section} id="coverage">
            <div className={styles.limitationsPanel}>
              <div className={styles.limitationsCopy}>
                <div className={styles.kicker}>Coverage and limits</div>
                <h2 className={styles.sectionTitle}>
                  Broad enough to replace several niche preview tools, honest
                  enough to say where macOS still wins.
                </h2>
                <p className={styles.sectionBody}>
                  Where macOS owns the preview path, the limitation is stated
                  directly.
                </p>
              </div>

              <ul className={styles.limitationsList}>
                {limitations.map((item) => (
                  <li key={item.id}>{item.content}</li>
                ))}
              </ul>
            </div>

            <section className={styles.statsStrip} aria-label="Coverage summary">
              {proofStats.map((item) => (
                <article className={styles.statItem} key={item.label}>
                  <AnimatedStat value={item.value} className={styles.statValue} />
                  <div className={styles.statLabel}>{item.label}</div>
                </article>
              ))}
            </section>

            <div className={styles.mappingPanel}>
              <div className={styles.sectionIntro}>
                <div className={styles.kicker}>Custom mappings</div>
                <h2 className={styles.sectionTitle}>
                  Be explicit about what users can map themselves.
                </h2>
                <p className={styles.sectionBody}>
                  Custom mappings work for file types the extension already
                  routes. dotViewer cannot teach macOS Quick Look brand-new file
                  types at runtime. Everything in the accordion below is already
                  shipped.
                </p>
              </div>

              <div className={styles.mappingCallout}>
                <p>
                  Currently shipped coverage: <strong>{stats.fileTypes}</strong>{" "}
                  file types, <strong>{stats.extensions}</strong> extensions,
                  and <strong>{stats.filenameMappings}</strong> exact filename
                  mappings.
                </p>
                <p>
                  If you need something outside that list, please open a GitHub
                  issue so it can be added to a future release.
                </p>
                <div className={styles.mappingActions}>
                  <a className={styles.primaryAction} href={issueRequestHref}>
                    Request file type support
                  </a>
                  <a className={styles.secondaryAction} href={issuesHref}>
                    View support issues
                  </a>
                </div>
              </div>

              <details className={styles.supportAccordion}>
                <summary>
                  Everything dotViewer already ships today
                  <span>
                    {stats.fileTypes} file types • {stats.extensions} extensions
                    • {stats.filenameMappings} filenames • {routingCaveatCount}{" "}
                    macOS routing caveat
                    {routingCaveatCount === 1 ? "" : "s"} called out inline
                  </span>
                </summary>
                <div className={styles.supportList}>
                  {supportedFileTypes.map((type) => (
                    <article className={styles.supportItem} key={type.id}>
                      <div className={styles.supportItemHeader}>
                        <h3>{type.displayName}</h3>
                        <p>
                          {type.extensions.length} extension
                          {type.extensions.length === 1 ? "" : "s"}
                          {type.filenames.length > 0
                            ? ` • ${type.filenames.length} exact filename${
                                type.filenames.length === 1 ? "" : "s"
                              }`
                            : ""}
                        </p>
                      </div>

                      {type.extensions.length > 0 ? (
                        <div className={styles.tokenGroup}>
                          {type.extensions.map((extension) => (
                            <code key={`${type.displayName}-ext-${extension}`}>
                              .{extension}
                            </code>
                          ))}
                        </div>
                      ) : null}

                      {type.filenames.length > 0 ? (
                        <div className={styles.tokenGroup}>
                          {type.filenames.map((filename) => (
                            <code key={`${type.displayName}-file-${filename}`}>
                              {filename}
                            </code>
                          ))}
                        </div>
                      ) : null}

                      {type.routingLimitations.length > 0 ? (
                        <div className={styles.supportCaveats}>
                          {type.routingLimitations.map((limitation) => (
                            <div
                              className={styles.supportCaveat}
                              key={`${type.id}-${limitation.id}`}
                            >
                              <div className={styles.supportCaveatHeader}>
                                <strong>{limitation.title}</strong>
                                <div className={styles.supportCaveatTokens}>
                                  {limitation.matchedExtensions.map(
                                    (extension) => (
                                      <code
                                        key={`${type.id}-${limitation.id}-${extension}`}
                                      >
                                        .{extension}
                                      </code>
                                    ),
                                  )}
                                </div>
                              </div>
                              <p>{limitation.summary}</p>
                            </div>
                          ))}
                        </div>
                      ) : null}
                    </article>
                  ))}
                </div>
              </details>
            </div>
          </section>

          <section className={styles.section} id="install">
            <div className={styles.sectionIntro}>
              <div className={styles.kicker}>Install</div>
              <h2 className={styles.sectionTitle}>
                A normal Mac install flow, kept intentionally short.
              </h2>
              <p className={styles.sectionBody}>
                Download, drag to Applications, launch once. Also available on
                the App Store.
              </p>
            </div>

            <div className={styles.installGrid}>
              {installSteps.map((item) => (
                <article className={styles.installCard} key={item.step}>
                  <div className={styles.installStep}>{item.step}</div>
                  <h3 className={styles.installTitle}>{item.title}</h3>
                  <p className={styles.installBody}>{item.body}</p>
                </article>
              ))}
            </div>

          </section>

          <section className={styles.section} id="faq">
            <div className={styles.sectionIntro}>
              <div className={styles.kicker}>FAQ</div>
              <h2 className={styles.sectionTitle}>
                Short answers before installation.
              </h2>
            </div>

            <div className={styles.faqShell}>
              <div className={styles.faqList}>
                {faqs.map((item) => (
                  <details className={styles.faqItem} key={item.id}>
                    <summary>{item.question}</summary>
                    <div className={styles.faqContent}>{item.answer}</div>
                  </details>
                ))}
              </div>

              <div className={styles.ctaPanel}>
                <h2 className={styles.ctaTitle}>
                  A better Finder Quick Look workflow for technical files on
                  macOS.
                </h2>
                <p className={styles.ctaBody}>
                  Inspect the file, understand what it is, and keep moving.
                </p>
                <div className={styles.ctaActions}>
                  <Link className={styles.primaryAction} href="/download">
                    Get the free DMG
                  </Link>
                  {appStoreHref ? (
                    <TrackedDownloadLink
                      assetKind="app_store"
                      className={styles.secondaryAction}
                      releaseTag={null}
                      source="home_page_bottom_cta_app_store"
                      targetUrl={appStoreHref}
                    >
                      Buy on App Store
                    </TrackedDownloadLink>
                  ) : (
                    <a className={styles.secondaryAction} href={releasesHref}>
                      View releases
                    </a>
                  )}
                </div>
              </div>
            </div>
          </section>
        </div>
      </main>

      <footer className={styles.footer}>
        <div className={styles.shell}>
          <div className={styles.footerBar}>
            <div className={styles.footerCopy}>
              <strong>dotViewer</strong>
              <br />
              Better Quick Look for dotfiles, config files, markdown, logs,
              plain text, and code on macOS.
              <br />
              Created by <a href={CREATOR_URL}>{CREATOR_NAME}</a>. Also from the
              same creator: <a href={DBHOST_URL}>dbHost</a> for free PostgreSQL
              database management.
            </div>

            <div className={styles.footerLinks}>
              <a href="#previews">Previews</a>
              <a href="#controls">Controls</a>
              <a href="#coverage">Coverage</a>
              <a href="#install">Install</a>
              <a href="#faq">FAQ</a>
              <Link href="/download">Download</Link>
              {appStoreHref ? <a href={appStoreHref}>App Store</a> : null}
              <a href={releasesHref}>Releases</a>
              <a href={repoHref}>GitHub</a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
