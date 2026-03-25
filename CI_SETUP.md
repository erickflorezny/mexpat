# Codemagic + Supabase setup for Mexpat

This project reads runtime keys from `Info.plist` keys:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## 1) Codemagic environment variables

In Codemagic UI, add:
- `SUPABASE_URL` (plain text)
- `SUPABASE_ANON_KEY` (secure)

Use your project URL:
- `https://juyrhwdygiesqbuoujdh.supabase.co`

## 2) Xcode config mapping (required)

In your Xcode project once created:

1. Add config files:
   - `Mexpat/Config/Secrets.local.xcconfig` (local, ignored)
   - `Mexpat/Config/Secrets.ci.xcconfig` (generated in CI)

2. Create base config include chain, e.g. in `Config/Debug.xcconfig` and `Config/Release.xcconfig`:

```xcconfig
#include? "Secrets.local.xcconfig"
#include? "Secrets.ci.xcconfig"
```

3. In `Info.plist`, set:

```xml
<key>SUPABASE_URL</key>
<string>$(SUPABASE_URL)</string>
<key>SUPABASE_ANON_KEY</key>
<string>$(SUPABASE_ANON_KEY)</string>
```

## 3) Codemagic build file

`codemagic.yaml` already includes:
- env var validation
- generation of `Mexpat/Config/Secrets.ci.xcconfig`
- IPA build and TestFlight publishing

Adjust these values in `codemagic.yaml`:
- `XCODE_PROJECT`
- `XCODE_SCHEME`
- `APP_BUNDLE_ID`

## 4) Local development

1. Copy `Mexpat/Config/Secrets.template.xcconfig` to `Mexpat/Config/Secrets.local.xcconfig`
2. Fill your real values.
3. Ensure `Secrets.local.xcconfig` is gitignored.

## 5) Security notes

- Use only **anon** key in iOS app.
- Never ship service-role key in client.
- Keep `SUPABASE_ANON_KEY` as secure variable in Codemagic.
