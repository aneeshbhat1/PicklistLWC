/**************************************************************************************
Apex Class Name    : FieldUtilityClass
Version            : 1.0
Created Date       : July 27 2017
Function           : Utility class for Field metadata queries
Modification Log   :
-----------------------------------------------------------------------------
 * Developer                   Date                   Description
 * ----------------------------------------------------------------------------
 * Aneesh B                  07/27/2017              Original Version
 *************************************************************************************/
public with sharing class FieldUtilityClass {

    public class PicklistDetails {
        public string active { get; set; }
        public string defaultValue { get; set; }
        public string label { get; set; }
        public string value { get; set; }
        public string validFor { get; set; }
        public PicklistDetails() { }
    }

    public static String getFieldLabel(String objName, String fieldName) {
        try{
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objName);
            return objType.getDescribe().fields.getMap().get(fieldName).getDescribe().getLabel();
        }catch (Exception ex){
            return '';
        }
    }

    public static Map<Object, List<Map<String,String>>> getFieldDependenciesMaps(String objectName, String controllingField, String dependentField) {

        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        if (objType == null) {
            return new Map<Object, List<Map<String,String>>>();
        }
        Schema.DescribeSObjectResult describeResult = objType.getDescribe();

        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)){
            return new Map<Object, List<Map<String,String>>>();
        }
        List<Schema.PicklistEntry> controllingValues = objFieldMap.get(controllingField).getDescribe().getPicklistValues();
        List<Schema.PicklistEntry> dependentValues = objFieldMap.get(dependentField).getDescribe().getPicklistValues();
        return getFieldDependenciesMaps(dependentValues, controllingValues);
    }

    private static Map<Object, List<Map<String,String>>> getFieldDependenciesMaps(List<Schema.PicklistEntry> dependentValues, List<Schema.PicklistEntry> controllingValues) {
        Map<Object, List<Map<String,String>>> controllingInfo = new Map<Object, List<Map<String,String>>>();

        for (Schema.PicklistEntry currControllingValue : controllingValues) {
            controllingInfo.put(currControllingValue.getValue(), new List<Map<String,String>>());
        }

        for (Schema.PicklistEntry currDependentValue : dependentValues) {

            String jsonString = JSON.serialize(currDependentValue);
            PicklistDetails info = (PicklistDetails) JSON.deserialize(jsonString, PicklistDetails.class);
            if(info.validFor == null) {
                continue;
            }
            String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();
            Integer baseCount = 0;
            for (Integer curr : hexString.getChars()) {
                Integer val = 0;
                if (curr >= 65) {
                    val = curr - 65 + 10;
                }
                else {
                    val = curr - 48;
                }
                if ((val & 8) == 8) {
                    controllingInfo.get(controllingValues[baseCount + 0].getValue()).add(new Map<String, String>{'value' => currDependentValue.getValue(), 'label' => currDependentValue.getLabel()});
                }
                if ((val & 4) == 4) {
                    controllingInfo.get(controllingValues[baseCount + 1].getValue()).add(new Map<String, String>{'value' => currDependentValue.getValue(), 'label' => currDependentValue.getLabel()});
                }
                if ((val & 2) == 2) {
                    controllingInfo.get(controllingValues[baseCount + 2].getValue()).add(new Map<String, String>{'value' => currDependentValue.getValue(), 'label' => currDependentValue.getLabel()});
                }
                if ((val & 1) == 1) {
                    controllingInfo.get(controllingValues[baseCount + 3].getValue()).add(new Map<String, String>{'value' => currDependentValue.getValue(), 'label' => currDependentValue.getLabel()});
                }
                baseCount += 4;
            }
        }
        return controllingInfo;
    }
}
