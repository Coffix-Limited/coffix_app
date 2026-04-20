export const topupEmailTemplate = `
<h2 style="margin:0 0 16px;font-size:18px;font-weight:700;color:#1a1a1a;">TopUp Invoice #{{transactionNumber}}</h2>
<p style="margin:0 0 16px;font-size:14px;color:#333333;">Hi {{customerName}},</p>
<table width="100%" cellpadding="0" cellspacing="0" border="0" style="border-collapse:collapse;border:1px solid #e0e0e0;">
  <tr style="border-bottom:1px solid #e0e0e0;">
    <td style="padding:10px 12px;font-size:13px;color:#555555;">TopUp Amount</td>
    <td style="padding:10px 12px;font-size:13px;font-weight:700;color:#1a1a1a;text-align:right;">{{amount}}</td>
  </tr>
  <tr style="border-bottom:1px solid #e0e0e0;">
    <td style="padding:10px 12px;font-size:13px;color:#555555;">Bonus Amount</td>
    <td style="padding:10px 12px;font-size:13px;font-weight:700;color:#1a1a1a;text-align:right;">{{bonusAmount}}</td>
  </tr>
  <tr>
    <td style="padding:10px 12px;font-size:14px;font-weight:700;color:#1a1a1a;">Total Amount Added</td>
    <td style="padding:10px 12px;font-size:14px;font-weight:700;color:#1a1a1a;text-align:right;">{{totalAmount}}</td>
  </tr>
</table>
<p style="margin:16px 0 0;font-size:12px;color:#666666;">Date: {{createdAt}}</p>
`;
