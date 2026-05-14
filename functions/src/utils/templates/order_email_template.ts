export const orderEmailTemplate = `<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Your Coffix Order Receipt</title>
    <style>
      body {
        margin: 0;
        padding: 0;
        background-color: #f5f5f5;
        font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
        color: #333333;
      }
      .wrapper {
        max-width: 480px;
        margin: 40px auto;
        background-color: #ffffff;
        border: 1px solid #cccccc;
      }
      .docket-header {
        padding: 20px 24px 16px;
        text-align: center;
        border-bottom: 1px solid #cccccc;
      }
      .order-number {
        font-size: 11px;
        color:rgb(0, 0, 0);
        margin: 0 0 8px;
      }
      .customer-name {
        font-size: 20px;
        font-weight: 700;
        color: #1a1a1a;
        margin: 0;
      }
      .items-section {
        padding: 0 24px;
        border-bottom: 1px solid #cccccc;
      }
      .item-row {
        display: table;
        width: 100%;
        padding: 10px 0;
        border-bottom: 1px solid #eeeeee;
        box-sizing: border-box;
      }
      .item-row:last-child {
        border-bottom: none;
      }
      .item-left {
        display: table-cell;
        width: 75%;
        vertical-align: top;
      }
      .item-right {
        display: table-cell;
        width: 25%;
        text-align: right;
        vertical-align: top;
        font-size: 13px;
        color: #1a1a1a;
      }
      .item-name {
        font-size: 13px;
        font-weight: 700;
        color: #1a1a1a;
      }
      .item-modifiers {
        font-size: 11px;
        color:rgb(0, 0, 0);
        margin-top: 2px;
      }
      .total-section {
        padding: 12px 24px;
        text-align: right;
        border-bottom: 1px solid #cccccc;
      }
      .total-text {
        font-size: 14px;
        font-weight: 700;
        color: #1a1a1a;
      }
      .meta-section {
        padding: 12px 24px 16px;
      }
      .meta-line {
        font-size: 11px;
        color: #333333;
        margin: 4px 0;
      }
      .footer {
        background-color: #f9f9f9;
        border-top: 1px solid #cccccc;
        padding: 16px 24px;
        text-align: center;
      }
      .footer p {
        margin: 4px 0;
        font-size: 11px;
        color: #aaaaaa;
      }
    </style>
  </head>
  <body>
    <div class="wrapper">
      <div class="docket-header">
        <p class="order-number">Order #: {{orderNumber}}</p>
        <p class="customer-name">{{customerName}}</p>
      </div>

      <div class="items-section">
        {{items}}
      </div>

      <div class="total-section">
        <span class="total-text">Total: {{total}}</span>
      </div>

      <div class="meta-section">
        <p class="meta-line">Paid by: {{paymentMethod}}</p>
        <p class="meta-line">Order Time: {{createdAt}}</p>
        {{serviceTimeLine}}
      </div>

      <div class="footer">
        <p>Thank you for choosing Coffix!</p>
        <p>This is an automated receipt — please do not reply to this email.</p>
      </div>
    </div>
  </body>
</html>`;
