import { LightningElement, api, wire, track } from 'lwc';
import getPickListValues from '@salesforce/apex/PicklistController.getPickListValues';
import getDependentOptions from '@salesforce/apex/PicklistController.getDependentOptions';

export default class SelectComponent extends LightningElement {
    @api options;
    @api selectedOption;
    @api label;
    @api isAttributeRequired = false;
    // @api isComponentDisabled = false;
    @api fieldName;
    @api objectName;
    @api controllingFieldName;
    @api contrFieldValue;
    dependentOptions;

    connectedCallback() {
        if(this.controllingFieldName) {
            getDependentOptions({ objApiName: this.objectName, fieldName: this.fieldName, contrFieldApiName: this.controllingFieldName })
            .then(data => {
                debugger;
                this.dependentOptions = data;
                this.options = this.dependentOptions[this.contrFieldValue];
            })
            .catch(error => {
                this.displayError(error);
            });
        }
        else {
            getPickListValues({ objApiName: this.objectName, fieldName: this.fieldName })
            .then(data => {
                debugger;
                this.options = data;
            })
            .catch(error => {
                this.displayError(error);
            });
        }
    }

    selectionChangeHandler(event) {
        this.dispatchEvent(new CustomEvent('selected' , {detail : event.target.value}));
    }

    displayError(error) {
        this.error = 'Unknown error';
        if (Array.isArray(error.body)) {
            this.error = error.body.map(e => e.message).join(', ');
        }
        else if (typeof error.body.message === 'string') {
            this.error = error.body.message;
        }
    }

    get conrollingFieldValue() {
        debugger;
        return this.conrollingFieldValue;
    }

    set controllingFieldValue(value) {
        debugger;
        this.contrFieldValue = value;
        this.options = this.dependentOptions[value];
    }

    get isPicklistDisabled() {
        return (this.options &&
                this.contrFieldValue !== 'Select') ? false: true;
    }
}