# Як вручну опублікувати MD_View-Edit_macOS на GitHub

Це інструкція без Terminal. Ідея проста:

- **Repository** зберігає source code, README, license, і demo file.
- **Release** зберігає готову app для скачування: `.dmg` і `.zip`.

Не змішуй ці дві речі. Source code живе в repository, готові збірки живуть у Releases.

## Що саме завантажувати

У repository завантаж source files:

- `.github`
- `docs`
- `Resources`
- `Sources`
- `scripts`
- `.gitattributes`
- `.gitignore`
- `CHANGELOG.md`
- `CONTRIBUTING.md`
- `LICENSE`
- `Package.swift`
- `README.md`
- `SECURITY.md`
- `VERSION`
- `markdown_demo.md`

Не завантажуй у repository:

- `.build`
- `dist`
- `.DS_Store`
- будь-які приватні нотатки, документи, screenshots, архіви, паролі або ключі

Готові файли з `dist` завантажуй тільки в GitHub Release:

- `MD_View-Edit_macOS-v1.0.0.dmg`
- `MD_View-Edit_macOS-v1.0.0.zip`

`MD_View-Edit_macOS-v1.0.0.app` краще не завантажувати окремо, бо GitHub і браузери погано працюють з `.app` як з папкою. Для людей зручніше `.dmg` або `.zip`.

## 1. Створи repository

1. Відкрий GitHub.
2. Натисни **New repository**.
3. Назва: `MD_View-Edit_macOS` або `md-view-edit-macos`.
4. Visibility: **Public**.
5. Не додавай README, `.gitignore` або license на сайті, бо вони вже є в цій папці.
6. Натисни **Create repository**.

## 2. Завантаж source code вручну

1. Відкрий створений repository.
2. Натисни **Add file**.
3. Натисни **Upload files**.
4. Перетягни файли й папки зі списку “У repository завантаж source files”.
5. Не перетягуй `.build`, `dist` і `.DS_Store`.
6. Унизу сторінки натисни **Commit changes**.

Після цього GitHub repository буде містити код програми. Це і є open source частина.

## 3. Створи Release для скачування app

1. Відкрий вкладку **Releases**.
2. Натисни **Create a new release**.
3. У полі **Tag version** напиши `v1.0.0`.
4. У полі **Release title** напиши `MD_View-Edit_macOS v1.0.0`.
5. У тексті release коротко напиши:

```text
Initial public release of MD_View-Edit_macOS.

This build is not Apple-notarized because I do not currently have an Apple Developer license. macOS may ask you to allow the app manually in System Settings > Privacy & Security, or by right-clicking the app and choosing Open.
```

6. У блок **Attach binaries by dropping them here or selecting them** завантаж:
   - `dist/MD_View-Edit_macOS-v1.0.0.dmg`
   - `dist/MD_View-Edit_macOS-v1.0.0.zip`
7. Натисни **Publish release**.

## Важлива примітка для користувачів

Я зараз не маю Apple Developer license, тому публічна збірка не підписана і не notarized через Apple. Через це macOS може показати попередження, що app від непідтвердженого розробника.

Користувачу треба буде вручну дозволити запуск у **System Settings > Privacy & Security** або через right-click на app і **Open**.

Це нормально для безкоштовної open source збірки без Apple Developer ID. Для максимально зручної установки потрібні підпис і notarization від Apple.
