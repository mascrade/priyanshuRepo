public class HM_ContentTriggerHandler {
    
    public static void createPublicLinkForFile(List<ContentVersion> contentVersions){
        
        System.debug('in HM_ContentTriggerHandler');
        
        ContentDistribution[] distributionsToInsert = new List<ContentDistribution>();
       	
        for(ContentVersion objContentVersion : contentVersions){
             
                distributionsToInsert.add(createContentDistribution(objContentVersion.Id));
            
        }
        if(!distributionsToInsert.isEmpty())
        {
            System.debug('distributionsToInsert size = '+distributionsToInsert.size());
        	insert distributionsToInsert;
            System.debug('distributionsToInsert : '+distributionsToInsert[0]);

        }
    }
    
    public static ContentDistribution createContentDistribution(Id contentVersionId){
        ContentDistribution newDist = new ContentDistribution();
        newDist.ContentVersionId = contentVersionId;
        newDist.Name = 'External Link';
        newDist.PreferencesNotifyOnVisit = false;
        newDist.PreferencesAllowViewInBrowser = true;
        newDist.PreferencesAllowOriginalDownload=true;
        system.debug('createContentDistribution created');
        return newDist;
    }
}