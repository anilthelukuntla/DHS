import { api, LightningElement, track } from 'lwc';
import LightningModal from 'lightning/modal';
import getFieldData from '@salesforce/apex/utils.getFieldData';
export default class MergeFieldsModal extends LightningElement {
    @api objectname;
    @track fieldData = [];
    @track parentfieldData = [];
    @track gparentfieldData = [];
    @track ggparentfieldData = [];
    @track showParent = false;
    @track showGParent = false;
    @track showGGParent = false;
    @track parentName;
    @track gparentName;
    @track ggparentName;
    @track showMergeField = false;
    @track mergeText;

    @track addFieldData = [];
    handleOkay() {
        this.close('okay');
    }
    connectedCallback() {
        getFieldData({objectName : this.objectname}).then(res=>{
            console.log(res);
            if(res){
                this.fieldData = res.sort((a,b)=>a.label.localeCompare(b.label));
            }
        }).catch(e=>{   
            console.error(e);
        });
    }
    fieldSelectHandler(e){
        const apiname = e.currentTarget.dataset.apiname;
        const isparent = e?.currentTarget?.dataset?.isparent;
        this.mergeText = apiname;
        this.fieldData.forEach(val=>{
            if(val.apiname === apiname){
                val.isselected = true;
            }else{
                val.isselected = false;
            }
        })
        if(isparent){
            if(apiname.slice(-2) === 'id'){
                this.mergeText = apiname.slice(0, -2);
            }else{
                this.mergeText = apiname;
            }
            this.parentName = `${apiname}(${isparent})`;
            this.showParent = true;
            this.showGParent = false;
            this.showGGParent = false;
            this.showMergeField = false;
            getFieldData({objectName : isparent}).then(res=>{
                this.parentfieldData = JSON.parse(JSON.stringify(res));
                this.parentfieldData = this.parentfieldData.sort((a,b)=>a.label.localeCompare(b.label));
            }).catch(e=>{   
                console.error(e);
            })
        }else{
            this.showMergeField = true;
            this.showParent = false;
            this.showGParent = false;
            this.showGGParent = false;
        }
        console.log('current '+this.mergeText);
    }
    parentFieldSelectHandler(e){
        console.log('prent start '+this.mergeText);
        this.mergeText = this.mergeText.replace(/__c/g, "__r");
        if(this.mergeText.includes('.')){
            this.mergeText = this.mergeText.split('.')[0];
        }
        const apiname = e.currentTarget.dataset.apiname;
        const isparent = e?.currentTarget?.dataset?.isparent;
        this.parentfieldData.forEach(val=>{
            if(val.apiname === apiname){
                val.isselected = true;
            }else{
                val.isselected = false;
            }
        })
        let field = '';
        if(isparent){
            if(apiname.slice(-2) === 'id'){
                field = apiname.slice(0, -2);
            }else{
                field = apiname;
            }
            this.gparentName = `${apiname}(${isparent})`;
            this.showMergeField = false;
            this.showGParent = true;
            this.showGGParent = false;
            getFieldData({objectName : isparent}).then(res=>{
                this.gparentfieldData = JSON.parse(JSON.stringify(res));
                this.gparentfieldData = this.gparentfieldData.sort((a,b)=>a.label.localeCompare(b.label));
            }).catch(e=>{   
                console.error(e);
            })
        }else{
            field = apiname;
            this.showMergeField = true;
            this.showGParent = false;
            this.showGGParent = false;
        }
        this.mergeText += '.'+field;
        console.log('parent final '+this.mergeText);
    }
    gparentFieldSelectHandler(e){
        console.log('g parent start '+this.mergeText);
        this.mergeText = this.mergeText.replace(/__c/g, "__r");
        if((this.mergeText.match(/\./g) || []).length > 1){
            if(this.mergeText.includes('.')){
                this.mergeText = this.mergeText.split('.')[0]+'.'+this.mergeText.split('.')[1];
            }
        }
        
        
        //console.log(this.mergeText);
        
        const apiname = e.currentTarget.dataset.apiname;
        const isparent = e?.currentTarget?.dataset?.isparent;
        this.gparentfieldData.forEach(val=>{
            if(val.apiname === apiname){
                val.isselected = true;
            }else{
                val.isselected = false;
            }
        })
        let field = '';
        if(isparent){
            if(apiname.slice(-2) === 'id'){
                field = apiname.slice(0, -2);
            }else{
                field = apiname;
            }
            console.log(field)
            this.ggparentName = `${apiname}(${isparent})`;
            this.showMergeField = false;
            this.showGGParent = true;
            getFieldData({objectName : isparent}).then(res=>{
                this.ggparentfieldData = JSON.parse(JSON.stringify(res));
                this.ggparentfieldData = this.ggparentfieldData.filter(item => item.isparent === undefined);
                this.ggparentfieldData = this.ggparentfieldData.sort((a,b)=>a.label.localeCompare(b.label));
            }).catch(e=>{   
                console.error(e);
            })
        }else{
            field = apiname;
            this.showMergeField = true;
            this.showGGParent = false;
        }
            this.mergeText += '.'+field;
            //console.log(this.mergeText);
    }
    ggparentFieldSelectHandler(e){
        this.mergeText = this.mergeText.replace(/__c/g, "__r");
        if((this.mergeText.match(/\./g) || []).length > 2){
            if(this.mergeText.includes('.')){
                this.mergeText = this.mergeText.split('.')[0]+'.'+this.mergeText.split('.')[1]+'.'+this.mergeText.split('.')[2];
            }
        }
        
        const apiname = e.currentTarget.dataset.apiname;
        const isparent = e?.currentTarget?.dataset?.isparent;
        this.ggparentfieldData.forEach(val=>{
            if(val.apiname === apiname){
                val.isselected = true;
            }else{
                val.isselected = false;
            }
        });
        if(!isparent){
            this.showMergeField = true;
             this.mergeText += '.'+apiname;
        }
    }
    sendEvent(event){
        console.log( event);
        const selectEvent = new CustomEvent('save', {
            detail: this.mergeText
        });
        try{
            this.dispatchEvent(selectEvent);
        }catch(e){
            console.error(e);
        }
    }
    handleClose(event){
        
        this.dispatchEvent(new customEvent('close', { detail: { value: true } }));
    }
}