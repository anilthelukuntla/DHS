import { LightningElement, api } from 'lwc';

export default class Select extends LightningElement {
    @api disabled;
    @api label;
    @api name;
    @api options;
    @api required;
    @api value;
    @api checkValidity() {}
    @api reportValidity() {}
    @api setCustomValidity() {}
    @api showHelpMessageIfInvalid() {}
}
