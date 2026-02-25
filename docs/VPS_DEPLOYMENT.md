# استقرار روی VPS (راهنمای عملیاتی)

## پیش‌نیازها
- Ubuntu 22.04+
- نصب ابزارها: `node`, `pnpm`, `pm2`, `rsync`, `nginx`
- دامنه و DNS برای `alirezasafaeisystems.ir`
- هم‌میزبانی با `persiantoolbox.ir` روی همان VPS (بدون تداخل پورت)

## ساختار مسیرها
- `/var/www/my-portfolio/releases/<env>/<release>`
- `/var/www/my-portfolio/shared/env/<env>.env`
- `/var/www/my-portfolio/shared/logs/`
- `/var/www/my-portfolio/current/<env>`

## توپولوژی Co-Hosting (روی یک سرور)
- PersianToolbox:
  - Production: `127.0.0.1:3000` -> `persiantoolbox.ir`
  - Staging: `127.0.0.1:3001` -> `staging.persiantoolbox.ir`
- Portfolio:
  - Production: `127.0.0.1:3002` -> `alirezasafaeisystems.ir`
  - Staging: `127.0.0.1:3003` -> `staging.alirezasafaeisystems.ir`
- پیش از deploy هر پروژه، تداخل را چک کنید:
  - `bash scripts/deploy/check-hosting-sync.sh --strict`

## مراحل استقرار
1. آماده‌سازی release روی لوکال (گیت‌های کیفیت + smoke + ساخت artifact):
   - `pnpm run release:prepare:vps`
   - خروجی:
     - `artifacts/releases/production/<release-id>/*.tar.gz`
     - `docs/runtime/VPS_DEPLOY_PREP_<timestamp>.md`
2. فایل محیطی را بسازید:
   - `cp .env.example /var/www/my-portfolio/shared/env/production.env`
3. سورس کد را روی VPS قرار دهید (extract در یک مسیر موقت).
4. اجرای preflight روی VPS:
   - `bash scripts/vps-preflight.sh --env production --strict`
5. اجرای deploy:
   - `bash ops/deploy/deploy.sh --env production --source-dir /tmp/release`
6. راه‌اندازی سرویس systemd:
   - `sudo cp ops/systemd/my-portfolio-production.service /etc/systemd/system/`
   - `sudo systemctl daemon-reload`
   - `sudo systemctl enable --now my-portfolio-production`
7. پیکربندی nginx:
   - حالت پیشنهادی (Production): co-hosting یکپارچه با TLS/HSTS:
     - `sudo cp ops/nginx/asdev-cohosting.conf /etc/nginx/sites-available/asdev-cohosting.conf`
     - `sudo ln -sfn /etc/nginx/sites-available/asdev-cohosting.conf /etc/nginx/sites-enabled/asdev-cohosting.conf`
     - `sudo nginx -t && sudo systemctl reload nginx`
   - حالت تکی portfolio (`ops/nginx/my-portfolio.conf`) فقط HTTP است و HSTS را enforce نمی‌کند.
     - از این فایل فقط در صورتی استفاده کنید که TLS termination در Edge خارجی انجام شود و redirect/headerها در همان لایه enforce شوند.

## سلامت
- بررسی سلامت: `curl -fsS http://127.0.0.1:3002/api`
- متریک‌ها: `http://127.0.0.1:3002/api/metrics`
- readiness: `http://127.0.0.1:3002/api/ready`

## Rollback
- `bash ops/deploy/rollback.sh --env production`

## نکته پایگاه داده
- اگر نیاز به Postgres دارید، `DATABASE_URL` را به URL مربوطه تغییر دهید.

## الزامات عملیاتی برای اینترنت/تحریم ایران
- `local-first` بمانید: از فونت/اسکریپت/Asset خارجی در runtime استفاده نکنید.
- Build را تا جای ممکن در محیط داخلی/لوکال انجام دهید و artifact آماده را منتقل کنید.
- وابستگی به pull مستقیم image در لحظه deploy را حذف یا به زمان غیرحساس منتقل کنید.
- DNS/TLS/HSTS را روی Edge/Nginx با evidence مستند کنید.
- برای مسیر اضطراری، rollback drill و go/no-go signoff را قبل release واقعی انجام دهید.
