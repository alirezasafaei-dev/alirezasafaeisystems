import TelegramBot from "node-telegram-bot-api";
import { execSync } from "child_process";

const TOKEN = process.env.TELEGRAM_BOT_TOKEN;
const GITHUB_TOKEN = process.env.GITHUB_TOKEN;
const AUDIT_REPO = process.env.AUDIT_REPO || "auditsystems";
const BRAND_REPO = process.env.BRAND_REPO || "AliRezaSafaeiSystems";
const ALIREZASAFAEISYSTEMS_REPO =
  process.env.ALIREZASAFAEISYSTEMS_REPO || "alirezasafaeisystems";

if (!TOKEN) {
  console.error("TELEGRAM_BOT_TOKEN is required");
  process.exit(1);
}

const bot = new TelegramBot(TOKEN, { polling: true });

function gh(endpoint) {
  const cmd = GITHUB_TOKEN
    ? `gh api -H "Accept: application/vnd.github+json" ${endpoint}`
    : `gh api ${endpoint}`;
  return execSync(cmd, { encoding: "utf-8" }).trim();
}

function ghRepo(repo, endpoint) {
  return gh(`repos/${repo}/${endpoint}`);
}

function systemctlStatus(service) {
  try {
    return execSync(`systemctl is-active ${service}`, {
      encoding: "utf-8",
    }).trim();
  } catch {
    return "inactive";
  }
}

function formatIssue(issue) {
  const labels = issue.labels.map((l) => `[${l.name}]`).join(" ");
  return `#${issue.number} ${issue.title}\n  ${labels || "no labels"}\n  Updated: ${new Date(issue.updated_at).toLocaleDateString()}`;
}

function formatPR(pr) {
  const labels = pr.labels.map((l) => `[${l.name}]`).join(" ");
  return `#${pr.number} ${pr.title}\n  ${labels || "no labels"}\n  ${pr.user.login} • ${new Date(pr.updated_at).toLocaleDateString()}`;
}

bot.onText(/\/start/, (msg) => {
  bot.sendMessage(
    msg.chat.id,
    "ASDEV Status Bot\n\nCommands:\n/status - Full status report\n/prs - List open PRs\n/blockers - Show blockers\n/last - Last Issue #45 comment"
  );
});

bot.onText(/\/status/, async (msg) => {
  const chatId = msg.chat.id;
  bot.sendMessage(chatId, "Fetching status...");

  try {
    const issue45 = JSON.parse(ghRepo(ALIREZASAFAEISYSTEMS_REPO, "issues/45"));
    const auditPRs = JSON.parse(ghRepo(AUDIT_REPO, "pulls?state=open"));
    const brandPRs = JSON.parse(ghRepo(BRAND_REPO, "pulls?state=open"));

    const vpsStatus = systemctlStatus("nginx");

    const lines = [
      "📊 ASDEV Status Report",
      "",
      `Issue #45: ${issue45.title}`,
      `  State: ${issue45.state}`,
      `  Labels: ${issue45.labels.map((l) => l.name).join(", ") || "none"}`,
      "",
      `Audit PRs: ${auditPRs.length} open`,
      auditPRs.map((pr) => `  #${pr.number} ${pr.title}`).join("\n"),
      "",
      `Brand PRs: ${brandPRs.length} open`,
      brandPRs.map((pr) => `  #${pr.number} ${pr.title}`).join("\n"),
      "",
      `VPS Nginx: ${vpsStatus}`,
    ];

    bot.sendMessage(chatId, lines.join("\n"));
  } catch (err) {
    bot.sendMessage(chatId, `Error: ${err.message}`);
  }
});

bot.onText(/\/prs/, async (msg) => {
  const chatId = msg.chat.id;
  bot.sendMessage(chatId, "Fetching PRs...");

  try {
    const auditPRs = JSON.parse(ghRepo(AUDIT_REPO, "pulls?state=open"));
    const brandPRs = JSON.parse(ghRepo(BRAND_REPO, "pulls?state=open"));

    const lines = [
      "🔀 Open Pull Requests",
      "",
      `${AUDIT_REPO} (${auditPRs.length}):`,
      auditPRs.map((pr) => formatPR(pr)).join("\n"),
      "",
      `${BRAND_REPO} (${brandPRs.length}):`,
      brandPRs.map((pr) => formatPR(pr)).join("\n"),
    ];

    bot.sendMessage(chatId, lines.join("\n"));
  } catch (err) {
    bot.sendMessage(chatId, `Error: ${err.message}`);
  }
});

bot.onText(/\/blockers/, async (msg) => {
  const chatId = msg.chat.id;
  bot.sendMessage(chatId, "Fetching blockers...");

  try {
    const auditPRs = JSON.parse(ghRepo(AUDIT_REPO, "pulls?state=open"));
    const brandPRs = JSON.parse(ghRepo(BRAND_REPO, "pulls?state=open"));

    const blocked = [
      ...auditPRs.filter(
        (pr) =>
          pr.labels.some((l) => l.name === "blocked") ||
          pr.labels.some((l) => l.name === "priority: high")
      ),
      ...brandPRs.filter(
        (pr) =>
          pr.labels.some((l) => l.name === "blocked") ||
          pr.labels.some((l) => l.name === "priority: high")
      ),
    ];

    if (blocked.length === 0) {
      bot.sendMessage(chatId, "No blockers found");
    } else {
      const lines = [
        "🚨 Blocked / High Priority PRs",
        "",
        blocked.map((pr) => formatPR(pr)).join("\n"),
      ];
      bot.sendMessage(chatId, lines.join("\n"));
    }
  } catch (err) {
    bot.sendMessage(chatId, `Error: ${err.message}`);
  }
});

bot.onText(/\/last/, async (msg) => {
  const chatId = msg.chat.id;
  bot.sendMessage(chatId, "Fetching Issue #45...");

  try {
    const comments = JSON.parse(
      ghRepo(ALIREZASAFAEISYSTEMS_REPO, "issues/45/comments?per_page=1")
    );

    if (comments.length === 0) {
      bot.sendMessage(chatId, "No comments on Issue #45");
    } else {
      const comment = comments[0];
      const lines = [
        `💬 Latest on Issue #45`,
        `By: ${comment.user.login}`,
        `At: ${new Date(comment.created_at).toLocaleString()}`,
        "",
        comment.body.slice(0, 2000),
      ];
      bot.sendMessage(chatId, lines.join("\n"));
    }
  } catch (err) {
    bot.sendMessage(chatId, `Error: ${err.message}`);
  }
});

bot.on("polling_error", (err) => {
  console.error("Polling error:", err.message);
});

console.log("ASDEV Status Bot started");
