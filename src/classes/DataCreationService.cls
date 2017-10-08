/**
 * Created by Rohan.Gore on 9/26/2017.
 */

public class DataCreationService {
    @testVisible
    private static List<object> recordsList;

    @testVisible
    private static List<sObject> sObjectList;

    //To be used in future
    //@testVisible
    //private static Map<String, ObjectRelationShipInfo> externalIdToParentObjInfoMap;

    @testVisible
    private static Set<String> additionalFields;

    @testVisible
    private static Set<String> parentObjectFields;

    public static void methodTobeCalledInQueueableJob() {
        for(DataCreationAndRestoreSettings__mdt dataCreationSetting : fetchDataCreationSettings()) {
            createData(dataCreationSetting);
        }
    }

    @testVisible
    private static List<DataCreationAndRestoreSettings__mdt> fetchDataCreationSettings() {

        additionalFields = new Set<String>{'Object__r.QualifiedAPIName',
                'ParentObject1__r.QualifiedAPIName',
                'ParentObject2__r.QualifiedAPIName',
                'ExternalIdParent1__r.QualifiedAPIName',
                'ExternalIdParent2__r.QualifiedAPIName',
                'RelationshipFieldParent1__r.RelationshipName',
                'RelationshipFieldParent2__r.RelationshipName'};
        parentObjectFields = new Set<String>{'ParentObject1__c', 'ParentObject2__c'};
        String query = SOQLGenerationService.generateSOQLForCMDTWithAdditionalFields('DataCreationAndRestoreSettings__mdt', additionalFields, 'Active__c = true')+' ORDER BY Order__c';
        System.debug('Generated Query: '+query);
        return Database.query(query);
    }

    public static void createData(DataCreationAndRestoreSettings__mdt dataCreationSetting) {
        if(dataCreationSetting != null) {
            if(dataCreationSetting.DataSource__c == 'Content') {
                populateRecordsList(DataFetchingService.fetchDataFromContentVersion(dataCreationSetting.DocumentName__c));
            }
            else if(dataCreationSetting.DataSource__c == 'External Service') {
                //Call implementation for External Service
            }
            else {
                populateRecordsList(DataFetchingService.fetchDataFROMStaticResource(dataCreationSetting.DocumentName__c));
            }
            //To be used in future
            //populateExternalIdToParentObjInfoMap(dataCreationSetting);
            createSObjectRecordsList(dataCreationSetting);
            Database.insert(sObjectList, false);
        }
    }

    @testVisible
    private static void populateRecordsList(String data) {
        recordsList = (List<Object>)JSON.deserializeUntyped(data);
        System.debug(recordsList);
    }

    //To be used in future
    //@testVisible
    //private static void populateExternalIdToParentObjInfoMap(DataCreationAndRestoreSettings__mdt dataCreationSetting) {
    //	externalIdToParentObjInfoMap = new Map<String, ObjectRelationShipInfo>();
    //	externalIdToParentObjInfoMap = new Map<String, ObjectRelationShipInfo>{
    //	    	dataCreationSetting.ExternalIdParent1__r.QualifiedAPIName=>new ObjectRelationShipInfo(dataCreationSetting.ParentObject1__r.QualifiedAPIName, dataCreationSetting.RelationshipFieldParent1__r.RelationshipName), dataCreationSetting.ExternalIdParent2__r.QualifiedAPIName=>new ObjectRelationShipInfo(dataCreationSetting.ParentObject2__r.QualifiedAPIName, dataCreationSetting.RelationshipFieldParent2__r.RelationshipName)};
    //	System.debug('externalIdToParentObjInfoMap: '+externalIdToParentObjInfoMap);
    //}

    @testVisible
    private static void createSObjectRecordsList(DataCreationAndRestoreSettings__mdt dataCreationSetting) {
        sObjectList = new List<sObject>();
        for(Object obj: recordsList) {

            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

            Schema.DescribeSObjectResult sObjDscrbResult = gd.get(dataCreationSetting.Object__r.QualifiedAPIName).getDescribe();
            System.debug(sObjDscrbResult);
            Map<String, Schema.SObjectField> fldsMap = sObjDscrbResult.fields.getMap();
            sObject sObj = gd.get(dataCreationSetting.Object__r.QualifiedAPIName).newSObject();
            Map<String, Object> sOMap = (Map<String, Object>)obj;
            //System.debug(sOMap);
            sOMap.remove('attributes');
            sOMap.remove('Id');
            for(String fieldAPIName: sOMap.keyset()) {
                System.debug('fieldAPIName: '+fieldAPIName);
                //To be used in future if required, based on developers feedback
                //  	if(externalIdToParentObjInfoMap.containsKey(fieldAPIName)) {
                //  		System.debug('Match Found');
                //  		sObject pSObj = gd.get(externalIdToParentObjInfoMap.get(fieldAPIName).parentObjectName).newSObject();
                //	pSObj.put(fieldAPIName, (String)sOMap.get(fieldAPIName));
                //	System.debug(pSObj);
                //	sObj.putSObject(externalIdToParentObjInfoMap.get(fieldAPIName).parentObjectRelaltioshipName, pSObj);
                //}
                if(fieldAPIName.contains('.')) {
                    System.debug('fieldAPIName: '+fieldAPIName);
                    String[] splittedStrings = fieldAPIName.split('\\.');
                    System.debug('splittedStrings: '+splittedStrings);
                    String externalIdFieldName = splittedStrings[1];
                    String parentObjName = splittedStrings[0];
                    System.debug('parentObjName: '+parentObjName);
                    if(splittedStrings[0].contains('__r')) {
                        String referenceName = splittedStrings[0].replace('__r', '__c');
                        Schema.DescribeFieldResult fieldDscrbResult = sObjDscrbResult.Fields.getMap().get(referenceName).getDescribe();
                        parentObjName = fieldDscrbResult.getReferenceTo()[0].getDescribe().getName();
                        System.debug('parentObjName: '+parentObjName);
                    }
                    sObject pSObj = gd.get(parentObjName).newSObject();
                    pSObj.put(externalIdFieldName, (String)sOMap.get(fieldAPIName));
                    System.debug(pSObj);
                    sObj.putSObject(splittedStrings[0], pSObj);
                }
                else {
                    Type t = Type.forName(''+String.valueOf(fldsMap.get(fieldAPIName).getDescribe().getSOAPType())+'Conversion');
                    System.debug(t);
                    DataConversionInterface dataConversionInstance = (DataConversionInterface)t.newInstance();
                    System.debug(dataConversionInstance);
                    sObj.put(fieldAPIName,  dataConversionInstance.convert(sOMap.get(fieldAPIName)));
                }
            }
            sObjectList.add(sObj);

        }
        System.debug('$$size: '+sObjectList.size());
    }

    public class ObjectRelationShipInfo {
        public String parentObjectName;
        public String parentObjectRelaltioshipName;

        public ObjectRelationShipInfo(String parentObjectName, String parentObjectRelaltioshipName) {
            this.parentObjectName = parentObjectName;
            this.parentObjectRelaltioshipName = parentObjectRelaltioshipName;
        }
    }
}