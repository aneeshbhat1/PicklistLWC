import { LightningElement, api, track } from 'lwc';
import getPickListValues from '@salesforce/apex/PicklistController.getPickListValues';
import getDependentOptions from '@salesforce/apex/PicklistController.getDependentOptions';
import getFieldLabel from '@salesforce/apex/PicklistController.getFieldLabel';

export default class SelectComponent extends LightningElement {
    @track options;
    @track selectedOption;
    @track isAttributeRequired = false;
    @api fieldName;
    @api objectName;
    @api controllingFieldName;
    contrFieldValue;
    @track fieldLabelName;
    dependentOptions;

    connectedCallback() {
        if(this.controllingFieldName) {
            getDependentOptions({ objApiName: this.objectName, fieldName: this.fieldName, contrFieldApiName: this.controllingFieldName })
            .then(data => {
                this.dependentOptions = data;
                if(this.contrFieldValue) {
                    this.options = this.dependentOptions[this.contrFieldValue];
                }
            })
            .catch(error => {
                this.displayError(error);
            });
        }
        else {
            getPickListValues({ objApiName: this.objectName, fieldName: this.fieldName })
            .then(data => {
                this.options = data;
            })
            .catch(error => {
                this.displayError(error);
            });
        }

        getFieldLabel({objName:this.objectName,fieldName:this.fieldName})
        .then(data => {
            this.fieldLabelName = data;
        })
        .catch(error => {
            this.displayError(error);
        });
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

    @api
    get controllingFieldValue() {
        return this.contrFieldValue;
    }

    set controllingFieldValue(value) {
        this.contrFieldValue = value;
        if(value) {
            this.options = this.dependentOptions[value];
        }
    }

    get isPicklistDisabled() {
        return (this.options &&
                this.contrFieldValue !== 'Select') ? false: true;
    }
}