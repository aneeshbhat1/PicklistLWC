public with sharing class PicklistController {
    @AuraEnabled
    public static List<Map<String, String>> getPickListValues(String objApiName, String fieldName) {
        List<Map<String, String>> options = new List<Map<String, String>>();

        Map<String, Schema.SObjectType> objGlobalMap = Schema.getGlobalDescribe();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objApiName);
        if (objType == null) {
            return options;
        }
        Schema.DescribeSObjectResult sobjectDescribe = objType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = sobjectDescribe.fields.getMap();
        if (fieldMap.get(fieldName) == null) {
            return options;
        }
        List<Schema.PicklistEntry> pickListValues = fieldMap.get(fieldName).getDescribe().getPickListValues();

        for(Schema.PicklistEntry f : pickListValues) {
            Map<String, String> values = new Map<String, String>{
                    'label' => f.getLabel(),
                    'value' => f.getValue()
            };
            options.add(values);
        }
        return options;
    }

    @AuraEnabled
    public static Map<Object, List<Map<String, String>>> getDependentOptions(String objApiName, String fieldName, String contrFieldApiName) {
        return FieldUtilityClass.getFieldDependenciesMaps(objApiName,contrFieldApiName, fieldName);
    }

    @AuraEnabled
    public static String getFieldLabel(String objName, String fieldName) {
        return FieldUtilityClass.getFieldLabel(objName, fieldName);
    }
}