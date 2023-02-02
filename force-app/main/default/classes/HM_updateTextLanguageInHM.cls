/*
* Class Name               : HM_Test_HM_Reassign_CaseOwner
* Description              : Apex Test Class - Apex Class to update the Text Language whenever Text Language is updated on SF Case.
* Author                   : Darshana Dange (Futran Solutions)
* Created On               : 14 Sep 2022
* Test Class               : HM_Test_HM_updateTextLanguage
* Change Log History       :
*  |--------------------------------------------------------------------------------|
*  | Version | Modified By     | Date       | Comment                               |
*  |--------------------------------------------------------------------------------|
*  | 0.1     | Darshana Dange   | 14/09/2022 | Initial Version of Class             |
*  |--------------------------------------------------------------------------------|
*/

public class HM_updateTextLanguageInHM {
    
    @InvocableMethod(label='Update Text Language in HM' description='Update Text Language in HM' category= 'Case')
    public static void HM_update_TextLanguageInHM(List<string> lstCaseIds){
        
        if(lstCaseIds == null || lstCaseIds.size() <= 0){
            return;
        }
        
        //Create Variables to store the details 
        List<Case> lstCases = new List<Case>();
        Map<String, object> mapJsonData = new Map<String, object>();
        string sCaseId, sQuery, sEndPointUrl, sSerializedData, sStatusCode, sJSONResponse;
        
        //Create a dynamic query to get related case details
        sQuery = 'Select Id, HM_Case_Id__c, HM_Text_Language__c, HM_Integration_Message__c from Case where Id IN :lstCaseIds';
        system.debug('sQuery ==> ' + sQuery);
        
        //Fetch all the case details using the dynamic query
        lstCases = Database.query(sQuery);
        
        if(lstCases == null || lstCases.size() <= 0){
            return;
        }
        
        //Get Case Integration details from HM_Integration Metadata
        HM_Integration__mdt objCaseUpdateAPI = [Select Id, DeveloperName, API_Key__c, HM_End_Point_URL__c 
                                                from HM_Integration__mdt 
                                                where DeveloperName = 'HM_Case_Updation'];    
        
        if(string.isBlank(objCaseUpdateAPI.HM_End_Point_URL__c) || string.isBlank(objCaseUpdateAPI.API_Key__c)){
            for(Case objCase : lstCases) { 
                if(System.Label.HM_IM_Generic_1 != null){
                    objCase.HM_Integration_Message__c = System.Label.HM_IM_Generic_1;
                }
                update objCase;
            }
            return;
        }
        
        //Traverse All Cases to update the Language Preference
        List<UpdateWrapper> lstUpdateWrapper = new List<UpdateWrapper>();
        for(Case objCase : lstCases){
            
            //Create JSON Request Body using field mappings of the custom setting        
            mapJsonData.put('languagePreference', objCase.HM_Text_Language__c);
            
            if(mapJsonData == null || mapJsonData.size() <= 0){
                return;
            }
            
            //serialize the case details as a JSON Body
            sSerializedData = JSON.serialize(mapJsonData);
            System.debug('Data in Map:: '+ JSON.serializepretty(mapJsonData));            
            
            //Append HI Marley Case ID at end of Case Update API
            sEndPointUrl = objCaseUpdateAPI.HM_End_Point_URL__c + objCase.HM_Case_Id__c;
            
            //HTTP Request
            Http http = new Http();    
            
            HttpRequest httpReq = HM_Integration_Helper.getHttpRequest('PUT', sEndPointUrl, objCaseUpdateAPI.API_Key__c, ' ', sSerializedData);
            
            HttpResponse httpResponse = new HttpResponse();
            
            try{
                
                //create a wrapper instance for updating case details
                UpdateWrapper objUW = new UpdateWrapper();
                objUW.sHMCaseId = objCase.id;
                
                httpResponse = http.send(httpReq);
                sStatusCode = string.valueOf(httpResponse.getStatusCode());
                system.debug('Status Code ==> ' + sStatusCode );
                
                //Map Staus Code and Response body 
                objUW.sStatusCode = sStatusCode;
                objUW.sJSONResponse = httpResponse.getBody();
                
                if(sStatusCode == '201' || sStatusCode == '200'){
                    
                    sJSONResponse = httpResponse.getBody();
                    
                    Map<String, Object> mapHMResponse = (Map<String, Object>)JSON.deserializeUntyped(sJSONResponse);
                    system.debug('mapHMResponse ==> ' + mapHMResponse);
                    
                    //Get Case Details from Hi Marley
                    Map<String, Object> mapCaseData = (Map<String, Object>)mapHMResponse.get('caseData');
                    
                    //Update related Case details
                    if(mapHMResponse != null && mapHMResponse.size() > 0){
                        if(mapCaseData.get('id') == objCase.HM_Case_Id__c){
                            if(System.Label.HM_Update_Language_Preference_On_Case != null){
                                objUW.sIntegrationMessage = System.Label.HM_Update_Language_Preference_On_Case;
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
                HM_Integration_Helper.create_HMLogs('Update Language Preference in HM', 'Error', '0', 'Outbound', sSerializedData, e.getMessage(), ' ');
            }
            
        }
        
        if(lstUpdateWrapper.size() > 0){
            for(UpdateWrapper objUW : lstUpdateWrapper){
                for(Case objCase : lstCases){
                    if(objCase.id == objUW.sHMCaseId){
                        objCase.HM_Integration_Message__c = objUW.sIntegrationMessage;
                        if(objUW.bSuccess){
                            HM_Integration_Helper.create_HMLogs('Update Language Preference in HM', 'Success', sStatusCode, 'Outbound', ' ', sJSONResponse, ' ');
                        }
                        else{
                            HM_Integration_Helper.create_HMLogs('Update Language Preference in HM', 'Error', sStatusCode, 'Outbound', ' ', sJSONResponse, ' ');
                        }
                        break;
                    }
                }
            }
        }
        
        update lstCases; 
        
    }
    
    public class UpdateWrapper{
        public string sHMCaseId;
        public string sIntegrationMessage;
        public boolean bSuccess; 
        public string sJSONResponse;
        public string sStatusCode;
        
        public UpdateWrapper(){
            sHMCaseId = '';
            sIntegrationMessage = '';
            bSuccess = true;
            sJSONResponse = '';
            sStatusCode = '';
        }
    }
    
}