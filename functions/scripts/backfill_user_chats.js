const admin = require("firebase-admin");

admin.initializeApp({
  databaseURL: "https://questionmaker-a821f.firebaseio.com",
});

function rulesEmailKey(email) {
  return String(email || "")
    .trim()
    .toLowerCase()
    .replace(/\./g, ",");
}

function dartEmailKey(email) {
  return Buffer.from(String(email || "").trim().toLowerCase(), "utf8")
    .toString("base64url")
    .replace(/=/g, "");
}

function emailsFrom(raw) {
  if (Array.isArray(raw)) {
    return raw.map((e) => String(e || "").toLowerCase().trim()).filter(Boolean);
  }
  if (raw && typeof raw === "object") {
    return Object.keys(raw)
      .sort()
      .map((k) => String(raw[k] || "").toLowerCase().trim())
      .filter(Boolean);
  }
  return [];
}

function emailsFromChatId(chatId) {
  try {
    const padded = chatId + "=".repeat((4 - (chatId.length % 4)) % 4);
    const raw = Buffer.from(padded, "base64url").toString("utf8");
    const emails = raw
      .split("|")
      .map((e) => e.trim().toLowerCase())
      .filter((e) => e.includes("@"));
    return emails.length === 2 ? emails.sort() : [];
  } catch (_) {
    return [];
  }
}

async function main() {
  const db = admin.database();
  const snap = await db.ref("chatThreads").once("value");
  const threads = snap.val() || {};
  const updates = {};
  let rows = 0;
  for (const [chatId, thread] of Object.entries(threads)) {
    if (!thread || typeof thread !== "object") continue;
    const emails = emailsFrom(thread.participantEmails).slice(0, 2);
    const sorted = (emails.length >= 2 ? emails : emailsFromChatId(chatId)).slice(0, 2);
    if (sorted.length < 2) continue;
    if (emails.length < 2) {
      updates[`chatThreads/${chatId}/participantEmails`] = sorted;
    }
    if (!thread.lastMessageText && !thread.lastMessageAt) continue;
    for (const email of sorted) {
      const unreadMap = thread.unread && typeof thread.unread === "object"
        ? thread.unread
        : {};
      const unread = Number(unreadMap[dartEmailKey(email)] || 0);
      updates[`userChats/${rulesEmailKey(email)}/${chatId}`] = {
        participantEmails: sorted,
        lastMessageText: thread.lastMessageText || "",
        lastMessageAt: thread.lastMessageAt || 0,
        updatedAt: thread.updatedAt || 0,
        unread,
      };
      rows += 1;
    }
  }
  const keys = Object.keys(updates);
  const chunkSize = 200;
  for (let i = 0; i < keys.length; i += chunkSize) {
    const chunk = {};
    for (const key of keys.slice(i, i + chunkSize)) chunk[key] = updates[key];
    await db.ref().update(chunk);
  }
  console.log(`backfilled ${rows} inbox rows from ${Object.keys(threads).length} threads`);
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
