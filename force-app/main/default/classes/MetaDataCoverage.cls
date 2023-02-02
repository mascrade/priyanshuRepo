public class MetaDataCoverage {

    @testVisible 
    private static Map<String, List<sObject>> mapMetaDataCoverageRecords = new Map<String, List<sObject>>(); 
    
    public List<sObject> getMetaDataCoverageRecords(String query){
        if(!mapMetaDataCoverageRecords.containsKey(query)){
            mapMetaDataCoverageRecords.put(query, Database.query(query));
        } 
        return mapMetaDataCoverageRecords.get(query);
    }
}