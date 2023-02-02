/*
* Class Name               : HM_Notifications
* Description              : Apex Class(Outbound) - This Class calls the Send Message API Endpoint to send 
*							 an automated messages to the end user.
* Author                   : Team Futran 
* Created On               : 17 Nov 2022
* Test Class               : HM_Test_HM_Notifications
* Change Log History       : 
*  |--------------------------------------------------------------------------------|
*  | Version | Modified By     | Date       | Comment                               |
*  |--------------------------------------------------------------------------------|
*  | 0.1     | Team Futran    | 17/11/2022 | Initial Version of Class               |
*  |--------------------------------------------------------------------------------|
*/

public class HM_Notifications {
    
    @InvocableMethod(label='Send SMS' description='This action will trigger an automated sms messages to the end user.')
    public static void HM_Notifications(List<FlowInputs> lstFlowInputs) {
        
        system.debug('lstFlowInputs' + lstFlowInputs);
        
        string sTemplateId, sMessage, sEndpoint, sSerializedData, sStatusCode, sJSONResponse;
        map<string, string> mapContactIdMessage = new map<string, string>();
        String sObjectName;
        HM_Chat_Log__c objChatLog;
        
        //Traverse All Inputs received from Flow
        for(FlowInputs objInput : lstFlowInputs){
            
            if(string.isBlank(sTemplateId)){
                sTemplateId = objInput.SMS_Template_No;
            }
            
            if(string.isBlank(sObjectName)){
                Id recId = objInput.RecordId;
                sObjectName = recId.getSObjectType().getDescribe().getName();
            }
            
            mapContactIdMessage.putAll(HM_Integration_Helper.getMergedMessage(sTemplateId , objInput.RecordId , sObjectName));
        }
        
        system.debug('sObjectName ' + sObjectName);
        system.debug('mapContactIdMessage' + mapContactIdMessage);
        
        if(mapContactIdMessage.KeySet().size() <= 0){
            system.debug('Contact Ids Not Found!');
            HM_Integration_Helper.create_HMLogs('HM_Notifications', 'Error', '0', 'Outbound', '', 'Contact & Template Data not Found!','');
            return;
        }
        
        //Find Case with given sCaseId and get it's Parent Contact info
        List<Case> lstCase = [select id, HM_Case_Id__c, HM_Reference_ID__c, ContactId, Contact.Name, Owner.Email 
                              from Case where ContactId IN :mapContactIdMessage.KeySet() and HM_Enable_Notifications__c = true and
                              Contact.HM_Is_Opted_In__c = true and Contact.HM_Opt_Status_Detail__c = 'OPTED_IN'];
        
        System.debug('lstCase = ' + lstCase.size());
        
        //if there is no Case wih given sCaseId
        if(lstCase == null || lstCase.size() <= 0){
            System.debug('Case list is empty');
            HM_Integration_Helper.create_HMLogs('HM_Notifications', 'Error', '0', 'Outbound', '', 'Case list is empty!','');
            return;
        }
        
        //Get Integration details from HM_Integration Metadata
        HM_Integration__mdt objSendMsg = [Select Id, DeveloperName, API_Key__c, HM_End_Point_URL__c 
                                          from HM_Integration__mdt 
                                          where DeveloperName = 'HM_Send_SMS_Messages_without_template']; 
        
        //End Point URL or API Key is blank or null
        if(objSendMsg == null || String.isBlank(objSendMsg.HM_End_Point_URL__c) || String.isBlank(objSendMsg.API_Key__c)){
            
            System.debug('objSendMsg is empty');
            HM_Integration_Helper.create_HMLogs('HM_Notifications', 'Error', '0', 'Outbound', '', 'End Point URL or API Key is blank !','');
            return;
        }
        
        sEndpoint = objSendMsg.HM_End_Point_URL__c;
        System.debug('sEndpoint : ' + sEndpoint);
        
        List<UpdateWrapper> lstUpdateWrapper = new List<UpdateWrapper>();
        List<HM_Chat_Log__c> lstHMChatLogs = new List<HM_Chat_Log__c>();
        
        for(Case objCase : lstCase){
            
            if(mapContactIdMessage.containsKey(objCase.ContactId)){
                
                sMessage = mapContactIdMessage.get(objCase.ContactId);
                system.debug('sMessage' + sMessage);
                
                //create ChatLog
                objChatLog = new HM_Chat_Log__c();
                objChatLog.HM_Case__c = objCase.Id;	//establish M-D with Case
                objChatLog.HM_Contact__c = objCase.ContactId;	//establish lookup with Contact
                objChatLog.HM_To__c = objCase.Contact.Name;	//Contact or Customer's Name
                objChatLog.HM_From__c = 'Marley';	
                objChatLog.HM_Author_First_Name__c = 'Marley';
                objChatLog.HM_Origin__c = 'SFDC'; //from SF
                objChatLog.HM_Message_Type__c = 'text';
                objChatLog.HM_Channel_Source__c = 'ai';	//<---
                objChatLog.HM_Message_Data__c = sMessage;
                
                //Create json request body
                Map<String, object> mapJsonData = new Map<String, object>();
                mapJsonData.put('caseId', objCase.HM_Case_Id__c);
                mapJsonData.put('messageBody', sMessage);
                mapJsonData.put('source', 'ai');
                
                System.debug('mapJsonData => ' + mapJsonData.size());
                
                if(mapJsonData.size() <= 0){
                    return;
                }
                
                //serialize json request body
                sSerializedData = JSON.serialize(mapJsonData);
                System.debug('Data in Map = '+ JSON.serializepretty(mapJsonData));
                
                //call Hi Marley endpoint
                //1. HTTP Request
                Http http = new Http();
                
                HttpRequest httpReq = HM_Integration_Helper.getHttpRequest('POST', sEndpoint, objSendMsg.API_Key__c, '', sSerializedData);
                
                //2. HTTP Response
                HttpResponse httpResponse = new HttpResponse();
                
                try{
                    
                    //send request
                    httpResponse = http.send(httpReq);
                    
                    //create a wrapper instance for updating case details
                    UpdateWrapper objUW = new UpdateWrapper();
                    objUW.sSerializedData = sSerializedData;
                    
                    //receive Response from HM
                    sStatusCode = string.valueOf(httpResponse.getStatusCode());
                    system.debug('Status Code ==> ' + sStatusCode );             
                    
                    sJSONResponse = httpResponse.getBody();
                    
                    objUW.sStatusCode = sStatusCode;
                    objUW.sJSONResponse = sJSONResponse;
                    
                    //after Response is received, insert ChatLog only if Msg Delivery was successful
                    if(sStatusCode == '200' || sStatusCode == '201'){
                        
                        Map<String, Object> mapHMResponse = (Map<String, Object>)JSON.deserializeUntyped(sJSONResponse);
                        System.debug('mapHMResponse ==> ' + mapHMResponse);
                        
                        // Msg id
                        objChatLog.HM_Message_Id__c = (String) mapHMResponse.get('_id');
                        
                        // Created At : convert string to Date time before assigning to DateTime field
                        Datetime createdAtDate = Datetime.valueOf(mapHMResponse.get('createdAt').toString().replace('T',' '));
                        objChatLog.HM_Created_At__c = createdAtDate;
                        
                        //Author id
                        objChatLog.HM_Author_Id__c = (String) mapHMResponse.get('authorId');
                        
                    }
                    else{
                        
                        objUW.bSuccess = false;
                        
                        Map<String, Object> mapHMResponse = HM_Integration_Helper.getErrorDetails(sJSONResponse);                
                        System.debug('mapHMResponse = '+mapHMResponse);
                        
                        if(mapHMResponse != null || mapHMResponse.keySet().size() > 0){
                            // update the error details on the chat log  
                            objChatLog.HM_Error_Details__c = (String) mapHMResponse.get('detail');
                            objChatLog.HM_Created_At__c = System.now();
                        }                   
                        
                    }
                    
                  //  lstUpdateWrapper.add(objUW);
                  //  lstHMChatLogs.add(objChatLog); 
                    
                }
                catch(Exception e){
                    
                    System.debug('The following exception has occurred: ' + e.getMessage());            
                    
                    //Create an Error log Entry record
                    HM_Integration_Helper.create_HMLogs('Failed Message Delivery from SF to HM', 'Error', '0', 'Outbound', sSerializedData, e.getMessage(),'');
                }
            }
        }
        
        //Insert Chat Logs
        if(lstHMChatLogs.size() > 0){
            //insert lstHMChatLogs;
        }
        
        //Create Log Entries
        if(lstUpdateWrapper.size() > 0){
            for(UpdateWrapper objUW : lstUpdateWrapper){
                if(objUW.bSuccess){                                
                    //Create Success Log Entry record
                   // HM_Integration_Helper.create_HMLogs('Successful Message Delivery from SF to HM', 'Success', objUW.sStatusCode, 'Outbound', 
                                                       // objUW.sSerializedData, objUW.sJSONResponse,'');                          
                }
                else{
                    //Create a Error Log Entry record
                   // HM_Integration_Helper.create_HMLogs('Message Delivery from SF to HM failed', 'Failed', objUW.sStatusCode, 
                                                      //  'Outbound', objUW.sSerializedData, objUW.sJSONResponse,'');                           
                }
            }
        }
        
        
    }
    
    //input details that comes to apex from flow
    public class FlowInputs{
        
        @InvocableVariable
        public string RecordId;
        
        @InvocableVariable
        public String SMS_Template_No;
        
    }
    
    public class UpdateWrapper{
        public boolean bSuccess; 
        public string sJSONResponse;
        public string sStatusCode;
        public string sSerializedData;
        
        public UpdateWrapper(){
            bSuccess = true;
            sJSONResponse = '';
            sStatusCode = '';
            sSerializedData = '';
        }
    }
}