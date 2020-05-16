/**
@Class Name		: lrc_hierarchy_test.cls
@Description	: This class is a test calss for  lrc_hierarchy_controller.
@Created By		: Pradeepkumar Dani
@Created On 	: 08/02/2018

====================================================================================================
* Modification Log:  
* 
* Developer				Date			Description 
* Pradeepkumar Dani		18/12/2017		Initial version
*
**/
@isTest public class lrc_hierarchy_test {
    
    @testSetup static void dataSetup() {
        // Create common test accounts
        List<Account> testAccts = new List<Account>();
        for(Integer i=0;i<200;i++) {
            testAccts.add(new Account(Name = 'TestAcct'+i, ParentId = null));
        }
        insert testAccts;  
        
        for(Integer i=1;i<testAccts.size();i++) {
            testAccts[i].ParentId = testAccts[i-1].Id;
        }
        update testAccts;
    }
    
    @isTest static void testMethod1() {
        Account acct = [SELECT Id FROM Account WHERE Name='TestAcct0' LIMIT 1];
        
        /**
        * getUserRoles parameters in orader
        *
        * @param  nameAPI			API name of the field which will be shown on the displayed boxes. Ex. “Name”
        * @param  refFieldAPI 		API field name which holds the self-lookup information. Ex. "Related_To__c"
        * @param  objAPI 			API field name of the object for querying the data. "Child_Object_Hierarchy__c"  
        * @param  isSharing 		Boolean value to request with or without sharing hierarchy. 
        * @param  topId 			Title value that will display on the section header. Ex. "Child Object Hierarchy"
        * @param  cIdentifierAPI 	In case if all the hierarchy records has common lookup, then this attribute is recommended to reduce the number of SOQLs. Ex. "Master_Account__c"
        * @param  cIdentifier 		Value of a common identifier for all the records. Ex. "00128000003s3TaAAI"
        */        
        lrc_hierarchy_controller.fetchSobjects('Name', 'ParentId', 'Account', true, acct.Id, null, null);
        lrc_hierarchy_controller.fetchSobjects('Name', 'ParentId', 'Account', true, null, null, null);
        lrc_hierarchy_controller.fetchSobjects('Name', 'ParentId', 'Account', false, null, null, null);
        lrc_hierarchy_controller.fetchSobjects('Name', 'ParentId', 'Account', false, null, 'ParentId', acct.Id);
    }    
}