const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const crypto = require("crypto");

let nodemailer = null;
try {
  // Optional dependency for email OTP.
  nodemailer = require("nodemailer");
} catch (_) {
  nodemailer = null;
}

admin.initializeApp();

const B2_KEY_ID = process.env.B2_KEY_ID || "";
const B2_APP_KEY = process.env.B2_APP_KEY || "";
const B2_BUCKET_ID = process.env.B2_BUCKET_ID || "";
const B2_BUCKET_NAME = process.env.B2_BUCKET_NAME || "";

const OTP_SECRET = process.env.OTP_SECRET || "";
const OTP_TTL_SECONDS = Math.min(Math.max(Number(process.env.OTP_TTL_SECONDS || 600), 60), 1800);
const OTP_DEBUG_RETURN = String(process.env.OTP_DEBUG_RETURN || "").toLowerCase() === "true";

const SMTP_HOST = process.env.SMTP_HOST || "";
const SMTP_PORT = Number(process.env.SMTP_PORT || 587);
const SMTP_SECURE = String(process.env.SMTP_SECURE || "").toLowerCase() === "true";
const SMTP_USER = process.env.SMTP_USER || "";
const SMTP_PASS = process.env.SMTP_PASS || "";
const SMTP_FROM = process.env.SMTP_FROM || "";

function setCors(res) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Authorization, Content-Type");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
}

class HttpError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

function getJsonBody(req) {
  if (req.body && typeof req.body === "object") return req.body;
  if (typeof req.body === "string" && req.body.trim()) {
    try {
      return JSON.parse(req.body);
    } catch (_) {
      return {};
    }
  }
  return {};
}

async function verifyFirebaseToken(req) {
  const authHeader = req.headers.authorization || "";
  if (!authHeader.startsWith("Bearer ")) {
    throw new HttpError(401, "auth_missing_bearer", "Missing bearer token");
  }
  const idToken = authHeader.slice(7);
  try {
    return await admin.auth().verifyIdToken(idToken);
  } catch (error) {
    throw new HttpError(401, "auth_invalid_token", error.message || "Invalid Firebase token");
  }
}

function assertConfig() {
  if (!B2_KEY_ID || !B2_APP_KEY || !B2_BUCKET_ID || !B2_BUCKET_NAME) {
    throw new HttpError(500, "b2_config_missing", "Missing B2 environment variables");
  }
}

function sanitizePath(path) {
  if (typeof path !== "string") return "";
  const trimmed = path.trim().replace(/\\/g, "/");
  if (!trimmed || trimmed.includes("..")) return "";
  if (trimmed.startsWith("/")) return "";
  return trimmed;
}

function encodePath(path) {
  return path
    .split("/")
    .map((segment) => encodeURIComponent(segment))
    .join("/");
}

async function b2AuthorizeAccount() {
  const credentials = Buffer.from(`${B2_KEY_ID}:${B2_APP_KEY}`).toString("base64");
  const response = await fetch(
    "https://api.backblazeb2.com/b2api/v2/b2_authorize_account",
    {
      method: "GET",
      headers: {
        Authorization: `Basic ${credentials}`,
      },
    },
  );

  if (!response.ok) {
    const body = await response.text();
    throw new HttpError(
      502,
      "b2_authorize_failed",
      `b2_authorize_account failed (${response.status}): ${body}`,
    );
  }

  return response.json();
}

async function isSuperAdminUid(uid) {
  const coderDoc = await admin.firestore().collection("coders").doc(uid).get();
  if (coderDoc.exists) {
    const data = coderDoc.data() || {};
    const role = String(data.role || "").toLowerCase();
    if (data.isSuperAdmin === true || role === "super_admin" || role === "superadmin") {
      return true;
    }
  }

  const mainAdminDoc = await admin.firestore().collection("main_admins").doc(uid).get();
  return mainAdminDoc.exists;
}

function isBootstrapSuperAdminEmail(email) {
  return String(email || "").trim().toLowerCase() === "digitrixmedia05@gmail.com";
}

async function isSuperAdminDecoded(decoded) {
  if (!decoded || !decoded.uid) return false;
  if (isBootstrapSuperAdminEmail(decoded.email)) return true;
  return isSuperAdminUid(decoded.uid);
}

function hashPin(uid, pin) {
  return crypto.createHash("sha256").update(`${uid}::${pin}`).digest("hex");
}

function assertOtpConfig() {
  if (!OTP_SECRET && !OTP_DEBUG_RETURN) {
    throw new HttpError(500, "otp_secret_missing", "Missing OTP_SECRET env var");
  }
}

function hashOtp(uid, otp) {
  const secret = OTP_SECRET || "dev_secret";
  return crypto.createHash("sha256").update(`${uid}::${otp}::${secret}`).digest("hex");
}

function generateOtp() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function assertSmtpConfig() {
  if (!nodemailer) {
    throw new HttpError(500, "nodemailer_missing", "nodemailer dependency missing in functions");
  }
  if (!SMTP_HOST || !SMTP_USER || !SMTP_PASS || !SMTP_FROM) {
    throw new HttpError(
      500,
      "smtp_config_missing",
      "Missing SMTP env vars (SMTP_HOST, SMTP_USER, SMTP_PASS, SMTP_FROM)",
    );
  }
}

function getMailer() {
  assertSmtpConfig();
  return nodemailer.createTransport({
    host: SMTP_HOST,
    port: SMTP_PORT,
    secure: SMTP_SECURE,
    auth: { user: SMTP_USER, pass: SMTP_PASS },
  });
}

async function b2ListAndDeleteExactFile(auth, fileName) {
  let nextFileName = fileName;
  let nextFileId = null;

  while (true) {
    const listRes = await fetch(`${auth.apiUrl}/b2api/v2/b2_list_file_versions`, {
      method: "POST",
      headers: {
        Authorization: auth.authorizationToken,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        bucketId: B2_BUCKET_ID,
        startFileName: nextFileName,
        startFileId: nextFileId,
        maxFileCount: 100,
      }),
    });

    if (!listRes.ok) {
      const body = await listRes.text();
      throw new HttpError(502, "b2_list_versions_failed", body);
    }

    const listData = await listRes.json();
    const files = Array.isArray(listData.files) ? listData.files : [];

    for (const file of files) {
      if (!file || file.fileName !== fileName || !file.fileId) continue;
      const delRes = await fetch(`${auth.apiUrl}/b2api/v2/b2_delete_file_version`, {
        method: "POST",
        headers: {
          Authorization: auth.authorizationToken,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          fileName: file.fileName,
          fileId: file.fileId,
        }),
      });
      if (!delRes.ok) {
        const body = await delRes.text();
        throw new HttpError(502, "b2_delete_file_version_failed", body);
      }
    }

    nextFileName = listData.nextFileName || null;
    nextFileId = listData.nextFileId || null;
    if (!nextFileName || nextFileName !== fileName) break;
  }
}

async function deleteQueryInBatches(db, query, batchSize, onDoc) {
  const size = Math.min(Math.max(Number(batchSize || 400), 1), 450);
  let deleted = 0;
  while (true) {
    const snap = await query.limit(size).get();
    if (snap.empty) break;
    const batch = db.batch();
    snap.docs.forEach((d) => {
      if (onDoc) onDoc(d);
      batch.delete(d.ref);
    });
    await batch.commit();
    deleted += snap.size;
    if (snap.size < size) break;
  }
  return deleted;
}

async function collectB2PathsFromAttendanceQuery(query, outSet) {
  let lastDoc = null;
  while (true) {
    let q = query.orderBy(admin.firestore.FieldPath.documentId()).limit(400);
    if (lastDoc) q = q.startAfter(lastDoc);
    const snap = await q.get();
    if (snap.empty) break;
    for (const doc of snap.docs) {
      const data = doc.data() || {};
      const p1 = sanitizePath(String(data.verificationSelfie || ""));
      const p2 = sanitizePath(String(data.photoPath || ""));
      if (p1) outSet.add(p1);
      if (p2) outSet.add(p2);
    }
    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.size < 400) break;
  }
}

exports.hardDeleteInstitute = onRequest(
  { timeoutSeconds: 540, memory: "1GiB", region: "us-central1" },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") return res.status(204).send("");
    if (req.method !== "POST") return res.status(405).send("Method not allowed");

    try {
      assertConfig();
      const decoded = await verifyFirebaseToken(req);
      const canDelete = await isSuperAdminUid(decoded.uid);
      if (!canDelete) {
        throw new HttpError(403, "permission_denied", "Only super admin can hard-delete institute");
      }

      const body = getJsonBody(req);
      const instituteId = String(body.instituteId || "").trim();
      if (!instituteId) {
        throw new HttpError(400, "invalid_institute_id", "instituteId is required");
      }

      const db = admin.firestore();
      const instituteRef = db.collection("institutes").doc(instituteId);
      const instituteSnap = await instituteRef.get();
      if (!instituteSnap.exists) {
        throw new HttpError(404, "institute_not_found", "Institute not found");
      }
      const instituteData = instituteSnap.data() || {};
      const instituteName = String(instituteData.name || instituteData.instituteName || "").trim();

      const counts = {
        b2FilesDeleted: 0,
        authUsersDeleted: 0,
        userDocsDeleted: 0,
        oldAttendanceDocsDeleted: 0,
        errorLogsDeleted: 0,
      };

      const attendanceSnap = await instituteRef.collection("attendance").get();
      const b2Paths = new Set();
      attendanceSnap.forEach((doc) => {
        const data = doc.data() || {};
        const p1 = sanitizePath(String(data.verificationSelfie || ""));
        const p2 = sanitizePath(String(data.photoPath || ""));
        if (p1) b2Paths.add(p1);
        if (p2) b2Paths.add(p2);
      });

      // Also collect B2 paths from legacy top-level attendance docs.
      const attendanceCollection = db.collection("attendance");
      await collectB2PathsFromAttendanceQuery(
        attendanceCollection.where("instituteId", "==", instituteId),
        b2Paths,
      );
      if (instituteName) {
        await collectB2PathsFromAttendanceQuery(
          attendanceCollection.where("instituteName", "==", instituteName),
          b2Paths,
        );
      }
      await collectB2PathsFromAttendanceQuery(
        attendanceCollection.where("instituteName", "==", instituteId),
        b2Paths,
      );

      const b2Auth = await b2AuthorizeAccount();
      for (const fileName of b2Paths) {
        try {
          await b2ListAndDeleteExactFile(b2Auth, fileName);
          counts.b2FilesDeleted += 1;
        } catch (_) {
          // Continue best-effort cleanup for remaining files.
        }
      }

      const instituteUsersSnap = await instituteRef.collection("users").get();
      const candidateUids = new Set();
      instituteUsersSnap.forEach((doc) => candidateUids.add(doc.id));

      await deleteQueryInBatches(
        db,
        db.collection("users").where("instituteId", "==", instituteId),
        400,
        (doc) => {
          candidateUids.add(doc.id);
          counts.userDocsDeleted += 1;
        },
      );

      // Best-effort cleanup for legacy top-level attendance docs.
      counts.oldAttendanceDocsDeleted += await deleteQueryInBatches(
        db,
        attendanceCollection.where("instituteId", "==", instituteId),
        400,
      );
      if (instituteName) {
        counts.oldAttendanceDocsDeleted += await deleteQueryInBatches(
          db,
          attendanceCollection.where("instituteName", "==", instituteName),
          400,
        );
      }
      counts.oldAttendanceDocsDeleted += await deleteQueryInBatches(
        db,
        attendanceCollection.where("instituteName", "==", instituteId),
        400,
      );

      // Best-effort cleanup for error logs linked to institute.
      const errorLogs = db.collection("error_logs");
      counts.errorLogsDeleted += await deleteQueryInBatches(
        db,
        errorLogs.where("instituteId", "==", instituteId),
        400,
      );

      for (const uid of candidateUids) {
        try {
          await admin.auth().deleteUser(uid);
          counts.authUsersDeleted += 1;
        } catch (_) {
          // If user does not exist in Auth, ignore and continue.
        }
      }

      await db.recursiveDelete(instituteRef);

      return res.status(200).json({
        success: true,
        message: `Institute ${instituteId} hard-deleted`,
        counts,
      });
    } catch (error) {
      const status = Number.isInteger(error?.status) ? error.status : 500;
      const code = error?.code || "internal_error";
      return res.status(status).json({ error: error.message || "Internal error", code });
    }
  },
);

exports.b2GetUploadUrl = onRequest(async (req, res) => {
  setCors(res);
  if (req.method === "OPTIONS") return res.status(204).send("");
  if (req.method !== "POST") return res.status(405).send("Method not allowed");

  try {
    assertConfig();
    await verifyFirebaseToken(req);

    const body = getJsonBody(req);
    const objectPath = sanitizePath(body.objectPath || "");
    if (!objectPath) {
      return res.status(400).json({ error: "Invalid objectPath" });
    }

    const auth = await b2AuthorizeAccount();
    const uploadUrlResponse = await fetch(`${auth.apiUrl}/b2api/v2/b2_get_upload_url`, {
      method: "POST",
      headers: {
        Authorization: auth.authorizationToken,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        bucketId: B2_BUCKET_ID,
      }),
    });

    if (!uploadUrlResponse.ok) {
      const body = await uploadUrlResponse.text();
      throw new HttpError(
        502,
        "b2_get_upload_url_failed",
        `b2_get_upload_url failed (${uploadUrlResponse.status}): ${body}`,
      );
    }

    const uploadData = await uploadUrlResponse.json();
    return res.status(200).json({
      uploadUrl: uploadData.uploadUrl,
      authorizationToken: uploadData.authorizationToken,
      fileName: objectPath,
    });
  } catch (error) {
    const status = Number.isInteger(error?.status) ? error.status : 500;
    const code = error?.code || "internal_error";
    return res.status(status).json({ error: error.message || "Internal error", code });
  }
});

exports.b2GetDownloadUrl = onRequest(async (req, res) => {
  setCors(res);
  if (req.method === "OPTIONS") return res.status(204).send("");
  if (req.method !== "POST") return res.status(405).send("Method not allowed");

  try {
    assertConfig();
    await verifyFirebaseToken(req);

    const body = getJsonBody(req);
    const objectPath = sanitizePath(body.objectPath || "");
    const validForSecondsRaw = Number(body.validForSeconds || 600);
    const validForSeconds = Math.min(Math.max(validForSecondsRaw, 60), 3600);

    if (!objectPath) {
      return res.status(400).json({ error: "Invalid objectPath" });
    }

    const auth = await b2AuthorizeAccount();
    const downloadAuthResponse = await fetch(
      `${auth.apiUrl}/b2api/v2/b2_get_download_authorization`,
      {
        method: "POST",
        headers: {
          Authorization: auth.authorizationToken,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          bucketId: B2_BUCKET_ID,
          fileNamePrefix: objectPath,
          validDurationInSeconds: validForSeconds,
        }),
      },
    );

    if (!downloadAuthResponse.ok) {
      const bodyText = await downloadAuthResponse.text();
      throw new Error(
        `b2_get_download_authorization failed (${downloadAuthResponse.status}): ${bodyText}`,
      );
    }

    const downloadAuthData = await downloadAuthResponse.json();
    const encodedPath = encodePath(objectPath);
    const downloadUrl =
      `${auth.downloadUrl}/file/${encodeURIComponent(B2_BUCKET_NAME)}/${encodedPath}` +
      `?Authorization=${encodeURIComponent(downloadAuthData.authorizationToken)}`;

    return res.status(200).json({ downloadUrl });
  } catch (error) {
    const status = Number.isInteger(error?.status) ? error.status : 500;
    const code = error?.code || "internal_error";
    return res.status(status).json({ error: error.message || "Internal error", code });
  }
});

exports.superAdminHasPin = onRequest(
  { timeoutSeconds: 60, memory: "256MiB", region: "us-central1" },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") return res.status(204).send("");
    if (req.method !== "POST") return res.status(405).send("Method not allowed");

    try {
      const decoded = await verifyFirebaseToken(req);
      const allowed = await isSuperAdminDecoded(decoded);
      if (!allowed) throw new HttpError(403, "permission_denied", "Only super admin can use PIN auth");

      const doc = await admin.firestore().collection("coders").doc(decoded.uid).get();
      const data = doc.data() || {};
      const enabled = data.sa_pin_enabled === true;
      const hash = String(data.sa_pin_hash || "");
      return res.status(200).json({ hasPin: enabled && hash.length > 0 });
    } catch (error) {
      const status = Number.isInteger(error?.status) ? error.status : 500;
      const code = error?.code || "internal_error";
      return res.status(status).json({ error: error.message || "Internal error", code });
    }
  },
);

exports.superAdminSetPin = onRequest(
  { timeoutSeconds: 60, memory: "256MiB", region: "us-central1" },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") return res.status(204).send("");
    if (req.method !== "POST") return res.status(405).send("Method not allowed");

    try {
      const decoded = await verifyFirebaseToken(req);
      const allowed = await isSuperAdminDecoded(decoded);
      if (!allowed) throw new HttpError(403, "permission_denied", "Only super admin can set PIN");

      const body = getJsonBody(req);
      const pin = String(body.pin || "").trim();
      if (!/^\d{4}$/.test(pin)) throw new HttpError(400, "invalid_pin", "PIN must be exactly 4 digits");

      const coderRef = admin.firestore().collection("coders").doc(decoded.uid);
      const snap = await coderRef.get();
      const existing = snap.data() || {};
      if (existing.sa_pin_enabled === true && String(existing.sa_pin_hash || "").length > 0) {
        throw new HttpError(409, "pin_already_set", "PIN already set. Use reset flow to change PIN.");
      }

      await coderRef.set(
        {
          uid: decoded.uid,
          email: String(decoded.email || "").trim().toLowerCase(),
          ...(isBootstrapSuperAdminEmail(decoded.email)
            ? { role: "super_admin", isSuperAdmin: true }
            : {}),
          sa_pin_enabled: true,
          sa_pin_hash: hashPin(decoded.uid, pin),
          sa_pin_updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      return res.status(200).json({ success: true });
    } catch (error) {
      const status = Number.isInteger(error?.status) ? error.status : 500;
      const code = error?.code || "internal_error";
      return res.status(status).json({ error: error.message || "Internal error", code });
    }
  },
);

exports.superAdminVerifyPin = onRequest(
  { timeoutSeconds: 60, memory: "256MiB", region: "us-central1" },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") return res.status(204).send("");
    if (req.method !== "POST") return res.status(405).send("Method not allowed");

    try {
      const decoded = await verifyFirebaseToken(req);
      const allowed = await isSuperAdminDecoded(decoded);
      if (!allowed) throw new HttpError(403, "permission_denied", "Only super admin can verify PIN");

      const body = getJsonBody(req);
      const pin = String(body.pin || "").trim();
      if (!/^\d{4}$/.test(pin)) throw new HttpError(400, "invalid_pin", "PIN must be exactly 4 digits");

      const snap = await admin.firestore().collection("coders").doc(decoded.uid).get();
      const data = snap.data() || {};
      const enabled = data.sa_pin_enabled === true;
      const storedHash = String(data.sa_pin_hash || "");
      const ok = enabled && storedHash.length > 0 && storedHash === hashPin(decoded.uid, pin);
      return res.status(200).json({ ok });
    } catch (error) {
      const status = Number.isInteger(error?.status) ? error.status : 500;
      const code = error?.code || "internal_error";
      return res.status(status).json({ error: error.message || "Internal error", code });
    }
  },
);

exports.superAdminSendPinResetOtp = onRequest(
  { timeoutSeconds: 60, memory: "256MiB", region: "us-central1" },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") return res.status(204).send("");
    if (req.method !== "POST") return res.status(405).send("Method not allowed");

    try {
      assertOtpConfig();
      const decoded = await verifyFirebaseToken(req);
      const allowed = await isSuperAdminDecoded(decoded);
      if (!allowed) throw new HttpError(403, "permission_denied", "Only super admin can reset PIN");

      const otp = generateOtp();
      const expiresAt = admin.firestore.Timestamp.fromDate(new Date(Date.now() + OTP_TTL_SECONDS * 1000));
      const coderRef = admin.firestore().collection("coders").doc(decoded.uid);
      await coderRef.set(
        {
          sa_pin_reset_otp_hash: hashOtp(decoded.uid, otp),
          sa_pin_reset_otp_expiresAt: expiresAt,
          sa_pin_reset_otp_attempts: 0,
          sa_pin_reset_requestedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      const email = String(decoded.email || "").trim();
      if (!email) throw new HttpError(400, "email_missing", "User email missing in token");

      if (!OTP_DEBUG_RETURN) {
        const mailer = getMailer();
        await mailer.sendMail({
          from: SMTP_FROM,
          to: email,
          subject: "Your Super Admin PIN Reset Code",
          text: `Your OTP is ${otp}. It expires in ${Math.floor(OTP_TTL_SECONDS / 60)} minutes.`,
        });
      }

      return res.status(200).json({ success: true, ...(OTP_DEBUG_RETURN ? { otp } : {}) });
    } catch (error) {
      const status = Number.isInteger(error?.status) ? error.status : 500;
      const code = error?.code || "internal_error";
      return res.status(status).json({ error: error.message || "Internal error", code });
    }
  },
);

exports.superAdminResetPinWithOtp = onRequest(
  { timeoutSeconds: 60, memory: "256MiB", region: "us-central1" },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") return res.status(204).send("");
    if (req.method !== "POST") return res.status(405).send("Method not allowed");

    try {
      assertOtpConfig();
      const decoded = await verifyFirebaseToken(req);
      const allowed = await isSuperAdminDecoded(decoded);
      if (!allowed) throw new HttpError(403, "permission_denied", "Only super admin can reset PIN");

      const body = getJsonBody(req);
      const otp = String(body.otp || "").trim();
      const newPin = String(body.newPin || "").trim();
      if (!/^\d{6}$/.test(otp)) throw new HttpError(400, "invalid_otp", "OTP must be 6 digits");
      if (!/^\d{4}$/.test(newPin)) throw new HttpError(400, "invalid_pin", "PIN must be exactly 4 digits");

      const coderRef = admin.firestore().collection("coders").doc(decoded.uid);
      const snap = await coderRef.get();
      const data = snap.data() || {};

      const expiresAt = data.sa_pin_reset_otp_expiresAt;
      if (!expiresAt || typeof expiresAt.toMillis !== "function") {
        throw new HttpError(400, "otp_not_requested", "OTP not requested");
      }
      if (expiresAt.toMillis() < Date.now()) {
        throw new HttpError(400, "otp_expired", "OTP expired. Request a new OTP.");
      }

      const attempts = Number(data.sa_pin_reset_otp_attempts || 0);
      if (attempts >= 5) {
        throw new HttpError(429, "otp_too_many_attempts", "Too many incorrect attempts. Request a new OTP.");
      }

      const expectedHash = String(data.sa_pin_reset_otp_hash || "");
      const providedHash = hashOtp(decoded.uid, otp);
      if (!expectedHash || expectedHash !== providedHash) {
        await coderRef.set(
          { sa_pin_reset_otp_attempts: attempts + 1 },
          { merge: true },
        );
        throw new HttpError(400, "otp_invalid", "Incorrect OTP");
      }

      await coderRef.set(
        {
          sa_pin_enabled: true,
          sa_pin_hash: hashPin(decoded.uid, newPin),
          sa_pin_updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          sa_pin_reset_otp_hash: admin.firestore.FieldValue.delete(),
          sa_pin_reset_otp_expiresAt: admin.firestore.FieldValue.delete(),
          sa_pin_reset_otp_attempts: admin.firestore.FieldValue.delete(),
          sa_pin_reset_requestedAt: admin.firestore.FieldValue.delete(),
          sa_pin_reset_completedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      return res.status(200).json({ success: true });
    } catch (error) {
      const status = Number.isInteger(error?.status) ? error.status : 500;
      const code = error?.code || "internal_error";
      return res.status(status).json({ error: error.message || "Internal error", code });
    }
  },
);
