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
}