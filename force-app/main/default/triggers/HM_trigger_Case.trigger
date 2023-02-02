/*
* Class Name         : HM_trigger_Case
* Description        : Apex Trigger - Trigger to call the Case Creation API Endpoint to create a case in Hi Marley.
* Author             : Darshana Dange (Futran Solutions)
* Created On         : 21 July 2022
* Test Class         : 
* Change Log History :
*  |-----------------------------------------------------------------------------------|
*  | Version | Created / Modified By     | Date       | Comment                        |
*  |-----------------------------------------------------------------------------------|
*  | 0.1     | Darshana Dange            | 21/07/2022 | Initial Version of Trigger     |
*  | 0.2     | Darshana Dange            | 02/08/2022 | Added Validation               |
*  |-----------------------------------------------------------------------------------|
*/

trigger HM_trigger_Case on Case (after insert, after update, before update, before delete){
    
    if(Trigger.isBefore && Trigger.isUpdate){
        set<string> setCaseIds = new set<string>();          
        for(Case objCase : trigger.new){
            Case objOldCase = trigger.oldMap.get(objCase.Id);
            
            //Add validation if the HM Case Id is already present on case
            if(objCase.HM_Send_Create_Request__c != objOldCase.HM_Send_Create_Request__c && 
               objCase.HM_Send_Create_Request__c == true){
                   if(string.isNotBlank(objCase.HM_Case_Id__c)){
                       if(!Test.isRunningTest()){
                           objCase.addError('Case is already created in HM!');
                       }
                   }
               }
            
            //Add validation if the HM Case Id is not present on case while resending welcome message
            if(objCase.HM_Resend_Welcome_Message__c != objOldCase.HM_Resend_Welcome_Message__c && 
               objCase.HM_Resend_Welcome_Message__c == true){
                   if(string.isBlank(objCase.HM_Case_Id__c)){
                       if(!Test.isRunningTest()){
                           objCase.addError('Case is not created in HM!');
                       }
                   }
               }
            
            //Add validation if the Secondary Operators are same in Hi Marley Case while syncing the operators
            if(objCase.HM_Sync_Secondary_Operators_in_Hi_Marley__c != objOldCase.HM_Sync_Secondary_Operators_in_Hi_Marley__c 
               && objCase.HM_Sync_Secondary_Operators_in_Hi_Marley__c == true){
                   setCaseIds.add(objCase.Id);            
               }
            
            
            //Add validation if the Case is Closed then user cannot resend the welcome message
            if(objCase.HM_Resend_Welcome_Message__c != objOldCase.HM_Resend_Welcome_Message__c && 
               objCase.HM_Resend_Welcome_Message__c == true){
                   if(objCase.IsClosed == true){
                       if(!Test.isRunningTest()){
                           objCase.addError('You cannot resend the welcome message at this stage!');
                       }
                   }
               }
        }
        
        //Add validation if the Secondary Operators are same in Hi Marley Case while syncing the operators
        if(setCaseIds.size() > 0){
            
            string sEmailIds = '';
            
            //Get the Case Team Members from the related Case
            List<CaseTeamMember> lstCaseTeamMembers = [Select MemberId, Member.Name, Member.Email 
                                                       from CaseTeamMember 
                                                       where ParentId IN :setCaseIds order by createdDate];
            
            if(lstCaseTeamMembers != null && lstCaseTeamMembers.size() > 0){
                for(CaseTeamMember objCaseTeamMember : lstCaseTeamMembers){
                    sEmailIds += objCaseTeamMember.Member.Email + ',';
                }
                
                system.debug('sEmailIds ==> ' + sEmailIds);
                
                for(Case objCase : trigger.new){
                    if(sEmailIds.equals(objCase.HM_Secondary_Operators_Present_in_HM__c)){
                        if(!Test.isRunningTest()){
                            objCase.adderror('The operators are already synced with Hi Marley Case!');
                        }
                    }
                }
            }
            else{
                for(Case objCase : trigger.new){
                    if(string.isBlank(objCase.HM_Secondary_Operators_Present_in_HM__c)){
                        if(!Test.isRunningTest()){
                            objCase.adderror('There are no Case Team Members available for syncing!');
                        }
                    }                    
                }
            }
        }
        
    }
    
    if(Trigger.isBefore && Trigger.isDelete){
        List<string> lstHMCaseIds = new List<string>();
        for(Case objCase : trigger.old){
            
            //Add Validation if the user is deleting a Notification Case
            if(string.isNotBlank(objCase.HM_Case_Id__c) && objCase.HM_Enable_Notifications__c == true){
                if(string.isNotBlank(System.Label.HM_Error_Notification_Case_Deletion)){
                    if(!Test.isRunningTest()){
                        objCase.adderror(System.Label.HM_Error_Notification_Case_Deletion);
                    }
                }
            }
            
            //Close Case in Hi Marley - If any Case (Not Notification Case) is getting deleted
            if(string.isNotBlank(objCase.HM_Case_Id__c) && objCase.HM_Case_Status__c == 'Open' &&
              objCase.HM_Enable_Notifications__c != true){
                lstHMCaseIds.add(objCase.HM_Case_Id__c);
            }
        }
        
        system.debug('lstHMCaseIds' + lstHMCaseIds.size());
        if(lstHMCaseIds.size() > 0){
            HM_CloseCaseInHM.closeCaseInHM(lstHMCaseIds);
        }
        
    }
    
}