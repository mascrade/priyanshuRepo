/*
* Class Name               : HM_Test_HM_syncSecondaryOperatorsInCase
* Description              : Apex Test Class - Apex Test Class for HM_syncSecondaryOperatorsInCase 
* Author                   : Darshana Dange (Futran Solutions)
* Created On               : 18 Aug 2022
* Change Log History       :
*  |-------------------------------------------------------------------------------------------|
*  | Version | Modified By      | Date       | Comment                                         |
*  |-------------------------------------------------------------------------------------------|
*  | 0.1     | Darshana Dange   | 18/08/2022 | Initial Version of Class                        |
*  |-------------------------------------------------------------------------------------------|
*/

@IsTest
public class HM_Test_HM_syncSecondaryOperatorsInCase {
    
    public class HM_Mock_ResponseSuccess implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"primaryContact": {"last": "string","mobile": "string","first": "string","email": "string"},' +
                             '"customer": {"last": "string","mobile": "string","first": "string","email": "string"},'+
                             '"caseData": {"statusDescription": "string","brand": "string", "id": "string"},'+
                             '"caseType": "claim","privacy": "public","languagePreference": "en",' +
                             '"secondaryOperators": [{"email": "Test@testt.com"}]}');
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
    public static void test_addSecondaryOperators(){        
        
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
        objCase.HM_Sync_Secondary_Operators_in_Hi_Marley__c = false;
        objCase.HM_Case_Id__c = 'string';
        insert objCase;
        
        system.runas(sysUser){
            //Create Case Team Role
            CaseTeamRole role = new CaseTeamRole();
            role.Name = 'Agent';
            role.AccessLevel = 'Read';
            insert role;
            
            //Add Case Team members
            CaseTeamMember objCaseTeamMember = new CaseTeamMember();
            objCaseTeamMember.MemberId = sUser2.Id;
            objCaseTeamMember.ParentId = objCase.Id;
            objCaseTeamMember.TeamRoleId = role.Id;
            insert objCaseTeamMember;
        }
   
        List<string> lstCaseIds = new List<string>();
        lstCaseIds.add(objCase.Id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HM_Mock_ResponseSuccess()); 
        HM_syncSecondaryOpertorsInCase.HM_sync_SecondaryOperators(lstCaseIds);
        Test.stopTest();
    }
    
    @isTest
    public static void test_addSecondaryOperatorsError(){        
        
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
        objCase.HM_Sync_Secondary_Operators_in_Hi_Marley__c = false;
        objCase.HM_Case_Id__c = 'string';
        insert objCase;
        
        system.runas(sysUser){
            //Create Case Team Role
            CaseTeamRole role = new CaseTeamRole();
            role.Name = 'Agent';
            role.AccessLevel = 'Read';
            insert role;
            
            //Add Case Team members
            CaseTeamMember objCaseTeamMember = new CaseTeamMember();
            objCaseTeamMember.MemberId = sUser2.Id;
            objCaseTeamMember.ParentId = objCase.Id;
            objCaseTeamMember.TeamRoleId = role.Id;
            insert objCaseTeamMember;
        }       
        
        List<string> lstCaseIds = new List<string>();
        lstCaseIds.add(objCase.Id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HM_Mock_ResponseError()); 
        HM_syncSecondaryOpertorsInCase.HM_sync_SecondaryOperators(lstCaseIds);
        Test.stopTest();
    }
    
    @isTest
    public static void test_addSecondaryOperatorssException(){        
        
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
        objCase.HM_Sync_Secondary_Operators_in_Hi_Marley__c = false;
        objCase.HM_Case_Id__c = 'string';
        insert objCase;
        
        system.runas(sysUser){
            //Create Case Team Role
            CaseTeamRole role = new CaseTeamRole();
            role.Name = 'Agent';
            role.AccessLevel = 'Read';
            insert role;
            
            //Add Case Team members
            CaseTeamMember objCaseTeamMember = new CaseTeamMember();
            objCaseTeamMember.MemberId = sUser2.Id;
            objCaseTeamMember.ParentId = objCase.Id;
            objCaseTeamMember.TeamRoleId = role.Id;
            insert objCaseTeamMember;
        }
       
        List<string> lstCaseIds = new List<string>();
        lstCaseIds.add(objCase.Id);
        
        Test.startTest();
        HM_syncSecondaryOpertorsInCase.HM_sync_SecondaryOperators(lstCaseIds);
        Test.stopTest();
    }
}