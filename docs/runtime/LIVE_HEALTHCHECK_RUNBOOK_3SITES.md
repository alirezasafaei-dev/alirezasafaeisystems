# Runbook: Monitoring 3 Live Sites

این runbook برای مانیتورینگ خودکار ۳ سایت زنده تهیه شده:

- `alirezasafaeisystems.ir`
- `persiantoolbox.ir`
- `audit.alirezasafaeisystems.ir`

## مسیرهای عملیاتی

- اسکریپت محلی: `scripts/live-sites-healthcheck.sh`
- اسکریپت اجرا روی VPS: `/home/deploy/.local/scripts/live-sites-healthcheck.sh`
- کرون‌جاب: `*/5 * * * * /home/deploy/.local/scripts/live-sites-healthcheck-wrapper.sh`
- فایل تنظیمات (برای alert): `/home/deploy/.local/.env-live-healthcheck`
- لاگ: `/home/deploy/.local/logs/live-sites-healthcheck.log` (در صورت نبودن مسیر: `/tmp/live-sites-healthcheck.log`)

## وضعیت فعلی پیاده‌سازی (۱ اردیبهشت ۱۴۰۵)

- اجرای پایدار روی VPS فعال است و هر ۵ دقیقه اجرا می‌شود.
- اسکریپت‌ها و env روی VPS همگام‌سازی شده‌اند.
- اجرای دستی اخیر روی VPS موفق بوده و همه endpointها `OK` هستند.
- برای اطلاع‌رسانی فعلاً فقط آماده‌سازی انجام شده؛ فعال‌سازی نیاز به endpoint نهایی دارد.

## اجرای سریع (SRE)

- اجرای دستی چک:
  - `bash /home/deploy/.local/scripts/live-sites-healthcheck.sh`
- دیدن آخرین خروجی:
  - `tail -n 40 /home/deploy/.local/logs/live-sites-healthcheck.log`

## نسخه اتوماسیون n8n (لوکال)

بله، می‌شود و به‌صورت خیلی حرفه‌ای هم می‌شود:

- فایل‌ها:
  - `scripts/n8n-live-healthcheck/docker-compose.yml`
  - `scripts/n8n-live-healthcheck/live-sites-healthcheck-workflow.json`
- اجرای سریع n8n محلی:
  - `cd scripts/n8n-live-healthcheck`
  - `N8N_BASIC_AUTH_USER=admin N8N_BASIC_AUTH_PASSWORD=change-me N8N_ENCRYPTION_KEY=..."$(openssl rand -hex 16)" docker compose up -d`
  - `open http://localhost:5678`
- ایمپورت workflow:
  - در UI → Workflows → Import from File → `live-sites-healthcheck-workflow.json`
- اجرای اسکریپت داخل n8n:
  - Workflow همان اسکریپت محلی را هر 5 دقیقه اجرا می‌کند.
- نکته:
  - برای Alert باید متغیر محیطی `LIVE_HEALTHCHECK_WEBHOOK` ست باشد:
    - Slack/Teams/Telegram webhook (فرمت JSON: `{\"text\":\"...\"}` )
- اگر Telegram داخل ایران محدود است:
  - یک proxy برای API تلگرام ست کن:
    - `LIVE_HEALTHCHECK_TELEGRAM_PROXY=http://127.0.0.1:8080`
    - (برای SOCKS5 نیز مانند `socks5h://127.0.0.1:1080`)
  - برای سرویس‌های ایرانی سازگار با Bot API:
    - `LIVE_HEALTHCHECK_TELEGRAM_API_BASE=https://tapi.bale.ai/bot` (به‌عنوان مثال برای Bale)
  - اگر Rubika endpoint شخصی/فوری داری:
    - فقط با `LIVE_HEALTHCHECK_WEBHOOK=<url>` به webhook داخلی‌ات متصل شو.
- مسیرهای نهایی برای تولید:
  - می‌توانید wrapper فعلی cron را نگه دارید و برای alert حرفه‌ای‌ از n8n استفاده کنید.

## تفسیر وضعیت

- `200` برای `/api/ready` هر سه دامنه: OK
- `alirezasafaeisystems.ir/` باید `308` و ریدایرکت به `/fa` دهد (رفتار فعلی)
- هر خروجی `FAIL` یا کد غیرمنتظره یعنی حادثه سطح 1 (بلافاصله بررسی وضعیت سرویس‌ها)

## مسیر تشخیص مشکل (اختصار)

1) تایید Nginx:
   - `sudo systemctl status nginx`
2) بررسی سلامت سرویس‌های PM2:
   - `pm2 list`
   - `pm2 logs my-portfolio-production --lines 80`
   - `pm2 logs persian-tools-production --lines 80`
   - `pm2 logs asdev-audit-ir-production --lines 80`
3) بررسی مستقیم endpointها:
   - `curl -I https://alirezasafaeisystems.ir/api/ready`
   - `curl -I https://persiantoolbox.ir/api/ready`
   - `curl -I https://audit.alirezasafaeisystems.ir/api/ready`
4) بعد از رفع، اجرای مجدد healthcheck را تأیید کن.

## Alert (مرحله بعدی)

- برای فعال‌سازی سریع (اولویت ۱):
  - `LIVE_HEALTHCHECK_WEBHOOK=<url>` را در `/home/deploy/.local/.env-live-healthcheck` قرار بده.
  - فرمت body: `{\"text\":\"...\"}`
- برای Telegram/Bale مستقیم:
  - `LIVE_HEALTHCHECK_TELEGRAM_TOKEN=<bot_token>`
  - `LIVE_HEALTHCHECK_TELEGRAM_CHAT_ID=<chat_id>`
  - اگر endpoint سازگار با Telegram داری و از `tapi.bale.ai` است، فقط مقدار زیر را ست کن:
    - `LIVE_HEALTHCHECK_TELEGRAM_API_BASE=https://tapi.bale.ai/bot`
- برای بله (Bale):
    - `LIVE_HEALTHCHECK_BALE_TOKEN=...` (یا `BALE_BOT`)
    - `LIVE_HEALTHCHECK_BALE_CHAT_ID=...`
    - `LIVE_HEALTHCHECK_BALE_API_BASE=https://tapi.bale.ai/bot`
  - برای گرفتن `Bale CHAT_ID`:  
    - یک پیام به ربات بفرست  
    - `curl -sS "https://tapi.bale.ai/bot$LIVE_HEALTHCHECK_BALE_TOKEN/getUpdates"`
- اولویت اجرای خطاها:
  - اول Webhook
  - بعد Bale
  - بعد Telegram
- اگر Telegram فیلتر است یا نیاز به حذف مسیر Telegram داری:
  - `LIVE_HEALTHCHECK_DISABLE_TELEGRAM=1`
- Telegram با proxy:
  - `LIVE_HEALTHCHECK_TELEGRAM_PROXY=<http|socks5h://host:port>`
- API base جایگزین (برای Bale در صورت سازگاری):
  - `LIVE_HEALTHCHECK_TELEGRAM_API_BASE=https://tapi.bale.ai/bot`
- اسکریپت با `send_alert` در صورت شکست، فقط در صورت تنظیم متغیرها تلاش به ارسال می‌کند.
- تست اتصال مستقیم Telegram روی VPS فعلاً موفق نبود (خطای resolve/connect timeout)، پس در صورت نیاز به Telegram حتماً از proxy/endpoint جایگزین تست کن.

## تست پس از deploy

- 1) deploy انجام شود
- 2) تغییرات Nginx/PM2 اعمال و reload/restart شوند
- 3) اجرای دستی healthcheck:
  - `bash /home/deploy/.local/scripts/live-sites-healthcheck.sh`
- 4) 1~2 خط جدید لاگ با `[live-healthcheck] success` باید دیده شود.
