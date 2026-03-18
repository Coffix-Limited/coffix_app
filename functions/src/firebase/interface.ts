export interface Product {
  availableToStores: string[];
  categoryId: string;
  cost: number; // capital cost for stats only
  docId: string;
  imageUrl: string;
  modifierGroupIds: string[];
  name: string;
  order: number; // order in the product
  price: number; // price of the product
}

export interface Store {
  docId: string;
  name: string;
  address: string;
}

export interface SnapshotModifier {
  modifierId: string;
  name: string;
  priceDelta: number;
}

export interface EnrichedOrderItem {
  productId: string;
  productName: string;
  price: number;          // unit price = basePrice + sum(modifier priceDelta)
  quantity: number;
  selectedModifiers: Record<string, string>;      // groupId -> modifierId
  modifiers: SnapshotModifier[];                  // snapshot: id + name + priceDelta
}
