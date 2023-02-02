/*
* Name               : HM_CreateRelatedMassNfContacts
* Description        : Apex Class - Creates Mass Notification Contact records whenever 'Generate Related Contacts' button is clicked
* Author             : Team Futran 
* Created On         : 14 December 2022
* Test Class         : HM_Test_CreateRelatedMassNfContacts
* Change Log History :
*  |------------------------------------------------------------------------------|
*  | Version | Modified By        | Date        | Comment                         |
*  |------------------------------------------------------------------------------|
*  | 0.1     |    | 14 December 2022 | Initial Version of Apex Class   |
*  |------------------------------------------------------------------------------|
*/

public class HM_CreateRelatedMassNfContacts {
    
    @InvocableMethod(label='Generate Related Contacts' description='Generate Related Contacts' category= 'HM_Mass_Notifications__c')
    public static void HM_CollectMassNotifRec(List<HM_Mass_Notifications__c> lstMNotifs){
        
        if(lstMNotifs == null || lstMNotifs.size() <= 0){
            system.debug('lstMNotifs is null or empty');
            return;
        }
        
        if(lstMNotifs[0] == null){
            system.debug('lstMNotifs[0] is empty');
            return;
        }
        
        if(String.isBlank(lstMNotifs[0].HM_Zip_Codes__c)){
            system.debug('HM_Zip_Codes__c is null or empty');
            return; 
        }
        
        //Convert string of zip code values into list of zip code values
        List<String> lstZipCodes = lstMNotifs[0].HM_Zip_Codes__c.replaceAll('(\\s+)', '').split(',');
        Set<String> setZipCodes = new Set<String>();
        setZipCodes.addAll(lstZipCodes);
        
        if(lstZipCodes == null || lstZipCodes.size() <= 0){
            system.debug('lstZipCodes is null or empty');
            return;   
        }
        
        system.debug('after if');
        //look for Contacts that have the same zip code as Mass Notif. rec
        List<Contact> lstContacts = [select id, name, HM_Enable_Notifications__c,
                                     HM_Is_Opted_In__c, HM_Opt_Status_Detail__c
                                     from Contact
                                     where HM_Enable_Notifications__c = true and 
                                     HM_Is_Opted_In__c = true and HM_Opt_Status_Detail__c = 'OPTED_IN' and
                                     MailingPostalCode in :setZipCodes ];
        
        system.debug('lstContacts = '+lstContacts);
        
        if(lstContacts == null || lstContacts.size() <= 0){
            system.debug('lstContacts is null or empty');
            return;   
        }
        
        system.debug('lstContacts size = '+lstContacts.size());
        
        //get all contactIds from Contact records
        Set<String> setContactIds = (new Map<String,Contact>(lstContacts)).keySet();
        
        if(setContactIds == null || setContactIds.size() <= 0){
            system.debug('setContactIds is null or empty');
            return;   
        }
        
        
        //traverse contacts to get related cases 
        Map<String, Case> mapCaseIdvsCaseObj = new Map<String, Case>([select id, ContactId, HM_Enable_Notifications__c 
                                                                      from Case
                                                                      where HM_Enable_Notifications__c = true 
                                                                      and ContactId in :setContactIds]);
        
        //create Mass Notification Contacts
        List<HM_Mass_Notification_Contacts__c> lstMassNotifContacts = new List<HM_Mass_Notification_Contacts__c>();
        
        for(String sCaseId : mapCaseIdvsCaseObj.keySet()){
            
            //create MassNotifContact record
            HM_Mass_Notification_Contacts__c objMassNotifContact = new HM_Mass_Notification_Contacts__c();  
            objMassNotifContact.HM_Mass_Notifications__c = lstMNotifs[0].Id; //establish M-D
            objMassNotifContact.HM_Contact__c = mapCaseIdvsCaseObj.get(sCaseId).ContactId;   
            objMassNotifContact.HM_Case__c = sCaseId;
            system.debug('objMassNotifContact = '+objMassNotifContact);
            lstMassNotifContacts.add(objMassNotifContact);
        }
        
        //insert
        if(lstMassNotifContacts != null && lstMassNotifContacts.size() > 0){
            try{
                insert lstMassNotifContacts;
            } catch(Exception e){
                system.debug('error = '+e.getMessage()); 
            }  
        }
    }
}