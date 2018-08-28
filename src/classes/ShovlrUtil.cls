
public with sharing class ShovlrUtil {

    MetadataService.MetadataPort createService(String sessionId) {
        System.debug('ShovlrUtil ShovlrUtil');
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = sessionId;
        return service;
    }

    public static void createXCIdField(String objectName, String sessionId) {
        MetadataService.MetadataPort svc = createService(sessionId);
    }

}