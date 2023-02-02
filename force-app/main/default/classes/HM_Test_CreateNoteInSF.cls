/*
* Name               : HM_Test_CreateNoteInSF
* Description        : This is a test class that covers HM_CreateNoteInSF.
* Author             : Team Futran 
* Created On         : 26 Aug 2022
* Change Log History :
*  |------------------------------------------------------------------------------|
*  | Version | Modified By        | Date        | Comment                         |
*  |------------------------------------------------------------------------------|
*  | 0.1     | Team Futran        | 26 Aug 2022 | Initial Version of Apex Class---|
*  |------------------------------------------------------------------------------|
*/
@isTest
public class HM_Test_CreateNoteInSF {
	
    @testSetup 
    public static void testData() {
        
        //create Case
        Case objCase = new Case(
            Status = 'Open',
            Origin = 'Web',
            HM_Reference_ID__c = 'pqr123',
            HM_Case_Id__c = 'abc123');
        insert objCase;
    }
    
    @isTest
    public static void testMethod1(){
       
        //covers SUCCESS
        String sJsonMsg = '{"id": "abc123","referenceId": "abc123","text": "Great Response to this issue","createdAt": "2021-06-16T19:42:20.201Z","author": {"email": "adjuster@carrier.com","id": "d210c053-1d1e-4a55-a3e9-71222b57f445","first": "abc","last": "Test"}}';
    	callCreateNote(sJsonMsg);	
        
        //covers FAILURE : empty JSON
        sJsonMsg = '{}';
    	callCreateNote(sJsonMsg);
        
        //covers FAILURE : empty id
        sJsonMsg = '{"id": "","referenceId": "001a3e18-60e5-47c2-81be-218c888bc4af","text": "Great Response to this issue","createdAt": "2021-06-16T19:42:20.201Z","author": {"email": "adjuster@carrier.com","id": "d210c053-1d1e-4a55-a3e9-71222b57f445","first": "abc","last": "Test"}}';
    	callCreateNote(sJsonMsg);
        
        //covers FAILURE : wrong id
        sJsonMsg = '{"id": "jkl123","referenceId": "001a3e18-60e5-47c2-81be-218c888bc4af","text": "Great Response to this issue","createdAt": "2021-06-16T19:42:20.201Z","author": {"email": "adjuster@carrier.com","id": "d210c053-1d1e-4a55-a3e9-71222b57f445","first": "abc","last": "Test"}}';
    	callCreateNote(sJsonMsg);
        
        //covers FAILURE : empty text
        sJsonMsg = '{"id": "jkl123","referenceId": "001a3e18-60e5-47c2-81be-218c888bc4af","text": "","createdAt": "2021-06-16T19:42:20.201Z","author": {"email": "adjuster@carrier.com","id": "d210c053-1d1e-4a55-a3e9-71222b57f445","first": "abc","last": "Test"}}';
    	callCreateNote(sJsonMsg);
        
        //covers FAILURE : empty JSON
        sJsonMsg = '';
    	callCreateNote(sJsonMsg);
        
        //covers FAILURE : empty text
        sJsonMsg = '{"id": "jkl123","referenceId": "001a3e18-60e5-47c2-81be-218c888bc4af","text": "","createdAt": "2021-06-16T19:42:20.201Z","author": {"email": "adjuster@carrier.com","id": "d210c053-1d1e-4a55-a3e9-71222b57f445","first": "abc","last": "Test"}}';
    	callCreateNote(sJsonMsg);
        
        //covers FAILURE : no text
        sJsonMsg = '{"id": "jkl123","referenceId": "001a3e18-60e5-47c2-81be-218c888bc4af","createdAt": "2021-06-16T19:42:20.201Z","author": {"email": "adjuster@carrier.com","id": "d210c053-1d1e-4a55-a3e9-71222b57f445","first": "abc","last": "Test"}}';
    	callCreateNote(sJsonMsg);
        }
    
    public static void callCreateNote(String sJsonMsg){
        RestRequest objRequest = new RestRequest(); 
        RestResponse objResponse = new RestResponse();
        
        objRequest.requestBody = Blob.valueof(sJsonMsg);
        
        objRequest.requestURI = '/services/apexrest/CreateNoteService/';
        objRequest.httpMethod = 'POST';
        
        RestContext.request = objRequest;
        RestContext.response = objResponse;
        
        //call endpoint
        HM_CreateNoteInSF.createNote();
    }
}