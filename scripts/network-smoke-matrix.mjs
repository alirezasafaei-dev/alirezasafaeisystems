#!/usr/bin/env node
/* eslint-disable no-console */

import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium, firefox } from "playwright";

const TARGETS = [
  "https://persiantoolbox.ir/",
  "https://alirezasafaeisystems.ir/",
  "https://audit.alirezasafaeisystems.ir/",
];
const SUPPORTED_BROWSERS = new Set(["chromium", "firefox"]);

const CSP_PATTERN = /content security policy|csp|refused to|blocked/i;

function timestampId() {
  return new Date().toISOString().replaceAll(":", "-").replace(/\..+$/, "Z");
}

function getProxyCandidates() {
  const keys = [
    "HTTPS_PROXY",
    "HTTP_PROXY",
    "ALL_PROXY",
    "https_proxy",
    "http_proxy",
    "all_proxy",
  ];
  const out = [];
  for (const key of keys) {
    const value = process.env[key]?.trim();
    if (!value) continue;
    out.push({ key, value });
  }
  return out;
}

function normalizeProxy(serverRaw) {
  try {
    const u = new URL(serverRaw);
    const proxy = {
      server: `${u.protocol}//${u.hostname}:${u.port || (u.protocol === "https:" ? "443" : "80")}`,
    };
    if (u.username) proxy.username = decodeURIComponent(u.username);
    if (u.password) proxy.password = decodeURIComponent(u.password);
    return proxy;
  } catch {
    return null;
  }
}

function getEnabledBrowsers() {
  const raw = process.env.NETWORK_SMOKE_BROWSERS?.trim();
  if (!raw) return ["chromium", "firefox"];

  const items = raw
    .split(",")
    .map((item) => item.trim().toLowerCase())
    .filter((item) => SUPPORTED_BROWSERS.has(item));
  if (items.length === 0) return ["chromium"];

  return [...new Set(items)];
}

function shouldIncludeProxyScenarios() {
  const flag = process.env.NETWORK_SMOKE_INCLUDE_PROXY?.trim().toLowerCase();
  return flag === "1" || flag === "true" || flag === "yes";
}

function createScenarios(enabledBrowsers) {
  const scenarios = [];
  for (const browser of enabledBrowsers) {
    scenarios.push({ id: `direct-${browser}`, browser, proxy: null });
  }

  if (!shouldIncludeProxyScenarios()) return scenarios;

  const seen = new Set();
  for (const item of getProxyCandidates()) {
    const proxy = normalizeProxy(item.value);
    if (!proxy) continue;
    const key = proxy.server;
    if (seen.has(key)) continue;
    seen.add(key);
    const suffix = key.replace(/[^a-zA-Z0-9]+/g, "-").replace(/^-+|-+$/g, "");
    for (const browser of enabledBrowsers) {
      scenarios.push({
        id: `proxy-${browser}-${suffix}`,
        browser,
        proxy,
        source: item.key,
      });
    }
  }
  return scenarios;
}

async function fileExists(p) {
  try {
    await fs.access(p);
    return true;
  } catch {
    return false;
  }
}

function summarizeFailure(failures) {
  if (failures.length === 0) return "none";
  return failures.slice(0, 3).join(" | ");
}

async function runScenario(scenario, outDir) {
  const scenarioOutDir = path.join(outDir, scenario.id);
  await fs.mkdir(scenarioOutDir, { recursive: true });

  const engine = scenario.browser === "firefox" ? firefox : chromium;
  const launchOptions = { headless: true };
  if (scenario.browser === "chromium" && (await fileExists("/usr/bin/google-chrome"))) {
    launchOptions.executablePath = "/usr/bin/google-chrome";
    launchOptions.args = ["--disable-dev-shm-usage"];
  }
  if (scenario.proxy) launchOptions.proxy = scenario.proxy;

  let browser;
  try {
    browser = await engine.launch(launchOptions);
  } catch (err) {
    return {
      scenario: scenario.id,
      browser: scenario.browser,
      proxy: scenario.proxy?.server ?? null,
      target: null,
      ok: false,
      launchError: String(err?.message || err),
    };
  }

  const results = [];

  for (const target of TARGETS) {
    const safeTarget = target.replace(/^https?:\/\//, "").replace(/[^\w.-]+/g, "_");
    const harPath = path.join(scenarioOutDir, `${safeTarget}.har`);
    const screenshotPath = path.join(scenarioOutDir, `${safeTarget}.png`);
    const context = await browser.newContext({
      locale: "fa-IR",
      recordHar: { path: harPath },
    });
    const page = await context.newPage();

    const cspViolations = [];
    const pageErrors = [];
    const requestFailed = [];
    const responseErrors = [];

    page.on("console", (msg) => {
      const text = msg.text();
      if (CSP_PATTERN.test(text)) cspViolations.push(text);
    });
    page.on("pageerror", (err) => pageErrors.push(err.message));
    page.on("requestfailed", (req) => {
      const info = `${req.resourceType()} ${req.url()} :: ${req.failure()?.errorText || "unknown"}`;
      requestFailed.push(info);
    });
    page.on("response", (res) => {
      if (res.status() >= 400) responseErrors.push(`${res.status()} ${res.url()}`);
    });

    let status = null;
    let gotoError = null;
    try {
      const res = await page.goto(target, { waitUntil: "domcontentloaded", timeout: 60000 });
      status = res?.status() ?? null;
    } catch (err) {
      gotoError = String(err?.message || err);
    }

    const readBodySnapshot = async () =>
      page
        .evaluate(() => ({
          textLength: document?.body?.innerText?.trim()?.length || 0,
          htmlLength: document?.body?.innerHTML?.trim()?.length || 0,
        }))
        .catch(() => ({ textLength: 0, htmlLength: 0 }));

    const bodyLens = {};
    const htmlLens = {};

    const snap0 = await readBodySnapshot();
    bodyLens.t0 = snap0.textLength;
    htmlLens.t0 = snap0.htmlLength;

    await page.waitForTimeout(1000);
    const snap1 = await readBodySnapshot();
    bodyLens.t1s = snap1.textLength;
    htmlLens.t1s = snap1.htmlLength;

    await page.waitForTimeout(4000);
    const snap5 = await readBodySnapshot();
    bodyLens.t5s = snap5.textLength;
    htmlLens.t5s = snap5.htmlLength;

    const title = await page.title().catch(() => "");
    await page.screenshot({ path: screenshotPath, fullPage: true }).catch(() => {});
    await context.close();

    const hardFailures = [];
    if (status !== 200) hardFailures.push(`http:${status ?? "n/a"}`);
    if (gotoError) hardFailures.push("goto-timeout-or-failure");
    if (bodyLens.t1s < 120) hardFailures.push(`low-body:${bodyLens.t1s}`);
    if (bodyLens.t0 > 120 && bodyLens.t5s === 0 && htmlLens.t5s < 200) {
      hardFailures.push("white-screen-after-load");
    }
    if (cspViolations.length > 0) hardFailures.push(`csp:${cspViolations.length}`);
    if (pageErrors.length > 0) hardFailures.push(`pageerror:${pageErrors.length}`);

    results.push({
      scenario: scenario.id,
      browser: scenario.browser,
      proxy: scenario.proxy?.server ?? null,
      proxySource: scenario.source ?? null,
      target,
      status,
      title,
      bodyLens,
      htmlLens,
      gotoError,
      cspViolations: cspViolations.slice(0, 20),
      pageErrors: pageErrors.slice(0, 20),
      requestFailed: requestFailed.slice(0, 20),
      responseErrors: responseErrors.slice(0, 20),
      ok: hardFailures.length === 0,
      failureSummary: summarizeFailure(hardFailures),
      artifacts: {
        screenshotPath,
        harPath,
      },
    });
  }

  await browser.close();
  return results;
}

function rowForMarkdown(item) {
  const proxy = item.proxy ? "yes" : "no";
  const status = item.status ?? "n/a";
  const body = `${item.bodyLens.t0}/${item.bodyLens.t1s}/${item.bodyLens.t5s}`;
  const csp = item.cspViolations.length;
  const pe = item.pageErrors.length;
  return `| ${item.scenario} | ${item.target} | ${status} | ${body} | ${csp} | ${pe} | ${proxy} | ${item.ok ? "PASS" : "FAIL"} | ${item.failureSummary} |`;
}

async function main() {
  const runId = timestampId();
  const root = process.cwd();
  const outDir = path.join(root, "reports", "network-smoke", runId);
  await fs.mkdir(outDir, { recursive: true });

  const enabledBrowsers = getEnabledBrowsers();
  const scenarios = createScenarios(enabledBrowsers);
  const allResults = [];
  for (const scenario of scenarios) {
    const scenarioResult = await runScenario(scenario, outDir);
    if (Array.isArray(scenarioResult)) allResults.push(...scenarioResult);
    else allResults.push(scenarioResult);
  }

  const resultJsonPath = path.join(outDir, "result.json");
  await fs.writeFile(resultJsonPath, JSON.stringify({ runId, scenarios, allResults }, null, 2), "utf8");

  const lines = [];
  lines.push(`# Network Smoke Matrix (${runId})`);
  lines.push("");
  lines.push(`Scenarios: ${scenarios.length}`);
  lines.push(`Targets per scenario: ${TARGETS.length}`);
  lines.push("");
  lines.push("| Scenario | Target | HTTP | BodyLen t0/t1s/t5s | CSP | PageErr | Proxy | Result | Failure |");
  lines.push("|---|---|---:|---:|---:|---:|---|---|---|");
  for (const item of allResults.filter((r) => r.target)) {
    lines.push(rowForMarkdown(item));
  }

  const fails = allResults.filter((r) => r.target && !r.ok).length;
  lines.push("");
  lines.push(`Total checks: ${allResults.filter((r) => r.target).length}`);
  lines.push(`Failed checks: ${fails}`);
  lines.push(`JSON: ${resultJsonPath}`);

  const reportMdPath = path.join(outDir, "report.md");
  await fs.writeFile(reportMdPath, lines.join("\n"), "utf8");

  console.log(`REPORT_DIR=${outDir}`);
  console.log(`REPORT_MD=${reportMdPath}`);
  console.log(`REPORT_JSON=${resultJsonPath}`);
  console.log(`TOTAL=${allResults.filter((r) => r.target).length} FAIL=${fails}`);

  if (fails > 0) process.exitCode = 1;
}

main().catch(async (err) => {
  const scriptPath = fileURLToPath(import.meta.url);
  const errPath = path.join(path.dirname(scriptPath), "..", "reports", `network-smoke-error-${timestampId()}.log`);
  await fs.mkdir(path.dirname(errPath), { recursive: true });
  await fs.writeFile(errPath, String(err?.stack || err), "utf8");
  console.error(String(err?.stack || err));
  process.exit(1);
});
