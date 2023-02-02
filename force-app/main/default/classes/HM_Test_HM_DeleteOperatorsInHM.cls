/*
* Class Name               : HM_Test_HM_DeleteOperatorsInHM
* Description              : Apex Test Class - Test Coverage for Class HM_DeleteOperatorsInHM
* Author                   : Darshana Dange (Futran Solutions)
* Created On               : 17 August 2022
* Change Log History       :
*  |--------------------------------------------------------------------------------|
*  | Version | Modified By     | Date       | Comment                               |
*  |--------------------------------------------------------------------------------|
*  | 0.1     | Darshana Dange   | 17/08/2022 | Initial Version of Class             |
*  |--------------------------------------------------------------------------------|
*/

@IsTest
public class HM_Test_HM_DeleteOperatorsInHM {
    
    public class HM_Mock_ResponseSuccess implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"last":"string","mobile": "string","first": "string","email": "string", "id":"string"}');
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
    public static void test_deleteOperatorsInHM(){        
        
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
        
        User sUser2 = new User();
        sUser2.FirstName = 'Test';
        sUser2.LastName = 'S';
        sUser2.Email = 'Test@testt.com';
        sUser2.Username = 'sUser2@abc.com';
        sUser2.ProfileId = objProfile.Id;
        sUser2.EmailEncodingKey = 'UTF-8';
        sUser2.LanguageLocaleKey = 'en_US';
        sUser2.TimeZoneSidKey = 'America/Los_Angeles';
        sUser2.LocaleSidKey = 'en_US';
        sUser2.Alias = 'TestS';
        insert sUser2;
        
        HM_Sync_Users_with_HM_Operators__c objSyncOperators = new HM_Sync_Users_with_HM_Operators__c();
        objSyncOperators.Name = 'Sync SF Users with HM Operators';
        objSyncOperators.HM_Sync_SF_Users_with_HM_Operators__c = true;
        insert objSyncOperators;
        
        List<string> lstUserIds = new List<string>();
        lstUserIds.add(sUser2.Id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HM_Mock_ResponseSuccess()); 
        HM_DeleteOperatorsInHM.HM_DeleteOperatorsInHM(lstUserIds);
        Test.stopTest();
    }
    
    @isTest
    public static void test_deleteOperatorInHMError(){        
        
        Profile objProfile = [Select Id from profile where Name = 'Standard User'];
        
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
        
        User sUser2 = new User();
        sUser2.FirstName = 'Test';
        sUser2.LastName = 'S';
        sUser2.Email = 'Test@testt.com';
        sUser2.Username = 'sUser2@abc.com';
        sUser2.ProfileId = objProfile.Id;
        sUser2.EmailEncodingKey = 'UTF-8';
        sUser2.LanguageLocaleKey = 'en_US';
        sUser2.TimeZoneSidKey = 'America/Los_Angeles';
        sUser2.LocaleSidKey = 'en_US';
        sUser2.Alias = 'TestS';
        insert sUser2;
        
        HM_Sync_Users_with_HM_Operators__c objSyncOperators = new HM_Sync_Users_with_HM_Operators__c();
        objSyncOperators.Name = 'Sync SF Users with HM Operators';
        objSyncOperators.HM_Sync_SF_Users_with_HM_Operators__c = true;
        insert objSyncOperators;
        
        List<string> lstUserIds = new List<string>();
        lstUserIds.add(sUser2.Id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HM_Mock_ResponseError()); 
        HM_DeleteOperatorsInHM.HM_DeleteOperatorsInHM(lstUserIds);
        Test.stopTest();
    }
    
    @isTest
    public static void test_deleteOperatorInHMException(){        
        
        Profile objProfile = [Select Id from profile where Name = 'Standard User'];
        
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
        
        User sUser2 = new User();
        sUser2.FirstName = 'Test';
        sUser2.LastName = 'S';
        sUser2.Email = 'Test@testt.com';
        sUser2.Username = 'sUser2@abc.com';
        sUser2.ProfileId = objProfile.Id;
        sUser2.EmailEncodingKey = 'UTF-8';
        sUser2.LanguageLocaleKey = 'en_US';
        sUser2.TimeZoneSidKey = 'America/Los_Angeles';
        sUser2.LocaleSidKey = 'en_US';
        sUser2.Alias = 'TestS';
        insert sUser2;
        
        HM_Sync_Users_with_HM_Operators__c objSyncOperators = new HM_Sync_Users_with_HM_Operators__c();
        objSyncOperators.Name = 'Sync SF Users with HM Operators';
        objSyncOperators.HM_Sync_SF_Users_with_HM_Operators__c = true;
        insert objSyncOperators;
        
        List<string> lstUserIds = new List<string>();
        lstUserIds.add(sUser2.Id);
        
        Test.startTest();
        HM_DeleteOperatorsInHM.HM_DeleteOperatorsInHM(lstUserIds);
        Test.stopTest();
    }
}