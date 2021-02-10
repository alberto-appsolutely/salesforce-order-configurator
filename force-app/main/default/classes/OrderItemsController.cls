public with sharing class OrderItemsController {
    /**
     * Queries the order items related to the specified order id
     *
     * @return List<OrderItem>
     */
    @AuraEnabled
    public static List<OrderItem> queryOrderItems(Id orderId) {
        List<OrderItem> orderItems = [
            SELECT Product2Id, Product2.Name, ListPrice, Quantity, TotalPrice
            FROM OrderItem
            WHERE OrderId = :orderId
            ORDER BY Product2.Name
        ];
        return orderItems;
    }

    /**
     * Creates a new order item related to the specified order and product or increases the quantity if a related item
     * already exists
     *
     * @param orderId The order id to attach the order item to
     * @param productId The product id that will be linked with the order item
     * @param priceBookEntryId The price book entry that will be linked with the order item
     */
    @AuraEnabled
    public static void addOrderItemToOrder(Id orderId, Id productId, Id priceBookEntryId) {
        List<OrderItem> orderItems = queryOrderItems(orderId);
        Map<String, OrderItem> orderItemsByProductId = new Map<String, OrderItem>();
        for (OrderItem orderItem : orderItems) {
            orderItemsByProductId.put(orderItem.Product2Id, orderItem);
        }

        List<PriceBookEntry> priceBookEntries = [SELECT UnitPrice FROM PriceBookEntry WHERE Id = :priceBookEntryId];

        OrderItem orderItem = orderItemsByProductId.get(productId);
        if (orderItem == null) {
            orderItem = new OrderItem(
                OrderId = orderId,
                Product2Id = productId,
                PriceBookEntryId = priceBookEntryId,
                Quantity = 0,
                UnitPrice = priceBookEntries.IsEmpty() ? 0 : priceBookEntries[0].UnitPrice
            );
        }
        orderItem.Quantity += 1;
        upsert orderItem;
    }

    final static String ENDPOINT_URL = 'https://sf-order.requestcatcher.com/test';

    /**
     * Send the order to request catcher
     *
     * @param orderId The order id to be sent
     */
    @AuraEnabled
    public static Boolean sendOrder(Id orderId) {
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setEndpoint(ENDPOINT_URL);
        req.setBody(generateOrderJSON(orderId));

        Http http = new Http();
        HTTPResponse res = http.send(req);
        Integer statusCode = res.getStatusCode();
        if (statusCode != 200) {
            return false;
        } else {
            Order order = new Order(Id = orderId, Status = 'Activated');
            update order;
        }
        return true;
    }

    @TestVisible
    class RequestOrderProduct {
        public String name;
        public String code;
        public Decimal unitPrice;
        public Integer quantity;
    }

    @TestVisible
    class RequestOrder {
        public String accountNumber;
        public String orderNumber;
        public String type;
        public String status;
        public List<RequestOrderProduct> orderProducts;
    }

    /**
     * Generate a JSON payload for the specified order
     *
     * @param orderId The order id to be sent
     */
    @TestVisible
    private static String generateOrderJSON(Id orderId) {
        List<OrderItem> orderItems = queryOrderItems(orderId);
        Order order = [SELECT Account.Name, OrderNumber, Type, Status FROM Order WHERE Id = :orderId LIMIT 1];

        List<RequestOrderProduct> requestOrderProducts = new List<RequestOrderProduct>();
        for (OrderItem orderItem : orderItems) {
            RequestOrderProduct rop = new RequestOrderProduct();
            rop.name = orderItem.Product2.Name;
            rop.code = orderItem.Product2.Name;
            rop.unitPrice = orderItem.ListPrice;
            rop.quantity = Integer.valueOf(orderItem.Quantity);
            requestOrderProducts.add(rop);
        }

        RequestOrder requestOrder = new RequestOrder();
        requestOrder.accountNumber = order.Account.Name;
        requestOrder.orderNumber = order.OrderNumber;
        requestOrder.type = order.Type;
        requestOrder.status = order.Status;
        requestOrder.orderProducts = requestOrderProducts;

        return JSON.serialize(requestOrder);
    }
}
