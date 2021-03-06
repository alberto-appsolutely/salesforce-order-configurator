@isTest
private class ProductListControllerTest {
    @TestSetup
    static void setup() {
        TestDataUtils.activateStandardPricebook();

        List<Product2> products = TestDataUtils.insertTestProducts(1);
        insert TestDataUtils.createStandardPricebookEntry(products[0].Id);
    }

    @IsTest
    static void queryStandardPricebookProductsTest() {
        //the method should return one product and one pricebook entry
        ProductListController.ProductsAndPricebookEntries productsAndPricebookEntries = ProductListController.queryStandardPricebookProducts(
            1
        );
        System.assertEquals(1, productsAndPricebookEntries.products.size());
        System.assertEquals(1, productsAndPricebookEntries.priceBookEntries.size());

        //no products should be returned because the page number exceeds the maximum offset
        productsAndPricebookEntries = ProductListController.queryStandardPricebookProducts(9999999);
        System.assertEquals(0, productsAndPricebookEntries.products.size());
    }
}
