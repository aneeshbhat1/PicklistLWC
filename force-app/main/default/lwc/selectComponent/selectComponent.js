import { LightningElement, api, track } from 'lwc';
import getPickListValues from '@salesforce/apex/PicklistController.getPickListValues';
import getDependentOptions from '@salesforce/apex/PicklistController.getDependentOptions';
import getFieldLabel from '@salesforce/apex/PicklistController.getFieldLabel';

export default class SelectComponent extends LightningElement {
    @track options;
    @track selectedOptions = 'Select';
    @track isAttributeRequired = false;
    @api fieldName;
    @api objectName;
    @api controllingFieldName;
    @api isMultiSelect;
    @api dropDownLength;
    @api label;
    contrFieldValue;
    @track fieldLabelName;
    dependentOptions;
    @track isMouseOver;

    connectedCallback() {
        if(this.controllingFieldName) {
            getDependentOptions({ objApiName: this.objectName, fieldName: this.fieldName, contrFieldApiName: this.controllingFieldName })
            .then(data => {
                this.dependentOptions = data;
                if(this.contrFieldValue) {
                    this.options = this.getPicklistOptions(this.dependentOptions[this.contrFieldValue]);
                }
            })
            .catch(error => {
                this.displayError(error);
            });
        }
        else {
            getPickListValues({ objApiName: this.objectName, fieldName: this.fieldName })
            .then(data => {
                this.options = this.getPicklistOptions(data);
            })
            .catch(error => {
                this.displayError(error);
            });
        }

        if(!this.label) {
            getFieldLabel({objName:this.objectName,fieldName:this.fieldName})
            .then(data => {
                this.fieldLabelName = data;
            })
            .catch(error => {
                this.displayError(error);
            });
        }
        else {
            this.fieldLabelName = this.label;
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

    @api
    get controllingFieldValue() {
        debugger;
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

    get multiSelectClassAttr() {
        return (this.isMultiSelect) ? 'slds-dropdown__list slds-dropdown--length-'+this.dropDownLength :'';
    }

    get mainDivClassAttr() {
        return (this.isMouseOver) ? 'slds-picklist slds-dropdown-trigger slds-dropdown-trigger--click slds-is-open' :
                                    'slds-picklist slds-dropdown-trigger slds-dropdown-trigger--click';
    }

    handleMouseEnter() {
        this.isMouseOver = true;
    }

    handleMouseLeave() {
        this.isMouseOver = false;
    }

    handleSelection(event) {
        let tickedOptions = '';
        const selectedLabel = event.target.label;
        const selectedValue = event.target.checked;
        if(this.options) {
            this.options.forEach(function(option){
                if(option.label === selectedLabel) {
                    option.isSelected = selectedValue;
                }
            });
            this.options.forEach(function(option){
                if(option.isSelected) {
                    tickedOptions += (option.label+',');
                }
            });
            this.selectedOptions = tickedOptions.slice(0, -1);
        }
        if(!this.selectedOptions) {
            this.selectedOptions = 'Select';
        }
    }

    getPicklistOptions(dataFromServer) {
        if(dataFromServer && this.isMultiSelect) {
            dataFromServer.forEach(function(datum) {
                datum.isSelected = false;
            });
        }
        return dataFromServer;
    }
}
