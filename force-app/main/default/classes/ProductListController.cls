public with sharing class ProductListController {
    public class ProductsAndPricebookEntries {
        @AuraEnabled
        public List<Product2> products;
        @AuraEnabled
        public List<PricebookEntry> priceBookEntries;

        public ProductsAndPricebookEntries() {
            this.products = new List<Product2>();
            this.priceBookEntries = new List<PricebookEntry>();
        }

        public ProductsAndPricebookEntries(List<Product2> products, List<PricebookEntry> priceBookEntries) {
            this.products = products;
            this.priceBookEntries = priceBookEntries;
        }
    }

    final static Integer PRODUCT_PAGE_SIZE = 15;

    /**
     * Queries the active products and price book entries related to the standard pricebook
     */
    @AuraEnabled
    public static ProductsAndPricebookEntries queryStandardPricebookProducts(Integer page) {
        List<PriceBookEntry> priceBookEntries = [
            SELECT Pricebook2Id, Product2Id, UnitPrice, IsActive
            FROM PricebookEntry
            WHERE IsActive = TRUE AND Pricebook2.IsStandard = TRUE
        ];

        Set<Id> productIds = new Set<Id>();
        for (PriceBookEntry pbe : priceBookEntries) {
            productIds.add(pbe.Product2Id);
        }

        Integer productOffset = (page - 1) * PRODUCT_PAGE_SIZE;
        if (productOffset <= 0) {
            productOffset = 0;
        } else if (productOffset > 2000) {
            return new ProductsAndPricebookEntries();
        }

        List<Product2> products = [
            SELECT Id, Name, Description
            FROM Product2
            WHERE Id IN :productIds AND IsActive = TRUE
            ORDER BY Name ASC
            LIMIT :PRODUCT_PAGE_SIZE
            OFFSET :productOffset
        ];

        return new ProductsAndPricebookEntries(products, priceBookEntries);
    }
}
