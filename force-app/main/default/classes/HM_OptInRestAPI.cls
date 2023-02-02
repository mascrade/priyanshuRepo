/*
* Name               : HM_OptInRestAPI
* Description        : Apex REST Resource for setting Opt in--API Endpoint to set 'Is Opted In' field equal to true in Salesforce when a User replies 'Yes' in Hi Marley.
* Author             : Rohit (Futran Solutions)
* Created On         : 5 Aug 2022
* Test Class         : HM_Test_OptIn_OptOut
* Change Log History :
*  |------------------------------------------------------------------------------|
*  | Version | Modified By        | Date        | Comment                         |
*  |------------------------------------------------------------------------------|
*  | 0.1     | Rohit              |  5 Aug 2022 | Initial Version of Apex Class---|
*  |------------------------------------------------------------------------------|
*/
@RestResource(urlMapping='/setOptIn/*')
global class HM_OptInRestAPI {
    
    @HttpPost
    global static string optIn(){
        
        RestContext objRestContext;
        return HM_OptIn_OptOut_Helper.handleJSON(objRestContext , true);
    }
    
}