/*
* Name               : HM_Test_CreateRelatedMassNfContacts
* Description        : Apex Class - Test Coverage for HM_CreateRelatedMassNfContacts
* Author             : Team Futran 
* Created On         : 14 December 2022
* Change Log History :
*  |------------------------------------------------------------------------------|
*  | Version | Modified By    | Date             | Comment                        |
*  |------------------------------------------------------------------------------|
*  | 0.1     | Futran Team    | 14 December 2022 | Initial Version of Apex Class  |
*  |------------------------------------------------------------------------------|
*/

@isTest
public class HM_Test_CreateRelatedMassNfContacts {

    @isTest 
    public static void testData() {
    
    //create Contact
    Contact objContact = new Contact(
        FirstName = 'mno',
        LastName = 'Abc',
        Title = 'VP',
        MobilePhone = '+1962365233',
    	HM_Enable_Notifications__c = true,
    	HM_Is_Opted_In__c = true,
        HM_Opt_Status_Detail__c = 'OPTED_IN',
        MailingPostalCode = '123');
        insert objContact;
    
        //create Case
        Case objCase = new Case(
            Status = 'Open',
            Origin = 'Web',
            HM_Case_Id__c = 'abc123',
        	HM_Enable_Notifications__c = true,
            ContactId = objContact.Id);
        insert objCase;
    	
        //create SMS Template
        HM_SMS_Template__c objSMS = new HM_SMS_Template__c(
        HM_Name__c = 'abc',
        HM_Is_Active__c = true,
        HM_Object_Name__c = 'Contact',
        HM_Template_Body__c = 'Hi {FirstName}',
        HM_Contact_API_Name__c = 'Contact'    
        );
        insert objSMS;
            
        //create MN
        //MN list
        List<HM_Mass_Notifications__c> lstMN1 = new List<HM_Mass_Notifications__c>();
        HM_Mass_Notifications__c objMN = new HM_Mass_Notifications__c(
        HM_Zip_Codes__c = '123',
        HM_SMS_Template__c = objSMS.Id);
        lstMN1.add(objMN);
        insert lstMN1;

		//create MNC
        List<HM_Mass_Notification_Contacts__c> lstMNC1 = new List<HM_Mass_Notification_Contacts__c>();
        HM_Mass_Notification_Contacts__c objMNC = new HM_Mass_Notification_Contacts__c(
        HM_Case__c = objCase.Id,
        HM_Contact__c = objContact.Id,
        HM_Mass_Notifications__c = lstMN1[0].Id);
        lstMN1.add(objMN);
        insert lstMNC1;
        
        //empty MN list
        List<HM_Mass_Notifications__c> lstMN2 = new List<HM_Mass_Notifications__c>();
        
        //MN list
        List<HM_Mass_Notifications__c> lstMN3 = new List<HM_Mass_Notifications__c>();
        HM_Mass_Notifications__c objMN3 = new HM_Mass_Notifications__c(
        HM_Zip_Codes__c = '456',
        HM_SMS_Template__c = objSMS.Id);
        lstMN3.add(objMN3);
        insert lstMN3;
        
        HM_CreateRelatedMassNfContacts.HM_CollectMassNotifRec(lstMN1);
        HM_CreateRelatedMassNfContacts.HM_CollectMassNotifRec(lstMN2);
        HM_CreateRelatedMassNfContacts.HM_CollectMassNotifRec(lstMN3);
        
        List<String> lstMNIds = new List<String>();
        lstMNIds.add(objMN.Id);
        
}
 	/*
    @isTest
    public static void test1() {
        
    }*/
}