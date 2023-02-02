/*
* Name               : HM_Create_CaseIn_SF
* Description        : Apex REST Resource for Case Creation- API Endpoint to create a case in Salesforce when a case is created in Hi Marley.
* Author             : Rohit (Futran Solutions)
* Created On         : 29 July 2022
* Test Class         : HM_Test_HM_Create_CaseIn_SF
* Change Log History : 
*  |------------------------------------------------------------------------------|
*  | Version | Modified By        | Date        | Comment                         |
*  |------------------------------------------------------------------------------|
*  | 0.1     | Rohit              | 02 Aug 2022 | Initial Version of Apex Class---|
*  |------------------------------------------------------------------------------|
*/

@RestResource(urlMapping='/HM_Create_CaseIn_SF/*')
global class HM_Create_CaseIn_SF {
    @HttpPost
    global Static string createCASE(){
        
        //Case Response Message
        CaseResponseMsg caseResponse = new CaseResponseMsg();
        
        //define new instance of strings
        string jSONRequestBody, CreatedCaseId, HMUserId, SFUserId;
        Boolean BradingStatus;
        
        //define new instance of Map<String, Object> to save the deserialized list
        Map<String, Object> Map_RequestBody = new Map<String, Object>();
        
        try {
            
            //get the body from request
            RestRequest CaseRequest = RestContext.request;
            RestResponse CaseResp = Restcontext.response;
            
            jSONRequestBody = CaseRequest.requestBody.tostring().trim();
            
            system.debug('jSONRequestBody--- '+jSONRequestBody);
            
            //Deserialize the specified JSON string into collections of Untyped data.
            Map_RequestBody = (Map<String, Object>)JSON.deserializeUntyped(jSONRequestBody);
            
            Map<String, Object> Map_caseData = (Map<String, Object>)Map_RequestBody.get('caseData'); // get 'caseData' from Map_RequestBody
            
            Map<String, Object> Map_customer = (Map<String, Object>)Map_RequestBody.get('customer');  // get 'customer' from Map_RequestBody
            
            Map<String, Object> Map_user = (Map<String, Object>)Map_RequestBody.get('primaryContact'); // get 'primaryContact' from Map_RequestBody
            
            //get custom settings : 'HM Case Fields Mapping (Inbound)'
            Map<String , HM_Case_Fields_Mapping_Inbound__c> Map_SF_CaseField = (Map<String, HM_Case_Fields_Mapping_Inbound__c>)HM_Case_Fields_Mapping_Inbound__c.getAll();
            
            //get custom setting: 'HM Branding' whether Branding is enabled or disabled
            Map<String , HM_Branding__c> map_HM_Branding = (Map<String, HM_Branding__c>)HM_Branding__c.getAll();
            BradingStatus = map_HM_Branding.get('Branding').HM_Enable_Branding__c; 
            
            //new instance of Case object
            Case objCase;
            List<User> lstUser;
            
            if(Map_user != null && Map_user.size() > 0){
                if(Map_user.containsKey('id') &&  Map_user.get('id') != null){
                    system.debug('(String)Map_user.get(id)'+(String)Map_user.get('id'));
                    HMUserId = (String)Map_user.get('id');
                    lstUser = [SELECT Id, Name, HM_Operator_Id__c,IsActive FROM User WHERE HM_Operator_Id__c =:HMUserId AND IsActive=true AND HM_Operator_Id__c != null LIMIT 1];
                    system.debug('objUser--'+lstUser);
                }
            }
            
            if(lstUser != null && lstUser.size() > 0){
                SFUserId = lstUser[0].Id;
            }
            
            system.debug('Map_SF_CaseField--'+Map_SF_CaseField);
            system.debug('Map_SF_CaseField--'+Map_SF_CaseField.keyset());
            //traverse on keyset() of Map_SF_CaseField 
            for(string SF_Name: Map_SF_CaseField.keyset()){  
                
                // get sub object name field value where name is SF_Name
                string subObjectName = Map_SF_CaseField.get(SF_Name).HM_API_sub_Object_Name__c; 
                
                // null check and if map contains key check
                if(Map_RequestBody.containsKey(SF_Name) && Map_RequestBody.get(SF_Name) != null && Map_SF_CaseField.get(SF_Name).HM_API_sub_Object_Name__c != null){
                    //traverse on keyset() of Map_RequestBody i.e the request body
                    for(string HM_Name_key: Map_RequestBody.keyset()){   
                        if(subObjectName == HM_Name_key){
                            if (objCase == null){
                                objCase = new Case();
                            }
                            if(Map_RequestBody.get(SF_Name) != null){
                                objCase.put(Map_SF_CaseField.get(SF_Name).HM_SF_Field__c, Map_RequestBody.get(SF_Name));
                            }
                        }
                    }
                } 
                // If the SF_Name/sub Object name is the sub object name is 'caseData'
                else if(subObjectName == 'caseData' && Map_caseData.containsKey(SF_Name) && Map_caseData.get(SF_Name) != null){
                    system.debug('SF_Name: '+SF_Name+'is present in: '+subObjectName);
                    if(Map_SF_CaseField.get(SF_Name).Name == 'dateOfLoss'){
                        
                        //converting string to Date time before assigning to DateTime field
                        Datetime DtOfLoss = Datetime.valueOf(Map_caseData.get(SF_Name).toString().replace('T',' '));
                        if (objCase == null){
                            objCase = new Case();
                        }
                        objCase.put(Map_SF_CaseField.get(SF_Name).HM_SF_Field__c, DtOfLoss);
                    }
                    else if(Map_SF_CaseField.get(SF_Name).Name == 'brand'){
                        if (objCase == null){
                            objCase = new Case();
                        }
                        if (BradingStatus == true){
                            objCase.put(Map_SF_CaseField.get(SF_Name).HM_SF_Field__c, Map_caseData.get(SF_Name));
                        }
                    }
                    else{
                        if (objCase == null){
                            objCase = new Case();
                        }
                        objCase.put(Map_SF_CaseField.get(SF_Name).HM_SF_Field__c, Map_caseData.get(SF_Name));
                    }
                }
                // If the SF_Name/sub Object name is the sub object name is 'customer'
                else if(subObjectName == 'customer' && SF_Name.contains('ContactId') &&  Map_customer.get('id') != null){
                    
                    if (objCase == null){
                        objCase = new Case();
                    }
                    
                    string ContactId = HM_Integration_Helper.getContact(Map_customer);
                    
                    if(ContactId == null || string.isBlank(ContactId) || ContactId == ''){
                        string newContactId = HM_Integration_Helper.createAndGetContact(Map_customer,SFUserId);
                        system.debug('newContactId---'+newContactId);
                        if(newContactId == null || string.isBlank(newContactId)){
                            HM_Integration_Helper.create_HMLogs('Error: Contact creation failed', 'Failure', '0','Inbound' , jSONRequestBody, 'NA','');
                            return 'Contact Creation Failed';
                        }
                        else{
                            objCase.put(Map_SF_CaseField.get(SF_Name).HM_SF_Field__c, newContactId);
                        }
                    }
                    else{
                        objCase.put(Map_SF_CaseField.get(SF_Name).HM_SF_Field__c, ContactId);
                    }
                }
            }
            
            //since this is Inbound Case Creation, so update HM Case Origin field to 'Hi Marley'
            objCase.put('HM_Case_Origin__c', 'Hi Marley');
            
            if(string.isNotBlank(SFUserId) && SFUserId != null){
               objCase.put('OwnerId', SFUserId); 
            }
            
            if (objCase != null){
                system.debug('objCase--'+objCase);
                insert objCase;
                CreatedCaseId = objCase.Id;
            }
                        
            if(CreatedCaseId != null || string.isNotBlank(CreatedCaseId)){
                caseResponse.Status = 'Success';
                caseResponse.Message = 'Case created successfully';
                caseResponse.CreatedCaseRecord = objCase; 
                HM_Integration_Helper.create_HMLogs('Case Created Successfully. Case Id = ' + CreatedCaseId, 'Success', '200','Inbound' , jSONRequestBody, 'NA', '');
                HM_Integration_Helper.createChatLog(objCase.HM_Case_Id__c,CreatedCaseId);
            }
        }
        catch(Exception e) {
            caseResponse.Status = 'Fail';
            caseResponse.Message = e.getMessage();
            HM_Integration_Helper.create_HMLogs('Error: ' + e.getMessage(), 'Failure', '0','Inbound' , jSONRequestBody, 'NA','');
        }
        return caseResponse.Status + ' - ' + caseResponse.Message;
    }
    
    //Inner Class For Case Response Message
    global class CaseResponseMsg {
        global String Status;
        global String message;
        global sObject CreatedCaseRecord;
    }
}