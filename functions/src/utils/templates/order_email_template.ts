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
        max-width: 600px;
        margin: 40px auto;
        background-color: #ffffff;
        border-radius: 8px;
        overflow: hidden;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
      }
      .header {
        background-color: #f15f2c;
        padding: 32px 40px;
        text-align: center;
      }
      .header h1 {
        margin: 0;
        color: #ffffff;
        font-size: 28px;
        letter-spacing: 4px;
        text-transform: uppercase;
      }
      .header p {
        margin: 6px 0 0;
        color: #fff;
        font-size: 13px;
        letter-spacing: 1px;
      }
      .body {
        padding: 32px 40px;
      }
      .section-title {
        font-size: 11px;
        font-weight: 700;
        letter-spacing: 2px;
        text-transform: uppercase;
        color: #999999;
        margin: 0 0 12px;
      }
      .info-table {
        width: 100%;
        border-collapse: collapse;
        margin-bottom: 32px;
      }
      .info-table td {
        padding: 8px 0;
        font-size: 14px;
        border-bottom: 1px solid #f0f0f0;
      }
      .info-table td:first-child {
        color: #888888;
        width: 40%;
      }
      .info-table td:last-child {
        font-weight: 600;
        text-align: right;
      }
      .items-table {
        width: 100%;
        border-collapse: collapse;
        margin-bottom: 24px;
      }
      .items-table thead tr {
        border-bottom: 2px solid #1a1a1a;
      }
      .items-table thead th {
        padding: 8px 0;
        font-size: 11px;
        font-weight: 700;
        letter-spacing: 1px;
        text-transform: uppercase;
        color: #555555;
        text-align: left;
      }
      .items-table thead th.right {
        text-align: right;
      }
      .items-table tbody tr {
        border-bottom: 1px solid #f0f0f0;
      }
      .items-table tbody td {
        padding: 12px 0;
        font-size: 14px;
        vertical-align: top;
      }
      .items-table tbody td.right {
        text-align: right;
      }
      .item-name {
        font-weight: 600;
        color: #1a1a1a;
      }
      .item-modifiers {
        font-size: 12px;
        color: #888888;
        margin-top: 2px;
      }
      .total-row {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 16px 0;
        border-top: 2px solid #1a1a1a;
        margin-top: 4px;
      }
      .total-label {
        font-size: 14px;
        font-weight: 700;
        letter-spacing: 1px;
        text-transform: uppercase;
      }
      .total-amount {
        font-size: 20px;
        font-weight: 700;
        color: #1a1a1a;
      }
      .footer {
        background-color: #f9f9f9;
        border-top: 1px solid #eeeeee;
        padding: 24px 40px;
        text-align: center;
      }
      .footer p {
        margin: 4px 0;
        font-size: 12px;
        color: #aaaaaa;
      }
    </style>
  </head>
  <body>
    <div class="wrapper">
      <div class="header">
        <h1>Coffix</h1>
        <p>Order Receipt</p>
      </div>

      <div class="body">
        <p class="section-title">Order Details</p>
        <table class="info-table">
          <tbody>
            <tr>
              <td>Order Number</td>
              <td>#{{orderNumber}}</td>
            </tr>
            <tr>
              <td>Store</td>
              <td>{{storeName}}</td>
            </tr>
            <tr>
              <td>Address</td>
              <td>{{storeAddress}}</td>
            </tr>
            <tr>
              <td>Date</td>
              <td>{{createdAt}}</td>
            </tr>
            <tr>
              <td>Payment Method</td>
              <td>{{paymentMethod}}</td>
            </tr>
          </tbody>
        </table>

        <p class="section-title">Items</p>
        <table class="items-table">
          <thead>
            <tr>
              <th>Item</th>
              <th class="right">Qty</th>
              <th class="right">Price</th>
              <th class="right">Subtotal</th>
            </tr>
          </thead>
          <tbody>
            {{items}}
          </tbody>
        </table>

        <div class="total-row">
          <span class="total-label">Total</span>
          <span class="total-amount">{{total}}</span>
        </div>
      </div>

      <div class="footer">
        <p>Thank you for choosing Coffix!</p>
        <p>This is an automated receipt — please do not reply to this email.</p>
      </div>
    </div>
  </body>
</html>`;
