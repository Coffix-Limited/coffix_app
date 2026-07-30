import * as dotenv from "dotenv";
import * as path from "path";

dotenv.config({ path: path.join(__dirname, "..", "..", "..", ".env") });
dotenv.config({ path: path.join(__dirname, "..", "..", "..", ".env.local") });

import { firestore } from "../../config/firebaseAdmin";

const PRODUCT_CATEGORIES = [
  { id: "iced", name: "Iced", order: 0 },
  { id: "hot", name: "Hot", order: 1 },
  { id: "tea", name: "Tea", order: 2 },
];

const MODIFIER_GROUP_ID = "sizes";
const MODIFIER_GROUP_ID_2 = "flavors";
const MODIFIER_GROUPS = [
  {
    docId: MODIFIER_GROUP_ID,
    name: "Sizes",
    modifierIds: ["regular", "large"],
    required: true,
    selectionType: "single",
  },
  {
    docId: MODIFIER_GROUP_ID_2,
    name: "Flavors",
    modifierIds: ["sugar", "milk", "cream", "sweetener"],
    required: true,
    selectionType: "single",
  },
];

const MODIFIERS = [
  {
    docId: "regular",
    modifierGroupIds: MODIFIER_GROUP_ID,
    label: "Regular",
    priceDelta: 0,
    isDefault: true,
  },
  {
    docId: "large",
    modifierGroupIds: MODIFIER_GROUP_ID,
    label: "Large",
    priceDelta: 1.5,
    isDefault: false,
  },
  {
    docId: "sugar",
    modifierGroupIds: MODIFIER_GROUP_ID_2,
    label: "Sugar",
    priceDelta: 0,
    isDefault: true,
  },
  {
    docId: "milk",
    modifierGroupIds: MODIFIER_GROUP_ID_2,
    label: "Milk",
    priceDelta: 0,
    isDefault: false,
  },
  {
    docId: "cream",
    modifierGroupIds: MODIFIER_GROUP_ID_2,
    label: "Cream",
    priceDelta: 0,
    isDefault: false,
  },
  {
    docId: "sweetener",
    modifierGroupIds: MODIFIER_GROUP_ID_2,
    label: "Sweetener",
    priceDelta: 0,
    isDefault: false,
  },
];

const PRODUCTS = [
  {
    name: "Iced Matcha Latte",
    categoryId: "iced",
    price: 5.5,
    cost: 1.2,
    order: 0,
  },
  {
    name: "Cafe Americano",
    categoryId: "hot",
    price: 3.5,
    cost: 0.5,
    order: 1,
  },
  { name: "Iced Tea", categoryId: "tea", price: 4.0, cost: 0.6, order: 2 },
  {
    name: "Hot Chocolate",
    categoryId: "hot",
    price: 4.5,
    cost: 0.8,
    order: 3,
  },
  {
    name: "Cold Brew",
    categoryId: "iced",
    price: 5.0,
    cost: 0.7,
    order: 4,
  },
];

async function main() {
  const batch = firestore.batch();

  for (const cat of PRODUCT_CATEGORIES) {
    const ref = firestore.collection("productCategories").doc(cat.id);
    batch.set(ref, { docId: cat.id, name: cat.name, order: cat.order });
  }

  for (const mg of MODIFIER_GROUPS) {
    const ref = firestore.collection("modifierGroups").doc(mg.docId);
    batch.set(ref, {
      name: mg.name,
      modifierIds: mg.modifierIds,
      required: mg.required,
      selectionType: mg.selectionType,
    });
  }

  for (const mod of MODIFIERS) {
    const ref = firestore.collection("modifiers").doc(mod.docId);
    batch.set(ref, {
      docId: mod.docId,
      modifierGroupIds: mod.modifierGroupIds,
      label: mod.label,
      priceDelta: mod.priceDelta,
      isDefault: mod.isDefault,
    });
  }

  for (const p of PRODUCTS) {
    const ref = firestore.collection("products").doc();
    batch.set(ref, {
      docId: ref.id,
      name: p.name,
      categoryId: p.categoryId,
      price: p.price,
      cost: p.cost,
      order: p.order,
      modifierGroupIds: [MODIFIER_GROUP_ID],
      availableToStores: [],
      imageUrl: "",
    });
  }

  await batch.commit();
  console.log("Seeded: productCategories, modifierGroups, modifiers, products");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
