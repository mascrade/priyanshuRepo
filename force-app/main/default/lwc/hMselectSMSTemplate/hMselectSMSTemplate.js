import { LightningElement, track, api, wire } from 'lwc';
import getCaseDataForUpdateTemplate from '@salesforce/apex/HM_Select_SMS_Template.getCaseDataForUpdateTemplate';
import getDataForUpdateTemplate from '@salesforce/apex/HM_Select_SMS_Template.getDataForUpdateTemplate';
import getOwnerDataForUpdateTemplate from '@salesforce/apex/HM_Select_SMS_Template.getOwnerDataForUpdateTemplate';
import GetAllSMSTemplates from '@salesforce/apex/HM_Select_SMS_Template.GetAllSMSTemplates';

export default class Select_SMS_Template extends LightningElement {
    @api recordId;
    @track lstAllTemplates = [];
    @track AllTemplateList = []; //it contains all the template records.
    @api isLoading = false;
    @track SelectedTemplateBody;
    @track UpdatedTemplateBody ='SMS template will be visible here after selection...';
    @track DisableSelect = false;
    @track ZeroMatchingTemplate = false;
    @track MatchingTemplatesFound = true;
    
    @wire(GetAllSMSTemplates) 
    WireSMSTemplates({error, data}){
        this.isLoading = true;
        if(data){
            console.log('data in wire ========',data);
            this.lstAllTemplates = data.map((item)=>({...item}));
            this.AllTemplateList = data.map((item)=>({...item}));
            console.log('----Template list-----',this.lstAllTemplates);
            this.error = undefined;
            this.isLoading = false;
            this.DisableSelect = true;
        }
        else{
            this.error = error;
            this.lstAllTemplates = undefined;
        }
    }
    
    handleRadioSelect(event){
        console.log('in handleRadioSelect ');
        let foundelement = this.lstAllTemplates.find((ele) => ele.TemplateId === event.target.value);
        let templObjName = foundelement.objName;
        console.log('templObjName = '+templObjName);
        this.SelectedTemplateBody = foundelement.Body;
        
        if(foundelement.Body.length != 0){
            this.isLoading = true;    
            
            this.DisableSelect = false;
            
            let regExp = /{[\w.]+}/g;
            //let regExp = /{\w+.\w+}/g; (this is also working)
            let retrievedResult = this.SelectedTemplateBody.match(regExp);     
            console.log('retrievedResult =  ',retrievedResult);
            if(retrievedResult != null && retrievedResult.length != 0){
                
                let lstReplacingVars = [];
                let FieldsQueryStringList = []; //<---
                let CaseQueryStringList = [];
                let UserQueryStringList = [];
                
                for (let i = 0; i < retrievedResult.length; i++) {
                    let update1 = retrievedResult[i].replace(/{/g,'');
                    let update2 = update1.replace(/}/g,'');
                    
                    // push all fields to a list 'lstReplacingVars'
                    lstReplacingVars.push(String(update2)); 
                }
                console.log('lstReplacingVars---',lstReplacingVars);
                
                // to remove duplicate values from List<string>
                let uniqueStringList = [...new Set(lstReplacingVars)]; 
                
                //logic to separate Case/Related Object fields and Owner/User fields
                for(let j = 0; j < uniqueStringList.length; j++){
             
                        FieldsQueryStringList.push(String(uniqueStringList[j]));
                        CaseQueryStringList.push(String(uniqueStringList[j]));
                  //  }
                }
                
                
                //a joined string of Case fields to send to apex for quering
                let joinedFieldString = FieldsQueryStringList.join(',');
                
                //a joined string of User/Owner fields to send to apex for quering
                //since all fields cannot be queried through 'Owner.' relationship fields
                //whereas we can query all fields from user wher Id = Case OwnerId
                let joinedOwnerString = UserQueryStringList.join(',');
                console.log('joinedFieldString = '+joinedFieldString);
                console.log('lstReplacingVars = '+lstReplacingVars);
                console.log('UserQueryStringList = '+UserQueryStringList);
                console.log('SelectedTemplateBody = '+this.SelectedTemplateBody);

                this.CallApexForData(joinedFieldString,lstReplacingVars,UserQueryStringList,joinedOwnerString, templObjName);

            }else{
                // if there are no API fields in body
                this.UpdatedTemplateBody = this.SelectedTemplateBody;
                this.isLoading = false;
            }
        }else{
            // if template body is Empty
            this.UpdatedTemplateBody = '*** Template Body is blank ***';
            this.isLoading = false;
        }
    }   
    
    
    //contains imperative apex callout and logic for mapping varibles in body and apex returned resuts
    CallApexForCaseData(joinedString,lstReplacingVars,UserQueryStringList,joinedOwnerString){
        
        let FinalResult;
        getCaseDataForUpdateTemplate({CaseId: this.recordId, QueryString:joinedString})
        .then(result=>{
            this.isLoading = true;
            console.log('Case result from Apex---',result);
            
            //check if UserQueryStringList is blank and if not then  then call server/apex controller to get the User field values
            //i.e if body contains owner fields then Manipulate FinalResult
            if(UserQueryStringList.length != 0 && UserQueryStringList.length > 0){
                
                getOwnerDataForUpdateTemplate({CaseId: this.recordId, QueryString:joinedOwnerString})
                .then(data=>{
                    console.log('User data from Apex---',data);
                    FinalResult = {...result,...{'Owner' : data}}; // final merged result will be in FinalResult
                    console.log('FinalResult ---',FinalResult);
                    
                    //Call another method to perform update body logic
                    //updatedBody contains Owner related fields
                    this.PerformUpdateBodyLogic(FinalResult,lstReplacingVars);
                })
                .catch(error=>{
                    this.error = error;
                    console.log(this.error); // to get error message in inspect logs
                    this.isLoading = false;
                });
            }//or else don't Manipulate FinalResult (assign result directly to FinalResult)
            else{
                FinalResult = result;
                console.log('FinalResult ---',FinalResult);
                
                //Call another method to perform update body logic
                //updatedBody does not contain Owner related fields
                this.PerformUpdateBodyLogic(FinalResult,lstReplacingVars);
            }
            //this.isLoading = false;           
        })
        .catch(error=>{
            this.error = error;
            console.log(this.error); // to get error message in inspect logs
            this.isLoading = false;
        });
    }
    
    CallApexForData(joinedString,lstReplacingVars,UserQueryStringList,joinedOwnerString, templObjName){
        
        console.log('templObjName from CallApexForData : ',templObjName);

        let FinalResult;
        getDataForUpdateTemplate({objId: this.recordId, QueryString:joinedString, objName:templObjName})
        .then(result=>{
            this.isLoading = true;
            console.log('Data from Apex---',result);
            
            //check if UserQueryStringList is blank and if not then  then call server/apex controller to get the User field values
            //i.e if body contains owner fields then Manipulate FinalResult
            console.log('UserQueryStringList = '+UserQueryStringList);
            if(UserQueryStringList.length != 0 && UserQueryStringList.length > 0){
                
                getOwnerDataForUpdateTemplate({CaseId: this.recordId, QueryString:joinedOwnerString})
                .then(data=>{
                    console.log('User data from Apex---',data);
                    FinalResult = {...result,...{'Owner' : data}}; // final merged result will be in FinalResult
                    console.log('FinalResult ---',FinalResult);
                    
                    //Call another method to perform update body logic
                    //updatedBody contains Owner related fields
                    this.PerformUpdateBodyLogic(FinalResult,lstReplacingVars);
                })
                .catch(error=>{
                    this.error = error;
                    console.log(this.error); // to get error message in inspect logs
                    this.isLoading = false;
                });
            }//or else don't Manipulate FinalResult (assign result directly to FinalResult)
            else{
                FinalResult = result;
                console.log('FinalResult ---',FinalResult);
                
                //Call another method to perform update body logic
                //updatedBody does not contain Owner related fields
                this.PerformUpdateBodyLogic(FinalResult,lstReplacingVars);
            }
            //this.isLoading = false;           
        })
        .catch(error=>{
            this.error = error;
            console.log(this.error); // to get error message in inspect logs
            this.isLoading = false;
        });
    }
    
    PerformUpdateBodyLogic(FinalResult,lstReplacingVars){
        let finalTemplateBody;
        if(FinalResult != null){
            this.isLoading = true;
            finalTemplateBody = this.SelectedTemplateBody;
            
            for (let i = 0; i < lstReplacingVars.length; i++) {
                
                // create regex pattern string for replacing it afterwards
                let regExpVar = new RegExp('{'+lstReplacingVars[i]+'}');
                
                if(lstReplacingVars[i].includes(".")==true){
                    let lookupObject = lstReplacingVars[i].split('.');
                    let lookupObjectValue = FinalResult[lookupObject[0]];
                    let NestedValue;
                    if(lookupObjectValue === undefined){
                        NestedValue = '{IS BLANK}';
                    }else{
                        NestedValue = lookupObjectValue[lookupObject[1]];
                    }

                    if(NestedValue === undefined){
                        NestedValue = '{IS BLANK}';
                    }
                    finalTemplateBody = finalTemplateBody.replace(regExpVar, NestedValue);
                }else{
                    let ObjectValue = FinalResult[lstReplacingVars[i]];
                    if(ObjectValue === undefined){
                        ObjectValue = '{IS BLANK}';
                    }
                    finalTemplateBody = finalTemplateBody.replace(regExpVar, ObjectValue);
                }
                
            }
            this.UpdatedTemplateBody = finalTemplateBody;
            this.error = undefined;
            this.isLoading = false;
        }else{
            this.UpdatedTemplateBody = '*** Error: Incorrect variable names found in template body, edit them as per requirement ***';
            this.isLoading = false;
        }
        console.log('UpdatedTemplateBody---->>>  ',this.UpdatedTemplateBody);
        //console.log('JSON String UpdatedTemplateBody---->>>  ',JSON.stringify(this.UpdatedTemplateBody));
        //let breakLine = String('\n');
        //let richtextTempBody = JSON.stringify(this.UpdatedTemplateBody).replace(/\n/g,'<br>');
        //console.log('richtextTempBody---->>>  ',richtextTempBody);
        
    }
    
    handleOnUseTemplateSelect(){
        if (this.SelectedTemplateBody == undefined || this.UpdatedTemplateBody == undefined) {
            console.log('SMS Template not selected');
        }else{
            this.dispatchEvent( new CustomEvent( 'pass', {
                detail: this.UpdatedTemplateBody
            } ) );
            //console.log(this.UpdatedTemplateBody);
        }
    }
    
    handleKeyChange(event){
        this.isLoading = true;
        let searchValue = event.target.value;
        //just some alternate stringCase conditions created for checking
        let strLowCase = searchValue.toLowerCase();
        let strUpCase = searchValue.toUpperCase();
        let strFisrtCap = searchValue.charAt(0).toUpperCase() + searchValue.slice(1).toLowerCase();

        let filteredList = this.AllTemplateList.filter((ele) => ele.TemplateName.includes(searchValue) || ele.TemplateName.includes(strLowCase) || ele.TemplateName.includes(strUpCase) || ele.TemplateName.includes(strFisrtCap));
        this.lstAllTemplates = filteredList;
        if(filteredList.length == 0){
            this.ZeroMatchingTemplate = true;
            this.MatchingTemplatesFound = false;
        }else{
            this.ZeroMatchingTemplate = false;
            this.MatchingTemplatesFound = true;
        }
        this.isLoading = false;
    }

    closeSectionModal(){
        console.log('In Close Section Modal');
        let closeParentSection = 'Close Section Modal';
        this.dispatchEvent( new CustomEvent( 'pass', {
            detail: closeParentSection
        } ) );
    }
}