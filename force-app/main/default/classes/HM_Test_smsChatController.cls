/*
* Name               : HM_Test_smsChatController
* Description        : Test Class for Apex Controller - HM_smsChatController
* Created On         : Aug 2022
* Change Log History :
*  |---------------------------------------------------------------------------------|
*  | Version | Modified By        | Date        | Comment                            |
*  |---------------------------------------------------------------------------------|
*  | 0.1     | Team Futran        | Sep 2022    | Initial Version of Test Class      |
*  |---------------------------------------------------------------------------------|
*/

@isTest
public class HM_Test_smsChatController {
    
    @isTest
    public static void testMethod1(){
        
        //Create Contact
        Contact objContact1 = new Contact(
            FirstName = 'mno',
            LastName = 'Abc',
            Title = 'VP',
            MobilePhone = '999999',
            HM_User_Id__c = 'pqr123',
            HM_Is_Opted_In__c = true,
            HM_Opt_Status_Detail__c	= 'OPTED_IN',
            HM_Text_Language__c = 'en',
            HM_Opt_In_Date__c = System.today());
        insert objContact1;
        
        //Create Case
        Case objCase = new Case(
            Status = 'Open',
            Origin = 'Web',
            HM_Case_Id__c = 'abc123',
            ContactId = objContact1.Id);
        insert objCase;
            
        //Create multiple Chat Logs
        List<HM_Chat_Log__c> lstChatLogs = new List<HM_Chat_Log__c>();
        HM_Chat_Log__c objChatLog1 = new HM_Chat_Log__c(
            HM_Case__c = objCase.Id,
            HM_Author_First_Name__c = 'abc',
            HM_Author_Last_Name__c = 'pqr',
            HM_Message_Type__c = 'text',
            HM_Channel_Source__c = 'mobile',
            HM_Message_Data__c = 'good day',
            HM_Message_Id__c = 'dfg2456',
            HM_Created_At__c = system.now(),
           HM_Unread__c = true);
        lstChatLogs.add(objChatLog1);
        insert lstChatLogs;
        
        HM_smsChatController.getChat_Count(objCase.Id);
        HM_smsChatController.getCaseDetails(objCase.Id);
        HM_smsChatController.getChatLogs(objCase.Id);
        HM_smsChatController.getLanguageValues('HM_Chat_Log__c','HM_Message_Id__c');
        HM_smsChatController.updateTextLanguageOnCase(objCase.Id,'en');
        HM_smsChatController.updateUnreadMessageCount(objCase.Id);
        HM_smsChatController.updateCreateCaseInHM(objCase.Id);
        
    }
}