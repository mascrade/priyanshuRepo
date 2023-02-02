/*
* Name               : HM_DeleteNoteInSF
* Description        : This is an endpoint which will be called whenever a Note is deleted against a Case in Hi Marley,
					   to delete same Note in Salesforce.
* Author             : Team Futran 
* Created On         : 28 Sept 2022
* Test Class         : HM_Test_DeleteNoteInSF
* Change Log History :
*  |------------------------------------------------------------------------------|
*  | Version | Modified By        | Date         | Comment                        |
*  |------------------------------------------------------------------------------|
*  | 0.1     | Team Futran        | 28 Sept 2022 | Initial Version of Apex Class--|
*  |------------------------------------------------------------------------------|
*/

@RestResource(urlMapping='/DeleteNoteService/*')
global class HM_DeleteNoteInSF {
    
    global static String sMethodName = 'POST', sIntegrationType = 'Inbound', sJSONRequestBody, sResponseBody = 'NA';
    
    @HttpPost
    global static String deleteNote(){
        
        //get body from request
        RestRequest objRequest = RestContext.request;
        RestResponse objResponse = Restcontext.response;
        
        sJSONRequestBody = objRequest.requestBody.tostring();
        
        if(String.isBlank(sJSONRequestBody)){
            return getResponse('Failure', 'Error : JSON requestBody is empty', '0'); 
        }
        
        //get contents from main JSON body
        Map<String, Object>  mapRequestBody = (Map<String, Object>)JSON.deserializeUntyped(sJSONRequestBody);
        
        //If JSON Request Body is empty return with Response
        if(mapRequestBody == null || mapRequestBody.keySet().size() <= 0){            
            //Error Response, requestBody empty
            return getResponse('Failure', 'Error : JSON requestBody is empty', '0');
        }
        
        if(!mapRequestBody.containsKey('id') || mapRequestBody.get('id') == null || 
           String.isBlank((String)mapRequestBody.get('id'))){
               //Error Response, empty note id
               return getResponse('Failure', 'Error : empty id', '0');  
           }
        
        //find Bridge Note using id
        List<HM_Bridge_Notes__c> lstBridgeNote = [select id, HM_Case_Note_id__c, SF_Case_Note_id__c,HM_Archived__c
                                                  from HM_Bridge_Notes__c 
                                                  where HM_Case_Note_id__c =: (String)mapRequestBody.get('id')];
        
        if(lstBridgeNote == null || lstBridgeNote.size() == 0){
            //Error Response, Bridge Note not found
            return getResponse('Failure', 'Error : Note not found', '0');  
        }
        
        System.debug('lstBridgeNote = '+lstBridgeNote);
        lstBridgeNote[0].HM_Archived__c = true;
        
        try{
            update lstBridgeNote[0];
        }
        catch(Exception e){
            System.debug('Exception = '+e.getMessage()); 
        }
        
        //find Std Note with SF_Case_Note_id__c
        List<ContentNote> lstContentNote = [select id from ContentNote where id =: lstBridgeNote[0].SF_Case_Note_id__c];
        
        if(lstContentNote == null || lstContentNote.size() == 0){
            //Error Response, Content Note not found
            return getResponse('Failure', 'Error : Note not found', '0');  
        }
        
        try{
            delete lstContentNote;
        }
        catch(Exception e){
            System.debug('Exception = '+e.getMessage()); 
            return getResponse('Failure', 'Error : Note Not deleted', '0');
        }
        
        return getResponse('Success', 'Success : Note deleted', '0');
    }
    
    global static String getResponse(String sStatus, String sMessage, String sStatusCode){        
        HM_Integration_Helper.create_HMLogs(sMessage, sStatus, sStatusCode, sIntegrationType, sJSONRequestBody, sResponseBody,'');
        return sStatus + ' - '+  sMessage;  
    }
    
}