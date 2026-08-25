import { api, track, LightningElement } from 'lwc';
import LightningModal from 'lightning/modal';
import updateReport from "@salesforce/apex/utils.updateReport";
export default class UpsertReportExport extends LightningElement {
    @api title; // Modal title
    @api edit = false;
    @api input; // Modal message
    @api objectname;
    @api currentsystem;
    modifiedLabel;
    modifiedapiname;
    @track showMergeField = false;
    _input = {};
    handleSaveEvent(event) {
        const textVal = event.detail;
        this.modifiedapiname = textVal;
        this.showMergeField = false;
    }
    handleCloseEvent(){
        this.showMergeField = false;
    }
    set input(val){
        this._input = val;
        this.modifiedLabel = val?.label;
        this.modifiedapiname = val?.apiname;
    }
    get input() {
        return this._input; // Return the private property's value
    }
    labelChange(e){
        this.modifiedLabel = e.detail.value;
    }
    apinameChange(e){
        this.modifiedapiname = e.detail.value;
    }
    handleSubmit(){
        let obj = {};
        obj.label = this.modifiedLabel;
        obj.apiname = this.modifiedapiname;
        if(this._input?.id){
            obj.id = this._input?.id;
            obj.index = this._input?.index;
        }else{
            obj.currentsystem = this.currentsystem;
            obj.objectname = this.objectname;
        }
        updateReport({info:obj}).then(res=>{
            console.log('success');
            this.dispatchEvent(new CustomEvent('submitpopup', { detail: { value: true } }));
        }).catch(e=>{
            console.error(e);
        });
    }
    handleClick(){
        this.showMergeField = true;
    }
    handleClose(){
        this.dispatchEvent(new CustomEvent('closepopup', { detail: { value: true } }));
    }
}