@isTest
public class HM_Test_Batch_SendMassNotifications {
 	
    public class MockHttpResponseGeneratorSuccess implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
           
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"createdAt":"2021-08-12T15:18:51.580Z"}');
            res.setStatusCode(200);
            return res;
        }
    }
     public class MockHttpResponseGeneratorError implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
           
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"createdAt":"2021-08-12T15:18:51.580Z", "errors" : [{"abc":123},{"pqr":456}]}');
            res.setStatusCode(400);
            return res;
        }
    }
       
    @isTest 
    public static void test1() {
    
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
        HM_Template_Body__c = 'Hi {FirstName}'
        //HM_Contact_API_Name__c = 'Contact'    
        );
        insert objSMS;
            
        //create MN
        //MN list
      //  List<HM_Mass_Notifications__c> lstMN1 = new List<HM_Mass_Notifications__c>();
        HM_Mass_Notifications__c objMN = new HM_Mass_Notifications__c(
        HM_Zip_Codes__c = '123',
        HM_SMS_Template__c = objSMS.Id);
      //  lstMN1.add(objMN);
        insert objMN;

		//create MNC
        List<HM_Mass_Notification_Contacts__c> lstMNC1 = new List<HM_Mass_Notification_Contacts__c>();
        HM_Mass_Notification_Contacts__c objMNC = new HM_Mass_Notification_Contacts__c(
        HM_Case__c = objCase.Id,
        HM_Contact__c = objContact.Id,
        HM_Mass_Notifications__c = objMN.Id);
        lstMNC1.add(objMNC);
        insert lstMNC1;
        
        //create custom setting
        HM_Integration_Logs__c objLog = new HM_Integration_Logs__c();
        objLog.Name = 'HM Logs';
        objLog.Enable_HM_Logs__c = true;
        insert objLog;
        
        List<String> lstMNIds = new List<String>();
        lstMNIds.add(objMN.Id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorSuccess());
        HM_Batch_SendMassNotifications.HM_MassNotif(lstMNIds);
        
        Test.stopTest();  
}
    
    @isTest 
    public static void test2() {
    
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
        HM_Template_Body__c = 'Hi {FirstName}'
        //HM_Contact_API_Name__c = 'ReportsTo'    
        );
        insert objSMS;
            
        //create MN
        //MN list
      //  List<HM_Mass_Notifications__c> lstMN1 = new List<HM_Mass_Notifications__c>();
        HM_Mass_Notifications__c objMN = new HM_Mass_Notifications__c(
        HM_Zip_Codes__c = '123',
        HM_SMS_Template__c = objSMS.Id);
      //  lstMN1.add(objMN);
        insert objMN;

		//create MNC
        List<HM_Mass_Notification_Contacts__c> lstMNC1 = new List<HM_Mass_Notification_Contacts__c>();
        HM_Mass_Notification_Contacts__c objMNC = new HM_Mass_Notification_Contacts__c(
        HM_Case__c = objCase.Id,
        HM_Contact__c = objContact.Id,
        HM_Mass_Notifications__c = objMN.Id);
        lstMNC1.add(objMNC);
        insert lstMNC1;
        
        //create custom setting
        HM_Integration_Logs__c objLog = new HM_Integration_Logs__c();
        objLog.Name = 'HM Logs';
        objLog.Enable_HM_Logs__c = true;
        insert objLog;
            
        List<String> lstMNIds = new List<String>();
        lstMNIds.add(objMN.Id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorError());
        HM_Batch_SendMassNotifications.HM_MassNotif(lstMNIds);	
        
        Test.stopTest();  
}
    
    @isTest 
    public static void test3() {
        Test.startTest();
        HM_SendNotificationsToHM.create_HMLogs('sMethodName', 'sStatus', 'sStatusCode',  'integrationType', 'sRequestBody',  'sResponseBody', 'sSubscription_ID');
		Test.stopTest();
    }
    
     
    
    
    
    
    
    
    
}