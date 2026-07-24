import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";

const PRODUCT_IDS = new Set([
  "numbering_hints_11",
  "numbering_hints_50",
  "numbering_hints_100",
]);

type PurchaseRequest = {
  platform?: unknown;
  productId?: unknown;
  purchaseId?: unknown;
  verificationData?: unknown;
};

type ParsedPurchaseRequest = {
  platform: "apple" | "google";
  productId: string;
  purchaseId: string;
  verificationData: string;
};

type VerifiedPurchase = {
  store: "apple" | "google";
  transactionId: string;
  productId: string;
  environment: string;
  purchasedAt: string | null;
  payloadSha256: string;
};

class PurchaseVerificationError extends Error {
  constructor(message: string, readonly status = 400) {
    super(message);
  }
}

export default {
  fetch: withSupabase({ auth: "user" }, async (req, ctx) => {
    if (req.method !== "POST") {
      return Response.json({ error: "method_not_allowed" }, { status: 405 });
    }

    try {
      const body = await readRequest(req);
      const userId = String(ctx.userClaims?.id ?? "");
      if (!isUuid(userId)) {
        throw new PurchaseVerificationError("invalid authenticated user", 401);
      }

      const verified = body.platform === "apple"
        ? await verifyApplePurchase(body, userId)
        : await verifyGooglePurchase(body, userId);

      const admin = ctx.supabaseAdmin as unknown as {
        rpc: (
          name: string,
          params: Record<string, unknown>,
        ) => Promise<{
          data: Record<string, unknown> | null;
          error: { code?: string; message?: string } | null;
        }>;
      };
      const { data, error } = await admin.rpc(
        "grant_verified_numbering_hint_purchase",
        {
          p_user_id: userId,
          p_store: verified.store,
          p_transaction_id: verified.transactionId,
          p_product_id: verified.productId,
          p_store_environment: verified.environment,
          p_purchased_at: verified.purchasedAt,
          p_payload_sha256: verified.payloadSha256,
        },
      );
      if (error) {
        console.error("purchase grant failed", error.code, error.message);
        throw new PurchaseVerificationError(
          "purchase could not be granted",
          409,
        );
      }

      return Response.json({ ok: true, ...(data ?? {}) });
    } catch (error) {
      const known = error instanceof PurchaseVerificationError;
      if (!known) console.error("purchase verification failed", error);
      return Response.json(
        { error: known ? error.message : "purchase verification failed" },
        { status: known ? error.status : 500 },
      );
    }
  }),
};

async function readRequest(req: Request): Promise<ParsedPurchaseRequest> {
  const contentLength = Number(req.headers.get("content-length") ?? "0");
  if (contentLength > 100_000) {
    throw new PurchaseVerificationError("request is too large", 413);
  }

  let body: PurchaseRequest;
  try {
    body = await req.json();
  } catch {
    throw new PurchaseVerificationError("invalid JSON");
  }

  const platform = asString(body.platform, 16);
  const productId = asString(body.productId, 128);
  const purchaseId = asString(body.purchaseId, 512, true);
  const verificationData = asString(body.verificationData, 80_000);

  if (platform !== "apple" && platform !== "google") {
    throw new PurchaseVerificationError("unsupported platform");
  }
  if (!PRODUCT_IDS.has(productId)) {
    throw new PurchaseVerificationError("unknown product");
  }
  if (verificationData.length < 8) {
    throw new PurchaseVerificationError("missing verification data");
  }

  return {
    platform: platform as "apple" | "google",
    productId,
    purchaseId,
    verificationData,
  };
}

async function verifyApplePurchase(
  body: ParsedPurchaseRequest,
  userId: string,
): Promise<VerifiedPurchase> {
  const bundleId = env("APPLE_IAP_BUNDLE_ID", "com.neoreo.numbering");
  const clientPayload = decodeJwtPayload(body.verificationData);
  const transactionId = body.purchaseId ||
    String(clientPayload.transactionId ?? "");
  if (!/^\d{8,32}$/.test(transactionId)) {
    throw new PurchaseVerificationError("invalid App Store transaction");
  }

  const authorization = await createAppleAuthorization(bundleId);
  const production = "https://api.storekit.itunes.apple.com";
  const sandbox = "https://api.storekit-sandbox.itunes.apple.com";
  let response = await fetchAppleTransaction(
    production,
    transactionId,
    authorization,
  );
  if (response.status === 404) {
    response = await fetchAppleTransaction(
      sandbox,
      transactionId,
      authorization,
    );
  }
  if (!response.ok) {
    console.error("App Store verification rejected", response.status);
    throw new PurchaseVerificationError(
      "App Store could not verify this purchase",
      422,
    );
  }

  const result = await response.json() as { signedTransactionInfo?: string };
  if (!result.signedTransactionInfo) {
    throw new PurchaseVerificationError(
      "App Store response was incomplete",
      502,
    );
  }
  const payload = decodeJwtPayload(result.signedTransactionInfo);
  const productId = String(payload.productId ?? "");
  const appAccountToken = String(payload.appAccountToken ?? "").toLowerCase();

  if (
    String(payload.transactionId ?? "") !== transactionId ||
    String(payload.bundleId ?? "") !== bundleId ||
    productId !== body.productId ||
    String(payload.type ?? "") !== "Consumable" ||
    Number(payload.quantity ?? 1) !== 1 ||
    payload.revocationDate != null
  ) {
    throw new PurchaseVerificationError(
      "App Store purchase details did not match",
      422,
    );
  }
  if (appAccountToken !== userId.toLowerCase()) {
    throw new PurchaseVerificationError(
      "purchase belongs to another account",
      403,
    );
  }

  return {
    store: "apple",
    transactionId,
    productId,
    environment: String(payload.environment ?? "Unknown"),
    purchasedAt: millisToIso(payload.purchaseDate),
    payloadSha256: await sha256Hex(result.signedTransactionInfo),
  };
}

async function fetchAppleTransaction(
  origin: string,
  transactionId: string,
  authorization: string,
) {
  return await fetch(
    `${origin}/inApps/v1/transactions/${encodeURIComponent(transactionId)}`,
    {
      headers: {
        Authorization: `Bearer ${authorization}`,
        Accept: "application/json",
      },
    },
  );
}

async function createAppleAuthorization(bundleId: string): Promise<string> {
  const issuerId = env("APPLE_IAP_ISSUER_ID");
  const keyId = env("APPLE_IAP_KEY_ID");
  const privateKey = env("APPLE_IAP_PRIVATE_KEY").replaceAll("\\n", "\n");
  const now = Math.floor(Date.now() / 1000);
  return await signJwt(
    { alg: "ES256", kid: keyId, typ: "JWT" },
    {
      iss: issuerId,
      iat: now,
      exp: now + 600,
      aud: "appstoreconnect-v1",
      bid: bundleId,
    },
    privateKey,
    "ES256",
  );
}

async function verifyGooglePurchase(
  body: ParsedPurchaseRequest,
  userId: string,
): Promise<VerifiedPurchase> {
  const packageName = env("GOOGLE_PLAY_PACKAGE_NAME", "com.neoreo.numbering");
  const token = body.verificationData;
  const accessToken = await getGoogleAccessToken();
  const url = "https://androidpublisher.googleapis.com/androidpublisher/v3" +
    `/applications/${encodeURIComponent(packageName)}` +
    `/purchases/products/${encodeURIComponent(body.productId)}` +
    `/tokens/${encodeURIComponent(token)}`;
  const response = await fetch(url, {
    headers: {
      Authorization: `Bearer ${accessToken}`,
      Accept: "application/json",
    },
  });
  if (!response.ok) {
    console.error("Google Play verification rejected", response.status);
    throw new PurchaseVerificationError(
      "Google Play could not verify this purchase",
      422,
    );
  }

  const payload = await response.json() as Record<string, unknown>;
  const returnedProductId = String(payload.productId ?? body.productId);
  if (
    Number(payload.purchaseState) !== 0 || returnedProductId !== body.productId
  ) {
    throw new PurchaseVerificationError(
      "Google Play purchase is not completed",
      422,
    );
  }
  if (Number(payload.quantity ?? 1) !== 1) {
    throw new PurchaseVerificationError("unsupported purchase quantity", 422);
  }
  if (String(payload.obfuscatedExternalAccountId ?? "") !== userId) {
    throw new PurchaseVerificationError(
      "purchase belongs to another account",
      403,
    );
  }

  return {
    store: "google",
    transactionId: await sha256Hex(token),
    productId: returnedProductId,
    environment: Number(payload.purchaseType) === 0 ? "Test" : "Production",
    purchasedAt: millisToIso(payload.purchaseTimeMillis),
    payloadSha256: await sha256Hex(JSON.stringify(payload)),
  };
}

async function getGoogleAccessToken(): Promise<string> {
  let serviceAccount: { client_email?: string; private_key?: string };
  try {
    serviceAccount = JSON.parse(env("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON"));
  } catch {
    throw new PurchaseVerificationError(
      "Google Play server is not configured",
      500,
    );
  }
  if (!serviceAccount.client_email || !serviceAccount.private_key) {
    throw new PurchaseVerificationError(
      "Google Play server is not configured",
      500,
    );
  }

  const now = Math.floor(Date.now() / 1000);
  const assertion = await signJwt(
    { alg: "RS256", typ: "JWT" },
    {
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/androidpublisher",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    },
    serviceAccount.private_key.replaceAll("\\n", "\n"),
    "RS256",
  );
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  const result = await response.json() as { access_token?: string };
  if (!response.ok || !result.access_token) {
    throw new PurchaseVerificationError(
      "Google Play authorization failed",
      502,
    );
  }
  return result.access_token;
}

async function signJwt(
  header: Record<string, unknown>,
  payload: Record<string, unknown>,
  pem: string,
  algorithm: "ES256" | "RS256",
): Promise<string> {
  const encodedHeader = base64Url(
    new TextEncoder().encode(JSON.stringify(header)),
  );
  const encodedPayload = base64Url(
    new TextEncoder().encode(JSON.stringify(payload)),
  );
  const signingInput = `${encodedHeader}.${encodedPayload}`;
  const keyData = pemToBytes(pem);
  const importAlgorithm = algorithm === "ES256"
    ? { name: "ECDSA", namedCurve: "P-256" }
    : { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" };
  const keyBuffer = Uint8Array.from(keyData).buffer;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyBuffer,
    importAlgorithm,
    false,
    ["sign"],
  );
  const signAlgorithm = algorithm === "ES256"
    ? { name: "ECDSA", hash: "SHA-256" }
    : { name: "RSASSA-PKCS1-v1_5" };
  const signature = await crypto.subtle.sign(
    signAlgorithm,
    key,
    new TextEncoder().encode(signingInput),
  );
  return `${signingInput}.${base64Url(new Uint8Array(signature))}`;
}

function decodeJwtPayload(jwt: string): Record<string, unknown> {
  const part = jwt.split(".")[1];
  if (!part) throw new PurchaseVerificationError("invalid signed transaction");
  try {
    const bytes = base64UrlDecode(part);
    return JSON.parse(new TextDecoder().decode(bytes));
  } catch {
    throw new PurchaseVerificationError("invalid signed transaction");
  }
}

function pemToBytes(pem: string): Uint8Array {
  const base64 = pem.replace(/-----[^-]+-----/g, "").replace(/\s/g, "");
  if (!base64) throw new PurchaseVerificationError("invalid server key", 500);
  return Uint8Array.from(atob(base64), (char) => char.charCodeAt(0));
}

function base64Url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replace(
    /=+$/,
    "",
  );
}

function base64UrlDecode(value: string): Uint8Array {
  const normalized = value.replaceAll("-", "+").replaceAll("_", "/");
  const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, "=");
  return Uint8Array.from(atob(padded), (char) => char.charCodeAt(0));
}

async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function millisToIso(value: unknown): string | null {
  const millis = Number(value);
  if (!Number.isFinite(millis) || millis <= 0) return null;
  return new Date(millis).toISOString();
}

function asString(value: unknown, maxLength: number, optional = false): string {
  if (value == null && optional) return "";
  if (typeof value !== "string" || value.length > maxLength) {
    throw new PurchaseVerificationError("invalid request field");
  }
  return value.trim();
}

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
}

function env(name: string, fallback?: string): string {
  const value = Deno.env.get(name)?.trim() || fallback;
  if (!value) {
    throw new PurchaseVerificationError(`${name} is not configured`, 500);
  }
  return value;
}
