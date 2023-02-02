/*
* Name               : HM_Test_OptIn_OptOut
* Description        : This Test Class covers HM_OptIn_OptOut_Helper,HM_OptInRestAPI,HM_OptOutRestAPI Apex Classes
* Author             : Rohit (Futran Solutions)
* Created On         : 5 Aug 2022
* Test Class         : HM_Test_OptIn_OptOut
* Change Log History :
*  |------------------------------------------------------------------------------|
*  | Version | Modified By        | Date        | Comment                         |
*  |------------------------------------------------------------------------------|
*  | 0.1     | Rohit              | 5 Aug 2022 | Initial Version of Apex Class---|
*  |------------------------------------------------------------------------------|
*/
@isTest
public class HM_Test_OptIn_OptOut {
    
    @testSetup 
    public static void setup() {
        
        User objUser = [select id, Name,Profile.Name from User where Profile.Name = 'System Administrator' limit 1];
        System.debug('objUser = '+objUser);    
        
        // Create test Contacts
        List<Contact> lstContact = new List<Contact>();
        Contact objContact1 = new Contact(
            FirstName = 'mno',
            LastName = 'Abc',
            Title = 'VP',
            MobilePhone = '999999');
        
        lstContact.add(objContact1);
        
        Contact objContact2 = new Contact(
            FirstName = 'pqr',
            LastName = 'Xyz',
            Title = 'Manager',
            MobilePhone = '999999',
            HM_Is_Opted_In__c = true);
        
        lstContact.add(objContact2);	
        insert lstContact;
        
        //insert Custom Setting
        HM_User_Mobile_Field_Mapping__c objMobileField = new HM_User_Mobile_Field_Mapping__c();
        objMobileField.Name = 'mobile';
        objMobileField.HM_SF_Field__c = 'HM_MobileNumber__c';
        insert objMobileField;
    }
    
    @isTest
    public static void testMethod1(){
        
        //Test Opt In
        RestRequest requestOptIn = new RestRequest(); 
        RestResponse responseOptIn = new RestResponse();
        String jsonMsg = '{"id": "fgh7778","first": "Jean Luc","last": "Picard","email": "tester1701@testemail.com","mobile": "+1999999"}';
        requestOptIn.requestBody = Blob.valueof(jsonMsg);
        
        requestOptIn.requestURI = '/services/apexrest/setOptIn/';
        requestOptIn.httpMethod = 'POST';
        
        RestContext.request = requestOptIn;
        RestContext.response= responseOptIn;
        
        //Test Opt Out
        RestRequest requestOptOut = new RestRequest(); 
        RestResponse responseOptOut = new RestResponse();
        
        requestOptIn.requestURI = '/services/apexrest/setOptOut/';
        requestOptIn.httpMethod = 'POST';
        
        Test.startTest();
        HM_OptInRestAPI.optIn();
        HM_OptOutRestAPI.optOut();
        Test.stopTest();
        
    }
}