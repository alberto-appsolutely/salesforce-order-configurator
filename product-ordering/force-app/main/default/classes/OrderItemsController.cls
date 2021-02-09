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
}
