/*
* Class Name               : HM_Test_HM_ReopenCaseInHM
* Description              : Apex Test Class - Apex Test Class for HM_ReopenCaseInHM
* Author                   : Rohit Korake (Futran Solutions)
* Created On               : 18 August 2022
* Change Log History       :
*  |--------------------------------------------------------------------------------|
*  | Version | Modified By     | Date       | Comment                               |
*  |--------------------------------------------------------------------------------|
*  | 0.1     | Rohit Korake    | 18/08/2022 | Initial Version of Class              |
*  |--------------------------------------------------------------------------------|
*/

@IsTest
public class HM_Test_HM_ReopenCaseInHM {
    
    public class HM_Mock_ResponseSuccess implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"primaryContact": {"last": "string","mobile": "string","first": "string","email": "string"},' +
                             '"customer": {"last": "string","mobile": "string","first": "string","email": "string"},'+
                             '"caseData": {"statusDescription": "string","brand": "string", "id": "string"},'+
                             '"caseType": "claim","privacy": "public","languagePreference": "en"}');
            response.setStatusCode(200);
            return response; 
        }
    }
    
    public class HM_Mock_ResponseError implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"errors":[{"code":"PolicyExists","category":"DataIntegrityError","retryable":false,"status":400,"detail":"Policy already exists for your requests customer mobile and policy number combination."}]}');
            response.setStatusCode(400);
            return response; 
        }
    }
    
    @isTest
    public static void test_reopenCaseInHM(){        
        
        Profile objProfile = [Select Id from profile where Name = 'Standard User'];
        
        User sysUser = [Select Id, Name from User where profile.Name = 'System Administrator' and isActive = true Limit 1];
        
        User sUser = new User();
        sUser.FirstName = 'Anne';
        sUser.LastName = 'S';
        sUser.Email = 'AnneS@testt.com';
        sUser.Username = 'anne@test.com';
        sUser.ProfileId = objProfile.Id;
        sUser.EmailEncodingKey = 'UTF-8';
        sUser.LanguageLocaleKey = 'en_US';
        sUser.TimeZoneSidKey = 'America/Los_Angeles';
        sUser.LocaleSidKey = 'en_US';
        sUser.Alias = 'AnneS';
        insert sUser;
        
        //Create a Test Contact Data
        Contact objCon = new Contact();
        objCon.FirstName = 'Jane';
        objCon.LastName = 'Smith';
        objCon.MobilePhone = 'string';
        objCon.email = 'abc@test.com';
        insert objCon;
        
        //Create a Test Case Data
        Case objCase = new Case();
        objCase.Origin = 'Phone';
        objCase.HM_Brand__c = 'Brand 1';
        objCase.HM_Case_Status__c = 'open';
        objCase.HM_Case_Type__c = 'case';
        objCase.HM_Text_Language__c = 'en';
        objCase.ContactId = objCon.Id;
        objCase.OwnerId = sUser.Id;
        objCase.HM_Case_Id__c = 'string';
        insert objCase;
        
        objCase.Status = 'Open';
        update objCase;
        
        List<string> lstCaseIds = new List<string>();
        lstCaseIds.add(objCase.Id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HM_Mock_ResponseSuccess()); 
        HM_ReopenCaseInHM.HM_ReopenCaseInHM(lstCaseIds);
        Test.stopTest();
    }
    
    @isTest
    public static void test_reopenCaseInHMError(){        
        
        Profile objProfile = [Select Id from profile where Name = 'Standard User'];
        
        User sysUser = [Select Id, Name from User where profile.Name = 'System Administrator' and isActive = true Limit 1];
        
        User sUser = new User();
        sUser.FirstName = 'Anne';
        sUser.LastName = 'S';
        sUser.Email = 'AnneS@testt.com';
        sUser.Username = 'anne@test.com';
        sUser.ProfileId = objProfile.Id;
        sUser.EmailEncodingKey = 'UTF-8';
        sUser.LanguageLocaleKey = 'en_US';
        sUser.TimeZoneSidKey = 'America/Los_Angeles';
        sUser.LocaleSidKey = 'en_US';
        sUser.Alias = 'AnneS';
        insert sUser;
        
        //Create a Test Contact Data
        Contact objCon = new Contact();
        objCon.FirstName = 'Jane';
        objCon.LastName = 'Smith';
        objCon.MobilePhone = 'string';
        objCon.email = 'abc@test.com';
        insert objCon;
        
        //Create a Test Case Data
        Case objCase = new Case();
        objCase.Origin = 'Phone';
        objCase.HM_Brand__c = 'Brand 1';
        objCase.HM_Case_Status__c = 'open';
        objCase.HM_Case_Type__c = 'case';
        objCase.HM_Text_Language__c = 'en';
        objCase.ContactId = objCon.Id;
        objCase.OwnerId = sUser.Id;
        objCase.HM_Send_Create_Request__c = false;
        insert objCase;
        
        objCase.Status = 'Open';
        update objCase;
        
        List<string> lstCaseIds = new List<string>();
        lstCaseIds.add(objCase.Id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HM_Mock_ResponseError()); 
        HM_ReopenCaseInHM.HM_ReopenCaseInHM(lstCaseIds);
        Test.stopTest();
    }
    
    @isTest
    public static void test_reopenCaseInHMException(){        
        
        Profile objProfile = [Select Id from profile where Name = 'Standard User'];
        
        User sysUser = [Select Id, Name from User where profile.Name = 'System Administrator' and isActive = true Limit 1];
        
        User sUser = new User();
        sUser.FirstName = 'Anne';
        sUser.LastName = 'S';
        sUser.Email = 'AnneS@testt.com';
        sUser.Username = 'anne@test.com';
        sUser.ProfileId = objProfile.Id;
        sUser.EmailEncodingKey = 'UTF-8';
        sUser.LanguageLocaleKey = 'en_US';
        sUser.TimeZoneSidKey = 'America/Los_Angeles';
        sUser.LocaleSidKey = 'en_US';
        sUser.Alias = 'AnneS';
        insert sUser;
        
        //Create a Test Contact Data
        Contact objCon = new Contact();
        objCon.FirstName = 'Jane';
        objCon.LastName = 'Smith';
        objCon.MobilePhone = 'string';
        objCon.email = 'abc@test.com';
        insert objCon;
        
        //Create a Test Case Data
        Case objCase = new Case();
        objCase.Origin = 'Phone';
        objCase.HM_Brand__c = 'Brand 1';
        objCase.HM_Case_Status__c = 'open';
        objCase.HM_Case_Type__c = 'case';
        objCase.HM_Text_Language__c = 'en';
        objCase.ContactId = objCon.Id;
        objCase.OwnerId = sUser.Id;
        objCase.HM_Send_Create_Request__c = false;
        insert objCase;
        
        objCase.Status = 'Open';
        update objCase;
        
        List<string> lstCaseIds = new List<string>();
        lstCaseIds.add(objCase.Id);
        
        Test.startTest();
        HM_ReopenCaseInHM.HM_ReopenCaseInHM(lstCaseIds);
        Test.stopTest();
    }
       
}