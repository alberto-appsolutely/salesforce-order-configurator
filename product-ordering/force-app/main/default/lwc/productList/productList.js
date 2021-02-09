import { LightningElement, wire, track } from "lwc";
import queryProducts from "@salesforce/apex/ProductListController.queryStandardPricebookProducts";
import { publish, MessageContext } from "lightning/messageService";
import productOrderingChannel from "@salesforce/messageChannel/productOrdering__c";
import { keyByField } from "c/helper";

export default class ProductList extends LightningElement {
    /** The datatable columns */
    columns = [
        {
            label: "Name",
            fieldName: "productUrl",
            type: "url",
            typeAttributes: {
                label: { fieldName: "name" },
                target: "_blank"
            }
        },
        { label: "Price", fieldName: "unitPrice", type: "currency" },
        {
            type: "button-icon",
            fixedWidth: 50,
            typeAttributes: {
                iconName: "utility:add",
                variant: "border-filled",
                name: "addProduct",
                title: "Add to basket",
                value: "id"
            }
        }
    ];

    products = [];
    priceBookEntriesByProductId = {};
    @track isLoading = false;

    /** Call the controller to query the produts and related price book entries */
    async connectedCallback() {
        this.isLoading = true;
        const res = await queryProducts();
        const { products, priceBookEntries } = res;

        this.priceBookEntriesByProductId = keyByField(priceBookEntries, "Product2Id");
        this.products = products.map((p) => ({
            id: p.Id,
            name: p.Name,
            productUrl: `/${p.Id}`,
            unitPrice: this.priceBookEntriesByProductId[p.Id] ? this.priceBookEntriesByProductId[p.Id].UnitPrice : 0
        }));
        this.isLoading = false;
    }

    /** Handle the datatable row actions */
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        const productId = row.id;

        switch (actionName) {
            case "addProduct":
                this.addProductToBasket(productId);
                break;
            default:
        }
    }

    @wire(MessageContext)
    messageContext;

    /** Send a message to the message channel to add the order item to the order */
    addProductToBasket(productId) {
        publish(this.messageContext, productOrderingChannel, {
            productId,
            priceBookEntryId: this.priceBookEntriesByProductId[productId].Id
        });
    }
}
