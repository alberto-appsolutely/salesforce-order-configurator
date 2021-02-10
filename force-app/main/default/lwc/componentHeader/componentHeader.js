import { LightningElement, api } from "lwc";

/**
 * A header component that mimics standard Salesforce headers
 */
export default class ComponentHeader extends LightningElement {
    @api title;
    @api subtitle;
    @api iconName;
    @api iconClass;

    get iconContainerClass() {
        return `slds-icon_container ${this.iconClass}`;
    }
}
