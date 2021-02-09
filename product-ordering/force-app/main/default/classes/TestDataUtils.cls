public inherited sharing class TestDataUtils {
    public static PricebookEntry createStandardPricebookEntry(Id productId) {
        return new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = productId,
            UnitPrice = 100,
            IsActive = true
        );
    }

    public static List<Product2> insertTestProducts(Integer num) {
        List<Product2> products = new List<Product2>();
        for (Integer i = 1; i <= num; i++) {
            products.add(new Product2(Name = 'Test Product ' + i));
        }
        insert products;
        return products;
    }

    public static void activateStandardPricebook() {
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;
    }
}
