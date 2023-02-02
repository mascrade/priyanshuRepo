/*
* Name               : HM_DownloadCaseTranscript
* Description        : Apex Class - To Download the Case Transcript and upload in related Files on Case in SF
* Author             : Darshana Dange (Futran Solutions)
* Created On         : 19 August 2022
* Test Class         : HM_Test_HM_DownloadCaseTranscript
* Change Log History :
*  |------------------------------------------------------------------------------|
*  | Version | Modified By        | Date        | Comment                         |
*  |------------------------------------------------------------------------------|
*  | 0.1     | Darshana Dange     | 19 Aug 2022 | Initial Version of Apex Class   |
*  |------------------------------------------------------------------------------|
*/

public class HM_DownloadCaseTranscript {
    
    @InvocableMethod(label='Download Case Transcript' description='Download Case Transcript' category= 'Case')
    public static void HM_DownloadCaseTranscript(List<string> lstCaseIds){
      
        if(lstCaseIds == null || lstCaseIds.size() <= 0){
            system.debug('Case Not Found!');
            return;
        }
        
        List<Case> lstCases = new List<Case>();
        string sCaseId, sQuery, sEndpoint, sStatusCode, sJSONResponse;
        
        if(string.isBlank(lstCaseIds[0])){
            return;
        }
        
        //Check whether Sending the Survey Message on Case Closure is Enabled
        Map<string, HM_Download_Case_Transcript__c> mapDownloadCaseTranscript = HM_Download_Case_Transcript__c.getAll();
        
        if(mapDownloadCaseTranscript == null || mapDownloadCaseTranscript.size() <= 0){
            return;
        }
        
        if(mapDownloadCaseTranscript.get('Case Transcript Download') != null){
            if(!mapDownloadCaseTranscript.get('Case Transcript Download').Enable_Case_Transcript_Download__c){
              system.debug('Case Transcipt feature is disabled!');
              return;  
            }
        }
        
        //Store Case Id in local variable
        sCaseId = lstCaseIds[0];
        
        //Create a dynamic query to get related case details
        sQuery = 'Select Id, HM_Case_Id__c, HM_Download_Case_Transcript__c, HM_Integration_Message__c from Case where Id = ' + '\'' + sCaseId + '\'';
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
        
        //Get the Integration details from Custom metadata of Download Case Transcript
        HM_Integration__mdt objDownloadTranscript = [Select Id, DeveloperName, API_Key__c, HM_End_Point_URL__c 
                                                     from HM_Integration__mdt 
                                                     where DeveloperName = 'HM_Download_Case_Transcript'];  
        
        if(string.isBlank(objDownloadTranscript.HM_End_Point_URL__c) || string.isBlank(objDownloadTranscript.API_Key__c)){
            objCase.HM_Download_Case_Transcript__c = false; 
            if(System.Label.HM_IM_Generic_1 != null){
                objCase.HM_Integration_Message__c = System.Label.HM_IM_Generic_1;
            }
            update objCase;
            return;
        }
        
        //Append Hi Marley Case Id at the end of Download Case Transcript API
        sEndpoint = objDownloadTranscript.HM_End_Point_URL__c + objCase.HM_Case_Id__c;
        system.debug('sEndpoint => ' + sEndpoint);
        
        //HTTP Request
        Http http = new Http();    
        
        HttpRequest httpReq = HM_Integration_Helper.getHttpRequest('GET', sEndpoint, objDownloadTranscript.API_Key__c, 'application/pdf', ' ');
        
        HttpResponse httpResponse = new HttpResponse();
        
        try{
            
            httpResponse = http.send(httpReq);
            sStatusCode = string.valueOf(httpResponse.getStatusCode());
            system.debug('Status Code ==> ' + sStatusCode ); 
            
            if(sStatusCode == '201' || sStatusCode == '200'){
                // this part is not used as per the current API of HM but has been developed for any future changes
                system.debug('httpResponse : ' + httpResponse.getBodyAsBlob());
                
                //Create Transcript PDF in related File section on Case
                HM_Integration_Helper.createTranscriptPDF(httpResponse.getBodyAsBlob(), objCase);
                
                //Create a success log Entry record
                HM_Integration_Helper.create_HMLogs('Download Case Transcript', 'Success', sStatusCode, 'Outbound', ' ', sJSONResponse, ' ');
                
            }
            else if(sStatusCode == '301' || sStatusCode == '302'){               
                
                //Get location of the redirect
                String loc = httpResponse.getHeader('Location'); 
                system.debug('Response Location: ' + loc);
                
                if(string.isNotBlank(loc)) {
                    HttpRequest httpRequest = new HttpRequest();
                    httpRequest.setEndpoint(loc);
                    httpRequest.setMethod('GET');
                    
                    HttpResponse httpRes = http.send(httpRequest);                   
                    system.debug('httpResponse : ' + httpRes.getBodyAsBlob());
                    
                    //Create Transcript PDF in related File section on Case
                    HM_Integration_Helper.createTranscriptPDF(httpRes.getBodyAsBlob(), objCase);
                    
                    //Create a Success Log Entry record
                    HM_Integration_Helper.create_HMLogs('Download Case Transcript', 'Success', sStatusCode, 'Outbound', ' ', sJSONResponse, ' ');
                    
                }
                else{      
                    
                    //Update the Failure Integration Message on case
                    objCase.HM_Download_Case_Transcript__c = false;
                    if(System.Label.HM_Download_Case_Transcript_Error_Msg != null){
                        objCase.HM_Integration_Message__c = System.Label.HM_Download_Case_Transcript_Error_Msg;
                    }                    
                    update objCase;
                }
            }
            else{
                
                sJSONResponse = httpResponse.getBody();
                
                Map<string, Object> mapErrorDetails = HM_Integration_Helper.getErrorDetails(sJSONResponse);
                system.debug('mapErrorDetails ==> ' + mapErrorDetails); 
                
                if(mapErrorDetails != null && mapErrorDetails.size() > 0){
                    objCase.HM_Download_Case_Transcript__c = false;
                    objCase.HM_Integration_Message__c = mapErrorDetails.get('code') + '\r\n' + mapErrorDetails.get('detail');
                    update objCase;
                }
                
                //Create a Error Log Entry record
                HM_Integration_Helper.create_HMLogs('Download Case Transcript', 'Error', sStatusCode, 'Outbound', ' ', sJSONResponse, ' ');
                
            }
        } 
        catch(Exception e){
            
            System.debug('The following exception has occurred: ' + e.getMessage());    
            
            objCase.HM_Download_Case_Transcript__c = false;            
            update objCase;
            
            //Create a Exception Log Entry record
            HM_Integration_Helper.create_HMLogs('Download Case Transcript', 'Error', '0', 'Outbound', ' ', e.getMessage(), ' ');
        }
        
    }
}