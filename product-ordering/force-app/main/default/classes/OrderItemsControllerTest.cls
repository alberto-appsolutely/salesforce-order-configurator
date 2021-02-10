@isTest
private class OrderItemsControllerTest {
    final static String ACCOUNT_NAME = 'Order Test Account';

    @TestSetup
    static void setup() {
        List<Product2> products = TestDataUtils.insertTestProducts(2);

        insert TestDataUtils.createStandardPricebookEntry(products[0].Id);

        Account account = new Account(Name = ACCOUNT_NAME);
        insert account;

        Contract contract = new Contract(
            AccountId = account.Id,
            StartDate = Date.today(),
            ContractTerm = 12,
            Status = 'Draft'
        );
        insert contract;

        contract.Status = 'Activated';
        update contract;

        Order order = new Order(
            AccountId = account.Id,
            ContractId = contract.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert order;
    }

    @IsTest
    static void queryOrderItemsTest() {
        Order order = [SELECT Id FROM Order LIMIT 1];
        PriceBookEntry priceBookEntry = [SELECT Id FROM PriceBookEntry LIMIT 1];

        //insert only one order item, queryOrderItems should return one record
        TestDataUtils.insertTestOrderItems(1, order.Id, priceBookEntry.Id, 100);
        List<OrderItem> orderItems = OrderItemsController.queryOrderItems(order.Id);
        System.assertEquals(1, orderItems.size());
    }

    @IsTest
    static void addOrderItemToOrderTest() {
        Order order = [SELECT Id FROM Order LIMIT 1];
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 2];
        Product2 product1 = products[0];
        Product2 product2 = products[1];

        PriceBookEntry priceBookEntry = [SELECT Id FROM PriceBookEntry LIMIT 1];

        Test.startTest();

        //call the method for the first time, new order item with quantity 1 should be created
        OrderItemsController.addOrderItemToOrder(order.Id, product1.Id, priceBookEntry.Id);
        List<OrderItem> orderItems = queryOrderItems();
        System.assertEquals(1, orderItems.size());
        System.assertEquals(1, orderItems[0].Quantity);

        //using the same product id should increase the quantity and not create a new item
        OrderItemsController.addOrderItemToOrder(order.Id, product1.Id, priceBookEntry.Id);
        orderItems = queryOrderItems();
        System.assertEquals(1, orderItems.size());
        System.assertEquals(2, orderItems[0].Quantity);

        //using a new product id should create a new line item
        OrderItemsController.addOrderItemToOrder(order.Id, product2.Id, priceBookEntry.Id);
        System.assertEquals(2, queryOrderItems().size());

        Test.stopTest();
    }

    private static List<OrderItem> queryOrderItems() {
        return [SELECT Id, Quantity FROM OrderItem ORDER BY CreatedDate];
    }

    @isTest
    static void generateOrderJSONTest() {
        Integer unitPrice = 100;
        Order order = [SELECT Id FROM Order LIMIT 1];
        PriceBookEntry priceBookEntry = [SELECT Id FROM PriceBookEntry LIMIT 1];
        TestDataUtils.insertTestOrderItems(2, order.Id, priceBookEntry.Id, unitPrice);

        Test.startTest();

        //serialize and deserialize the order
        String jsonString = OrderItemsController.generateOrderJSON(order.Id);
        OrderItemsController.RequestOrder requestOrder = (OrderItemsController.RequestOrder) JSON.deserialize(
            jsonString,
            OrderItemsController.RequestOrder.class
        );

        //check that the number of order items is 2, the account name and unit price match
        System.assertEquals(2, requestOrder.orderProducts.size());
        System.assertEquals(ACCOUNT_NAME, requestOrder.accountNumber);
        System.assertEquals(unitPrice, requestOrder.orderProducts[0].unitPrice);

        //use the http mock class test the callout
        Test.setMock(HttpCalloutMock.class, new OkHttpCalloutMock());
        Boolean orderStatus = OrderItemsController.sendOrder(order.Id);
        System.assertEquals(true, orderStatus);

        Test.stopTest();
    }
}
