/*
* Class Name               : HM_ReopenCaseInHM
* Description              : Apex Class - Apex Class to call the Reopen Case 
*                            API Endpoint to Reopen a case in Hi Marley.
* Author                   : Rohit Korake (Futran Solutions)
* Created On               : 18 August 2022
* Test Class               : HM_Test_HM_ReopenCaseInHM
* Change Log History       :
*  |--------------------------------------------------------------------------------|
*  | Version | Modified By     | Date       | Comment                               |
*  |--------------------------------------------------------------------------------|
*  | 0.1     | Rohit Korake    | 18/08/2022 | Initial Version of Class              |
*  |--------------------------------------------------------------------------------|
*/

public class HM_ReopenCaseInHM {
    
    @InvocableMethod(label='Reopen Case in HM' description='Reopen Case in HM' category= 'Case')
    public static void HM_ReopenCaseInHM(List<string> lstCaseIds){
        
        if(lstCaseIds == null || lstCaseIds.size() <= 0){
            return;
        }
        
        List<Case> lstCases = new List<Case>();
        string sQuery, sEndpoint, sStatusCode, sJSONResponse;
        
        //Create a dynamic query to get related case details
        sQuery = 'Select Id, HM_Case_Id__c, HM_Integration_Message__c, HM_Case_Status__c, HM_Case_Status_Comments__c from Case where Id IN :lstCaseIds';
        system.debug('sQuery ==> ' + sQuery);
        
        //Fetch all the case details using the dynamic query
        lstCases = Database.query(sQuery);
        
        if(lstCases == null || lstCases.size() <= 0){
            return;
        }
        
        //Get Integration details from HM_Integration Metadata
        HM_Integration__mdt objReopenCase = [Select Id, DeveloperName, API_Key__c, HM_End_Point_URL__c 
                                             from HM_Integration__mdt 
                                             where DeveloperName = 'HM_Re_Open_Case_in_Hi_Marley']; 
        
        if(string.isBlank(objReopenCase.HM_End_Point_URL__c) || string.isBlank(objReopenCase.API_Key__c)){
            for(Case objCase : lstCases){
                if(System.Label.HM_IM_Generic_1 != null){
                    objCase.HM_Integration_Message__c = System.Label.HM_IM_Generic_1;
                }
            }
            update lstCases;
            return;
        }
        
        //Reopen Hi Marley Case for all the Cases where Status is changed as Reopen
        //Callout - Reopen Case in HM API
        
        List<UpdateWrapper> lstUpdateWrapper = new List<UpdateWrapper>();
        for(Case objCase : lstCases){
            
            //Append CaseId to Endpoint Url
            sEndpoint = objReopenCase.HM_End_Point_URL__c + objCase.HM_Case_Id__c;
            
            //HTTP Request
            Http http = new Http();    
            
            HttpRequest httpReq = HM_Integration_Helper.getHttpRequest('PUT', sEndpoint, objReopenCase.API_Key__c, '', '');
            
            HttpResponse httpResponse = new HttpResponse();
            
            try{
                
                //create a wrapper instance for updating case details
                UpdateWrapper objUW = new UpdateWrapper();
                objUW.sHMCaseId = objCase.id;
                
                httpResponse = http.send(HttpReq);
                sStatusCode = string.valueOf(httpResponse.getStatusCode());
                system.debug('Status Code ==> ' + sStatusCode );
                
                //Map Staus Code and Response body 
                objUW.sStatusCode = sStatusCode;
                objUW.sJSONResponse = httpResponse.getBody();
                
                if(sStatusCode == '201' || sStatusCode == '200'){
                    
                    sJSONResponse = httpResponse.getBody();
                    
                    Map<String, Object> mapHMResponse = (Map<String, Object>)JSON.deserializeUntyped(sJSONResponse);
                    system.debug('mapHMResponse ==> ' + mapHMResponse);
                    
                    Map<String, Object> mapCaseData = (Map<String, Object>)mapHMResponse.get('caseData');
                    
                    if(mapHMResponse != null && mapHMResponse.size() > 0){
                        if(mapCaseData.get('id') == objCase.HM_Case_Id__c){
                            objUW.sHMCaseStatus = 'Open';
                            if(System.Label.HM_Reopen_Case_In_HM != null){
                                objUW.sIntegrationMessage = System.Label.HM_Reopen_Case_In_HM;
                            }
                        }
                    }                    
                }
                else{
                    
                    sJSONResponse = httpResponse.getBody();
                    
                    Map<string, Object> mapErrorDetails = HM_Integration_Helper.getErrorDetails(sJSONResponse);
                    
                    if(mapErrorDetails != null && mapErrorDetails.size() > 0){
                        objUW.sIntegrationMessage = mapErrorDetails.get('code') + '\r\n' + mapErrorDetails.get('detail');
                    }
                }
                
                lstUpdateWrapper.add(objUW);
            } 
            catch(Exception e){
                
                System.debug('The following exception has occurred: ' + e.getMessage());  
                
                //Create a Exception Log Entry record
                HM_Integration_Helper.create_HMLogs('Re-Open case in HM', 'Error', '0', 'Outbound', ' ', e.getMessage(), ' ');
            }
        }
        
        //Update Case Details
        if(lstUpdateWrapper.size() > 0){
            for(UpdateWrapper objUW : lstUpdateWrapper){
                for(Case objCase : lstCases){
                    if(objCase.id == objUW.sHMCaseId){
                        objCase.HM_Integration_Message__c = objUW.sIntegrationMessage;
                        objCase.HM_Case_Status__c = objUW.sHMCaseStatus;
                        if(objUW.bSuccess){                                
                            //Create Success Log Entry record
                            HM_Integration_Helper.create_HMLogs('Re-Open case in HM', 'Success', sStatusCode, 'Outbound', ' ', sJSONResponse, ' ');                            
                        }
                        else{
                            //Create a Error Log Entry record
                            HM_Integration_Helper.create_HMLogs('Re-Open case in HM', 'Error', sStatusCode, 'Outbound', ' ', sJSONResponse, ' ');                            
                        }
                        break;
                    }
                }
            }
            
            update lstCases;
        }
        
    }
    
    
    public class UpdateWrapper{
        public string sHMCaseId;
        public string sIntegrationMessage;
        public string sHMCaseStatus;
        public boolean bSuccess; 
        public string sJSONResponse;
        public string sStatusCode;
        
        public UpdateWrapper(){
            sHMCaseId = '';
            sIntegrationMessage = '';
            sHMCaseStatus = '';
            bSuccess = true;
            sJSONResponse = '';
            sStatusCode = '';
        }
    }
    
}