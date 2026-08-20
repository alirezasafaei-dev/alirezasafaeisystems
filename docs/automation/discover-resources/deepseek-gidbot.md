# Discover Resource Candidate — DeepSeek Telegram Bot by G.Media

**Status:** READY_TO_PUBLISH
**Priority:** HIGH
**Tracker:** #188

## Authoritative identity

- Telegram handle: `@deepseek_gidbot`
- Clean destination: `https://t.me/deepseek_gidbot`
- Operator/product registry: G.Media lists `@deepseek_gidbot` in its AI-agent product family as `DeepSeek in Telegram. Free.`
- This is **not the official DeepSeek product/bot**. Present it as a third-party G.Media Telegram bot using the DeepSeek name/model experience, never as DeepSeek's own official Telegram bot.

## Source Instagram Reel

`https://www.instagram.com/p/Db9O3I-M6Dy/`

Owner-provided Reel copy records these first-hand observations from testing:
- no separate registration observed;
- no special setup required;
- Persian was understood/responded to well in the test;
- response personality/style could be changed in the tested experience;
- no noticeable usage limit was encountered during the test period.

These are **first-hand test observations, not permanent service guarantees**. Do not claim unlimited usage. Availability, limits and behavior may change.

## Discover payload

```json
{
  "slug": "deepseek-telegram-bot",
  "title": "بات رایگان DeepSeek در تلگرام (غیررسمی)",
  "description": "یک بات شخص ثالث از G.Media برای استفاده از تجربه DeepSeek داخل تلگرام؛ بدون نیاز به نصب اپ جدا. در تست ASDEV فارسی را خوب پاسخ داد. رایگان بودن فعلی توسط کاتالوگ رسمی G.Media تأیید شده است.",
  "content": "اگر می‌خواهی بدون نصب اپ جدا از یک دستیار مبتنی بر تجربه DeepSeek داخل تلگرام استفاده کنی، این بات یکی از گزینه‌های ساده است.\n\nروش استفاده: لینک رسمی بات را باز کن، Start را بزن و پیام خودت را بفرست. برای شروع نیاز به ثبت‌نام جداگانه یا تنظیمات پیچیده‌ای در تست ASDEV مشاهده نشد.\n\nدر تست واقعی ASDEV، بات فارسی را خوب متوجه شد و پاسخ فارسی داد. همچنین امکان تغییر سبک و شخصیت پاسخ‌دادن در تجربه آزمایش‌شده وجود داشت. در مدت تست محدودیت محسوسی مشاهده نشد، اما این موضوع تضمین دائمی نیست و شرایط سرویس ممکن است تغییر کند.\n\nنکته مهم: این بات رسمی DeepSeek نیست. هندل @deepseek_gidbot در کاتالوگ G.Media به‌عنوان یکی از AI botهای این مجموعه ثبت شده است. بنابراین آن را به‌عنوان یک سرویس شخص ثالث استفاده کن و اطلاعات حساس یا محرمانه را در هیچ بات شخص ثالثی ارسال نکن.\n\nبرای ورود، از دکمه مقصد رسمی همین صفحه استفاده کن و قبل از Start مطمئن شو username دقیقاً @deepseek_gidbot است.",
  "externalUrl": "https://t.me/deepseek_gidbot",
  "category": "AI",
  "tags": ["DeepSeek", "Telegram", "AI", "هوش مصنوعی", "چت بات"],
  "imageUrl": "",
  "instagramUrl": "https://www.instagram.com/p/Db9O3I-M6Dy/",
  "telegramGuideUrl": "",
  "featured": true,
  "published": true,
  "order": 10
}
```

## Field semantics

- `externalUrl` must be `https://t.me/deepseek_gidbot` because the bot itself is the resource destination.
- `telegramGuideUrl` must remain empty unless ASDEV later publishes an **exact message-level** Telegram tutorial/file link. A bot homepage or channel profile is not a guide deep-link.
- `instagramUrl` links the original Reel for campaign/evidence continuity.
- Do not append ASDEV UTM parameters to the Telegram destination.

## Verification after publish

1. Confirm item appears in `/discover` search for `DeepSeek`, `تلگرام`, and `بات`.
2. Verify `/discover/deepseek-telegram-bot` and `/en/discover/deepseek-telegram-bot` return 200 and hard-refresh cleanly.
3. Verify official CTA href is exactly `https://t.me/deepseek_gidbot` with no ASDEV UTM leakage.
4. Verify no Telegram guide CTA renders while `telegramGuideUrl` is null.
5. Verify sitemap contains `/discover/deepseek-telegram-bot` after publication.
6. Verify canonical/hreflang/structured data and mobile/desktop rendering.
7. With analytics consent, verify `discover_item_view` and `discover_external_click` fire with safe slug/category/allowlisted attribution only.
8. Record publication item id/time and live evidence in issue #188.

## Evidence notes

Primary external verification: G.Media public product catalog identifies `@deepseek_gidbot` and labels it `DeepSeek in Telegram. Free.` The Instagram Reel and its copy are owner-supplied first-party ASDEV content for the test observations above.
