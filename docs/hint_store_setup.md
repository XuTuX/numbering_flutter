# Hint store setup

The app implements three consumable hint packs. Product prices shown in the UI
come from StoreKit or Google Play Billing, so each store remains the source of
truth for localized pricing.

| Product ID | Type | Hints | Korea price |
| --- | --- | ---: | ---: |
| `numbering_hints_11` | Consumable / one-time product | 11 | ₩1,100 |
| `numbering_hints_50` | Consumable / one-time product | 50 | ₩3,300 |
| `numbering_hints_100` | Consumable / one-time product | 100 | ₩5,500 |

Use the exact same product IDs in App Store Connect and Google Play Console.
Suggested Korean display names are `힌트 11개`, `힌트 50개`, and `힌트 100개`.
Set all three products to consumable on Apple and one-time/consumable on Google.
Do not hardcode another price in the app; configure the Korea price in each
store and let the stores calculate other regions.

## Supabase deployment

The purchase verification function calls the App Store Server API and Google
Play Developer API, then writes through a service-role-only RPC. Apply the
migrations before deploying the function:

```bash
supabase db push
supabase functions deploy verify-hint-purchase
```

Configure these Edge Function secrets in the Supabase project:

```bash
supabase secrets set \
  APPLE_IAP_BUNDLE_ID=com.neoreo.numbering \
  APPLE_IAP_ISSUER_ID=... \
  APPLE_IAP_KEY_ID=... \
  APPLE_IAP_PRIVATE_KEY='-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----' \
  GOOGLE_PLAY_PACKAGE_NAME=com.neoreo.numbering \
  GOOGLE_PLAY_SERVICE_ACCOUNT_JSON='{"client_email":"...","private_key":"..."}'
```

Create the Apple in-app purchase API key in App Store Connect and use its `.p8`
private key. For Google, enable the Android Publisher API and grant the service
account access to the NUMBERING app in Play Console. Never put either private
key in Flutter assets, Dart defines, or the repository.

## Release checks

1. Complete the paid-app agreements, tax, and banking setup in App Store
   Connect and Play Console.
2. Attach all three in-app purchases to the App Store version being reviewed.
3. Upload an Android build to an internal testing track before testing billing;
   install it through Google Play with a license tester account.
4. Test Apple purchases with a Sandbox Apple Account or StoreKit test session.
5. Confirm a successful purchase increments the signed-in account once, can be
   purchased again, and does not increment again if the same transaction is
   re-delivered.
6. Confirm pending, canceled, offline, wrong-account, and refunded/revoked
   transactions never grant hints.

Consumables do not have a user-facing restore button. Unfinished transactions
are re-delivered by the store purchase stream, while completed hint balances
remain in `numbering_user_resources` on Supabase.
