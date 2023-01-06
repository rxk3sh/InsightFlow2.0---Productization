import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getLocalExpertDetails from '@salesforce/apex/IFv2_LocalExpertDetails.getLocalExpertDetails';
export default class LocalExpertDetails extends NavigationMixin(LightningElement) {
    @api recordId;
    @track localexpert;
    @track error;
    @wire(getLocalExpertDetails, {recordId: '$recordId'}) 
    localexperts({error,data}){
        if(data){
            this.localexpert = data;
            this.error = error;
        }
    }
    @track recordPageUrl;
    navigatetoUser(){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.localexpert[0].Id,
                objectApiName: 'User',
                actionName: 'view'
            },
        });
    }
    //alert("localexperts");
}