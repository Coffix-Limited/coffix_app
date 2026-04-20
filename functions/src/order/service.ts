export function getPaymentMethod(paymentMethod: string) {
  switch (paymentMethod) {
    case "coffixCredit":
      return "Coffix Credit";
    case "card":
      return "Card";
    case "cash":
      return "Cash";
    default:
      return paymentMethod;
  }
}
