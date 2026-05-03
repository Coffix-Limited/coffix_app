export const invoiceEmailTemplate = `<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Your Coffix Tax Invoice</title>
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
      .store-header {
        padding: 20px 24px 16px;
        text-align: center;
        border-bottom: 1px solid #cccccc;
      }
      .store-name {
        font-size: 20px;
        font-weight: 700;
        color: #1a1a1a;
        margin: 0 0 4px;
      }
      .store-address {
        font-size: 11px;
        color: #333333;
        margin: 0 0 2px;
      }
      .store-gst {
        font-size: 11px;
        color: #333333;
        margin: 0;
      }
      .tax-invoice-header {
        padding: 16px 24px;
        text-align: center;
        border-bottom: 1px solid #cccccc;
      }
      .tax-invoice-number {
        font-size: 16px;
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
        font-size: 11px;
        color: #1a1a1a;
      }
      .item-name {
        font-size: 11px;
        font-weight: 700;
        color: #1a1a1a;
      }
      .item-modifiers {
        font-size: 11px;
        color: #333333;
        margin-top: 2px;
      }
      .total-section {
        padding: 12px 24px 4px;
        text-align: right;
        border-bottom: 1px solid #cccccc;
      }
      .total-text {
        font-size: 14px;
        font-weight: 700;
        color: #1a1a1a;
        display: block;
      }
      .gst-text {
        font-size: 11px;
        color: #333333;
        display: block;
        margin-top: 4px;
        padding-bottom: 12px;
      }
      .meta-section {
        padding: 12px 24px 16px;
        border-bottom: 1px solid #cccccc;
      }
      .meta-line {
        font-size: 11px;
        color: #333333;
        margin: 4px 0;
      }
      .thank-you-section {
        padding: 16px 24px;
        text-align: center;
        border-bottom: 1px solid #cccccc;
      }
      .thank-you-text {
        font-size: 14px;
        color: #333333;
        margin: 0 0 6px;
      }
      .website-text {
        font-size: 11px;
        font-weight: 700;
        color: #1a1a1a;
        margin: 0;
      }
    </style>
  </head>
  <body>
    <div class="wrapper">
      <div class="store-header">
        <p class="store-name">Coffix</p>
        <p class="store-address">{{invoiceText}}</p>
        <p class="store-gst">GST: {{gst}}</p>
      </div>

      <div class="tax-invoice-header">
        <p class="tax-invoice-number">Tax Invoice: {{transactionNumber}}</p>
      </div>

      <div class="items-section">
        {{items}}
      </div>

      <div class="total-section">
        <span class="total-text">Total: {{total}}</span>
        <span class="gst-text">{{gstLine}}</span>
      </div>

      <div class="meta-section">
        <p class="meta-line">Paid by: {{paymentMethod}}</p>
        <p class="meta-line">Order Time: {{createdAt}}</p>
        {{serviceTimeLine}}
      </div>

      <div class="thank-you-section">
        <p class="thank-you-text">Thank you for your purchase</p>
        <p class="website-text">coffix.co.nz</p>
      </div>
    </div>
  </body>
</html>`;
