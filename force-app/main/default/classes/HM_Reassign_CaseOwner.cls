/*
* Class Name               : HM_Reassign_CaseOwner
* Description              : Apex Class - Apex Class to Reassign Case Owner in HM
* Author                   : Darshana Dange (Futran Solutions)
* Created On               : 09 August 2022
* Test Class               : HM_Test_HM_Reassign_CaseOwner
* Change Log History       :
*  |--------------------------------------------------------------------------------|
*  | Version | Modified By     | Date       | Comment                               |
*  |--------------------------------------------------------------------------------|
*  | 0.1     | Darshana Dange   | 09/08/2022 | Initial Version of Class             |
*  |--------------------------------------------------------------------------------|
*/

public class HM_Reassign_CaseOwner {
    
    @InvocableMethod(label='Reassign Case Owner in HM' description='Reassign Case Owner in HM' category= 'Case')
    public static void HM_Reassign_CaseOwner(List<string> lstCaseIds){
        
        if(lstCaseIds == null || lstCaseIds.size() <= 0){
            return;
        }
        
        List<Case> lstCases = new List<Case>();
        Map<string, Object> mapJSONData = new Map<string, Object>();
        Map<string, Object> mapPrimaryContact = new Map<string, Object>();
        string sQuery, sSerializedData, sEndpoint, sStatusCode, sJSONResponse;
        
        //Create a dynamic query to get related case details
        sQuery = 'Select Id, HM_Case_Id__c, HM_Integration_Message__c, Owner.Email from Case where Id IN: lstCaseIds';
        system.debug('sQuery ==> ' + sQuery);
        
        //Fetch all the case details using the dynamic query
        lstCases = Database.query(sQuery);
        system.debug('lstCases ==> ' + lstCases.size());
        
        if(lstCases == null || lstCases.size() <= 0){
            return;
        }
        
        //Create Request Body with Primary Contact Email Ids
        for(Case objCase : lstCases){
            mapPrimaryContact.put('email', objCase.Owner.Email);
        }
        
        if(mapPrimaryContact != null && mapPrimaryContact.size() > 0){
            mapJSONData.put('primaryContact', mapPrimaryContact);
        }
        
        if(mapJSONData == null || mapJSONData.size() <= 0){
            return;
        }
        
        //serialize the case details as a JSON Body
        sSerializedData = JSON.serialize(mapJsonData);
        System.debug('Data in Map:: '+ JSON.serializepretty(mapJsonData));  
        
        //Get Integration details from HM_Integration Metadata
        HM_Integration__mdt objReassignOwner = [Select Id, DeveloperName, API_Key__c, HM_End_Point_URL__c 
                                                from HM_Integration__mdt 
                                                where DeveloperName = 'HM_Re_assign_Case']; 
        
        if(string.isBlank(objReassignOwner.HM_End_Point_URL__c) || string.isBlank(objReassignOwner.API_Key__c)){
            for(Case objCase : lstCases){
                if(System.Label.HM_IM_Generic_1 != null){
                    objCase.HM_Integration_Message__c = System.Label.HM_IM_Generic_1;
                }               
            }
            update lstCases;            
            return;
        }
        
        //Callout : Callout for re-assigning case owner
        List<UpdateWrapper> lstUpdateWrapper = new List<UpdateWrapper>();
        for(Case objCase : lstCases){
       
            //Append CaseId to Endpoint Url
            sEndpoint = objReassignOwner.HM_End_Point_URL__c + objCase.HM_Case_Id__c;
            system.debug('sEndpoint' + sEndpoint);
            
            //HTTP Request
            Http http = new Http();            
            
            HttpRequest httpReq = HM_Integration_Helper.getHttpRequest('PUT', sEndpoint, objReassignOwner.API_Key__c, '', sSerializedData);
            
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
                            if(System.Label.HM_Reassign_Case_Owner != null){
                                objUW.sIntegrationMessage = System.Label.HM_Reassign_Case_Owner;
                            }
                        }
                    } 
                }
                else{
                    
                    sJSONResponse = httpResponse.getBody();
                    
                    Map<string, Object> mapErrorDetails = HM_Integration_Helper.getErrorDetails(sJSONResponse);
                    
                    if(mapErrorDetails != null && mapErrorDetails.size() > 0){
                        objUW.sIntegrationMessage = mapErrorDetails.get('status') + '\r\n' + mapErrorDetails.get('code') + '\r\n' + mapErrorDetails.get('detail');
                    }
                    
                    objUW.bSuccess = false;             
                }
                
                lstUpdateWrapper.add(objUW);
            } 
            catch(Exception e){
                
                System.debug('The following exception has occurred: ' + e.getMessage());            
                
                //Create a Exception log Entry record
                HM_Integration_Helper.create_HMLogs('Reassign Case Owner', 'Error', '0', 'Outbound', ' ', e.getMessage(),'');
            }
            
        }
        
        if(lstUpdateWrapper.size() > 0){
            for(UpdateWrapper objUW : lstUpdateWrapper){
                for(Case objCase : lstCases){
                    if(objCase.id == objUW.sHMCaseId){
                        objCase.HM_Integration_Message__c = objUW.sIntegrationMessage;
                        if(objUW.bSuccess){
                            HM_Integration_Helper.create_HMLogs('Reassign Case Owner', 'Success', objUW.sStatusCode, 'Outbound', ' ', objUW.sJSONResponse,'');
                        }
                        else{
                            HM_Integration_Helper.create_HMLogs('Reassign Case Owner', 'Error', objUW.sStatusCode, 'Outbound', ' ', objUW.sJSONResponse,'');
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