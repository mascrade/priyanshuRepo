/*
* Name               : HM_OptIn_OptOut_Helper
* Description        : This is a Helper class which is being used by HM_OptInRestAPI & HM_OptOutRestAPI to send RestContext 
					   object and receive the Contact on which Opt In/ Opt Out needs to get updated whenever a User replies 
					   'Yes' or 'STOP' in Hi Marley.
* Author             : Rohit (Futran Solutions)
* Created On         : 5 Aug 2022
* Test Class         : HM_Test_OptIn_OptOut
* Change Log History :
*  |------------------------------------------------------------------------------|
*  | Version | Modified By        | Date        | Comment                         |
*  |------------------------------------------------------------------------------|
*  | 0.1     | Rohit              | 5 Aug 2022 | Initial Version of Apex Class ---|
*  |------------------------------------------------------------------------------|
*/
global class HM_OptIn_OptOut_Helper {
    
    global static String sMethodName = 'POST', sIntegrationType = 'Inbound', sJSONRequestBody, sResponseBody = 'NA';
    
    global static String handleJSON(RestContext objRestContext , Boolean bOptedIn){
        
        RestRequest request = RestContext.request;  
        RestResponse response = RestContext.response;
        sJSONRequestBody = request.requestBody.toString();
        
        //deserialize JSON request body
        Map<String, Object> mapjSONRequestBody = (Map<String, Object>) JSON.deserializeUntyped(sJSONRequestBody);
        String sMobileField;
        String sMobileNumber;
        List<Contact> lstContact;
            
        //empty json, return with Error Response
        if(mapjSONRequestBody == null || mapjSONRequestBody.keySet().size() == 0){
            return GetResponse('Failure', 'Empty JSON body', '0');
        }
        
        sMobileNumber = (String)mapjSONRequestBody.get('mobile');
        
        if(String.isBlank(sMobileNumber)){
            //Error Response
            return GetResponse('Failure', 'Error : Mobile information is empty', '0');
        } 
        
        /*
        //fetch custom setting values in a map
        Map<String, HM_User_Mobile_Field_Mapping__c> map_HM_SFmobile = HM_User_Mobile_Field_Mapping__c.getAll();  
        
        if(!map_HM_SFmobile.containsKey('mobile') || map_HM_SFmobile.get('mobile') == null){
            //Error Response
            return GetResponse('Failure', 'Error', '0');
        }
        
        if(string.isNotBlank(map_HM_SFmobile.get('mobile').HM_SF_Field__c)){
            sMobileField = map_HM_SFmobile.get('mobile').HM_SF_Field__c;                           
        }
       */
        
        String sQuery = 'SELECT Id, HM_Is_Opted_In__c, HM_Opt_Status_Detail__c, HM_Opt_In_Date__c, HM_Opt_Out_Date__c FROM Contact where HM_MobileNumber__c = ' + '\'' + sMobileNumber + '\' limit 1' ;
  
        //Fetch all the case details using the dynamic query
        lstContact = Database.query(sQuery);        
        system.debug('lstContact' + lstContact);
        
        //check lstContact, update field, create logs
        if(lstContact == null && lstContact.size() <= 0){
            //Error Response : incorrect mobile in json 
            return GetResponse('Failure', 'Contact not found.', '0');
        }
        
        //contact found, update contact, set status code
        lstContact[0].HM_Is_Opted_In__c = bOptedIn;
         
        if(bOptedIn){
            lstContact[0].HM_Opt_Status_Detail__c = 'OPTED_IN';
            lstContact[0].HM_Opt_In_Date__c = system.now();
            update lstContact;
            //Success Response
            return GetResponse('Success', 'Opted In successfully in Salesforce', '200');
            
        }
        else{
            lstContact[0].HM_Opt_Status_Detail__c = 'OPTED_OUT';
            lstContact[0].HM_Opt_Out_Date__c = system.now();
            update lstContact;
            //Success Response
            return GetResponse('Success', 'Opted Out successfully in Salesforce', '200');
        }
    }
    
    global static String GetResponse(String sStatus, String sMessage, String sStatusCode){
        HM_Integration_Helper.create_HMLogs(sMessage, sStatus, sStatusCode, sIntegrationType, sJSONRequestBody, sResponseBody,'');
        return sStatus + ' - '+  sMessage;  
    }
    
}