public with sharing class ProductListController {
    public class ProductsAndPricebookEntries {
        @AuraEnabled
        public List<Product2> products;
        @AuraEnabled
        public List<PricebookEntry> priceBookEntries;

        public ProductsAndPricebookEntries(List<Product2> products, List<PricebookEntry> priceBookEntries) {
            this.products = products;
            this.priceBookEntries = priceBookEntries;
        }
    }

    /**
     * Queries the active products and price book entries related to the standard pricebook
     */
    @AuraEnabled
    public static ProductsAndPricebookEntries queryStandardPricebookProducts() {
        List<PriceBookEntry> priceBookEntries = [
            SELECT Pricebook2Id, Product2Id, UnitPrice, IsActive
            FROM PricebookEntry
            WHERE IsActive = TRUE AND Pricebook2.IsStandard = TRUE
        ];

        Set<Id> productIds = new Set<Id>();
        for (PriceBookEntry pbe : priceBookEntries) {
            productIds.add(pbe.Product2Id);
        }
        List<Product2> products = [
            SELECT Id, Name, Description
            FROM Product2
            WHERE Id IN :productIds AND IsActive = TRUE
            ORDER BY Name ASC
        ];

        return new ProductsAndPricebookEntries(products, priceBookEntries);
    }
}
