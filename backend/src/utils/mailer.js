// Shared Nodemailer transport for backend notification emails.
const nodemailer = require("nodemailer");

function createMailerTransport() {
  const host = process.env.SMTP_HOST;
  const port = Number(process.env.SMTP_PORT || 587);
  const secure = String(process.env.SMTP_SECURE || "false") === "true";

  if (host) {
    return nodemailer.createTransport({
      host,
      port,
      secure,
      auth: process.env.SMTP_USER
        ? {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS,
          }
        : undefined,
    });
  }

  return nodemailer.createTransport({ jsonTransport: true });
}

const mailerTransport = createMailerTransport();

async function sendMail({ to, subject, text, html }) {
  if (
    String(process.env.NODE_ENV || "development").toLowerCase() === "production" &&
    process.env.SMTP_HOST == null
  ) {
    throw new Error(
      "SMTP_HOST is not configured. Set SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS and SMTP_FROM in the production environment."
    );
  }

  return mailerTransport.sendMail({
    from: process.env.SMTP_FROM || process.env.SMTP_USER || "no-reply@example.com",
    to,
    subject,
    text,
    html,
  });
}

module.exports = {
  sendMail,
};
