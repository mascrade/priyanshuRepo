import { LightningElement, wire, track, api } from 'lwc';
import GetAllSMSTemplates from '@salesforce/apex/HM_SMSTempApexController.GetAllSMSTemplates';
import deleteRecord from '@salesforce/apex/HM_SMSTempApexController.deleteRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id'; //this is how you will retreive the USER ID of current in user.
import USER_NAME from '@salesforce/schema/User.Name';

const columns = [
    {label: 'SMS Template Name',fieldName: 'TemplateName',type: 'text'},
    {label: 'Is Active',fieldName: 'IsActive',type: 'boolean' },
    {label: 'Template Body',fieldName: 'Body',type: 'text'},
    {type: 'button', typeAttributes: { label: 'Edit',
    name: 'Edit',
    title: 'Edit',
    value: 'Edit',
    iconPosition: 'center'
},initialWidth: 80},
{type: 'button-icon', typeAttributes: {
    title: 'Delete',
    label: 'Delete',
    name: 'Delete',
    iconName: 'utility:delete',
    iconPosition: 'center'
},initialWidth: 100}
]

export default class HM_Create_New_SMS_Template extends LightningElement {
    
    @api prop1;
    @track columns = columns; //holds column info.
    @track lstAllTemplates = [];
    @track lstAllActiveTemplates = [];
    @api isLoading = false;
    @track data = []; //data to be displayed in the table
    @track isdata;
    currentUserName;
    @track checkboxLabel='';
    @track checkboxchecked = false;
    error;
    wiredSMSTemplatesResult;

    //Wire function starts here
    @wire(GetAllSMSTemplates) 
    WireSMSTemplates(result){
        this.isLoading = true;
        this.wiredSMSTemplatesResult = result;
        if(result.data){
            this.data = result.data;
            console.log('result.data in wire ========',result.data);
            //this.PerformActionsToRenderUI();
            this.lstAllTemplates = result.data.map((item)=>({...item}));
            
            let allActiveTemplates = [];
            
            for(let i=0;i<this.lstAllTemplates.length;i++){
                if(this.lstAllTemplates[i].IsActive == true){
                    allActiveTemplates.push(this.lstAllTemplates[i]);
                }
            }
            this.lstAllActiveTemplates = allActiveTemplates.map((item)=>({...item}));
            console.log('this.lstAllTemplates-----',this.lstAllTemplates);
            console.log('this.lstAllActiveTemplates-----',this.lstAllActiveTemplates);
            
            if(this.lstAllTemplates.length==0){
                this.isdata = false;
            }else{
                this.isdata = true;
            }
            
            let AllTemplatesCount=this.lstAllTemplates.length;
            let ActiveTemplatesCount=this.lstAllActiveTemplates.length;
            this.checkboxLabel = 'Show Active Templates ( Total: '+AllTemplatesCount+', Active: '+ActiveTemplatesCount+' )';
            console.log('AllTemplatesCount-----',AllTemplatesCount);
            console.log('ActiveTemplatesCount-----',ActiveTemplatesCount);
            console.log('checkboxLabel-----',this.checkboxLabel);
            
            
            this.error = undefined;
            this.isLoading = false;
        }
        else if(result.error){
            this.error = error;
            this.lstAllTemplates = undefined;
        }
    }
    //Wire function ends here

    @wire(getRecord, { recordId: USER_ID, fields: [USER_NAME]}) 
    userDetails({error, data}) {
        if (data) {
            this.currentUserName = data.fields.Name.value;
        } else if (error) {
            this.error = error ;
        }
    }

    //to pass to child component
    @track smsTemplateIdToEdit;
    @track smsTemplateName;
    @track smsTemplateIsActive;
    @track smsTemplateBodyForEdit;
    @track smsTempCreatedBy;
    @track smsTempCreatedByDate;
    @track smsTempCreatedByTime;
    @track smsTempLastModifiedBy;
    @track smsTempObjectName;
    @track smsTempLastModifiedByDate;
    @track smsTempLastModifiedByTime;
    @track smsTemplateIdToDelete;
    @track createNewForm=true;
    @track isAddEditModalOpen=false;
    @track editExistingForm=false;
    @track editExistingForm=false;
    @track FormHeader='New SMS Template';
    @track updateListAfterDelete = [];
    @track PopUpHeader='Edit SMS Template';
    @track contactLookupName;
    
    //delete dialog box
    @track isDeleteModalOpen = false;
    
    TemplateRowAction(event){
        this.isLoading = true;
        let actionName = event.detail.action.name;
        console.log('actionName--',actionName);

        if(actionName=='Edit'){
            this.smsTemplateIdToEdit = event.detail.row.TemplateId;
            this.contactLookupName = event.detail.row.contactLkName;  
            this.smsTemplateName = event.detail.row.TemplateName;
            this.smsTemplateIsActive = event.detail.row.IsActive;
            this.smsTemplateBodyForEdit = event.detail.row.Body;
            this.smsTempObjectName = event.detail.row.ObjName;
            this.smsTempCreatedBy = event.detail.row.CreatedByName;
            this.smsTempCreatedByDate = event.detail.row.CreatedDate;
            this.smsTempCreatedByTime = '('+event.detail.row.CreatedTime+')';
            this.smsTempLastModifiedBy = event.detail.row.LastModifiedByName;
            this.smsTempLastModifiedByDate = event.detail.row.LastModifiedDate;
            this.smsTempLastModifiedByTime = '('+event.detail.row.LastModifiedTime+')';
            
            this.FormHeader='Edit SMS Template : '+this.smsTemplateName;
            
            this.PopUpHeader = 'Edit SMS Template';
            this.isAddEditModalOpen = true;

            console.log('smsTempObjectName = '+this.smsTempObjectName);
        }
        else if(actionName=='Delete'){
            this.smsTemplateIdToDelete = event.detail.row.TemplateId;
            //console.log('--Ready to callout Delete method Imperatively from Apex--');
            this.openDeleteModal();
        }
        this.isLoading = false;
    }
    
    handleCheckboxChange(event){
        if(event.target.checked == true){
            this.lstAllTemplates = this.lstAllActiveTemplates;
            this.checkboxchecked = true;
        }else{
            this.lstAllTemplates = this.data;
            this.checkboxchecked = false;
        }
    }
    
    openDeleteModal() {
        // to open modal set isDeleteModalOpen tarck value as true
        this.isDeleteModalOpen = true;
    }
    
    CancelDelete() {
        // to close modal set isDeleteModalOpen tarck value as false
        this.isDeleteModalOpen = false;
    }
    
    ConfirmedYesDelete() {
        // to close modal set isDeleteModalOpen tarck value as false at end  of this method
        let recordToDelete = this.smsTemplateIdToDelete;
        let isRecordinAllList = this.lstAllTemplates.find((ele) => ele.TemplateId === recordToDelete);
        
        if(isRecordinAllList !== null || isRecordinAllList !== undefined || isRecordinAllList !== ''){
            this.isLoading = true;
            this.deleteRecordCallApex(recordToDelete);
            if(recordToDelete == this.smsTemplateIdToEdit){
                this.createNewForm=true;
                this.editExistingForm=false;
                //this.FormHeader='New SMS Template';
            }
            this.isLoading = false;
        }
    }
    
    //Iperative Apex Call Out to delete Record
    deleteRecordCallApex(recordToDelete){
        this.isLoading = true;
        //Add your code to call apex method or do some processing
        deleteRecord({ TemplateIdToDelete : recordToDelete }) 
        .then((result) =>{
            if(result == '** Record deleted successfully **'){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title:'Template Deleted',
                        message:'Message template deleted successfully',
                        variant:'success',
                    })
                    );
                }
                this.checkboxchecked = false;
                return refreshApex(this.wiredSMSTemplatesResult);
            })
            .catch(error =>{
                this.error = error;
                this.isLoading = false;
            });
            this.isDeleteModalOpen = false;
            this.isLoading = false;
        }
        
        FireRefreshApex(event){
            this.isLoading = true;
            let dmlType=event.detail;
            if(dmlType !== 'Cancel'){
                this.checkboxchecked = false;
            }
            this.isLoading = false;
            this.isAddEditModalOpen = false;
            return refreshApex(this.wiredSMSTemplatesResult);
        }

        handleCreateNewTemplatebutton(){
            this.smsTemplateIdToEdit=null;
            this.smsTemplateName = '';
            this.smsTemplateIsActive = false;
            this.smsTemplateBodyForEdit = '';

            this.smsTempObjectName = '';
            this.smsTempCreatedBy = this.currentUserName;
            this.smsTempCreatedByDate = '(Created date and time)';
            this.smsTempCreatedByTime = '';
            this.smsTempLastModifiedBy = this.currentUserName;
            this.smsTempLastModifiedByDate = '(Modified date and time)';
            this.smsTempLastModifiedByTime = '';

            this.FormHeader='New SMS Template';
            this.isAddEditModalOpen=true;
            this.PopUpHeader = 'New SMS Template';
        }

        CancelNewCreation(){
            // to close modal set isAddEditModalOpen tarck value as false
            this.isAddEditModalOpen = false;
        }
    }     
    
    //update the list SMS Templates after deleting the recordToDelete
    /*       updateListOfSMSTemplates(recordToDelete){
        console.log('recordToDelete--',recordToDelete);
        
        //remove Deleted record from lstAllTemplates
        let varItemsList = this.lstAllTemplates;
        for(let i = 0; i < varItemsList.length; i++){
            if(recordToDelete === varItemsList[i].TemplateId){ 
                varItemsList.splice([i], 1); // At position [i], remove 1 item 
            }
        }
        //create a shadow copy first and then assign to 'lstAllActiveTemplates' to make changes visible on UI
        this.lstAllTemplates = [...varItemsList];
        this.data = [...varItemsList];
        //update Array.Length values
        this.AllTemplatesCount=this.lstAllTemplates.length;
        
        //if deleted record is in active sms template list then remove it from that 'lstAllActiveTemplates' as well
        let varActiveItemsList = this.lstAllActiveTemplates;
        let isRecordinActiveList = varActiveItemsList.find((ele) => ele.TemplateId === recordToDelete);
        
        if(isRecordinActiveList !== null || isRecordinActiveList !== undefined || isRecordinActiveList !== ''){
            for(let i = 0; i < varActiveItemsList.length; i++){
                if(recordToDelete === varActiveItemsList[i].TemplateId){ 
                    varActiveItemsList.splice([i], 1); // At position [i], remove 1 item 
                }
            }
            //create a shadow copy first and then assign to 'lstAllActiveTemplates' to make changes visible on UI
            this.lstAllActiveTemplates = [...varActiveItemsList];
            //update Array.Length values
            this.ActiveTemplatesCount=varActiveItemsList.length;
        }
        this.checkboxLabel = 'Show Active Templates ( Total: '+this.AllTemplatesCount+', Active: '+this.ActiveTemplatesCount+' )';
    }
    */