import { LightningElement, api, wire, track } from 'lwc';
import GetCaseFieldAPInames from '@salesforce/apex/HM_SMSTempApexController.GetCaseFieldAPInames';
import GetContactFieldAPInames from '@salesforce/apex/HM_SMSTempApexController.GetContactFieldAPInames';
import GetUserFieldAPInames from '@salesforce/apex/HM_SMSTempApexController.GetUserFieldAPInames';
import GetAccountFieldAPInames from '@salesforce/apex/HM_SMSTempApexController.GetAccountFieldAPInames';
import GetCustomSettingObjectNames from '@salesforce/apex/HM_SMSTempApexController.GetCustomSettingObjectNames';
import GetFieldAPInames from '@salesforce/apex/HM_SMSTempApexController.GetFieldAPInames';
import SaveTemplate from '@salesforce/apex/HM_SMSTempApexController.SaveTemplate';

/*
import SMStemplate_OBJECT from '@salesforce/schema/HM_SMS_Template__c';
import NAME_FIELD from '@salesforce/schema/HM_SMS_Template__c.HM_Name__c';
import BODY_FIELD from '@salesforce/schema/HM_SMS_Template__c.HM_Template_Body__c';
import IsActive_FIELD from '@salesforce/schema/HM_SMS_Template__c.HM_Is_Active__c';
import CreatedBy_FIELD from '@salesforce/schema/HM_SMS_Template__c.CreatedBy.Name';
import ModifiedBy_FIELD from '@salesforce/schema/HM_SMS_Template__c.LastModifiedBy.Name';   */
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningAlert from 'lightning/alert';

export default class Advance_SMS_Template_Creation extends LightningElement {
    /*
    smstempObject = SMStemplate_OBJECT;
    nameField = NAME_FIELD;
    bodyField = BODY_FIELD;
    IsActiveField = IsActive_FIELD;
    myFields = [NAME_FIELD, BODY_FIELD, IsActive_FIELD, CreatedBy_FIELD, ModifiedBy_FIELD]; */

    @api prop2;

    @track ListCustomSettingObjNames = [];
    @track ListFieldAPINames = [];
    @track ListCaseFieldAPInames = [];  //  from wire
    @track ListContactFieldAPInames = []; //  from wire
    @track ListUserFieldAPInames = []; //  from wire
    @track ListAccountFieldAPInames = []; //  from wire
    @track ListFieldAPINamesDropdown3 = [];

    //@track showCreateNewButton=false;

    @api isLoading = false;
    //@track CreateNewTemplate = true;
    @track showDropdown1 = true;
    @track showDropdown2 = false;
    @track showDropdown3 = false;
    @track OpenRelatedFields = false;
    @track APIdisplay = false;

    @track APInametoCopy = '';
    @track LabelName = '';
    @track parent;

    @track isInsertFieldModal = false;
    @track openConfirmationBox = false;
    //@track objectNotSelected = true; //TBD
    @track dropDown1Value = '';
    @track oldDropDown1Api = 'Select';
    @track displayWarning = false;
    @track dropDwn1Selected = false;
    @api contactApi;

    mapParentLabelLookUpName;
    parentApiName;
    //@track textValue='';
    //@track disableInsertFieldButton=false;

    //get Case Field Labels and API names using Wire
    @wire(GetCaseFieldAPInames)
    WireGetCaseFieldAPInames({ error, data }) {
        this.isLoading = true;
        if (data) {
            //console.log('data========',data);
            let conts = data;
            this.ListCaseFieldAPInames.push({ Label: 'Contact >', API: 'GetContactFieldAPInames' });
            this.ListCaseFieldAPInames.push({ Label: 'Case Owner (User) >', API: 'GetUserFieldAPInames' });
            this.ListCaseFieldAPInames.push({ Label: 'Account >', API: 'GetAccountFieldAPInames' });
            for (let key in conts) {
                this.ListCaseFieldAPInames.push({ Label: key, API: conts[key] }); //Here we are creating the array to show on UI.
            }
            //console.log('this.List--Case--FieldAPInames========',this.ListCaseFieldAPInames);
            this.error = undefined;
            this.isLoading = false;
        }
        else {
            this.error = error;
            this.isLoading = false;
        }
    }

    //get custom setting names and API names using Wire
    @wire(GetCustomSettingObjectNames)
    WireGetCustomSettingObjectNames({ error, data }) {
        this.isLoading = true;
        if (data) {
            console.log('CS data========', data);
            //console.log('obj Name = ',this.smsTempObject);
            console.log('obj Name = ', this.smsTempObjectapi);
            let conts = data;
            for (let key in conts) {
                this.ListCustomSettingObjNames.push({ Label: key, API: conts[key] }); 

            }

            if (this.smsTempObjectapi) {
                
                //look for api name from ListCustomSettingObjNames 
                let foundelement = this.ListCustomSettingObjNames.find((ele) => ele.API === this.smsTempObjectapi);
                this.smsTempObject = foundelement.Label;
                this.dropDown1Value = this.smsTempObjectapi;
                this.oldDropDown1Api = this.smsTempObjectapi; //stores old value of DropDown 1
                console.log('smsTempObjectapi = ' + this.smsTempObjectapi);
                console.log('smsTempObject = ' + this.smsTempObject);
            } else {
                this.smsTempObject = 'Select Object';
                this.smsTempObjectapi = 'Select';
            }

            this.error = undefined;
            this.isLoading = false;
        }
        else {
            this.error = error;
            this.isLoading = false;
        }
    }

    //get Contact Field Labels and API names using Wire
    @wire(GetContactFieldAPInames)
    WireGetContactFieldAPInames({ error, data }) {
        this.isLoading = true;
        if (data) {
            //console.log('data========',data);
            let conts = data;
            for (let key in conts) {

                if (key == 'Other Address' || key == 'Mailing Address') {
                    //console.log(key);
                } else {
                    this.ListContactFieldAPInames.push({ Label: key, API: conts[key] }); //Here we are creating the array to show on UI.
                }
            }
            //console.log('this.List--Contact--FieldAPInames========',this.ListContactFieldAPInames);
            this.error = undefined;
            this.isLoading = false;
        }
        else {
            this.error = error;
            this.isLoading = false;
        }
    }

    //get User Field Labels and API names using Wire
    @wire(GetUserFieldAPInames)
    WireGetUserFieldAPInames({ error, data }) {
        this.isLoading = true;
        if (data) {
            //console.log('data========',data);
            let conts = data;
            for (let key in conts) {
                if (key == 'Address') {
                    //console.log(key);
                } else {
                    //Here we are creating the array to show on UI.
                    this.ListUserFieldAPInames.push({ Label: key, API: conts[key] }); //Here we are creating the array to show on UI.
                }
            }
            //console.log('this.List--User--FieldAPInames========',this.ListUserFieldAPInames);
            this.error = undefined;
            this.isLoading = false;
        }
        else {
            this.error = error;
            this.isLoading = false;
        }
    }

    //get Account Field Labels and API names using Wire
    @wire(GetAccountFieldAPInames)
    WireGetAccountFieldAPInames({ error, data }) {
        this.isLoading = true;
        if (data) {
            //console.log('data========',data);
            let conts = data;
            for (let key in conts) {
                if (key == 'Billing Address' || key == 'Shipping Address') {
                    //console.log(key);
                } else {
                    //Here we are creating the array to show on UI.
                    this.ListAccountFieldAPInames.push({ Label: key, API: conts[key] });
                }
            }
            //console.log('this.List--Account--FieldAPInames========',this.ListAccountFieldAPInames);
            this.error = undefined;
            this.isLoading = false;
        }
        else {
            this.error = error;
            this.isLoading = false;
        }
    }


    @track ListLabelandAPI = []; // value assigned dynamically in onchageEvent
    Selectedlookup = ''; // value assigned dynamically in onchageEvent

    handleTemplateCreated() {
        //this.isLoading = true;
        console.log('SMS template is Created');
        const CreatedToastEvent = new ShowToastEvent({
            title: 'Success',
            message: 'Template Created Successfully',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(CreatedToastEvent);

        this.dispatchEvent(new CustomEvent('pass', {
            detail: 'Record Created'
        }));
    }

    handleTemplateUpdated() {
        console.log('SMS template is Updated');
        const event = new ShowToastEvent({
            title: 'Success',
            message: 'Template Updated Successfully',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
        this.dispatchEvent(new CustomEvent('pass', {
            detail: 'Record Updated'
        }));
    }

    handle_Dropdown_1_Click(event) {
        //console.log('in handle_Dropdown_1_Click');
        this.displayWarning = true;

        //console.log('this.oldDropDown1Api : '+this.oldDropDown1Api);
        let api = event.target.value;
        console.log('api : ' + api);

        //console.log('this.toSaveTempBody : '+this.toSaveTempBody);

        if (api != 'Select') {
            this.smsTempObject = 'Select Object';
            this.smsTempObjectapi = 'Select';
        }
        
    }

    handle_Dropdown_1_Selection(event) {
        this.dropDwn1Selected = true;
        this.ListFieldAPINames = [];
        console.log('in handle_Dropdown_1_Selection');
        this.showDropdown2 = false;
        this.showDropdown3 = false;
        this.APIdisplay = false;
        // console.log('showDropdown2 : '+this.showDropdown2);
        let api = event.target.value;
        console.log('onchange D1 api : ' + api);

        console.log('oldDropDown1Api before update = ' + this.oldDropDown1Api);
        if (api != 'Select' && api != this.oldDropDown1Api) { //if current chosen value is not Select(obj Name) & doesn't equal old chosen val, then erase contents
            console.log('toSaveTempBody before erase = ' + this.toSaveTempBody);
            console.log('erase contents');
            this.template.querySelector('.slds-textarea').value = '';
            console.log('after template.querySelector ');

            console.log('toSaveTempBody after erase = ' + this.toSaveTempBody);
        }

        this.oldDropDown1Api = api;

        console.log('oldDropDown1Api after update = ' + this.oldDropDown1Api);
        this.showDropdown2 = true;

        if (api == 'Select') {
            this.dropDown1Value = '';
            this.showDropdown2 = false;
            this.APIdisplay = false;
            this.OpenRelatedFields = false;
            this.isLoading = false;
        }
        else {
            console.log('oldDropDown1Api initially = ' + this.oldDropDown1Api);

            if (this.oldDropDown1Api == 'Select') {
                this.oldDropDown1Api = api;
            }

            console.log('oldDropDown1Api = ' + this.oldDropDown1Api);
            let foundelement = this.ListCustomSettingObjNames.find((ele) => ele.API === api);
            let label = foundelement.Label;
            console.log('label : ' + label);

            this.dropDown1Value = api; 

            //call apex method : 
            GetFieldAPInames({ SFObj: api })
                .then(result => {
                    console.log('result GetFieldAPInames = ', result);
                    let conts = result[0];

                    this.mapParentLabelLookUpName = result[1];
                    console.log('this.mapParentLabelLookUpName = ', this.mapParentLabelLookUpName);

                    for (let key in conts) {
                        this.ListFieldAPINames.push({ Label: key, API: conts[key] }); //Here we are creating the array to show on UI.

                    }
                    console.log('this.ListFieldAPINames = ', this.ListFieldAPINames);

                    let mapLookUp = result[1];
                    for (let key in mapLookUp) {
                        if (key = 'Contact') {
                            this.contactApi = mapLookUp[key];
                            if (this.contactApi.slice(-2) == "Id") {
                                this.contactApi = this.contactApi.slice(0, -2);
                            }
                        }
                    }
                    console.log('this.contactApi = ', this.contactApi);
                    console.log('this.ListFieldAPINames = ', this.ListFieldAPINames);

                }).catch(error => {
                    console.log('error GetFieldAPInames = ', error);
                });

        }
    }

    handle_Dropdown_2_Selection(event) {
        console.log('in handle_Dropdown_2_Selection');
        this.ListFieldAPINamesDropdown3 = [];
        this.showDropdown3 = false;
        this.APIdisplay = false;

        this.isLoading = true;

        let api = event.target.value;
        console.log('selected api = ', api);
        //  console.log('selected label = ',event.target.label);

        if (api == 'Select') {
            this.showDropdown3 = false;
            this.APIdisplay = false;
            this.OpenRelatedFields = false;
            this.isLoading = false;
        }
        else {
            //  let foundelement = this.ListCaseFieldAPInames.find((ele) => ele.API === api);
            let foundelement = this.ListFieldAPINames.find((ele) => ele.API === api);
            let label = foundelement.Label;

            console.log('label----', label);

            if (label.includes(">")) {

                //remove '>' from label
                let sLabel = label;
                sLabel = sLabel.replace('>', '');
                console.log('sLabel 1 : ' + sLabel);

                //remove white space
                sLabel = sLabel.replace(/\s/g, "");

                console.log('mapParentLabelLookUpName : ', this.mapParentLabelLookUpName);
                let mapResult = this.mapParentLabelLookUpName;

                //look for label in mapParentLabelLookUpName
                for (let key in mapResult) {
                    console.log('value : ', mapResult[key]);
                    console.log('key : ', key);
                    console.log('sLabel : ', sLabel);
                    if (key == sLabel) {
                        this.parent = mapResult[key];
                        break;
                    }
                  /*  if (key == 'Owner') {
                        this.parent = 'Owner';
                    }   */
                    if (key == 'User') {
                        this.parent = 'Owner';
                    }   
                }

                this.isLoading = false;
                console.log('is a parent!');
                if(sLabel == 'Owner'){
                      this.parent =  'Owner'; 
                }
                //store parent api or sobject name in a field
                //  this.parent = api;

                if(api == 'Owner'){
                   api = 'User'; 
                }

                this.showDropdown3 = true;
                this.APIdisplay = false;
                //call apex method : 
                GetFieldAPInames({ SFObj: api })
                    .then(result => {
                        console.log('result GetFieldAPInames = ', result);
                        let conts = result[0];
                        for (let key in conts) {
                            //  console.log('key : ',key); 
                            if (!(key.includes(">"))) {
                                this.ListFieldAPINamesDropdown3.push({ Label: key, API: conts[key] }); //Here we are creating the array to show on UI.
                            }
                        }
                        console.log('this.ListFieldAPINamesDropdown3 = ', this.ListFieldAPINamesDropdown3);

                    }).catch(error => {
                        console.log('error GetFieldAPInames = ', error);
                    });
            }
            else {
                /*   if(api == 'GetContactFieldAPInames' || api == 'GetUserFieldAPInames' || api == 'GetAccountFieldAPInames' || api == 'GetCustomSettingObjectNames'){
           
                       //console.log('api == GetContactFieldAPInames || api == GetUserFieldAPInames' || api == 'GetAccountFieldAPInames');
                       if(api == 'GetContactFieldAPInames'){
                           console.log('api == GetContactFieldAPInames');
                           this.ListLabelandAPI = this.ListContactFieldAPInames;
                           this.Selectedlookup = 'Contact';
                           console.log('this.Selectedlookup--',this.Selectedlookup);
                       }
                       if(api == 'GetUserFieldAPInames'){
                           console.log('api == GetUserFieldAPInames');
                           this.ListLabelandAPI = this.ListUserFieldAPInames;
                           this.Selectedlookup = 'User';
                           console.log('this.Selectedlookup--',this.Selectedlookup);
                       }
                       if(api == 'GetAccountFieldAPInames'){
                           console.log('api == GetAccountFieldAPInames');
                           this.ListLabelandAPI = this.ListAccountFieldAPInames;
                           this.Selectedlookup = 'Account';
                           console.log('this.Selectedlookup--',this.Selectedlookup);
                       }
                       if(api == 'GetCustomSettingObjectNames'){   //<---
                           console.log('api == GetCustomSettingObjectNames');
                           this.ListLabelandAPI = this.ListCustomSettingObjNames;
                           this.Selectedlookup = 'Account';
                           console.log('this.Selectedlookup--',this.Selectedlookup);
                       }
           
                       this.APIdisplay = false;
                       this.OpenRelatedFields = true;
           
                       setTimeout(() => { 
                           const picklist2value = this.template.querySelector('[name="picklist2value"]'); 
                           picklist2value.selectedIndex = [...picklist2value.options].findIndex(option => option.value === 'Select'); 
                       },200);
           
                       this.isLoading = false;
                       //console.log('api == GetContactFieldAPInames');
                   }   */
                //  else{
                this.APIdisplay = true;
                this.LabelName = label;
                this.APInametoCopy = '{' + api + '}';
                this.isLoading = false;
                // }
            }
        }

    }

    handle_Dropdown_3_Selection(event) {

        console.log(' in handle_Dropdown_3_Selection');

        this.isLoading = true;
        this.APIdisplay = true;

        let api = event.target.value;
        console.log('selected api = ', api);

        if (api == 'Select') {
            this.APIdisplay = false;
            this.OpenRelatedFields = false;
            this.isLoading = false;
        } else {

            let foundelement = this.ListFieldAPINamesDropdown3.find((ele) => ele.API === api);
            let label = foundelement.Label;
            this.APIdisplay = true;
            this.LabelName = label;
            this.APInametoCopy = '{' + api + '}';

            console.log('parent abc : '+this.parent);
            if (this.parent == 'User') {
                this.APInametoCopy = '{Owner.' + api + '}';
            } else {
                console.log('parent = ' + this.parent);
                if (this.parent.includes("__c")) {
                    this.parent = this.parent.replace("__c", "__r");
                } else if (this.parent.slice(-2) == "Id") {
                    console.log('ends with Id');
                    this.parent = this.parent.slice(0, -2);
                    console.log('this.parent after slicing = ' + this.parent);
                }
                this.APInametoCopy = '{' + this.parent + '.' + api + '}';
                //   this.APInametoCopy = '{'+this.Selectedlookup+'.'+api+'}';
            }

            //   console.log('APInametoCopy : '+this.APInametoCopy);
            this.isLoading = false;
        }

    }

    handle_Picklist_2_Selection(event) {
        console.log('in handle_Picklist_2_Selection');
        this.isLoading = true;
        this.APIdisplay = true;
        let api = event.target.value;
        console.log('selected api = ', api);
        if (api == 'Select') {
            this.APIdisplay = false;
            this.isLoading = false;
        }
        else {
            let foundelement;
            foundelement = this.ListLabelandAPI.find((ele) => ele.API === api);

            if (this.Selectedlookup == 'User') {
                this.APInametoCopy = '{Owner.' + api + '}';
            } else {
                this.APInametoCopy = '{' + this.Selectedlookup + '.' + api + '}';
            }
            let label = foundelement.Label;

            console.log('api----', api);
            this.LabelName = label;
            this.isLoading = false;
        }
    }

    @track toCopy = true;
    @track Copied = false;
    copyToClipboard() {
        let copyMe = this.template.querySelector('.copy-me');
        console.log(copyMe);
        copyMe.select();
        copyMe.setSelectionRange(0, 9999999);
        document.execCommand('copy');
        this.toCopy = false;
        this.Copied = true;

        setTimeout(() => {
            this.toCopy = true;
            this.Copied = false;
        }, 2000);
    }

    CloseAddEditModal() {
        //console.log('in CloseAddEditModal');
        this.dispatchEvent(new CustomEvent('pass', {
            detail: 'Cancel'
        }));
        //eval("$A.get('e.force:refreshView').fire();");
    }


    //from parent component to Edit Template
    @api smsTempIdToEdit;
    @api toSaveTempName;
    @api toSaveTempActive;
    @api toSaveTempBody;
    //@track toSaveTempBody;
    @api createNewForm;
    @api smsTempObject;
    @api smsTempObjectapi;
    @api editExistingForm;
    @api smsTempCreatedBy;
    @api smsTempCreatedByDate;
    @api smsTempCreatedByTime;
    @api smsTempLastModifiedBy;
    @api smsTempLastModifiedByDate;
    @api smsTempLastModifiedByTime;
   

    @api formHeader;

    handleTempNameChange(event) {
        console.log('smsTempObject = ' + this.smsTempObject);
        this.toSaveTempName = event.target.value;
        //console.log('this.toSaveTempName - ',this.toSaveTempName);
    }
    handleTempActiveChange(event) {
        this.toSaveTempActive = event.target.checked;
        //console.log('this.toSaveTempName - ',this.toSaveTempActive);
    }

    handleTempBodyChange(event) {
        console.log('in handleTempBodyChange');
        this.toSaveTempBody = event.target.value;
        console.log('toSaveTempBody = ' + this.toSaveTempBody);
    }

    handleSaveTemplate(event) {

        this.isLoading = true;
        let message = this.template.querySelector('.slds-textarea');
        this.toSaveTempBody = message.value;


        console.log('this.dropDown1Value : ' + this.dropDown1Value);

        if (!this.dropDown1Value) { //dropdown 1 or object not selected
            this.isLoading = false;
            //show error toast
            let eventObjectNotSelected = new ShowToastEvent({
                title: 'Object not selected',
                message: 'Please select an object before saving!',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(eventObjectNotSelected);
            return;
        }

        console.log('this.dropDown1Value before SaveTemplate : ' + this.dropDown1Value);
        console.log('something');
        console.log('this.toSaveTempBody : ' + this.toSaveTempBody);
        console.log('this.smsTempIdToEdit : ' + this.smsTempIdToEdit);
        console.log('this.contactApi : ' + this.contactApi);

        SaveTemplate({ TemplateIdToEdit: this.smsTempIdToEdit, TemplateName: this.toSaveTempName, IsActive: this.toSaveTempActive, Body: this.toSaveTempBody, selectedObject: this.dropDown1Value, contactLookUpName: this.contactApi })
            .then((result) => {
                console.log('result = '+result);
              /*  if (result.includes('Required fields are missing: [Name]: [Name]') || result == 'Template Body is Blank') {
                    let event = new ShowToastEvent({
                        title: 'Error',
                        message: 'Template Name/Template Body cannot be blank',
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(event);
                    this.isLoading = false;
                } else*/ if(result.includes('Template Body is Blank')){
                    let event = new ShowToastEvent({
                        title: 'Error',
                        message: 'Template Body is Blank',
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(event);
                    this.isLoading = false;
                }else if(result.includes('Object Name is Blank')){
                    let event = new ShowToastEvent({
                        title: 'Error',
                        message: 'Object Name is Blank',
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(event);
                    this.isLoading = false;
                }else if(result.includes('Contact LookUp Name is Blank')){
                    let event = new ShowToastEvent({
                        title: 'Error',
                        message: 'Contact LookUp Name is Blank',
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(event);
                    this.isLoading = false;
                }

                else {
                    if (this.smsTempIdToEdit == null) {
                        this.handleTemplateCreated();
                    } else {
                        this.handleTemplateUpdated();
                    }
                    this.isLoading = false;
                }
            })
            .catch(error => {
                this.error = error;
                console.log(this.error); // to get error message in inspect logs
                this.isLoading = false;
            });
    }

    cancelOptionChange() {
        console.log('in cancelOptionChange');
        // to close modal set isDeleteModalOpen tarck value as false
        this.openConfirmationBox = false;
    }

    confirmedYesChange() {
        this.openConfirmationBox = false;
        return;

    }

}