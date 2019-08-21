import { LightningElement, api, wire, track } from 'lwc';
import getPickListValues from '@salesforce/apex/PicklistController.getPickListValues';
import getFieldLabel from '@salesforce/apex/PicklistController.getFieldLabel';

export default class SelectComponent extends LightningElement {
    @track options;
    @track selectedOption;
    @track isAttributeRequired = false;
    @api fieldName;
    @api objectName;
    @track fieldLabelName;

    connectedCallback() {
        getPickListValues({ objApiName: this.objectName, fieldName: this.fieldName })
        .then(data => {
            this.options = data;
        })
        .catch(error => {
            this.displayError(error);
        });

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

    get isPicklistDisabled() {
        return (this.options &&
                this.contrFieldValue !== 'Select') ? false: true;
    }
}