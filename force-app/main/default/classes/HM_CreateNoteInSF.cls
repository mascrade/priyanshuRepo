/*
* Name               : HM_CreateNoteInSF
* Description        : This is an endpoint which will be called whenever a Note is created against a Case in Hi Marley,
					   to create same Note in Salesforce.
* Author             : Team Futran 
* Created On         : 25 Aug 2022
* Test Class         : HM_Test_CreateNoteInSF
* Change Log History :
*  |------------------------------------------------------------------------------|
*  | Version | Modified By        | Date        | Comment                         |
*  |------------------------------------------------------------------------------|
*  | 0.1     | Team Futran        | 28 September 2022 | Initial Version of Apex Class---|
*  |------------------------------------------------------------------------------|
*/

@RestResource(urlMapping='/CreateNoteService/*')
global class HM_CreateNoteInSF {
    
    global static String sMethodName = 'POST', sIntegrationType = 'Inbound', sJSONRequestBody, sResponseBody = 'NA';
    
    @HttpPost
    global static String createNote(){
        
        //get body from request
        RestRequest objRequest = RestContext.request;
        RestResponse objResponse = Restcontext.response;
        
        sJSONRequestBody = objRequest.requestBody.tostring();
        
        if(String.isNotBlank(sJSONRequestBody)){             
            //get contents from main JSON body
            Map<String, Object>  mapRequestBody = (Map<String, Object>)JSON.deserializeUntyped(sJSONRequestBody);
            
            //If JSON Request Body is empty return with Response
            if(mapRequestBody == null || mapRequestBody.keySet().size() <= 0){                    
                //Error Response, requestBody empty
                return GetResponse('Failure', 'Error : JSON requestBody is empty', '0');
            }
            
            if(!mapRequestBody.containsKey('id') || mapRequestBody.get('id') == null || 
               String.isBlank((String)mapRequestBody.get('id'))){
                //Error Response, empty id
                return GetResponse('Failure', 'Error : empty id', '0');  
            }
            
            //find Case using referenceId
           List<Case> lstCase = [select id, HM_Reference_ID__c, CaseNumber, HM_Case_Id__c 
                                  from Case where HM_Case_Id__c =:(String)mapRequestBody.get('referenceId') limit 1];
                        
            if(lstCase == null || lstCase.size() == 0){
                //Error Response, Case NOT Found
                return GetResponse('Failure', 'Error : Case NOT Found', '0');
            }
            
            System.debug('Case = '+lstCase[0]);
            
            //create Note against Case
            ContentNote objContentNote = new ContentNote();
            
            if(!mapRequestBody.containsKey('text') || mapRequestBody.get('text') == null || 
               String.isBlank((String)mapRequestBody.get('text'))){
                
                //Error Response, text is empty
                return GetResponse('Failure', 'Error : text in json is empty', '0');
            }
            
            objContentNote.Content = Blob.valueof((String)mapRequestBody.get('text'));
            objContentNote.Title = 'Hi Marley Note - ' + (String)mapRequestBody.get('id');
            
            if(objContentNote == null){
                //Error Response, Note not created
                GetResponse('Failure', 'Note not created', '0');
            }
            
            try{
                
                insert objContentNote;
                //call createBridgeNote method
                createBridgeNote(objContentNote,mapRequestBody,lstCase[0]);
                System.debug('ContentNote = '+objContentNote);
            }
            catch(Exception e){
                System.debug('Exception = '+e);
                String sErrorMsg = e+'';
                return GetResponse('Failure', sErrorMsg,'0');
            }
            
            ContentDocumentLink objContentDocLink = new ContentDocumentLink();
            objContentDocLink.LinkedEntityId = lstCase[0].Id;
            objContentDocLink.ContentDocumentId = objContentNote.Id;            
            
            try{                
                insert objContentDocLink;
            }
            catch(Exception e){
                return GetResponse('Failure', e.getMessage(),'0');
            }
            
            return GetResponse('Success','Case Note has been successfully created in Salesforce','200');            
        }
        
        return GetResponse('Failure', 'Error : JSON requestBody is empty', '0'); 
    }
    
    global static void createBridgeNote(ContentNote createdNote, Map<String, Object>  mapRequestBody, Case foundCase){
        
        if(createdNote != null && mapRequestBody != null && mapRequestBody.size()>0){
            
            //get Note Author details in a map
            Map<String, Object> mapNoteAuthor = (Map<String, Object>)mapRequestBody.get('author');
            
            //create a Bridge Note
            HM_Bridge_Notes__c objBridgeNote = new HM_Bridge_Notes__c();
            objBridgeNote.HM_Case_Note_id__c = (String)mapRequestBody.get('id');
            objBridgeNote.HM_Reference_id__c = (String)mapRequestBody.get('referenceId');
            objBridgeNote.HM_Note_Content__c = (String)mapRequestBody.get('text');
        	objBridgeNote.HM_Created_At__c = (String)mapRequestBody.get('createdAt');
        	objBridgeNote.SF_Case_Note_id__c = createdNote.Id;
            objBridgeNote.HM_Case__c = foundCase.Id;
            objBridgeNote.HM_Note_Title__c = createdNote.Title;
            
            if(mapNoteAuthor != null && mapNoteAuthor.size()>0){
              objBridgeNote.HM_Author_Email__c = (String)mapNoteAuthor.get('email');
              objBridgeNote.HM_Author_Id__c = (String)mapNoteAuthor.get('id');
              objBridgeNote.HM_Author_First_Name__c = (String)mapNoteAuthor.get('first');
              objBridgeNote.HM_Author_Last_Name__c = (String)mapNoteAuthor.get('last');  
            }
            
            try{
                insert objBridgeNote;
            }
            catch(Exception e){
               System.debug('Exception = '+e.getMessage()); 
            }
        }        
            
    }
    
    global static String GetResponse(String sStatus, String sMessage, String sStatusCode){
        
        HM_Integration_Helper.create_HMLogs(sMessage, sStatus, sStatusCode, sIntegrationType, sJSONRequestBody, sResponseBody,'');
        return sStatus + ' - '+  sMessage;  
    }
    
}