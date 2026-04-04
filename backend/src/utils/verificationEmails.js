function buildApprovalEmail(request) {
  const subject = "Your Common Facilities account has been approved";
  const text = [
    `Hello ${request.name},`,
    "",
    "Your Common Facilities account request has been approved.",
    `Email: ${request.email}`,
    `Category: ${request.category}`,
    "",
    "You can now sign in using your email and the password you set during registration.",
  ].join("\n");

  const html = `
    <p>Hello ${request.name},</p>
    <p>Your Common Facilities account request has been approved.</p>
    <ul>
      <li><strong>Email:</strong> ${request.email}</li>
      <li><strong>Category:</strong> ${request.category}</li>
    </ul>
    <p>You can now sign in using your email and the password you set during registration.</p>
  `;

  return { subject, text, html };
}

function buildDeclineEmail(request) {
  const subject = "Your Common Facilities account request was declined";
  const text = [
    `Hello ${request.name},`,
    "",
    "Your Common Facilities account request was declined by the admin team.",
    `Email: ${request.email}`,
    `Category: ${request.category}`,
  ].join("\n");

  const html = `
    <p>Hello ${request.name},</p>
    <p>Your Common Facilities account request was declined by the admin team.</p>
    <ul>
      <li><strong>Email:</strong> ${request.email}</li>
      <li><strong>Category:</strong> ${request.category}</li>
    </ul>
  `;

  return { subject, text, html };
}

function buildVerificationEmail(request) {
  if (request.status === "approved") {
    return buildApprovalEmail(request);
  }

  return buildDeclineEmail(request);
}

module.exports = {
  buildApprovalEmail,
  buildDeclineEmail,
  buildVerificationEmail,
};