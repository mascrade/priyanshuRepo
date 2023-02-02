/*
* Class Name               : HM_Test_HM_trigger_ChatLog
* Description              : Apex Test Class for trigger - HM_trigger_ChatLog
* Author                   : Darshana Dange (Futran Solutions)
* Created On               : 22 Sep 2022
* Change Log History       :
*  |----------------------------------------------------------------------------------|
*  | Version | Modified By      | Date        | Comment                               |
*  |----------------------------------------------------------------------------------|
*  | 0.1     | Darshana Dange   | 22/09/2022 | Initial Version of Class               |
*  |----------------------------------------------------------------------------------|
*/

@IsTest
public class HM_Test_HM_trigger_ChatLog {

    @IsTest
    public static void test_updateChatCount(){
        
        //Create a Test Case Data
        Case objCase = new Case();
        objCase.Origin = 'Phone';
        objCase.HM_Brand__c = 'Brand 1';
        objCase.HM_Case_Status__c = 'open';
        objCase.HM_Case_Type__c = 'case';
        objCase.HM_Text_Language__c = 'en';
        objCase.HM_Send_Create_Request__c = false;
        insert objCase;
        
        Case objCase2 = new Case();
        objCase2.Origin = 'Phone';
        objCase2.HM_Brand__c = 'Brand 1';
        objCase2.HM_Case_Status__c = 'open';
        objCase2.HM_Case_Type__c = 'case';
        objCase2.HM_Text_Language__c = 'en';
        objCase2.HM_Send_Create_Request__c = false;
        insert objCase2;
        
        HM_Chat_Log__c objChatLog = new HM_Chat_Log__c();
        objChatLog.HM_Case__c = objCase.Id;
        objChatLog.HM_Case_Id__c = 'test';
        objChatLog.HM_Unread__c = true;
        insert objChatLog;
        
    }
}