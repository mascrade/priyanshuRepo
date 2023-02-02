/*
* Class Name               : HM_ResendWelcomeMessage
* Description              : Apex Class - Apex Class to resend welcome message to end user
* Author                   : Rohit Korake (Futran Solutions)
* Created On               : 08 Aug 2022
* Test Class               : HM_Test_HM_ResendWelcomeMessage
* Change Log History       :
*  |--------------------------------------------------------------------------------|
*  | Version | Modified By     | Date       | Comment                               |
*  |--------------------------------------------------------------------------------|
*  | 0.1     | Rohit Korake    | 08/08/2022 | Initial Version of Class              |
*  |--------------------------------------------------------------------------------|
*/

public class HM_ResendWelcomeMessage {
    
    // moved the logic from invocable to Auraenabled as this option is now provided within the chat component  
    //@InvocableMethod(label='Resend Welcome Message' description='Resend Welcome Message to End User' category= 'Case')
    @AuraEnabled
    public static string HM_resendwelcomeMessage(string sCaseId){
        
        string sStatus = 'Error';
        
        if(string.isBlank(sCaseId)){
            return sStatus;
        }
          
        List<Case> lstCases = new List<Case>();
        string sQuery, sEndpoint, sStatusCode, sJSONResponse;
        
        //Create a dynamic query to get related case details
        sQuery = 'Select Id, HM_Case_Id__c, HM_Integration_Message__c, HM_Resend_Welcome_Message__c from Case where Id = ' + '\'' + sCaseId + '\'';
        system.debug('sQuery ==> ' + sQuery);
        
        //Fetch all the case details using the dynamic query
        lstCases = Database.query(sQuery);
        
        if(lstCases == null || lstCases.size() <= 0){
            return sStatus;
        }
        
        Case objCase = lstCases[0];
        
        if(objCase == null){
            return sStatus;
        }
        
        //Get Integration details from HM_Integration Metadata
        HM_Integration__mdt objResendWelcomeMsg = [Select Id, DeveloperName, API_Key__c, HM_End_Point_URL__c 
                                                   from HM_Integration__mdt 
                                                   where DeveloperName = 'HM_Resend_Welcome_Message']; 
        
        if(string.isBlank(objResendWelcomeMsg.HM_End_Point_URL__c) || string.isBlank(objResendWelcomeMsg.API_Key__c)){
            objCase.HM_Resend_Welcome_Message__c = false; 
            if(System.Label.HM_IM_Generic_1 != null){
                objCase.HM_Integration_Message__c = System.Label.HM_IM_Generic_1;
            }
            update objCase;
            return sStatus;
        }
        
        //Append CaseId to Endpoint Url
        sEndpoint = objResendWelcomeMsg.HM_End_Point_URL__c + objCase.HM_Case_Id__c;
        system.debug('sEndpoint => ' + sEndpoint);
        
        //HTTP Request
        Http http = new Http();    
        
        HttpRequest httpReq = HM_Integration_Helper.getHttpRequest('PUT', sEndpoint, objResendWelcomeMsg.API_Key__c, ' ', ' ');
        
        HttpResponse httpResponse = new HttpResponse();
        
        try{
            
            httpResponse = http.send(HttpReq);
            sStatusCode = string.valueOf(httpResponse.getStatusCode());
            system.debug('Status Code ==> ' + sStatusCode );
            
            if(sStatusCode == '201' || sStatusCode == '200'){
                
                sJSONResponse = httpResponse.getBody();
               
                Map<String, Object> mapHMResponse = (Map<String, Object>)JSON.deserializeUntyped(sJSONResponse);
                system.debug('mapHMResponse ==> ' + mapHMResponse);
                
                Map<String, Object> mapCaseData = (Map<String, Object>)mapHMResponse.get('caseData');
                
                if(mapHMResponse != null && mapHMResponse.size() > 0){
                    if(mapCaseData.get('id') == objCase.HM_Case_Id__c){                        
                        objCase.HM_Resend_Welcome_Message__c = false;
                        if(System.Label.HM_Resend_Welcome_Message != null){
                            objCase.HM_Integration_Message__c = System.Label.HM_Resend_Welcome_Message;
                        }
                    }
                }
                
                //Create Success Log Entry record
                HM_Integration_Helper.create_HMLogs('Resend Welcome Message', 'Success', sStatusCode, 'Outbound', ' ', sJSONResponse, ' ');
                sStatus = 'Success';
            }
            else{
                
                sJSONResponse = httpResponse.getBody();
                
                Map<string, Object> mapErrorDetails = HM_Integration_Helper.getErrorDetails(sJSONResponse);
                
                if(mapErrorDetails != null && mapErrorDetails.size() > 0){
                    objCase.HM_Resend_Welcome_Message__c = false;
                    objCase.HM_Integration_Message__c = mapErrorDetails.get('code') + '\r\n' + mapErrorDetails.get('detail');
                }
                
                //Create a Error Log Entry record
                HM_Integration_Helper.create_HMLogs('Resend Welcome Message', 'Error', sStatusCode, 'Outbound', ' ', sJSONResponse, ' ');
            }
        } 
        catch(Exception e){
            
            System.debug('The following exception has occurred: ' + e.getMessage());  
            
            if(System.Label.HM_Resend_Welcome_Message_failure != null){
                objCase.HM_Integration_Message__c = System.Label.HM_Resend_Welcome_Message_failure;
            }
            objCase.HM_Resend_Welcome_Message__c = false;            
            
            //Create a Exception log Entry record
            HM_Integration_Helper.create_HMLogs('Resend Welcome Message', 'Error', '0', 'Outbound', ' ', e.getMessage(), ' ');
        }
        
        update objCase;
        
        return sStatus;
    }
}