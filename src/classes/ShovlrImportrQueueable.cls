
public class ShovlrImportrQueueable implements Queueable {

    Integer counter { get; set; }
    Data_Shover_Setting__mdt settings { get; set; }

    public ShovlrImportrQueueable() {
        counter = 0;
        settings = [
                SELECT Object_Name__c, Limit__c, Sequence__c
                FROM Data_Shover_Setting__mdt
                ORDER BY Sequence__c
        ][counter];
    }

    public ShovlrImportrQueueable(Integer c, String sId) {
        counter = c;
        settings = [
                SELECT Object_Name__c, Limit__c, Sequence__c
                FROM Data_Shover_Setting__mdt
                ORDER BY Sequence__c
        ][counter];
    }

    public void execute(QueueableContext context) {
        String srName = settings.Object_Name__c.replaceAll('_', '');
        StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = :srName];

        Map<String, List<SObject>> dataMap = (Map<String, List<SObject>>)JSON.deserializeUntyped(sr.Body.toString());
        List<SObject> soList = dataMap.values()[0];

        Map<String, SObjectType> refFieldMap = defineRefFieldMap();

        for(SObject so : soList) {
            so.put('XC_Id__c', so.Id);
            for(String refField : refFieldMap.keySet()) {
                SObjectType refType = refFieldMap.get(refField);
                SObject refObj = refType.newSObject();
                refObj.put('XC_Id__c', String.valueOf(so.get(refField)));
                so.put(refField, refObj);
            }
        }

        Database.insert(soList);
    }

    Map<String, SObjectType> defineRefFieldMap() {
        Map<String, SObjectType> refFieldMap = new Map<String, SObjectType>();

        String objectName = settings.Object_Name__c;
        Schema.DescribeSObjectResult dsr = Schema.getGlobalDescribe().get(objectName).getDescribe();

        Map<String, Schema.SObjectField> fieldMap = dsr.fields.getMap();

        for(String field : fieldMap.keySet()) {
            Schema.SObjectField sof = fieldMap.get(field);
            if(sof.getDescribe().getType() == Schema.DisplayType.REFERENCE) {
                Schema.SObjectType soType = sof.getDescribe().getReferenceTo()[0];
                refFieldMap.put(field, soType);
            }
        }

        return refFieldMap;
    }
}