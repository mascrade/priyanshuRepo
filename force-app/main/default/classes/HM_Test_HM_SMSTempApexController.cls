/*
* Name               : HM_Test_HM_SMSTempApexController
* Description        : Apex Controller of Add/Edit LWC and SMS template Creation LWC
* Author             : Rohit (Futran Solutions)
* Created On         : 19 September 2022
* Change Log History : 
*  |------------------------------------------------------------------------------|
*  | Version | Modified By        | Date        | Comment                         |
*  |------------------------------------------------------------------------------|
*  | 0.1     | Rohit              | 19 Sep 2022 |-Initial Version of Apex Class---|
*  |------------------------------------------------------------------------------|
*/

@isTest
public class HM_Test_HM_SMSTempApexController {
    @isTest
    public static void HM_Test_HM_SMSTempApexController(){
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='Marley@testorg.com');
        insert u;
        
        HM_SMS_Template__c objSMSTemp = new HM_SMS_Template__c();
        objSMSTemp.HM_Is_Active__c = true;
        objSMSTemp.HM_Name__c = 'AbcTemp';
        objSMSTemp.HM_Template_Body__c = 'Something';
        objSMSTemp.HM_Object_Name__c = 'Contact';
        insert objSMSTemp;
        
        Case objCase= new Case();
        objCase.HM_Case_Type__c = 'policy';
        objCase.HM_Case_Id__c = 'ABC123';
        objCase.Status = 'Open';
        objCase.Origin = 'Email';
        objCase.OwnerId = u.Id;
        insert objCase;
        
        String caseQueryString = 'HM_Case_Type__c,HM_Case_Id__c,Status,Origin';
        String userQueryString = 'Alias,Email,LastName';
        
        Test.startTest();
        
        HM_SMSTempApexController.GetAllSMSTemplates();
        HM_SMSTempApexController.GetCaseFieldAPInames();
        HM_SMSTempApexController.GetContactFieldAPInames();
        HM_SMSTempApexController.GetAccountFieldAPInames();
        HM_SMSTempApexController.GetUserFieldAPInames();
        
        HM_Select_SMS_Template.GetAllSMSTemplates();
        HM_Select_SMS_Template.getCaseDataForUpdateTemplate(objCase.Id, caseQueryString);
        HM_Select_SMS_Template.getOwnerDataForUpdateTemplate(objCase.Id, userQueryString);
        HM_SMSTempApexController.deleteRecord(objSMSTemp.Id);	
        HM_SMSTempApexController.GetFieldAPInames('Contact');
        HM_SMSTempApexController.GetCustomSettingObjectNames();
        HM_SMSTempApexController.SaveTemplate(objSMSTemp.Id, 'TemplateName', true, 'Body', 'Contact',  'Contact');
        Test.stopTest();
    }
}