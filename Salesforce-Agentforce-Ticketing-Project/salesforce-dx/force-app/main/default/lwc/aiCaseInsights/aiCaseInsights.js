import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import SENTIMENT from '@salesforce/schema/Case.AI_Sentiment__c';
import SUMMARY from '@salesforce/schema/Case.AI_Summary__c';
import ACTION from '@salesforce/schema/Case.AI_Recommended_Action__c';
import TIER from '@salesforce/schema/Case.Customer_Tier__c';
import ID from '@salesforce/schema/Case.Id';
import PRIORITY from '@salesforce/schema/Case.Priority';

export default class AiCaseInsights extends LightningElement {
    @api recordId;
    @wire(getRecord, { recordId: '$recordId', fields: [SENTIMENT, SUMMARY, ACTION, TIER] }) record;

    get sentiment() { return getFieldValue(this.record.data, SENTIMENT) || 'Unknown'; }
    get summary() { return getFieldValue(this.record.data, SUMMARY) || 'No summary yet.'; }
    get action() { return getFieldValue(this.record.data, ACTION) || 'No recommendation yet.'; }
    get tier() { return getFieldValue(this.record.data, TIER) || 'Standard'; }
    get pillClass() { return 'slds-badge pill-' + this.sentiment.toLowerCase(); }

    async escalate() {
        try {
            await updateRecord({ fields: { [ID.fieldApiName]: this.recordId, [PRIORITY.fieldApiName]: 'High' } });
            this.dispatchEvent(new ShowToastEvent({ title: 'Escalated', message: 'Priority set to High.', variant: 'success' }));
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Could not escalate', message: e.body ? e.body.message : e.message, variant: 'error' }));
        }
    }
}
