public class BulkDataLoadRequestController {
      
   @AuraEnabled
    public static Id saveChunk(Id parentId, String fileName, String base64Data, String contentType, String fileId) {
        // check if fileId id ''(Always blank in first chunk), then call the saveTheFile method,
        //  which is save the check data and return the attachemnt Id after insert, 
        //  next time (in else) we are call the appentTOFile() method
        //   for update the attachment with reamins chunks   
        if (fileId == '') {
            fileId = saveTheFile(parentId, fileName, base64Data, contentType);
        } else {
            appendToFile(fileId, base64Data);
        }
 
        return Id.valueOf(fileId);
    }
 
    public static Id saveTheFile(Id parentId, String fileName, String base64Data, String contentType) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
 		
    /*    Attachment oAttachment = new Attachment();
        oAttachment.parentId = parentId;
 
        oAttachment.Body = EncodingUtil.base64Decode(base64Data);
        oAttachment.Name = fileName;
        oAttachment.ContentType = contentType;
 
        insert oAttachment; */
        
        ContentVersion conVer = new ContentVersion();
        conVer.VersionData = EncodingUtil.base64Decode(base64Data);
        conVer.PathOnClient = '/';
        conVer.Title = fileName;
        insert conVer;
        
        return conVer.Id;
    }
 
    private static void appendToFile(Id fileId, String base64Data) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
 
        Attachment a = [
            SELECT Id, Body
            FROM Attachment
            WHERE Id =: fileId
        ];
 
        String existingBody = EncodingUtil.base64Encode(a.Body);
 
        a.Body = EncodingUtil.base64Decode(existingBody + base64Data);
 
        update a;
    }

    @AuraEnabled
    public static void readFiles(){
        Map<String, Schema.SObjectField> fieldMap =Schema.SObjectType.Account.fields.getMap();
        Map<String, String> fieldApiNames = new Map<String, String>();
        for(String fieldName:  fieldMap.keySet()){
            fieldApiNames.put(fieldMap.get(fieldName).getDescribe().getLabel(), fieldName);
        }
        System.debug('fieldApiNames : ' + fieldApiNames);
        List<Account> accts = new List<Account>();
        String fieldValue;
  		Integer fieldNumber;
  		Map < String, Integer > fieldNumberMap = new Map < String, Integer > ();
        List<String> lstFieldNames = new List<String>();
        List<ContentVersion> allFiles = [Select Id,VersionData From ContentVersion Limit 1];
        List<String> acctDataLines = allFiles[0].VersionData.toString().split('\n');
        List<String> csvFieldNames = acctDataLines[0].split(',');
        for (Integer i = 0; i < csvFieldNames.size(); i++) {
            System.debug('csvfieldName 1: ' + csvFieldNames[i]);
                if(csvFieldNames[i].contains('\r')){
                    System.debug('csvfieldName 2: ' + csvFieldNames[i]);
                    csvFieldNames[i] = csvFieldNames[i].remove('\r');
                    System.debug('csvfieldName 3: ' + csvFieldNames[i]);
                }
                System.debug('csvfieldName 4: ' + csvFieldNames[i]);
            fieldNumberMap.put(csvFieldNames[i], i);
            lstFieldNames.add(csvFieldNames[i]);
        }
        for (Integer i = 1; i < acctDataLines.size(); i++) {
            Account accObj = new Account();
            List<String> csvRecordData = acctDataLines[i].split(',');
            for (String fieldName: csvFieldNames) {
                System.debug('fieldName 1: ' + fieldName);
                if(fieldName.contains('\r')){
                    System.debug('fieldName 2: ' + fieldName);
                    fieldName = fieldName.remove('\r');
                    System.debug('fieldName 3: ' + fieldName);
                }
                System.debug('fieldName 4: ' + fieldName);
                fieldNumber = fieldNumberMap.get(fieldName);
                fieldValue = csvRecordData[fieldNumber];
                if(fieldApiNames.get(fieldName) != null)
                	accObj.put(fieldApiNames.get(fieldName), fieldValue);
            }
            accts.add(accObj);                
        }
        if(accts.size() > 0){
            insert accts;
        }            
    }
}