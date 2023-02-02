/*
* Name               : HM_Test_DeleteNoteInSF
* Description        : This Test Class covers HM_DeleteNoteInSF Apex Class.
* Author             : Team Futran 
* Created On         : 29 Sept 2022
* Test Class         : HM_Test_Inbound_SMS_Creation
* Change Log History :
*  |------------------------------------------------------------------------------|
*  | Version | Modified By        | Date        | Comment                         |
*  |------------------------------------------------------------------------------|
*  | 0.1     | Team Futran        | 29 Sept 2022 | Initial Version of Apex Class---|
*  |------------------------------------------------------------------------------|
*/
@isTest
public class HM_Test_DeleteNoteInSF {
    
    @testSetup 
    public static void testData() {
        
        //create Case
        Case objCase = new Case(
            Status = 'Open',
            Origin = 'Web',
            HM_Reference_ID__c = 'pqr123',
            HM_Case_Id__c = 'abc123');
        insert objCase;
        
        //create Std Note against Case
        ContentNote objContentNote = new ContentNote();
        objContentNote.Content = Blob.valueof('Great Response to this issue');
        objContentNote.Title = 'Hi Marley Notes';
        insert objContentNote;
        
        //create Bridge Note
        HM_Bridge_Notes__c objBridgeNote = new HM_Bridge_Notes__c();
        objBridgeNote.HM_Case_Note_id__c = 'abc123';
        objBridgeNote.HM_Reference_id__c = 'pqr123';
        objBridgeNote.HM_Note_Content__c = 'Great Response to this issue';
        objBridgeNote.HM_Created_At__c = '2021-06-16T19:42:20.201Z';
        objBridgeNote.SF_Case_Note_id__c = objContentNote.Id;
        objBridgeNote.HM_Case__c = objCase.Id;
        objBridgeNote.HM_Note_Title__c = objContentNote.Title;
        objBridgeNote.HM_Author_Email__c = 'abc@test.com';
        objBridgeNote.HM_Author_Id__c = 'abc123';
        objBridgeNote.HM_Author_First_Name__c = 'ABC';
        objBridgeNote.HM_Author_Last_Name__c = 'PQR'; 
        insert objBridgeNote;
        
        //create CDL
        ContentDocumentLink objContentDocLink = new ContentDocumentLink();
        objContentDocLink.LinkedEntityId = objCase.Id;
        objContentDocLink.ContentDocumentId = objContentNote.Id;
        insert objContentDocLink;
        
    }
    
    @isTest
    public static void testMethod1(){
       
        //covers SUCCESS
        String sJsonMsg = '{"id": "abc123","referenceId": "abc123","text": "Great Response to this issue","createdAt": "2021-06-16T19:42:20.201Z","author": {"email": "adjuster@carrier.com","id": "d210c053-1d1e-4a55-a3e9-71222b57f445","first": "abc","last": "Test"}, "archived": true}';
    	callDeleteNote(sJsonMsg);	
        
        //covers FAILURE : empty JSON
        sJsonMsg = '{}';
    	callDeleteNote(sJsonMsg);
        
        //covers FAILURE : empty id
        sJsonMsg = '{"id": "","referenceId": "001a3e18-60e5-47c2-81be-218c888bc4af","text": "Great Response to this issue","createdAt": "2021-06-16T19:42:20.201Z","author": {"email": "adjuster@carrier.com","id": "d210c053-1d1e-4a55-a3e9-71222b57f445","first": "abc","last": "Test"}}';
    	callDeleteNote(sJsonMsg);
        
        //covers FAILURE : wrong id
        sJsonMsg = '{"id": "jkl123","referenceId": "001a3e18-60e5-47c2-81be-218c888bc4af","text": "Great Response to this issue","createdAt": "2021-06-16T19:42:20.201Z","author": {"email": "adjuster@carrier.com","id": "d210c053-1d1e-4a55-a3e9-71222b57f445","first": "abc","last": "Test"}}';
    	callDeleteNote(sJsonMsg);

        
        /*
        
                
        
        
        //covers FAILURE : empty text
        sJsonMsg = '{"id": "jkl123","referenceId": "001a3e18-60e5-47c2-81be-218c888bc4af","text": "","createdAt": "2021-06-16T19:42:20.201Z","author": {"email": "adjuster@carrier.com","id": "d210c053-1d1e-4a55-a3e9-71222b57f445","first": "abc","last": "Test"}}';
    	callDeleteNote(sJsonMsg);
        
        //covers FAILURE : empty JSON
        sJsonMsg = '';
    	callDeleteNote(sJsonMsg);
        
        //covers FAILURE : empty text
        sJsonMsg = '{"id": "jkl123","referenceId": "001a3e18-60e5-47c2-81be-218c888bc4af","text": "","createdAt": "2021-06-16T19:42:20.201Z","author": {"email": "adjuster@carrier.com","id": "d210c053-1d1e-4a55-a3e9-71222b57f445","first": "abc","last": "Test"}}';
    	callDeleteNote(sJsonMsg);
        
        //covers FAILURE : no text
        sJsonMsg = '{"id": "jkl123","referenceId": "001a3e18-60e5-47c2-81be-218c888bc4af","createdAt": "2021-06-16T19:42:20.201Z","author": {"email": "adjuster@carrier.com","id": "d210c053-1d1e-4a55-a3e9-71222b57f445","first": "abc","last": "Test"}}';
    	callDeleteNote(sJsonMsg);	*/
        }
    
    public static void callDeleteNote(String sJsonMsg){
        RestRequest objRequest = new RestRequest(); 
        RestResponse objResponse = new RestResponse();
        
        objRequest.requestBody = Blob.valueof(sJsonMsg);
        
        objRequest.requestURI = '/services/apexrest/DeleteNoteService/';
        objRequest.httpMethod = 'POST';
        
        RestContext.request = objRequest;
        RestContext.response = objResponse;
        
        //call endpoint
        HM_DeleteNoteInSF.deleteNote();
    }

}