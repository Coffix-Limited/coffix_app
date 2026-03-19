# `addCredit(customerId, amount)` behavior

This documents `CoffixCreditService.addCredit` in `functions/src/coffixCredit/service.ts`.

## What it does

- Loads customer doc: `customers/{customerId}`.
- Loads global config from `global/EQ0i4V6H47Ra7yMCdG7B`.
- Reads top-up rules:
  - `minTopUp`
  - `basicDiscount`
  - `discountLevel2`
  - `discountLevel3`
  - `topupLevel2`
  - `topupLevel3`
- Rejects if `amount < minTopUp`.
- Calculates bonus by tier:
  - if `amount < topupLevel2` -> `bonus = amount * basicDiscount`
  - else if `amount < topupLevel3` -> `bonus = amount * discountLevel2`
  - else -> `bonus = amount * discountLevel3`
- Computes `totalAmount = amount + bonus`.
- Runs a Firestore transaction to update credit atomically:
  - reads current `creditAvailable` (defaults to `0`)
  - writes `creditAvailable = current + totalAmount` with merge.

## Notes

- If global config document does not exist, it throws `Global not found`.
- If global config data is empty, it throws `Global data not found`.
- If customer doc does not exist, this method still works and creates/merges the doc with `creditAvailable`.
- This method **adds top-up amount plus promo bonus**, not just the raw top-up amount.

## Example scenarios (`50`, `150`, `600`)

Use this with your actual global values from Firestore:

- If `amount < topupLevel2`:  
  `bonus = amount * basicDiscount`
- If `topupLevel2 <= amount < topupLevel3`:  
  `bonus = amount * discountLevel2`
- If `amount >= topupLevel3`:  
  `bonus = amount * discountLevel3`
- Final added credit is always:  
  `totalAmount = amount + bonus`

Concrete worked example (sample config only):

- `minTopUp = 20`
- `topupLevel2 = 100`
- `topupLevel3 = 500`
- `basicDiscount = 0.10` (10%)
- `discountLevel2 = 0.15` (15%)
- `discountLevel3 = 0.20` (20%)

Then:

- Top-up `50` -> tier 1  
  `bonus = 50 * 0.10 = 5`  
  `totalAmount = 50 + 5 = 55`
- Top-up `150` -> tier 2  
  `bonus = 150 * 0.15 = 22.5`  
  `totalAmount = 150 + 22.5 = 172.5`
- Top-up `600` -> tier 3  
  `bonus = 600 * 0.20 = 120`  
  `totalAmount = 600 + 120 = 720`
