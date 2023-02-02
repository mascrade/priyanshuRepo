/*
* Name               : HM_Inbound_SMS_Creation
* Description        : Apex REST Resource for Chat Log Creation--API Endpoint, which is used to create a Chat Log record in 
*                      Salesforce when a User or Customer sends a message to Hi Marley Operator.
* Author             : Team Futran
* Created On         : Aug 2022
* Test Class         : HM_Test_Inbound_SMS_Creation
* Change Log History :
*  |--------------------------------------------------------------------------------|
*  | Version | Modified By        | Date        | Comment                           |
*  |--------------------------------------------------------------------------------|
*  | 0.1     | Team Futran        |  Aug 2022   | Initial Version of Apex Class     |
*  |--------------------------------------------------------------------------------|
*/

@RestResource(urlMapping='/TextMessageService/*')
global class HM_Inbound_SMS_Creation {    
    
    global static String sMethodName = 'POST', sIntegrationType = 'Inbound', sJSONRequestBody, sResponseBody = 'NA';
    
    global static HM_Chat_Log__c objChatLog;
    
    global static List<HM_Chat_Log__c> lstChatLogs;
    
    global static Map<String,Blob> mapImgBlob;
    
    global static Map<String,ContentVersion> mapImgCV;
    
    //get custom settings : HM Message Fields Mapping(Inbound)
    global static Map<String , HM_Message_Fields_Mapping_Inbound__c> mapMsgFieldMapping = 
        (Map<String, HM_Message_Fields_Mapping_Inbound__c>)HM_Message_Fields_Mapping_Inbound__c.getAll();     
    
    global static Map<String, Object> mapMessages;
    
    global static List<Case> lstCase;
    
    @HttpPost
    global Static String createChatLog(){
        
        List<Contact> lstContact;
        
        //define new instance of string for saving jSONRequestBody
        String sHMCaseId, sCaseQuery, sSFCaseId;
        
        //define new instance of Map<String, Object> to save the deserialized list
        Map<String, Object> mapRequestBody = new Map<String, Object>();
        
        //get body from request
        RestRequest objRequest = RestContext.request;
        RestResponse objResponse = Restcontext.response;
        
        sJSONRequestBody = objRequest.requestBody.tostring();
        
        if(String.isNotBlank(sJSONRequestBody)){
            
            //get contents from main JSON body
            mapRequestBody = (Map<String, Object>)JSON.deserializeUntyped(sJSONRequestBody);
            
            //If JSON Request Body is empty return with Response
            if(mapRequestBody == null || mapRequestBody.keySet().size() == 0){
                return response('Failure', 'Error : JSON requestBody is empty', '0');
            }
            
            //get 'primaryContact' from mapRequestBody
            Map<String, Object> mapPrimaryContact = (Map<String, Object>)mapRequestBody.get('primaryContact'); 
            
            
            //get 'customer' from mapRequestBody
            Map<String, Object> mapCustomerData = (Map<String, Object>)mapRequestBody.get('customer'); 
            
            //check if customer json body contains 'id', if it does, get value from custom setting
            if(mapCustomerData.containsKey('id') && mapCustomerData.get('id') != null && 
               String.isNotBlank((String)mapCustomerData.get('id'))){
                   
                   //get value from custom setting
                   if(mapMsgFieldMapping.containsKey('customerId') && mapMsgFieldMapping.get('customerId') != null){
                       
                       if(String.isNotBlank(mapMsgFieldMapping.get('customerId').HM_SF_Field__c)){
                           //query to find Contact
                           String sContactQuery = 'select id, Name from Contact where '+ 
                               mapMsgFieldMapping.get('customerId').HM_SF_Field__c + 
                               ' = \''+mapCustomerData.get('id')+'\' limit 1';
                           lstContact = Database.query(sContactQuery); //store the Contact in a lst
                       }
                   }
               }
            
            
            //get list of messages from mapRequestBody
            List<Object> lstMessages = (List<Object>)mapRequestBody.get('messages');
            
            // get 'caseData' from mapRequestBody to use caseId 
            Map<String, Object> mapCaseData = (Map<String, Object>)mapRequestBody.get('caseData'); 
            
            //fetch HM CaseId from JSON body
            if(mapCaseData.containsKey('id') && mapCaseData.get('id')!= null){
                sHMCaseId = (String)mapCaseData.get('id');        
                
                //use sSFFieldName & sHMCaseId to query and find Case with same HM Case id
                if(String.isNotBlank(sHMCaseId)){
                    sCaseQuery = 'select id, HM_Case_Id__c from Case where HM_Case_Id__c = \'' + sHMCaseId + '\' limit 1';
                    
                    lstCase = Database.query(sCaseQuery);   //get the case details                   
                    
                    if(lstCase != null && lstCase.size() > 0 ){
                        //assign found Case id
                        sSFCaseId = lstCase[0].id;
                        
                        //change HM Case status
                        if(mapMsgFieldMapping.containsKey('state') && mapMsgFieldMapping.get('state')!= null && 
                           mapRequestBody.containsKey('state') && mapRequestBody.get('state')!= null){
                               lstCase[0].put(mapMsgFieldMapping.get('state').HM_SF_Field__c, (String)mapRequestBody.get('state'));
                           }
                    }	
                    
                    lstChatLogs = new List<HM_Chat_Log__c>();
                    
                    //1. traverse lstMessages
                    integer nIndex = 0;
                    for(Object objMessage : lstMessages){
                        //create Chat Log object
                        objChatLog = new HM_Chat_Log__c();
                        
                        //assign parent Case id to ChatLog to establish LookUp
                        if(String.isNotBlank(sSFCaseId)){
                            objChatLog.HM_Case__c = sSFCaseId;
                        }
                        /*
                        else{
                            // Nitin TBD : need to create a record in tmp chat log and return
                            return response('Error', 'Error', '0');
                        }
                        */
                        
                        //  objChatLog.HM_Origin__c = 'Contact';
                        objChatLog.HM_Channel_Source__c = 'mobile'; 
                        objChatLog.HM_Case_Id__c = sHMCaseId;	//assign Hi Marley Case Id to Chat Log field as well
                        
                        if(lstContact != null && lstContact.size() > 0){
                            //use Contact fields to populate ChatLog record
                            //1. Contact : assign Contact id to ChatLog to establish lookup
                            objChatLog.HM_Contact__c = lstContact[0].Id;                            
                        }
                        
                        lstChatLogs.add(objChatLog);
                        //get 'messages' contents in a map ---> mapMessages
                        mapMessages = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(objMessage));
                        
                        for(String sjsonKey: mapMessages.keyset()){
                            if(sjsonKey == 'id') {                                
                                //pass 'id' as customSettingKey to useJSONKeys method
                                useJSONKeys('messageId', sjsonKey, mapMessages, nIndex);                                
                            }
                            else if(sjsonKey == 'translatedText'){
                                objChatLog.HM_Translated_Message__c = (String) mapMessages.get(sjsonKey);
                            }
                            
                            else if(sjsonKey == 'createdAt'){                                
                                //pass 'createdAt' as customSettingKey to useJSONKeys method                                
                                if(mapMsgFieldMapping.containsKey('createdAt') && mapMsgFieldMapping.get('createdAt') != null){
                                    String sSFCreatedAt =  mapMsgFieldMapping.get('createdAt').HM_SF_Field__c;
                                    
                                    //converting string to Date time before assigning to DateTime field
                                    Datetime createdAtDate = Datetime.valueOf(mapMessages.get('createdAt').toString().replace('T',' '));
                                    system.debug('createdAtDate 1==> ' + createdAtDate);
                                    createdAtDate = createdAtDate.addHours(Integer.valueOf(system.Label.HM_Timedifference));
                                    system.debug('createdAtDate 2==> ' + createdAtDate);
                                    string str = (string)mapMessages.get('createdAt').toString().replace('T',' ');
                                    str = str.right(4);
                                    str = str.removeEnd('Z');
                                    
                                    system.debug('CreatedAT--->'+  str);
                                    
                                    if(String.isNotBlank(sSFCreatedAt) && String.isNotBlank((String)mapMessages.get(sjsonKey))){
                                        objChatLog.put(sSFCreatedAt, createdAtDate);
                                        objChatLog.HM_Milliseconds__c = Integer.valueOf(str);
                                    }   
                                } 
                            }
                            else{
                                //pass jsonKey as customSettingKey & jsonKey to useJSONKeys method
                                useJSONKeys(sjsonKey, sjsonKey, mapMessages, nIndex);
                            }                            
                        }
                        
                        //if channelSource is mobile
                        if(mapMessages.containsKey('channelSource') && mapMessages.get('channelSource') == 'mobile'){
                            //get 'author' contents from mapMessages
                            objChatLog.HM_Unread__c = true;
                            if(mapPrimaryContact != null && mapPrimaryContact.size() > 0){
                                if((mapPrimaryContact.containsKey('first') && mapPrimaryContact.get('first') != null) || 
                                   (mapPrimaryContact.containsKey('last') && mapPrimaryContact.get('last') != null )){
                                       objChatLog.HM_To__c = mapPrimaryContact.get('first') + ' '+ mapPrimaryContact.get('last'); 
                                   }
                            }
                            
                            Map<String, Object> mapAuthor = (Map<String, Object>)mapMessages.get('author'); 
                            
                            //get 'profile' contents from mapAuthor
                            Map<String, Object> mapProfile = (Map<String, Object>)mapAuthor.get('profile'); 
                            
                            //2. traverse mapAuthor
                            for(String sjsonKey: mapAuthor.keyset()){
                                useJSONKeys(sjsonKey, sjsonKey, mapAuthor, nIndex);
                            }
                            
                            if((mapProfile.containsKey('firstName') && mapProfile.get('firstName') != null) || (mapProfile.containsKey('lastName') && mapProfile.get('lastName') != null)){
                                objChatLog.HM_From__c = mapProfile.get('firstName')+' '+mapProfile.get('lastName');
                            }
                            
                            //3. traverse mapProfile
                            for(String sjsonKey: mapProfile.keyset()){
                                useJSONKeys(sjsonKey, sjsonKey, mapProfile, nIndex);
                            }
                            // channelSource is marley
                        }
                        else if(mapMessages.containsKey('channelSource') && mapMessages.get('channelSource') == 'marley'){
                            
                            objChatLog.HM_To__c = lstContact[0].Name; 
                            
                            //get 'author' contents from mapMessages
                            Map<String, Object> mapAuthor = (Map<String, Object>)mapMessages.get('author'); 
                            
                            //get 'profile' contents from mapAuthor
                            Map<String, Object> mapProfile = (Map<String, Object>)mapAuthor.get('profile'); 
                            
                            //2. traverse mapAuthor
                            for(String sjsonKey: mapAuthor.keyset()){
                                useJSONKeys(sjsonKey, sjsonKey, mapAuthor, nIndex);
                            }
                            
                            if((mapProfile.containsKey('firstName') && mapProfile.get('firstName') != null) || 
                               (mapProfile.containsKey('lastName') && mapProfile.get('lastName') != null)){
                                   objChatLog.HM_From__c = mapProfile.get('firstName')+' '+mapProfile.get('lastName');
                               }
                            
                            //3. traverse mapProfile
                            for(String sjsonKey: mapProfile.keyset()){
                                useJSONKeys(sjsonKey, sjsonKey, mapProfile, nIndex);
                            }
                            
                        }// channelSource is ai
                        else if(mapMessages.containsKey('channelSource') && mapMessages.get('channelSource') == 'ai'){
                            
                            objChatLog.HM_From__c = 'Marley';
                            if(lstContact != null && lstContact.size() > 0){
                                 objChatLog.HM_To__c = lstContact[0].Name;
                            }
                           
                            Map<String, Object> mapAuthor = new Map<String, Object>();
                            mapAuthor.put('_id','');
                            
                            for(String sjsonKey: mapAuthor.keyset()){
                                useJSONKeys(sjsonKey, sjsonKey, mapAuthor, nIndex);
                            }	                            
                            Map<String, Object> mapProfile = new Map<String, Object>();
                            mapProfile.put('firstName','Marley');
                            mapProfile.put('lastName',''); 
                            for(String sjsonKey: mapProfile.keyset()){
                                useJSONKeys(sjsonKey, sjsonKey, mapProfile, nIndex);
                            }
                        }
                        
                        nIndex++;
                    }
                    
                    //upsert Chat Log records
                    if(lstChatLogs != null && lstChatLogs.size() > 0){
                        system.debug('Inside lstChatLogs-->');
                        if(string.isNotBlank(sSFCaseId)){
                            try{   
                                //call fetchImage method
                                fetchImage(lstChatLogs);
                                upsert lstChatLogs HM_Message_Id__c;
                                system.debug('lstChatLogs -->' + lstChatLogs);
                                
                                //update Case
                                if(lstCase!=null && lstCase.size()>0){
                                    update lstCase;
                                }
                                
                                //call createImgFile method
                                createImgFile(); 
                                return response('Success', 'ChatLog created/updated successfully', '200');
                            }
                            catch(Exception e){
                                return response('Failure', e.getMessage(), '0');
                            }
                        }
                        else{
                            system.debug('In Else - Temp Chats');
                            //Create Temprorary Chat Log to store the chat details
                            List<HM_Temp_Chat_Log__c> lstTempChatLogs = new List<HM_Temp_Chat_Log__c>();
                            for(HM_Chat_Log__c objChatLog : lstChatLogs){
                                system.debug('Create - Temp Chats');
                                HM_Temp_Chat_Log__c objTempChat = new HM_Temp_Chat_Log__c();
                                objTempChat.HM_Case_Id__c = objChatLog.HM_Case_Id__c;
                                objTempChat.HM_Message_Id__c = objChatLog.HM_Message_Id__c;
                                objTempChat.HM_Message_Type__c = objChatLog.HM_Message_Type__c;
                                objTempChat.HM_Media_URL__c = objChatLog.HM_Media_URL__c;
                                objTempChat.HM_Message_Data__c = objChatLog.HM_Message_Data__c;
                                objTempChat.HM_Translated_Message__c = objChatLog.HM_Translated_Message__c;
                                objTempChat.HM_Unread__c = objChatLog.HM_Unread__c;
                                objTempChat.HM_Author_Id__c = objChatLog.HM_Author_Id__c;
                                objTempChat.HM_Author_First_Name__c = objChatLog.HM_Author_First_Name__c;
                                objTempChat.HM_Author_Last_Name__c = objChatLog.HM_Author_Last_Name__c;
                                objTempChat.HM_To__c = objChatLog.HM_To__c;
                                objTempChat.HM_From__c = objChatLog.HM_From__c;
                                objTempChat.HM_Contact__c = objChatLog.HM_Contact__c;
                                objTempChat.HM_Channel_Source__c = objChatLog.HM_Channel_Source__c;
                                objTempChat.HM_Created_At__c = objChatLog.HM_Created_At__c;
                                objTempChat.HM_Milliseconds__c =  objChatLog.HM_Milliseconds__c;
                                objTempChat.HM_Date_Formatted__c = objChatLog.HM_Date_Formatted__c;
                                objTempChat.HM_Time_Formatted__c = objChatLog.HM_Time_Formatted__c;  
                                objTempChat.HM_Image_Public_Url__c = objChatLog.HM_Image_Public_Url__c;
                                lstTempChatLogs.add(objTempChat);
                            }
                            
                            if(lstTempChatLogs.size() > 0){
                                system.debug('In lstTempChatLogs: ' + lstTempChatLogs);
                                insert lstTempChatLogs;
                            }                            
                        }                        	
                    }
                }
                else{
                    //Error Response, blank HM Case Id
                    return response('Failure', 'id is missing in JSON Request Body', '0');
                }                
            }   
        }
        
        return response('Error', 'Error', '0');
    }
    
    public static void useJSONKeys(String customSettingKey, String sjsonKey, Map<String, Object> mapJsonData, integer nIndex){
        
        if(String.isNotBlank(customSettingKey) && String.isNotBlank(sjsonKey)){
            if(mapMsgFieldMapping.containsKey(customSettingKey) && mapMsgFieldMapping.get(customSettingKey) != null){
                String sSFField =  mapMsgFieldMapping.get(customSettingKey).HM_SF_Field__c;
                
                if(String.isNotBlank(sSFField) && String.isNotBlank((String)mapJsonData.get(sjsonKey))){
                    objChatLog = lstChatLogs[nIndex];
                    objChatLog.put(sSFField, mapJsonData.get(sjsonKey));
                }
            }
        }
    }
    
    global static void fetchImage(List<HM_Chat_Log__c> lstChatLogs){
        
        mapImgBlob = new Map<String,Blob>();
        
        for(HM_Chat_Log__c objCLog : lstChatLogs){
            if(objCLog.HM_Message_Type__c == 'image'){
                Blob img = callEndpoint(objCLog.HM_Message_Data__c);
                mapImgBlob.put(objCLog.HM_Message_Id__c,img);
            }  
        }
    }
    
    global static void createImgFile(){
        
        if(mapImgBlob.size() <= 0){
            return;
        }
        
        mapImgCV = new Map<String,ContentVersion>();
        
        //traverse keySet of mapImgBlob
        for(String key : mapImgBlob.keySet()){
            ContentVersion objContentVersion = new ContentVersion(); 
            Integer randomNumber = Integer.valueof((Math.random() * 100));
            objContentVersion.Title = 'Hi Marley '+randomNumber;
            objContentVersion.VersionData = mapImgBlob.get(key);
            objContentVersion.PathOnClient = 'Hi_Marley'+randomNumber+'.png';
            mapImgCV.put(key, objContentVersion);
        }
        
        if(mapImgCV.size() <= 0){
            return;
        }
        
        //insert CVs
        insert mapImgCV.values();
        
        Map<String, String> mapMsgIdAndCVId = new Map<String, String>();
        set<string> setCVIds = new set<string>();
        for(String sMsgId : mapImgCV.keyset()){
            mapMsgIdAndCVId.put(sMsgId, mapImgCV.get(sMsgId).Id);
            setCVIds.add(mapImgCV.get(sMsgId).Id);
        }
        
        // get the chatlogs associated to the message id
        List<HM_Chat_Log__c> lstChatLogs = [select id, HM_Message_Id__c from HM_Chat_Log__c 
                                            where HM_Message_Id__c =: mapImgCV.keyset()];
        
        // get the content versions associated with the messages Ids
        if(setCVIds.size() > 0){
            List<ContentVersion> lstCVs = [select id, Title, ContentDocumentId from ContentVersion
                                           where id =: setCVIds];
            
            if(lstCVs != null && lstCVs.size() > 0 && lstChatLogs != null && lstChatLogs.size() > 0){
                //Create ContentDocumentLink 
                string sCVId;
                List<ContentDocumentLink> lstCDL = new List<ContentDocumentLink>();
                List<ContentDistribution> lstContDistrib = new List<ContentDistribution>();
                
                Map<String,String> mapCLogIdAndCVId = new Map<String,String>();
                
                for(HM_Chat_Log__c objCL : lstChatLogs){
                    if(mapMsgIdAndCVId.containsKey(objCL.HM_Message_Id__c)){
                        sCVId = mapMsgIdAndCVId.get(objCL.HM_Message_Id__c);
                        for(ContentVersion objCV : lstCVs){
                            if(sCVId == objCV.id){
                                ContentDocumentLink cdl = new ContentDocumentLink();
                                cdl.LinkedEntityId = objCL.Id;		//record id : ChatLog
                                cdl.ContentDocumentId = objCV.ContentDocumentId;
                                cdl.shareType = 'V';
                                lstCDL.add(cdl);
                                
                                ContentDocumentLink cdlForCase = new ContentDocumentLink();
                                cdlForCase.LinkedEntityId = lstCase[0].id;		//record id : Case
                                cdlForCase.ContentDocumentId = objCV.ContentDocumentId;
                                cdlForCase.shareType = 'V';
                                lstCDL.add(cdlForCase);
                                
                                mapCLogIdAndCVId.put(objCL.Id,objCV.Id);
                                
                                //Create ContentDistribution
                                ContentDistribution objContentDistrib = new ContentDistribution(
                                    Name = objCV.Title,
                                    ContentVersionId = objCV.Id,
                                    PreferencesAllowViewInBrowser= true
                                    
                                );
                                lstContDistrib.add(objContentDistrib);
                                
                                break;
                            }
                        }
                    }
                }
                
                
                //Insert Content Doc Link
                if(lstCDL.size() > 0){
                    insert lstCDL;
                }
                //Insert content distribution to create public link
                if(lstContDistrib.size() > 0){
                    insert lstContDistrib;
                }
                
                //put public link in Msg data
                //1. traverse ContentDistribution to get DistributionPublicUrl
                List<ContentDistribution> lstCDs = [SELECT Id,Name,ContentVersionId,DistributionPublicUrl, ContentDownloadUrl FROM ContentDistribution
                                                    where ContentVersionId =: setCVIds];
                
                //2. This list will store update Chat Logs
                List<HM_Chat_Log__c> lstUpdateCLogs = new List<HM_Chat_Log__c>();
                
                //3. Traverse Chat Logs look for CV Id that maps with the particular Chat Log and put public link in Msg data
                for(HM_Chat_Log__c objCLog : lstChatLogs){
                    if(mapCLogIdAndCVId.containsKey(objCLog.Id)){
                        sCVId = mapCLogIdAndCVId.get(objCLog.Id);
                        for(ContentDistribution objCDist : lstCDs){	
                            if(sCVId == objCDist.ContentVersionId){
                                //put public link in Msg data
                                objCLog.HM_Message_Data__c = objCDist.ContentDownloadUrl;
                                objCLog.HM_Image_Public_Url__c = objCDist.DistributionPublicUrl;
                                lstUpdateCLogs.add(objCLog);
                            }
                        }	
                    }		
                }
                
                update lstUpdateCLogs;
            }
        }
    }
    
    global static Blob callEndpoint(String msgData){
        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint(msgData);
        httpReq.setMethod('GET');
        Http http = new Http(); 
        //fetch response
        HttpResponse res = http.send(httpReq); 
        //fetch img body from response
        Blob image = res.getBodyAsBlob(); 
        return image;
        
    }    
    
    global static String response(String sStatus, String sMessage, String sStatusCode){
        HM_Integration_Helper.create_HMLogs(sMessage, sStatus, sStatusCode, sIntegrationType, sJSONRequestBody, sResponseBody,'');
        return sStatus + ' - '+  sMessage;  
    }    
    
}