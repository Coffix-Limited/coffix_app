export function getPaymentMethod(paymentMethod: string, cardNumber?: string | null) {
  switch (paymentMethod) {
    case "coffixCredit":
      return "Coffix Credit";
    case "card": {
      if (cardNumber) {
        const last4 = cardNumber.replace(/\./g, "").slice(-4);
        return `Credit Card ${last4}`;
      }
      return "Credit Card";
    }
    case "cash":
      return "Cash";
    default:
      return paymentMethod;
  }
}
