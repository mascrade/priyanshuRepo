/*
* Class Name               : HM_sendSurveyMessage
* Description              : Apex Class - Apex Class to send survey message to end user when case closed
* Author                   : Rohit Korake (Futran Solutions)
* Created On               : 08 Aug 2022
* Test Class               : HM_Test_HM_sendSurveyMessage
* Change Log History       :
*  |--------------------------------------------------------------------------------|
*  | Version | Modified By     | Date       | Comment                               |
*  |--------------------------------------------------------------------------------|
*  | 0.1     |  Rohit Korake   | 08/08/2022 | Initial Version of Class              |
*  |--------------------------------------------------------------------------------|
*/

public class HM_sendSurveyMessage {
    
    @InvocableMethod(label='Send Survey Message' description='Send Survey Message on Case Closure' category= 'Case')
    public static void send_SurveyMessage(List<string> lstCaseIds){
        
        if(lstCaseIds == null || lstCaseIds.size() <= 0){
            return;
        }
            
        List<Case> lstCases = new List<Case>();
        string sCaseId, sQuery, sStatusCode, sJSONResponse, sEndpoint;
        
        if(string.isBlank(lstCaseIds[0])){
            return;
        }
        
        sCaseId = lstCaseIds[0];
        
        //Check whether Sending the Survey Message on Case Closure is Enabled
        Map<string, HM_Send_Survey_Message_on_Case_Closure__c> mapSendSurveyMsg = HM_Send_Survey_Message_on_Case_Closure__c.getAll();
        
        if(mapSendSurveyMsg == null || mapSendSurveyMsg.size() <= 0){
            return;
        }
        
        if(mapSendSurveyMsg.get('Send Survey Message') != null){
            if(!mapSendSurveyMsg.get('Send Survey Message').HM_Send_Survey_Message__c){
              return;  
            }
        }
        
        //Create a dynamic query to get related case details
        sQuery = 'Select Id, HM_Case_Id__c, HM_Integration_Message__c, HM_Send_Survey_Message__c from Case where Id = ' + '\'' + sCaseId + '\'';
        system.debug('sQuery ==> ' + sQuery);
        
        //Fetch all the case details using the dynamic query
        lstCases = Database.query(sQuery);
        
        if(lstCases == null || lstCases.size() <= 0){
            return;
        }
        
        Case objCase = lstCases[0];
        
        if(objCase == null){
            return;
        }
        
        //Get Case Integration details from HM_Integration Metadata
        HM_Integration__mdt objSendSurveyMsg = [Select Id, DeveloperName, API_Key__c, HM_End_Point_URL__c 
                                                from HM_Integration__mdt 
                                                where DeveloperName = 'HM_Send_Survey_Messages']; 
        
        if(string.isBlank(objSendSurveyMsg.HM_End_Point_URL__c) || string.isBlank(objSendSurveyMsg.API_Key__c)){  
            objCase.HM_Send_Survey_Message__c = false;
            if(System.Label.HM_IM_Generic_1 != null){
                objCase.HM_Integration_Message__c = System.Label.HM_IM_Generic_1;
            }
            update objCase;
            return;
        }
        
        //Append CaseId to Endpoint Url
        sEndpoint = objSendSurveyMsg.HM_End_Point_URL__c + objCase.HM_Case_Id__c;
        system.debug('sEndpoint==> ' + sEndpoint);
        
        //HTTP Request
        Http http = new Http();    
        
        HttpRequest HttpReq = HM_Integration_Helper.getHttpRequest('PUT', sEndpoint, objSendSurveyMsg.API_Key__c, '', '');
        
        HttpResponse httpResponse = new HttpResponse();
        
        try{
            
            httpResponse = http.send(HttpReq);
            
            sStatusCode = string.valueOf(httpResponse.getStatusCode());
            system.debug('Status Code ==> ' + sStatusCode );
            
            if(sStatusCode == '201' || sStatusCode == '200'){
                
                sJSONResponse = httpResponse.getBody();
                
                Map<String, Object> mapHMResponse = (Map<String, Object>)JSON.deserializeUntyped(sJSONResponse);
                system.debug('mapHMResponse ==> ' + mapHMResponse);
                
                if(mapHMResponse != null && mapHMResponse.size() > 0){
                    objCase.HM_Send_Survey_Message__c = false;
                    if(System.Label.HM_Survey_Message != null){
                        objCase.HM_Integration_Message__c = System.Label.HM_Survey_Message;
                    }
                    
                    update objCase;
                }
                
                //Create Success Log Entry record
                HM_Integration_Helper.create_HMLogs('Send survey message', 'Success', sStatusCode, 'Outbound', ' ', sJSONResponse, '');
            }
            else{
                
                sJSONResponse = httpResponse.getBody();
                
                Map<string, Object> mapErrorDetails = HM_Integration_Helper.getErrorDetails(sJSONResponse);
                
                if(mapErrorDetails != null && mapErrorDetails.size() > 0){
                    objCase.HM_Send_Survey_Message__c = false;
                    objCase.HM_Integration_Message__c = mapErrorDetails.get('code') + '\r\n' + mapErrorDetails.get('detail');
                    update objCase;
                }
                
                //Create a Error Log Entry record
                HM_Integration_Helper.create_HMLogs('Send survey message', 'Error', sStatusCode, 'Outbound', ' ', sJSONResponse, '');
            }
        } 
        catch(Exception e){
            
            if(System.Label.HM_Send_Survey_Message_failure != null){
                objCase.HM_Integration_Message__c = System.Label.HM_Send_Survey_Message_failure;
            }
            objCase.HM_Send_Survey_Message__c = false;
            update objCase;
            
			//Create a Exception Log Entry record
            HM_Integration_Helper.create_HMLogs('Exception - Send survey message', 'Error', '0', 'Outbound', ' ', e.getMessage(), '');
        }
    }
}