# گزارش نهایی تعمیرات بنیادی ASDEV

**تاریخ:** 2026-07-08
**وضعیت:** تکمیل شده

---

## ۱. اشکالات یافته شده در PR #68/#69/#70

### PR #69 (موتور Deploy):
- Schema رجیستری ۱۰ ستونه بود، اسکریپت‌ها ۱۸ ستون انتظار داشتند
- اسکریپت‌ها از `read` تعاملی برای تأیید استفاده می‌کردند (غیر ایمن برای اتوماسیون)
- اسکریپت‌ها `--force` داشتند که تأیید را دور می‌زد
- Deploy کل رپوی ASDEV را کپی می‌کرد به جای artifacts مخصوص سایت
- Release GC حذف مخرب به صورت پیش‌فرض داشت

### PR #68 (محافظت):
- اسکریپت‌های محافظت عملیات مخرب داشتند (rm, pm2, nginx, symlink)
- محافظت فقط check/guard نبود

### PR #70 (قرنطینه):
- قرنطینه زودتر از موعد عملیات زنده انجام می‌داد
- رویکرد inventory/plan-first نداشت
- PM2 را بدون تأیید متوقف و nginx را reload می‌کرد

---

## ۲. آیا PRها اصلاح شدند یا PR جایگزین باز شد؟

**PR جایگزین باز شد:** #71
- PRهای قدیمی #68, #69, #70 بسته شدند
- PR #71 تمام اصلاحات را در خود جای داده است

---

## ۳. آیا مسیر محلی استاندارد شد؟

**بله:**
- مسیر قدیمی: `/home/dev13/my-project`
- مسیر جدید: `/home/dev13/ASDEV`
- symlink ایجاد شد: `/home/dev13/ASDEV` -> `/home/dev13/alirezasafaeisystems`
- گزارش: `docs/ops/local-root-standardization.md`

---

## ۴. آیا GitHub به عنوان منبع حقیقت مستند شد؟

**بله:**
- `docs/automation/ASDEV_SOURCE_OF_TRUTH.md`
- `README.md`
- `AGENTS.md`

GitHub منبع حقیقت برای کد، نقشه راه، اهداف، قوانین操作، حافظه ایجنت، وضعیت وظایف، استانداردهای deploy، و ساختار پروژه است.

---

## ۵. کدام فایل‌ها حافظه ایجنت و handoff را تعریف می‌کنند؟

- `docs/automation/AGENT_MEMORY.md` - فرمت حافظه ایجنت
- `docs/automation/AGENT_HANDOFF_PROTOCOL.md` - پروتکل handoff
- `docs/automation/AGENT_OPERATING_RULES.md` - قوانین操作 ایجنت

---

## ۶. کدام فایل‌های نقشه راه وجود دارند؟

- `docs/roadmaps/TODAY.md`
- `docs/roadmaps/NEXT_7_DAYS.md`
- `docs/roadmaps/NEXT_30_DAYS.md`
- `docs/roadmaps/NEXT_90_DAYS.md`

---

## ۷. آیا رجیستری deploy و parser با هم مطابقت دارند؟

**بله:**
- رجیستری: ۱۸ ستون (`deploy/registry.tsv`)
- Parser: از `cut -f1` برای site_id استفاده می‌کند
- `protected` به صورت true/false است
- persiantoolbox.ir با protected=true علامت‌گذاری شده

---

## ۸. آیا اسکریپت‌های محافظت فقط check هستند؟

**بله:**
- `scripts/ops/check-critical-site-protection.sh` - فقط خواندن
- `scripts/ops/protect-critical-site.sh` - فقط guard/simulation
- هیچ عملیات مخربی: rm, pm2, nginx, symlink, DB

---

## ۹. آیا قرنطینه inventory/plan-first است؟

**بله:**
- `scripts/ops/iran-prod-inventory.sh` - فقط خواندن
- `scripts/ops/generate-quarantine-plan.sh` - طبقه‌بندی + allowlist
- `scripts/ops/quarantine-non-critical.sh` - dry-run پیش‌فرض، allowlist الزامی

---

## ۱۰. نتایج اعتبارسنجی

- ✅ تمام اسکریپت‌ها از `bash -n` عبور کردند
- ✅ هیچ رمز یا IP خام نمایش داده نشد
- ✅ Schema رجیستری با parser مطابقت دارد (۱۸ ستون)
- ✅ اسکریپت‌های محافظت فقط check/guard هستند
- ✅ قرنطینه inventory/plan-first است
- ✅ هیچ عملیات مخربی اجرا نشد

---

## ۱۱. عبارت تأیید برای مرحله بعدی

```bash
# برای deploy production:
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY

# برای deploy staging:
APPROVE_PHASE_2_STAGING_DEPLOY

# برای حذف ریلیز:
APPROVE_RELEASE_DELETE

# برای موجودیت‌خوانی (فقط خواندن):
APPROVE_IRAN_PROD_SITE_INVENTORY

# برای قرنطینه:
APPROVE_IRAN_PROD_QUARANTINE_NON_CRITICAL
```

---

## خلاصه

- ✅ هیچ PR خطرناکی باقی نمانده
- ✅ مسیر محلی ASDEV استاندارد شده
- ✅ GitHub منبع حقیقت مستند شده
- ✅ حافظه ایجنت وجود دارد
- ✅ handoff ایجنت وجود دارد
- ✅ نقشه راه‌ها وجود دارند
- ✅ موتور deploy fail-closed است
- ✅ Schema رجیستری با اسکریپت‌ها مطابقت دارد
- ✅ محافظت CRITICAL_SITE فقط guard است
- ✅ قرنطینه inventory/plan-first است
- ✅ هیچ رمزی فاش نشد
- ✅ هیچ عملیات مخربی اجرا نشد
