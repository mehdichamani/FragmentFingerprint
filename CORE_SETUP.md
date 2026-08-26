# راه‌اندازی و اجرای هسته (Core Setup)

این راهنما مراحل تنظیم آدرس مقصد، دانلود هسته Xray، اجرای زنده و ثبت سرویس خودکار (Startup Service) در سیستم‌عامل‌های مختلف را توضیح می‌دهد.

> 🌐 **[English Guide: CORE_SETUP.en.md](CORE_SETUP.en.md)** | 📖 **[بازگشت به صفحه اصلی](README.md)**

---

## ⚙️ گام اول: تنظیم آدرس سرور نهایی (Target Address)

فایل [config.json](config.json) را با یک ویرایشگر باز کنید و در بخش `outbounds -> settings -> redirect` آدرس و پورت سرور مقصد یا آی‌پی تمیز کلودفلر خود را قرار دهید:

```json
"settings": {
  "redirect": "188.114.97.6:443"
}
```

---

## 🖥️ روش‌های اجرا بر اساس سیستم‌عامل

### ویندوز (Windows Native TUI)

ساده‌ترین روش، استفاده از منوی تعاملی ویندوز است:
1. روی فایل [menu.bat](menu.bat) دبل‌کلیک کنید (یا فایل [menu.ps1](menu.ps1) را در PowerShell اجرا نمایید).
2. گزینه `[4]` را انتخاب کنید تا آخرین نسخه پایدار **Xray-core** به صورت خودکار دانلود و استخراج شود.
3. سپس:
   - **اجرای عادی:** با زدن گزینه `[1]` هسته در ترمینال اجرا می‌شود.
   - **اجرا در پس‌زمینه و استارتاپ:** با زدن گزینه `[2]` سرویس در Task Scheduler ویندوز ثبت شده و با روشن شدن سیستم به صورت خودکار و مخفی در پس‌زمینه اجرا می‌شود.

### لینوکس (Linux Native TUI)

ترمینال را در پوشه پروژه باز کرده و دستورات زیر را اجرا کنید:
```bash
chmod +x menu.sh
./menu.sh
```
1. گزینه `[4]` را انتخاب کنید تا بسته متناسب با معماری سیستم شما (`x86_64`, `arm64`, `armv7`) به شکل خودکار دانلود شود.
2. سپس:
   - **اجرای عادی:** گزینه `[1]` را برای تست زنده در محیط ترمینال بزنید.
   - **نصب سرویس systemd دائمی:** گزینه `[2]` را انتخاب کنید (به‌صورت سرویس سیستمی با دسترسی root یا سرویس کاربر بدون root).

### داکر (Docker Compose)

در صورت تمایل به اجرای ایزوله روی سرور یا کانتینر داکر:
```bash
docker compose up -d
```

---

## 🔄 مدیریت دستی سرویس‌های پس‌زمینه

### در ویندوز (PowerShell):
- **اجرای تسک:** `Start-ScheduledTask -TaskName "XrayFragment"`
- **توقف تسک:** `Stop-ScheduledTask -TaskName "XrayFragment"` و بستن پردازه با `taskkill /F /IM xray.exe`
- **حذف از استارتاپ:** `Unregister-ScheduledTask -TaskName "XrayFragment" -Confirm:$false`

### در لینوکس (systemd):
- **سرویس سیستمی:** `sudo systemctl [start|stop|status|restart] xray-fragment`
- **سرویس کاربر:** `systemctl --user [start|stop|status|restart] xray-fragment`
