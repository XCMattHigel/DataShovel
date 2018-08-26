
public class ShoveBundlr {

    static Map<String, Integer> objectQueryMap { get; set; }
    static Map<String, Schema.SObjectType> schemaMap { get; set; }

    public static void createShove() {
        System.debug('createShove');
        objectQueryMap = getObjectNameList();
        schemaMap = Schema.getGlobalDescribe();

        MetadataService.StaticResource staticResource = new MetadataService.StaticResource();
        staticResource.fullName = 'DataShove';
        staticResource.contentType = 'text';
        staticResource.cacheControl = 'private';
        staticResource.content = collectData();

        saveShove(staticResource);
    }

    static String collectData() {
        System.debug('collectData');
        Map<String, List<SObject>> dataMap = new Map<String, List<SObject>>();
        for (String objectName : objectQueryMap.keySet()) {
            System.debug('collectData: objectName = ' + objectName);

            String q = createQuery(objectName);
            Integer qLimit = objectQueryMap.get(objectName);

            if (qLimit > 0) {
                System.debug('collectData: objectName qLimit = ' + String.valueOf(qLimit));
                q += ' LIMIT ' + String.valueOf(qLimit);
            }

            System.debug('collectData: objectName query = ' + q);

            List<SObject> objectList = Database.query(q);
            dataMap.put(objectName, objectList);
        }

        String jsonData = JSON.serialize(dataMap);

        System.debug('collectData jsonData = ' + jsonData);

        return EncodingUtil.base64Encode(Blob.valueOf(jsonData));
    }

    static void saveShove(MetadataService.StaticResource staticResource) {
        System.debug('saveShove');
        MetadataService.MetadataPort service = createService();
        MetadataService.SaveResult[] results = service.createMetadata(new List<MetadataService.Metadata>{
                staticResource
        });
    }

    public static MetadataService.MetadataPort createService() {
        System.debug('createService');
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        return service;
    }

    static Map<String, Integer> getObjectNameList() {
        System.debug('getObjectNameList');
        Map<String, Integer> objectQueryMap = new Map<String, Integer>();

        for (Data_Shover_Setting__mdt dss : [
                SELECT
                        Object_Name__c, Limit__c
                FROM Data_Shover_Setting__mdt
                WHERE Object_Name__c != null
        ]) {
            System.debug('getObjectNameList dss.Object_Name__c = ' + dss.Object_Name__c);
            objectQueryMap.put(dss.Object_Name__c, Integer.valueOf(dss.Limit__c));
        }

        return objectQueryMap;
    }

    static String createQuery(String objectName) {
        System.debug('createQuery');
        System.debug('createQuery objectName = ' + objectName);
        String q = 'SELECT ';

        Schema.SObjectType soType = schemaMap.get(objectName);
        Schema.DescribeSObjectResult dsr = soType.getDescribe();
        List<String> fieldList = new List<String>(dsr.fields.getMap().keySet());

        q += String.join(fieldList, ', ');

        q += ' FROM ' + objectName;

        return q;
    }
}