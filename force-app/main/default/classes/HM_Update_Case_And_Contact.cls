/*
* Name               : HM_Update_Case_And_Contact
* Description        : Apex REST Resource for Case Updatation- API Endpoint to update a Case and Contact in Salesforce when a 
                      'Chatbot Finished WebHook' is called by Hi Marley.
* Author             : Rohit (Futran Solutions)
* Created On         : 10 Oct 2022
* Test Class         : HM_Test_HM_Create_CaseIn_SF
* Change Log History : 
*  |------------------------------------------------------------------------------|
*  | Version | Modified By        | Date        | Comment                         |
*  |------------------------------------------------------------------------------|
*  | 0.1     | Rohit              | 10 Oct 2022 | Initial Version of Apex Class---|
*  |------------------------------------------------------------------------------|
*/

@RestResource(urlMapping='/HM_UpdateCaseAfterChatbotFinished/*')
global class HM_Update_Case_And_Contact {
    @HttpPost
    global Static string updateCASE(){
        
        //Case Response Message
        CaseResponseMsg caseResponse = new CaseResponseMsg();
        
        //define new instance of variables
        Case objCaseExist;
        string jSONRequestBody, CreatedCaseId, HMCaseIdinRequest;
        Boolean BradingStatus;
        Boolean CasePresent = false;
        //new instance of Case object
        Case objCase;
        
        //define new instance of Map<String, Object> to save the deserialized list
        Map<String, Object> Map_RequestBody = new Map<String, Object>();
        
        try {
            
            //get the body from request
            RestRequest UpdateCaseRequest = RestContext.request;
            RestResponse CaseResp = Restcontext.response;
            
            jSONRequestBody = UpdateCaseRequest.requestBody.tostring().trim();
            
            //Deserialize the specified JSON string into collections of Untyped data.
            Map_RequestBody = (Map<String, Object>)JSON.deserializeUntyped(jSONRequestBody);
            
            Map<String, Object> Map_caseData = (Map<String, Object>)Map_RequestBody.get('caseData'); // get 'caseData' from Map_RequestBody
            
            Map<String, Object> Map_customer = (Map<String, Object>)Map_RequestBody.get('customer');  // get 'customer' from Map_RequestBody
            
            //get custom settings : 'HM Case Fields Mapping (Inbound)'
            Map<String , HM_Case_Fields_Mapping_Inbound__c> Map_SF_CaseField = (Map<String, HM_Case_Fields_Mapping_Inbound__c>)HM_Case_Fields_Mapping_Inbound__c.getAll();
            
            //get custom setting: 'HM Branding' whether Branding is enabled or disabled
            Map<String , HM_Branding__c> map_HM_Branding = (Map<String, HM_Branding__c>)HM_Branding__c.getAll();
            BradingStatus = map_HM_Branding.get('Branding').HM_Enable_Branding__c; 
            
            HMCaseIdinRequest = String.valueOf(Map_caseData.get('id'));
            
            if(HMCaseIdinRequest != null){
                objCase = [SELECT Id, HM_Case_Id__c, HM_Brand__c, HM_Case_Status__c, HM_Case_Type__c
                           FROM Case 
                           WHERE HM_Case_Id__c =: HMCaseIdinRequest];
                system.debug('objCase--'+objCase);
            }else{
                HM_Integration_Helper.create_HMLogs('HM Case Id not found in request Body', 'Failure', '0','Inbound' , jSONRequestBody, 'NA','');
            }
            
            if(objCase != null){
                //traverse on keyset() of Map_SF_CaseField 
                for(string SF_Name: Map_SF_CaseField.keyset()){  
                    
                    // get sub object name field value where name is SF_Name
                    string subObjectName = Map_SF_CaseField.get(SF_Name).HM_API_sub_Object_Name__c; 
                    
                    // null check and if map contains key check
                    if(Map_RequestBody.containsKey(SF_Name) && Map_RequestBody.get(SF_Name) != null && Map_SF_CaseField.get(SF_Name).HM_API_sub_Object_Name__c != null){
                        //traverse on keyset() of Map_RequestBody i.e the request body
                        for(string HM_Name_key: Map_RequestBody.keyset()){   
                            if(subObjectName == HM_Name_key){
                                if(Map_RequestBody.get(SF_Name) != null){
                                    objCase.put(Map_SF_CaseField.get(SF_Name).HM_SF_Field__c, Map_RequestBody.get(SF_Name));
                                }
                            }
                        }
                    } 
                    // If the SF_Name/sub Object name is the sub object name is 'caseData'
                    else if(subObjectName == 'caseData' && Map_caseData.containsKey(SF_Name) && Map_caseData.get(SF_Name) != null){ 
                        if(Map_SF_CaseField.get(SF_Name).Name == 'brand'){
                            if (BradingStatus == true){
                                objCase.put(Map_SF_CaseField.get(SF_Name).HM_SF_Field__c, Map_caseData.get(SF_Name));
                            }
                        }
                        else{
                            objCase.put(Map_SF_CaseField.get(SF_Name).HM_SF_Field__c, Map_caseData.get(SF_Name));   
                        }
                    }
                    // If the SF_Name/sub Object name is the sub object name is 'customer'
                    else if(subObjectName == 'customer' && SF_Name.contains('ContactId') &&  Map_customer.get('id') != null){
                        
                        string updatedContactId = HM_Integration_Helper.updateContact(Map_customer);
                        
                        if(updatedContactId == null || string.isBlank(updatedContactId)){
                                HM_Integration_Helper.create_HMLogs('Error: Contact updation failed', 'Failure', '0','Inbound' , jSONRequestBody, 'NA','');
                                return 'Contact updation failed';
                        }else{
                            objCase.put(Map_SF_CaseField.get(SF_Name).HM_SF_Field__c, updatedContactId);
                        }
                    }
                }
                update objCase;
                caseResponse.Status = 'Success';
                caseResponse.Message = 'Case Updated Successfully';
                HM_Integration_Helper.create_HMLogs('Case Updated Successfully. Case Id = ' + objCase.Id, 'Success', '200','Inbound' , jSONRequestBody, 'NA', '');
            }else{
                HM_Integration_Helper.create_HMLogs('Case not Found with HM Case Id - '+HMCaseIdinRequest, 'Failure', '0','Inbound' , jSONRequestBody, 'NA','');
            } 
        }
        catch(Exception e) {
            caseResponse.Status = 'Update Failed';
            caseResponse.Message = e.getMessage();
            HM_Integration_Helper.create_HMLogs('Error: ' + e.getMessage(), 'Failure', '0','Inbound' , jSONRequestBody, 'NA','');
        }
        if(caseResponse.Message == 'List has no rows for assignment to SObject'){
            caseResponse.Message = 'Case not Found with matching Case Id';
        }
        return caseResponse.Status + ' - ' + caseResponse.Message;
    }
    
    //Inner Class For Case Response Message
    global class CaseResponseMsg {
        global String Status;
        global String message;
    }
}