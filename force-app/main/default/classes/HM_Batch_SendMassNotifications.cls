/*
* Class Name               : HM_Batch_SendMassNotifications
* Description              : Apex Class - This Class is called from a Flow. This Class is called when a User clicks on the 'Send
							 Mass Notifications' button to send notifications to all Contacts whose zip codes are mentioned in 
							 the Mass Notification record.
* Author                   : Team Futran 
* Created On               : 16 December 2022
* Test Class               : HM_SendNotificationsToHM
* Change Log History       : 
*  |--------------------------------------------------------------------------------|
*  | Version | Modified By     | Date       | Comment                               |
*  |--------------------------------------------------------------------------------|
*  | 0.1     | Team Futran    | 16/12/2022 | Initial Version of Class               |
*  |--------------------------------------------------------------------------------|
*/

public class HM_Batch_SendMassNotifications implements Database.Batchable<sObject>,
Database.AllowsCallouts,Database.Stateful{ 
    //NOTE : HM_SMS_Template__r.Name is used as template id in getMergedMessage() method
    
    public String sMassNotifId;
    
    @InvocableMethod(label='Send Mass Notifications' description='Send Mass Notifications' category= 'HM_Mass_Notifications__c')    
    public static void HM_MassNotif(List<string> lstMassNotifIds){
        System.debug('lstMassNotifIds ' + lstMassNotifIds);
        if(lstMassNotifIds == null || lstMassNotifIds.size() <= 0){
            System.debug('lstMassNotifIds is empty');
            return;
        }
        
        HM_Batch_SendMassNotifications objBatch = new HM_Batch_SendMassNotifications();
        objBatch.sMassNotifId = lstMassNotifIds[0];
        //System.debug('objBatch.sMassNotifId : '+objBatch.sMassNotifId);
        
        //run batch
        Id batchId = Database.executeBatch(objBatch);
    }
    
    public List<HM_Mass_Notification_Contacts__c> start(Database.BatchableContext BC) {
        
        System.debug('sMassNotifId : ' + sMassNotifId);
        
        //  System.debug('sQuery = '+sQuery);
        List<HM_Mass_Notification_Contacts__c> lstMNCs = [select id, HM_Case__c, HM_Contact__c, HM_Message_Sent__c, HM_Mass_Notifications__r.HM_SMS_Template__r.Name,
                                                          HM_Success_Error_Details__c, HM_Mass_Notifications__r.HM_SMS_Template__c, HM_Mass_Notifications__r.Name
                                                          from HM_Mass_Notification_Contacts__c where HM_Mass_Notifications__c =:sMassNotifId ];
        System.debug('lstMNCs = '+lstMNCs);
        // return Database.getQueryLocator(sQuery);
        return lstMNCs;
    }
    
    public void execute(Database.BatchableContext BC, List<HM_Mass_Notification_Contacts__c> scope) {
        System.debug('in execute');
        System.debug('scope : '+scope);
        
        if(scope == null || scope.size() <= 0){
            System.debug('scope empty '); 
            return; 
        }
        
        //   Map<String,String> mainMapContactIdvsMergedBody = new Map<String,String>();
        Map<String,String> mapCaseIdvsMergedBody = new Map<String,String>();
        
        //traverse MNCs
        for(HM_Mass_Notification_Contacts__c objMNC : scope){
            
            //call  getMergedMessage from HM_Integration_Helper
            Map<String,String> mapContactIdvsMergedBody =  HM_Integration_Helper.getMergedMessage(objMNC.HM_Mass_Notifications__r.HM_SMS_Template__r.Name, objMNC.HM_Contact__c, 'Contact');
            //  System.debug('mapContactIdvsMergedBody = '+mapContactIdvsMergedBody);   
            // mainMapContactIdvsMergedBody.putAll(mapContactIdvsMergedBody);  
            
            if(mapContactIdvsMergedBody != null || mapContactIdvsMergedBody.size() < 0){
                mapCaseIdvsMergedBody.put(objMNC.HM_Case__c,mapContactIdvsMergedBody.get(objMNC.HM_Contact__c));
            }
        }
        
        //  System.debug('mapCaseIdvsMergedBody = '+mapCaseIdvsMergedBody);
        
        if(mapCaseIdvsMergedBody == null || mapCaseIdvsMergedBody.size() <= 0){
            System.debug('mapCaseIdvsMergedBody empty '); 
            return; 
        }
        
        Map<String,HM_SendNotificationsToHM.Wrapper_SendNotifications> mapCaseIdWrapper = new Map<String,HM_SendNotificationsToHM.Wrapper_SendNotifications>();         
        List<HM_Logs__c> lstIntegLogs = new List<HM_Logs__c>();
        
        //traverse map to send messages(make callouts)
        for(String keyCaseId : mapCaseIdvsMergedBody.keySet()){
            
            //call HM_SendMessageToHM to send msgs
            HM_SendNotificationsToHM.Wrapper_SendNotifications objWrap = HM_SendNotificationsToHM.sendMessage(mapCaseIdvsMergedBody.get(keyCaseId), keyCaseId);
            lstIntegLogs.add(objWrap.objIntegLog);
            //System.debug('objWrap = '+objWrap);
            mapCaseIdWrapper.put(keyCaseId,objWrap); 
        }
        
        if(mapCaseIdWrapper == null || mapCaseIdWrapper.size() <= 0 ){
            System.debug('mapCaseIdWrapper empty ');
            return;
        }
        
        List<HM_Chat_Log__c> lstChatLogs = new List<HM_Chat_Log__c>();
        Map<HM_Mass_Notification_Contacts__c,HM_Chat_Log__c> mapMNCvsChatLog = new Map<HM_Mass_Notification_Contacts__c,HM_Chat_Log__c>();
        
        //traverse MNCs to update
        for(HM_Mass_Notification_Contacts__c objMNC : scope){
            if(mapCaseIdWrapper.containsKey(objMNC.HM_Case__c)){
                objMNC.HM_Message_Sent__c = mapCaseIdWrapper.get(objMNC.HM_Case__c).msgSent;
                objMNC.HM_Success_Error_Details__c = mapCaseIdWrapper.get(objMNC.HM_Case__c).successOrErrorDetails;
                lstChatLogs.add(mapCaseIdWrapper.get(objMNC.HM_Case__c).objWrapChatLog);
                mapMNCvsChatLog.put(objMNC,mapCaseIdWrapper.get(objMNC.HM_Case__c).objWrapChatLog);
            }
        }
        
        if(lstChatLogs == null || lstChatLogs.size() <= 0 ){
            System.debug('lstChatLogs empty ');
            return;
        }
        
        //create Chat Logs
        try{
            System.debug('in try blk');  
            insert lstChatLogs; 
            System.debug('lstChatLogs inserted');
        }
        catch(Exception e){
            System.debug('error = '+e.getMessage());    
        }
        
        if(mapMNCvsChatLog == null || mapMNCvsChatLog.size() <= 0 ){
            System.debug('mapMNCvsChatLog empty ');
            return;
        }
        
        //match MNC to its ChatLog to establish lookup with ChatLog
        for(HM_Mass_Notification_Contacts__c objMNC : scope){
            if(mapMNCvsChatLog.containsKey(objMNC)){
                
                if(mapMNCvsChatLog.get(objMNC) != null){
                    //establish lookup with ChatLog
                    objMNC.HM_Chat_Log__c =  mapMNCvsChatLog.get(objMNC).Id; 
                }
                
            }
        }	
        
        //update MNCs
        try{
            System.debug('in try blk');  
            update scope; 
            System.debug('scope updated');
        }
        catch(Exception e){
            System.debug('error = '+e.getMessage());    
        }
        
        //insert Integration Logs
        try{
            System.debug('in try blk');  
            insert lstIntegLogs; 
            System.debug('lstIntegLogs inserted');
        }
        catch(Exception e){
            System.debug('error = '+e.getMessage());    
        }
    }
    
    
    
    public void finish(Database.BatchableContext info) { 
    }
    
}