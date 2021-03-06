public inherited sharing class TestDataUtils {
    public static PricebookEntry createStandardPricebookEntry(Id productId) {
        return createPricebookEntry(productId, Test.getStandardPricebookId());
    }

    public static PricebookEntry createPricebookEntry(Id productId, Id pricebookId) {
        return new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productId, UnitPrice = 100, IsActive = true);
    }

    public static List<Product2> insertTestProducts(Integer num) {
        List<Product2> products = new List<Product2>();
        for (Integer i = 1; i <= num; i++) {
            products.add(new Product2(Name = 'Test Product ' + i, IsActive = true));
        }
        insert products;
        return products;
    }

    public static List<OrderItem> insertTestOrderItems(
        Integer num,
        Id orderId,
        Id priceBookEntryId,
        Integer unitPrice
    ) {
        List<OrderItem> orderItems = new List<OrderItem>();
        for (Integer i = 1; i <= num; i++) {
            orderItems.add(
                new OrderItem(
                    OrderId = orderId,
                    PriceBookEntryId = priceBookEntryId,
                    UnitPrice = unitPrice,
                    Quantity = 1
                )
            );
        }
        insert orderItems;
        return orderItems;
    }

    public static void activateStandardPricebook() {
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;
    }
}
