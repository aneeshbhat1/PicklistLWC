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

    public static Boolean hasFieldAccess(SObject obj, String fieldName) {
        try{
            Boolean b = obj.getSObjectType().getDescribe().fields.getMap().get(fieldName).getDescribe().isAccessible();
            return b;
        }catch (Exception ex){
            return false;
        }
    }
    public static List<Map<String, String>> getPickListValues(Schema.sObjectField field){
        List<Map<String, String>> picklistValues = new List<Map<String, String>>();
        for(Schema.PicklistEntry pe :field.getDescribe().getPicklistValues()){
            picklistValues.add(new Map<String, String>{'value' => pe.value, 'label' => pe.label});
        }
        return picklistValues;
    }

    public static Map<String, String> getPickListValues(Schema.SObjectType type, String fieldName) {
        Map<String, String> picklistValues = new Map<String, String>();
        try{
            List<PicklistEntry> picklistEntries = type.getDescribe().fields.getMap().get(fieldName).getDescribe().getPicklistValues();
            for(PicklistEntry picklistEntry : picklistEntries){
                picklistValues.put(picklistEntry.value, picklistEntry.label);
            }
            return picklistValues;
        }catch (Exception ex) {}
        return picklistValues;
    }

    public static Map<String, List<String>> getDependentOptions(String pObjName, String pControllingFieldName, String pDependentFieldName) {
        Map<String, List<String>> objResults = new Map<String, List<String>>();
        //get the string to sobject global map
        Map<String, Schema.SObjectType> objGlobalMap = Schema.getGlobalDescribe();
        //get the type being dealt with
        Schema.SObjectType pType = objGlobalMap.get(pObjName);
        Map<String, Schema.SObjectField> objFieldMap = pType.getDescribe().fields.getMap();
        //get the control values
        List<Schema.PicklistEntry> ctrl_ple = objFieldMap.get(pControllingFieldName).getDescribe().getPicklistValues();
        //get the dependent values
        List<Schema.PicklistEntry> dep_ple = objFieldMap.get(pDependentFieldName).getDescribe().getPicklistValues();
        //iterate through the values and get the ones valid for the controlling field name
        PicklistUtil.Bitset objBitSet = new PicklistUtil.Bitset();
        //set up the results
        for (Integer pControllingIndex = 0; pControllingIndex < ctrl_ple.size(); pControllingIndex++) {
            //get the pointer to the entry
            Schema.PicklistEntry ctrl_entry = ctrl_ple[pControllingIndex];
            //get the label
            String pControllingLabel = ctrl_entry.getLabel();
            //create the entry with the label
            objResults.put(pControllingLabel, new List<String>());
        }
        //check the dependent values
        for (Integer pDependentIndex = 0; pDependentIndex < dep_ple.size(); pDependentIndex++) {
            //get the pointer to the dependent index
            Schema.PicklistEntry dep_entry = dep_ple[pDependentIndex];
            //get the valid for
            String pEntryStructure = JSON.serialize(dep_entry);
            PicklistUtil.PicklistDetails objDepPLE = (PicklistUtil.PicklistDetails) JSON.deserialize(pEntryStructure, PicklistUtil.PicklistDetails.class);
            //iterate through the controlling values
            for (Integer pControllingIndex = 0; pControllingIndex < ctrl_ple.size(); pControllingIndex++) {
                if (objBitSet.fitBit(objDepPLE.validFor, pControllingIndex)) {
                    //get the label
                    String pControllingLabel = ctrl_ple[pControllingIndex].getLabel();
                    objResults.get(pControllingLabel).add(objDepPLE.label);
                }
            }
        }
        return objResults;
    }

    public static Map<String, List<String>> getFieldDependencies(String objectName, String controllingField, String dependentField) {
        Map<String, List<String>> controllingInfo = new Map<String, List<String>>();

        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);

        Schema.DescribeSObjectResult describeResult = objType.getDescribe();
        Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap().get(controllingField).getDescribe();
        Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap().get(dependentField).getDescribe();

        List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
        List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();

        for (Schema.PicklistEntry currControllingValue : controllingValues) {
            controllingInfo.put(currControllingValue.getLabel(), new List<String>());
        }

        for (Schema.PicklistEntry currDependentValue : dependentValues) {
            String jsonString = JSON.serialize(currDependentValue);
            PicklistDetails info = (PicklistDetails) JSON.deserialize(jsonString, PicklistDetails.class);
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
                    controllingInfo.get(controllingValues[baseCount + 0].getLabel()).add(currDependentValue.getLabel());
                }
                if ((val & 4) == 4) {
                    controllingInfo.get(controllingValues[baseCount + 1].getLabel()).add(currDependentValue.getLabel());
                }
                if ((val & 2) == 2) {
                    controllingInfo.get(controllingValues[baseCount + 2].getLabel()).add(currDependentValue.getLabel());
                }
                if ((val & 1) == 1) {
                    controllingInfo.get(controllingValues[baseCount + 3].getLabel()).add(currDependentValue.getLabel());
                }
                baseCount += 4;
            }
        }
        return controllingInfo;
    }

    public static Map<String, Map<String,String>> getFieldDependenciesMap(String objectName, String controllingField, String dependentField) {
        Map<String, Map<String,String>> controllingInfo = new Map<String, Map<String,String>>();

        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);

        Schema.DescribeSObjectResult describeResult = objType.getDescribe();
        Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap().get(controllingField).getDescribe();
        Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap().get(dependentField).getDescribe();

        List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
        List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();

        for (Schema.PicklistEntry currControllingValue : controllingValues) {
            controllingInfo.put(currControllingValue.getValue(), new Map<String,String>());
        }

        for (Schema.PicklistEntry currDependentValue : dependentValues) {
            String jsonString = JSON.serialize(currDependentValue);
            PicklistDetails info = (PicklistDetails) JSON.deserialize(jsonString, PicklistDetails.class);
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
                    controllingInfo.get(controllingValues[baseCount + 0].getValue()).put(currDependentValue.getValue(),currDependentValue.getLabel());
                }
                if ((val & 4) == 4) {
                    controllingInfo.get(controllingValues[baseCount + 1].getValue()).put(currDependentValue.getValue(),currDependentValue.getLabel());
                }
                if ((val & 2) == 2) {
                    controllingInfo.get(controllingValues[baseCount + 2].getValue()).put(currDependentValue.getValue(),currDependentValue.getLabel());
                }
                if ((val & 1) == 1) {
                    controllingInfo.get(controllingValues[baseCount + 3].getValue()).put(currDependentValue.getValue(),currDependentValue.getLabel());
                }
                baseCount += 4;
            }
        }
        return controllingInfo;
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

    public static Map<Object, List<Map<String,String>>> getFieldDependenciesMaps(Schema.sObjectField controllingToken, Schema.sObjectField dependToken){
        List<Schema.PicklistEntry> contrEntries = controllingToken.getDescribe().getPicklistValues();
        List<Schema.PicklistEntry> depEntries = dependToken.getDescribe().getPicklistValues();
        return getFieldDependenciesMaps(depEntries, contrEntries);
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