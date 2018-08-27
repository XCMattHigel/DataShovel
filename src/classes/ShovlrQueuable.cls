
global class ShovlrQueuable implements Queueable, Database.AllowsCallouts {

    String query { get; set; }
    String objectName { get; set; }
    Integer counter { get; set; }
    Data_Shover_Setting__mdt settings { get; set; }
    String sessionId { get; set; }

    public ShovlrQueuable() {
        sessionId = UserInfo.getSessionId();
        System.debug('ShovlrQueuable init');
        counter = 0;
        settings = [
                SELECT Object_Name__c, Limit__c, Sequence__c
                FROM Data_Shover_Setting__mdt
                ORDER BY Sequence__c
        ][counter];
    }

    public ShovlrQueuable(Integer c, String sId) {
        sessionId = sId;
        System.debug('ShovlrQueuable');
        counter = c;
        System.debug('counter ' + String.valueOf(counter));
        settings = [
                SELECT Object_Name__c, Limit__c, Sequence__c
                FROM Data_Shover_Setting__mdt
                ORDER BY Sequence__c
        ][counter];
    }

    public void execute(QueueableContext context) {
        System.debug('ShovlrQueuable execute');
        query = createQuery(settings.Object_Name__c);
        String qLimit = settings.Limit__c > 0 ? String.valueOf(settings.Limit__c) : '50000';
        query += ' LIMIT ' + qLimit;
        objectName = settings.Object_Name__c;
        List<SObject> sObjectList = Database.query(query);
        Map<String, List<SObject>> dataMap = new Map<String, List<SObject>>{
                objectName => sObjectList
        };

        String jsonData = JSON.serialize(dataMap);

        MetadataService.StaticResource sr = createStaticResource(jsonData);
        MetadataService.MetadataPort service = createService();
        MetadataService.SaveResult[] results = service.createMetadata(new List<MetadataService.StaticResource>{sr});
        System.debug('saveResults = ' + JSON.serializePretty(results));

        counter += 1;
        System.enqueueJob(new ShovlrQueuable(counter, sessionId));
    }

    MetadataService.StaticResource createStaticResource(String jsonData) {
        System.debug('ShovlrQueuable createStaticResource');
        MetadataService.StaticResource sr = new MetadataService.StaticResource();
        System.debug('objectName = ' + objectName);
        String srName = objectName.replaceAll('_', '');
        System.debug('srName = ' + srName);
        sr.fullName = 'DataShove' + srName;
        sr.contentType = 'text';
        sr.cacheControl = 'private';
        sr.content = EncodingUtil.base64Encode(Blob.valueOf(jsonData));
        return sr;
    }

    String createQuery(String objectName) {
        System.debug('ShovlrQueuable createQuery');
        String q = 'SELECT ';

        Schema.SObjectType soType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult dsr = soType.getDescribe();
        List<String> fieldList = new List<String>(dsr.fields.getMap().keySet());

        q += String.join(fieldList, ', ');
        q += ' FROM ' + objectName;

        return q;
    }

    MetadataService.MetadataPort createService() {
        System.debug('ShovlrQueuable createService');
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = sessionId;
        return service;
    }
}