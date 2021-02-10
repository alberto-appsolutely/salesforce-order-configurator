import { LightningElement, wire, api, track } from "lwc";
import { refreshApex } from "@salesforce/apex";
import { subscribe, unsubscribe, MessageContext } from "lightning/messageService";
import productOrderingChannel from "@salesforce/messageChannel/productOrdering__c";
import queryOrderItems from "@salesforce/apex/OrderItemsController.queryOrderItems";
import addOrderItemToOrder from "@salesforce/apex/OrderItemsController.addOrderItemToOrder";
import sendOrder from "@salesforce/apex/OrderItemsController.sendOrder";
import { showErrorToast, showErrorMessageToast, showSuccessToast, showInfoToast } from "c/helper";
import { getRecord, deleteRecord } from "lightning/uiRecordApi";
import ORDER_NUMBER from "@salesforce/schema/Order.OrderNumber";
import ORDER_STATUS from "@salesforce/schema/Order.Status";

export default class OrderItems extends LightningElement {
    /** The datatable columns */
    columns = [
        {
            label: "Name",
            fieldName: "orderItemUrl",
            type: "url",
            typeAttributes: {
                label: { fieldName: "productName" },
                target: "_blank"
            }
        },
        { label: "Price", fieldName: "listPrice", type: "currency" },
        { label: "Quantity", fieldName: "quantity", type: "number" },
        { label: "Total", fieldName: "totalPrice", type: "currency" },
        {
            type: "button-icon",
            fixedWidth: 60,

            typeAttributes: {
                iconName: "utility:delete",
                variant: "border-filled",
                size: "large",
                name: "deleteOrderLineItem",
                title: "Delete from order",
                value: "Id"
            }
        }
    ];

    isLoading = false;

    @api recordId;
    @track order;

    @track wiredOrder;
    /** Query the record name for the title using the wire service */
    @wire(getRecord, { recordId: "$recordId", fields: [ORDER_NUMBER, ORDER_STATUS] })
    retrieveOrder(response) {
        this.wiredOrder = response;
        const { data, error } = response;
        if (data) {
            this.order = data.fields;
        } else if (error) {
            showErrorToast(error);
        }
    }

    get title() {
        return `Order ${this.order == null ? "" : this.order[ORDER_NUMBER.fieldApiName].value}`;
    }

    get orderActivated() {
        return this.order && this.order.Status.value === "Activated";
    }

    @track orderItemsData = [];

    connectedCallback() {
        this.subscribeToMessageChannel();
        this.refreshOrderItems();
    }

    /** Call the controller to query the order items and create the data to be displayed in the datatable */
    async refreshOrderItems() {
        this.isLoading = true;
        try {
            this.orderItems = await queryOrderItems({ orderId: this.recordId });
            this.orderItemsData = this.orderItems.map((oi) => ({
                id: oi.Id,
                productName: oi.Product2.Name,
                productUrl: "/" + oi.Product2.Id,
                orderItemUrl: "/" + oi.Id,
                listPrice: oi.ListPrice,
                quantity: oi.Quantity,
                totalPrice: oi.TotalPrice
            }));
        } catch (error) {
            showErrorToast(error);
        } finally {
            this.isLoading = false;
        }
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    get orderItemsIsEmpty() {
        return this.orderItemsData == null || this.orderItemsData.length <= 0;
    }

    subscription = null;

    @wire(MessageContext)
    messageContext;

    /** Subscribe to the message channel and handle the events */
    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(this.messageContext, productOrderingChannel, (message) =>
                this.handleMessage(message)
            );
        }
    }

    /** Handle the message comming from the message channel */
    handleMessage({ productId, priceBookEntryId }) {
        this.addProductToBasket(productId, priceBookEntryId);
    }

    /** Call the controller to create a new order item or increase the quantity and refresh the table */
    async addProductToBasket(productId, priceBookEntryId) {
        if (this.orderActivated) {
            this.showOrderActivatedInfo();
            return;
        }

        try {
            await addOrderItemToOrder({ orderId: this.recordId, productId, priceBookEntryId });
            await this.refreshOrderItems();
        } catch (error) {
            showErrorToast(this, error);
        }
    }

    /** Handle the row actions from the datatable */
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case "deleteOrderLineItem":
                this.deleteOrderItem(row.id);
                break;
            default:
        }
    }

    /** Delete an order item and refresh the table */
    async deleteOrderItem(orderItemId) {
        if (this.orderActivated) {
            this.showOrderActivatedInfo();
            return;
        }

        await deleteRecord(orderItemId);
        showSuccessToast(this, "Order item was deleted successfully");
        this.refreshOrderItems();
    }

    /** Calls the controller to send the order to the external endpoint */
    async handleSendOrderClicked() {
        if (this.orderActivated) {
            this.showOrderActivatedInfo();
            return;
        }

        try {
            this.isLoading = true;
            const orderSent = await sendOrder({ orderId: this.recordId });
            if (orderSent) {
                showSuccessToast(this, "Order was sent successfully");
                await refreshApex(this.wiredOrder);
            } else showErrorMessageToast(this, "An error occurred, the order couldn't be sent");

            this.isLoading = false;
        } catch (error) {
            console.log("handleSendOrderClicked", error);
            showErrorToast(this, error);
        } finally {
            this.isLoading = false;
        }
    }

    showOrderActivatedInfo() {
        showInfoToast(this, "Order has been activated and cannot be modified");
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }
}
