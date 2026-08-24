import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getDistributionPublicUrl from '@salesforce/apex/DHSBIManifest.getDistributionPublicUrl';
export default class Manifest extends NavigationMixin(LightningElement) {
    _manifestName;
    get manifestName(){
        return this._manifestName;
    }
    publicLink;
    connectedCallback() {
        this.getPublicURL();
    }
    handleDownload(){
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url:this.publicLink,
                }
            });
    }
    getPublicURL(){
        getDistributionPublicUrl().then(result => {
            console.log(result);
            this._manifestName = result?.ManifestName;
            this.publicLink = result?.DistributionPublicUrl;
        }).catch(e=>{
            console.error(e);
        });
    }
}