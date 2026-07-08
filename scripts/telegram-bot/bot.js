import TelegramBot from "node-telegram-bot-api";
import { execSync } from "child_process";

const TOKEN = process.env.TELEGRAM_BOT_TOKEN;
const ASDEV_SYSTEMS_REPO = process.env.ASDEV_SYSTEMS_REPO || "alirezasafaei-dev/alirezasafaeisystems";
const AUDITSYSTEMS_REPO = process.env.AUDITSYSTEMS_REPO || "alirezasafaei-dev/auditsystems";
const COMMAND_CENTER_ISSUE = process.env.COMMAND_CENTER_ISSUE || "45";

if (!TOKEN) {
  console.error("TELEGRAM_BOT_TOKEN is required");
  process.exit(1);
}

const bot = new TelegramBot(TOKEN, { polling: true });

function gh(endpoint) {
  try {
    const cmd = `gh api -H "Accept: application/vnd.github+json" ${endpoint}`;
    return execSync(cmd, { encoding: "utf-8", timeout: 15000 }).trim();
  } catch (err) {
    return null;
  }
}

function ghRepo(repo, endpoint) {
  return gh(`repos/${repo}/${endpoint}`);
}

function systemctlStatus(service) {
  try {
    return execSync(`systemctl is-active ${service}`, { encoding: "utf-8", timeout: 5000 }).trim();
  } catch {
    return "inactive";
  }
}

function formatPR(pr) {
  const labels = pr.labels?.map((l) => `[${l.name}]`).join(" ") || "";
  return `#${pr.number} ${pr.title}\n  ${labels || "no labels"}\n  ${pr.user?.login || "unknown"} • ${new Date(pr.updated_at).toLocaleDateString()}`;
}

function isBlocker(pr) {
  const blocked = ["blocked", "blocker", "priority: high", "failing", "deploy", "schema", "billing", "migration", "approval"];
  const labels = (pr.labels || []).map((l) => l.name.toLowerCase());
  const title = (pr.title || "").toLowerCase();
  const body = (pr.body || "").toLowerCase();
  return blocked.some((b) => labels.includes(b) || title.includes(b) || body.includes(b));
}

bot.onText(/\/start/, (msg) => {
  bot.sendMessage(msg.chat.id, [
    "ASDEV Status Bot",
    "",
    "/status - Full status report",
    "/prs - List open PRs",
    "/blockers - Show blockers",
    "/last - Last Issue #45 comment",
  ].join("\n"));
});

bot.onText(/\/status/, async (msg) => {
  const chatId = msg.chat.id;
  bot.sendMessage(chatId, "Fetching status...");
  const sections = [];

  try {
    const issue = JSON.parse(ghRepo(ASDEV_SYSTEMS_REPO, `issues/${COMMAND_CENTER_ISSUE}`) || "{}");
    if (issue.title) {
      sections.push(`📋 Issue #${COMMAND_CENTER_ISSUE}: ${issue.title}`);
      sections.push(`  State: ${issue.state}`);
    }
  } catch { sections.push("📋 Issue #45: unavailable"); }

  try {
    const asdevPRs = JSON.parse(ghRepo(ASDEV_SYSTEMS_REPO, "pulls?state=open") || "[]");
    sections.push(`🔀 alirezasafaeisystems: ${asdevPRs.length} open`);
  } catch { sections.push("🔀 alirezasafaeisystems: unavailable"); }

  try {
    const auditPRs = JSON.parse(ghRepo(AUDITSYSTEMS_REPO, "pulls?state=open") || "[]");
    sections.push(`🔀 auditsystems: ${auditPRs.length} open`);
  } catch { sections.push("🔀 auditsystems: unavailable"); }

  try {
    const timerStatus = systemctlStatus("asdev-agent-loop.timer");
    sections.push(`⏱️ Timer: ${timerStatus}`);
  } catch { sections.push("⏱️ Timer: unknown"); }

  try {
    const botStatus = systemctlStatus("asdev-bot.service");
    sections.push(`🤖 Bot: ${botStatus}`);
  } catch { sections.push("🤖 Bot: unknown"); }

  bot.sendMessage(chatId, ["📊 ASDEV Status Report", "", ...sections].join("\n"));
});

bot.onText(/\/prs/, async (msg) => {
  const chatId = msg.chat.id;
  bot.sendMessage(chatId, "Fetching PRs...");
  const lines = ["🔀 Open Pull Requests", ""];

  try {
    const asdevPRs = JSON.parse(ghRepo(ASDEV_SYSTEMS_REPO, "pulls?state=open") || "[]");
    lines.push(`${ASDEV_SYSTEMS_REPO} (${asdevPRs.length}):`);
    lines.push(...asdevPRs.map((pr) => formatPR(pr)));
  } catch { lines.push(`${ASDEV_SYSTEMS_REPO}: unavailable`); }

  lines.push("");

  try {
    const auditPRs = JSON.parse(ghRepo(AUDITSYSTEMS_REPO, "pulls?state=open") || "[]");
    lines.push(`${AUDITSYSTEMS_REPO} (${auditPRs.length}):`);
    lines.push(...auditPRs.map((pr) => formatPR(pr)));
  } catch { lines.push(`${AUDITSYSTEMS_REPO}: unavailable`); }

  if (lines.length === 2) lines.push("No open PRs.");
  bot.sendMessage(chatId, lines.join("\n"));
});

bot.onText(/\/blockers/, async (msg) => {
  const chatId = msg.chat.id;
  bot.sendMessage(chatId, "Fetching blockers...");
  const blocked = [];

  try {
    const asdevPRs = JSON.parse(ghRepo(ASDEV_SYSTEMS_REPO, "pulls?state=open") || "[]");
    blocked.push(...asdevPRs.filter(isBlocker));
  } catch {}

  try {
    const auditPRs = JSON.parse(ghRepo(AUDITSYSTEMS_REPO, "pulls?state=open") || "[]");
    blocked.push(...auditPRs.filter(isBlocker));
  } catch {}

  if (blocked.length === 0) {
    bot.sendMessage(chatId, "No active blockers found.");
  } else {
    bot.sendMessage(chatId, ["🚨 Blocked / High Priority PRs", "", ...blocked.map((pr) => formatPR(pr))].join("\n"));
  }
});

bot.onText(/\/last/, async (msg) => {
  const chatId = msg.chat.id;
  bot.sendMessage(chatId, "Fetching Issue #45...");

  try {
    const commentsRaw = ghRepo(ASDEV_SYSTEMS_REPO, `issues/${COMMAND_CENTER_ISSUE}/comments?per_page=100`);
    if (!commentsRaw) {
      bot.sendMessage(chatId, "Could not fetch comments.");
      return;
    }
    const comments = JSON.parse(commentsRaw);
    if (!comments.length) {
      bot.sendMessage(chatId, "No comments on Issue #45");
      return;
    }
    const sorted = comments.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    const latest = sorted[0];
    const body = latest.body.length > 2000 ? latest.body.slice(0, 2000) + "..." : latest.body;
    bot.sendMessage(chatId, [
      `💬 Latest on Issue #${COMMAND_CENTER_ISSUE}`,
      `By: ${latest.user.login}`,
      `At: ${new Date(latest.created_at).toLocaleString()}`,
      "",
      body,
    ].join("\n"));
  } catch (err) {
    bot.sendMessage(chatId, `Error: ${err.message}`);
  }
});

bot.on("polling_error", (err) => {
  console.error("Polling error:", err.message);
});

console.log("ASDEV Status Bot started");
