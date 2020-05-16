/**
    @Class Name		: lrc_hierarchy_controller.cls
    @Description	: This class perform server requests for lrc_hierarchy_init.cmp .
    @Created By		: Pradeepkumar Dani
    @Created On 	: 08/02/2018
    @Test class 	: lrc_hierarchy_test.cls
    
    ====================================================================================================
    * Modification Log:  
    * 
    * Developer				Date			Description 
    * Pradeepkumar Dani		08/02/2018		Initial version
    *
**/
public class lrc_hierarchy_controller {
    
    /**
    * Returns list of sObjects that can then be painted on the screen. 
    *
    * @param  nameAPI			API name of the field which will be shown on the displayed boxes. Ex. “Name”
    * @param  refFieldAPI 		API field name which holds the self-lookup information. Ex. "Related_To__c"
    * @param  objAPI 			API field name of the object for querying the data. "Child_Object_Hierarchy__c"  
    * @param  isSharing 		Boolean value to request with or without sharing hierarchy. 
    * @param  topId 			Title value that will display on the section header. Ex. "Child Object Hierarchy"
    * @param  cIdentifierAPI 	In case if all the hierarchy records has common lookup, then this attribute is recommended to reduce the number of SOQLs. Ex. "Master_Account__c"
    * @param  cIdentifier 		Value of a common identifier for all the records. Ex. "00128000003s3TaAAI"
    * 
    * 
    * @return lstReturn			list of sObjects
    * @see    hierarchy of objects resturn and arranged using CSS
    */
    @AuraEnabled public static list<sObject> fetchSobjects(string nameAPI, string refFieldAPI, string objAPI, Boolean isSharing, string topId, string cIdentifierAPI, string cIdentifier) {
        list<sObject> lstReturn = new list<sObject>();
        
        string query = 'SELECT '+nameAPI+', '+refFieldAPI+' FROM '+objAPI;      
        if(string.isNotBlank(cIdentifierAPI) && string.isNotBlank(cIdentifier)){
            query+= ' WHERE '+cIdentifierAPI+'=\''+cIdentifier+'\'';
        }
        
        if(string.isBlank(topId)){
            //When we dont have top ID given
            lstReturn = Database.query(query); System.debug('**2 '+lstReturn);           
        }else{
            //when we do not have top ID given
            lstReturn = getChildObjectsHierarchy(nameAPI, refFieldAPI, objAPI, isSharing, topId);
        }
        
        map<Id, sObject> mapObjects = new map<Id, sObject>(lstReturn);  
        lstReturn = new list<sObject>();
        if(isSharing){            
            for(UserRecordAccess ura: [SELECT HasEditAccess, HasReadAccess, RecordId FROM UserRecordAccess WHERE RecordId=:mapObjects.keyset() AND userID=:userinfo.getUserID()]){
                if(mapObjects.containsKey(ura.RecordId)){
                    lstReturn.add(mapObjects.get(ura.RecordId));
                }
            }
        }else{
            lstReturn = mapObjects.values();
        }
        lstReturn.sort();
        return lstReturn;
    }
    
    /**
    * Returns list of sObjects that can then be painted on the screen. 
    *
    * @param  nameAPI			API name of the field which will be shown on the displayed boxes. Ex. “Name”
    * @param  refFieldAPI 		API field name which holds the self-lookup information. Ex. "Related_To__c"
    * @param  objAPI 			API field name of the object for querying the data. "Child_Object_Hierarchy__c"  
    * @param  isSharing 		Boolean value to request with or without sharing hierarchy. 
    * @param  topId 			Title value that will display on the section header. Ex. "Child Object Hierarchy"
    * @param  cIdentifierAPI 	In case if all the hierarchy records has common lookup, then this attribute is recommended to reduce the number of SOQLs. Ex. "Master_Account__c"
    * @param  cIdentifier 		Value of a common identifier for all the records. Ex. "00128000003s3TaAAI"
    * 
    * 
    * @return lstReturn			list of sObjects
    * @see    hierarchy of objects resturn and arranged using CSS
    */
    public static List<sObject> getChildObjectsHierarchy(string nameAPI, string refFieldAPI, string objAPI, Boolean isSharing, string topId) {
        
        Boolean endTraversing = false;
        Integer accountLevel = 0;
        Integer maxLevelAllowed = 25;
        string query = '';
        list<string> parentIdList = new list<string>();
        list<sObject> lstObjects = new list<sObject>();
        map<Id, sObject> mapIdtoObj = new map<Id, sObject> ();
        
        parentIdList.add(topId);
        while(!endTraversing) {
            if(accountLevel == 0) {
                query = 'SELECT '+nameAPI+', '+refFieldAPI+' FROM '+objAPI + ' WHERE Id IN: parentIdList';
            } else {
                query = 'SELECT '+nameAPI+', '+refFieldAPI+' FROM '+objAPI + ' WHERE '+refFieldAPI+' IN: parentIdList';
            }
            lstObjects = Database.query(query);
            
            if(lstObjects.size() == 0 || accountLevel == maxLevelAllowed) {
                endTraversing = true;
            } else {
                parentIdList.clear();
                lstObjects.sort();
                sObject obj;
                for(Integer i = 0; i < lstObjects.size(); i++ ) {
                    obj = lstObjects.get(i);
                    parentIdList.add(obj.Id);
                    
                    // populate the sObject id and level and details maps to be later used
                    mapIdtoObj.put(obj.Id, obj);
                }
                accountLevel++;
            }
        }
        return mapIdtoObj.values();
    }
}