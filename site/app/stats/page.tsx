import type { Metadata } from "next";
import { headers } from "next/headers";
import { notFound } from "next/navigation";
import { basicCredentialsMatch } from "../../lib/stats/auth";
import { loadStats, type StatsReport } from "../../lib/stats/queries";
import type { Ranked } from "../../lib/stats/report";
import styles from "./page.module.css";

// Private numbers for the owner, behind Basic Auth (proxy.ts). Read on every request. The page
// checks the credentials again, so a future change to the proxy's matcher cannot expose it.

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  robots: { follow: false, index: false },
  title: "Stats",
};

const numbers = new Intl.NumberFormat("en-US", { maximumFractionDigits: 1 });
const show = (value: number | null | undefined) => (value === null || value === undefined ? "—" : numbers.format(value));
const percent = (share: number | null) => (share === null ? "—" : `${Math.round(share * 100)}%`);

function ago(date: Date | null, now: Date): string {
  if (!date) return "never";
  const minutes = Math.round((now.getTime() - date.getTime()) / 60_000);
  if (minutes < 60) return `${minutes} min ago`;
  const hours = Math.round(minutes / 60);
  if (hours < 48) return `${hours} h ago`;
  return `${Math.round(hours / 24)} days ago`;
}

function Freshness({ now, report }: { now: Date; report: StatsReport }) {
  const { lastDownloadLog, lastPageView, lastSnapshot } = report.freshness;
  const snapshotAge = lastSnapshot ? (now.getTime() - new Date(`${lastSnapshot}T00:00:00Z`).getTime()) / 86_400_000 : null;
  const items = [
    {
      label: "Daily snapshot",
      stale: snapshotAge === null || snapshotAge > 2,
      value: lastSnapshot ?? "none yet",
    },
    {
      label: "Last download logged",
      stale: !lastDownloadLog || now.getTime() - lastDownloadLog.getTime() > 3 * 86_400_000,
      value: ago(lastDownloadLog, now),
    },
    {
      label: "Last page view",
      stale: !lastPageView || now.getTime() - lastPageView.getTime() > 3 * 86_400_000,
      value: ago(lastPageView, now),
    },
  ];

  return (
    <ul className={styles.freshness}>
      {items.map((item) => (
        <li className={item.stale ? styles.stale : undefined} key={item.label}>
          <span>{item.label}</span> {item.value}
        </li>
      ))}
    </ul>
  );
}

function WeeklyBars({ weeks }: { weeks: { downloads: number | null; week: string }[] }) {
  const bars = weeks.filter((week): week is { downloads: number; week: string } => week.downloads !== null).slice(-26);
  if (bars.length === 0) {
    return <p className={styles.empty}>Weekly numbers start one week after the first daily snapshot.</p>;
  }

  const height = 160;
  const width = 640;
  const gap = 6;
  const max = Math.max(...bars.map((bar) => bar.downloads), 1);
  const barWidth = (width - gap * (bars.length - 1)) / bars.length;

  return (
    <svg aria-label="Downloads per week" className={styles.chart} role="img" viewBox={`0 0 ${width} ${height + 22}`}>
      {bars.map((bar, index) => {
        const barHeight = Math.max(2, (bar.downloads / max) * height);
        const x = index * (barWidth + gap);
        return (
          <g key={bar.week}>
            <title>{`Week of ${bar.week}: ${bar.downloads} downloads`}</title>
            <rect className={styles.bar} height={barHeight} rx={3} width={barWidth} x={x} y={height - barHeight} />
            {index % Math.ceil(bars.length / 8) === 0 ? (
              <text className={styles.axis} x={x} y={height + 16}>
                {bar.week.slice(5)}
              </text>
            ) : null}
          </g>
        );
      })}
    </svg>
  );
}

function DailyBars({ days }: { days: { day: string; visitors: number }[] }) {
  if (days.every((day) => day.visitors === 0)) {
    return <p className={styles.empty}>No visitors counted yet; day codes started with the consent update.</p>;
  }

  const height = 120;
  const width = 640;
  const gap = 3;
  const max = Math.max(...days.map((day) => day.visitors), 1);
  const barWidth = (width - gap * (days.length - 1)) / days.length;

  return (
    <svg aria-label="Visitors per day" className={styles.chart} role="img" viewBox={`0 0 ${width} ${height + 22}`}>
      {days.map((day, index) => {
        const barHeight = day.visitors > 0 ? Math.max(2, (day.visitors / max) * height) : 0;
        const x = index * (barWidth + gap);
        return (
          <g key={day.day}>
            <title>{`${day.day}: ${day.visitors} visitors`}</title>
            <rect className={styles.bar} height={barHeight} rx={2} width={barWidth} x={x} y={height - barHeight} />
            {index % 7 === 0 ? (
              <text className={styles.axis} x={x} y={height + 16}>
                {day.day.slice(5)}
              </text>
            ) : null}
          </g>
        );
      })}
    </svg>
  );
}

function RankedList({ empty, items, title }: { empty: string; items: Ranked[]; title: string }) {
  return (
    <div className={styles.ranked}>
      <h3>{title}</h3>
      {items.length === 0 ? (
        <p className={styles.empty}>{empty}</p>
      ) : (
        <ol>
          {items.map((item) => (
            <li key={item.key}>
              <span>{item.key}</span>
              <strong>{show(item.count)}</strong>
            </li>
          ))}
        </ol>
      )}
    </div>
  );
}

async function requireOwner() {
  const user = process.env.STATS_USER;
  const password = process.env.STATS_PASSWORD;
  const authorization = (await headers()).get("authorization");
  if (!user || !password || !basicCredentialsMatch(authorization, user, password)) {
    notFound();
  }
}

export default async function StatsPage() {
  await requireOwner();
  const now = new Date();
  const report = await loadStats(now);
  const { downloads } = report;
  const homebrew = new Map(report.homebrew.map((row) => [row.periodDays, row.installs]));
  const recentWeeks = report.pageViews.weekly.slice(-8).reverse();
  const { consent, conversion, daily, firstVisitDownloads, returning } = report.visitors;
  const lastWeek = daily.slice(-7);
  const weekAverage = lastWeek.length > 0 ? lastWeek.reduce((sum, day) => sum + day.visitors, 0) / lastWeek.length : null;
  const consentedWeeks = returning.filter((week) => week.newVisitors + week.returning > 0).reverse();

  return (
    <main className={styles.page}>
      <div className={styles.wrap}>
        <header className={styles.header}>
          <div>
            <p className={styles.label}>dotViewer · private</p>
            <h1>Downloads and visitors</h1>
          </div>
          <Freshness now={now} report={report} />
        </header>

        {report.warnings.length > 0 ? (
          <ul className={styles.warnings}>
            {report.warnings.map((warning) => (
              <li key={warning}>{warning}</li>
            ))}
          </ul>
        ) : null}

        <section className={styles.cards}>
          <article>
            <span>Downloads · 7 days</span>
            <strong>{show(downloads.last7)}</strong>
          </article>
          <article>
            <span>Downloads · 30 days</span>
            <strong>{show(downloads.last30)}</strong>
          </article>
          <article>
            <span>Downloads · all time</span>
            <strong>{show(downloads.allTime)}</strong>
            <small>{downloads.from === "live" ? "live from GitHub" : "GitHub DMG, every channel"}</small>
          </article>
          <article>
            <span>Homebrew installs · 30 / 90 / 365 days</span>
            <strong>
              {show(homebrew.get(30))} / {show(homebrew.get(90))} / {show(homebrew.get(365))}
            </strong>
            <small>Homebrew&apos;s public analytics; upgrades are not counted</small>
          </article>
        </section>

        <section className={styles.panel}>
          <h2>Downloads per week</h2>
          <p className={styles.note}>
            Growth of GitHub&apos;s DMG download count between the last snapshots of consecutive weeks. It counts
            downloads, not people: Homebrew installs and upgrades, the website, the release page and bots all end up
            here.
          </p>
          <WeeklyBars weeks={downloads.weekly} />
        </section>

        <section className={styles.panel}>
          <h2>By version</h2>
          <p className={styles.note}>
            GitHub&apos;s total beside the site&apos;s own log. Site columns count clicks on the download redirect,
            split by who clicked; your own deployment URLs are left out.
          </p>
          <div className={styles.tableScroll}>
            <table className={styles.table}>
              <thead>
                <tr>
                  <th>Version</th>
                  <th>GitHub DMG</th>
                  <th>Site · Mac</th>
                  <th>Site · phone</th>
                  <th>Site · other</th>
                  <th>Site · bots</th>
                  <th>Sparkle</th>
                  <th>Homebrew</th>
                </tr>
              </thead>
              <tbody>
                {report.versions.map((row) => (
                  <tr key={row.tag}>
                    <td>{row.tag}</td>
                    <td>{show(row.github)}</td>
                    <td>{show(row.mac)}</td>
                    <td>{show(row.phone)}</td>
                    <td>{show(row.other)}</td>
                    <td>{show(row.bot)}</td>
                    <td>{show(row.sparkle)}</td>
                    <td>{show(row.homebrew)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>

        <section className={styles.panel}>
          <h2>Visitors</h2>
          <p className={styles.note}>
            Everyone is counted once a day by a code that can&apos;t be linked across days. Returning visitors and
            downloads after an earlier visit come only from people who allowed dotViewer statistics.
          </p>
          <div className={`${styles.cards} ${styles.panelCards}`}>
            <article>
              <span>Visitors today</span>
              <strong>{show(daily.at(-1)?.visitors)}</strong>
              <small>UTC day so far</small>
            </article>
            <article>
              <span>Visitors · 7-day average</span>
              <strong>{show(weekAverage)}</strong>
            </article>
            <article>
              <span>Visited and downloaded · 30 days</span>
              <strong>{percent(conversion.rate)}</strong>
              <small>
                {show(conversion.downloaders)} of {show(conversion.visitors)} visitor-days
              </small>
            </article>
            <article>
              <span>Consent · 30 days</span>
              <strong>
                {percent(consent.statistics)} / {percent(consent.google)}
              </strong>
              <small>allowed dotViewer statistics / Google Analytics, of {show(consent.choices)} choices</small>
            </article>
          </div>
          <DailyBars days={daily} />
          <div className={`${styles.columns} ${styles.afterChart}`}>
            <div className={styles.ranked}>
              <h3>Sources · visitor-days → downloaded · 30 days</h3>
              {conversion.sources.length === 0 ? (
                <p className={styles.empty}>No visitors counted yet.</p>
              ) : (
                <ol>
                  {conversion.sources.map((source) => (
                    <li key={source.key}>
                      <span>{source.key}</span>
                      <strong>
                        {show(source.visitors)} <em>→ {show(source.downloaders)}</em>
                      </strong>
                    </li>
                  ))}
                </ol>
              )}
            </div>
            <div className={styles.ranked}>
              <h3>Returning visitors per week</h3>
              {consentedWeeks.length === 0 ? (
                <p className={styles.empty}>Nobody has allowed dotViewer statistics yet.</p>
              ) : (
                <ol>
                  {consentedWeeks.map((week) => (
                    <li key={week.week}>
                      <span>{week.week}</span>
                      <strong>
                        {show(week.newVisitors)} new <em>+ {show(week.returning)} returning</em>
                      </strong>
                    </li>
                  ))}
                </ol>
              )}
            </div>
            <div className={styles.ranked}>
              <h3>Downloads by visit</h3>
              <ol>
                <li>
                  <span>On a first visit</span>
                  <strong>{show(firstVisitDownloads.firstVisit)}</strong>
                </li>
                <li>
                  <span>After an earlier visit</span>
                  <strong>{show(firstVisitDownloads.laterVisit)}</strong>
                </li>
              </ol>
            </div>
          </div>
        </section>

        <section className={styles.panel}>
          <h2>Website</h2>
          <p className={styles.note}>First-party log, last 120 days. Visitors are counted in the section above.</p>
          <div className={styles.columns}>
            <div className={styles.ranked}>
              <h3>Page views per week</h3>
              {recentWeeks.length === 0 ? (
                <p className={styles.empty}>No page views logged.</p>
              ) : (
                <ol>
                  {recentWeeks.map((week) => (
                    <li key={week.week}>
                      <span>{week.week}</span>
                      <strong>
                        {show(week.people)} <em>+ {show(week.bots)} bots</em>
                      </strong>
                    </li>
                  ))}
                </ol>
              )}
            </div>
            <RankedList empty="No page views in 30 days." items={report.pageViews.paths} title="Top pages · 30 days" />
            <RankedList empty="No referrers in 30 days." items={report.pageViews.referrers} title="Referrers · 30 days" />
            <RankedList empty="No countries in 30 days." items={report.pageViews.countries} title="Countries · 30 days" />
          </div>
        </section>
      </div>
    </main>
  );
}
