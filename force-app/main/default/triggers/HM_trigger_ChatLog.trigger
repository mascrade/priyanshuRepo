/*
* Class Name               : HM_trigger_ChatLog
* Description              : Apex Trigger - To Update the Unread Chat Log count on case
* Author                   : Darshana Dange (Futran Solutions)
* Created On               : 21 Sep 2022
* Test Class               : HM_Test_HM_trigger_ChatLog
* Change Log History       :
*  |----------------------------------------------------------------------------------|
*  | Version | Modified By      | Date        | Comment                               |
*  |----------------------------------------------------------------------------------|
*  | 0.1     | Darshana Dange   | 21/09/2022 | Initial Version of Class               |
*  |----------------------------------------------------------------------------------|
*/


trigger HM_trigger_ChatLog on HM_Chat_Log__c (after insert) {
    
    if(trigger.isAfter){
        
       //Create set to store the Case Id and Chat Log Id
       set<string> setCaseId = new set<string>();
       set<string> setChatLogId = new set<string>();
        
        //Store Case Id in set whenever a new chat log is created
        if(trigger.isInsert){
            for(HM_Chat_Log__c objChatLog : trigger.New) {
                if(objChatLog.HM_Case__c != null && string.isNotBlank(objChatLog.HM_Case_Id__c) && objChatLog.HM_Unread__c == true){
                    setCaseId.add(objChatLog.HM_Case__c);
                    setChatLogId.add(objChatLog.Id);
                }
            }
        }
        
        if(setCaseId.size() > 0 && setChatLogId.size() > 0){
            
            AggregateResult [] aggChatCount = [Select Count(Id) unreadCount, HM_Case__c from HM_Chat_Log__c 
                                               where Id IN :setChatLogId and HM_Unread__c = true
                                               Group by HM_Case__c];
            
            if(aggChatCount == null || aggChatCount.size() <= 0){
                return;
            }
            
            List<Case> lstCases = [Select Id, HM_Count_of_Unread_Messages__c from Case where Id IN :setCaseId];
            
            if(lstCases == null || lstCases.size() <= 0){
                return;
            }
            
            for(Case objCase : lstCases){
                for(AggregateResult aggResult : aggChatCount){                    
                    if(aggResult.get('HM_Case__c') == objCase.Id){
                        if(aggResult.get('unreadCount') != null){
                            objCase.HM_Count_of_Unread_Messages__c += (Decimal)aggResult.get('unreadCount');
                        }                        
                    }
                }
            }
            
            update lstCases;
            
        }
    }

}