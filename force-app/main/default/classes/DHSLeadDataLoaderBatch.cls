/**
 * @description Retains the existing DHSLeadDataLoaderBatch integration and application behavior.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.EmptyStatementBlock,PMD.NcssCount,PMD.NcssMethodCount,PMD.StdCyclomaticComplexity')
global with sharing class DHSLeadDataLoaderBatch implements Database.Batchable< String >,Database.Stateful{
    global Blob csvFileAsBlob;
    global List<String> resultCSVFileLines;
    global String fileHeaderRow;
    global string resultFileAttachmentId;
    global string successResultFileAttachmentId;
    global string failureResultFileAttachmentId;
    global string exceptionMessage;
    global DHS_DataLoad_Activity__c  dLActivity;
    global integer totalRecords;
    global integer successCount;
    global integer errorCount;
    global string generatedCSVFile;
    global boolean attachmentNeedsToBeAttached;
    global integer numberOfRecordsInFile;
    global integer leadFilePart;
    /**
     * @description Provides this DHS API member.
     * @param csvFileBlob Method parameter.
     * @param activity Method parameter.
     */
    global DHSLeadDataLoaderBatch(Blob csvFileBlob, DHS_DataLoad_Activity__c  activity){
        numberOfRecordsInFile = 0;
        successCount = 0;
        errorCount = 0;
        csvFileAsBlob = csvFileBlob;
        dLActivity = activity;
        totalRecords = 0;
        generatedCSVFile = 'ISN Assigned Case Number,Case Name,Item_number__c,LeadType__c,Coverage_Type__c,Lead_Contact_Name__c,Lead_Contact_Address__c,Lead_Contact_City__c,Lead_Contact_State__c,Lead_Contact_Zip__c,Lead_Contact_Other_Information__c,Status,Error Message,Id\n';
        attachmentNeedsToBeAttached = true;
        leadFilePart = 1;
    }
    
    /**
     * @description Provides this DHS API member.
     * @param bc Method parameter.
     * @return The requested result.
     */
    global Iterable<String> start(Database.BatchableContext bc) {
        List<String> resultCSVFileLinesWithoutHeader = new List<String>();
        ResultCSVFileLines = new List<String>();
        String csvAsString = csvFileAsBlob.toString();
        DHSUtility_RowIterator r = New DHSUtility_RowIterator(csvAsString,'\n'); 
        if(r.hasNext()) {
            fileHeaderRow = r.next();
        }
        while(r.hasNext()){
            resultCSVFileLinesWithoutHeader.add(r.next());    
        }
        resultCSVFileLines.add(fileHeaderRow);
        for(String str: resultCSVFileLinesWithoutHeader){
            resultCSVFileLines.add(str);
        }
        
        for(String str: resultCSVFileLines){
        }
        return resultCSVFileLinesWithoutHeader;
    }
    
    /**
     * @description Provides this DHS API member.
     * @param bc Method parameter.
     * @param csvFileLines Method parameter.
     */
    global void execute(Database.BatchableContext bc, List<String> csvFileLines) {
        try{
            attachmentNeedsToBeAttached = true;
            List<DHS_Lead__c> leadListToInsert = new List<DHS_Lead__c>();
            List<String> caseNumbers = new List<String>();
            for(Integer i=0;i<csvFileLines.size();i++){
                List<string> csvRecordData = splitString(csvFileLines[i]);
                if(csvRecordData.size()>0){
                    caseNumbers.add(csvRecordData[0]);    
                }                  
            }
            List<DHS_Case__c> cases = [Select Id,DHS_Contact__c,Case_Number__c from DHS_Case__c where Case_Number__c IN:caseNumbers WITH SECURITY_ENFORCED];
            Map<String,DHS_Case__c> caseMap = new Map<String,DHS_Case__c>();
            Map<String,DHS_Case__c> caseIdMap = new Map<String,DHS_Case__c>();
            for(DHS_Case__c c: cases){
                caseMap.put(c.Case_Number__c, c); 
                caseIdMap.put(c.id,c);
            }
            
            for(Integer i=0;i<csvFileLines.size();i++){
                List<string> csvRecordData = splitString(csvFileLines[i]);
                DHS_Lead__c lead = new DHS_Lead__c();
                if(csvRecordData.size()>1) {
                    //lead.LeadType__c= csvRecordData[1];
                    if(csvRecordData.size()>2) {
                        lead.Item_number__c = Decimal.valueof(csvRecordData[2]);
                    }
                }
                if(csvRecordData.size()>3) {
                    lead.LeadType__c= csvRecordData[3];
                }
                if(csvRecordData.size()>4) {
                    lead.Coverage_Type__c= csvRecordData[4];
                }
                if(csvRecordData.size()>5) {
                    lead.Lead_Contact_Name__c= csvRecordData[5];
                }
                if(csvRecordData.size()>6) {
                    lead.Lead_Contact_Address__c= csvRecordData[6];
                }
                if(csvRecordData.size()>7) {
                    lead.Lead_Contact_City__c= csvRecordData[7];
                }
                if(csvRecordData.size()>8) {
                    lead.Lead_Contact_State__c = csvRecordData[8];
                }
                if(csvRecordData.size()>9) {
                    lead.Lead_Contact_Zip__c = csvRecordData[9];
                }
                if(csvRecordData.size()>10) {
                    lead.Lead_Contact_Other_Information__c = csvRecordData[10];
                }
                lead.DHS_Case__c = caseMap.get(csvRecordData[0]).id;
                lead.DHS_Contact__c = caseMap.get(csvRecordData[0]).DHS_Contact__c;
                leadListToInsert.add(lead); 
            }
            List<Database.SaveResult> dsrs = Database.insert(leadListToInsert, false, AccessLevel.USER_MODE);
            Integer index = 0;
            for(Database.SaveResult dsr : dsrs){
                DHS_Lead__c lead = leadListToInsert[index];
                if(!dsr.isSuccess()){
                    String errMsg = dsr.getErrors()[0].getMessage();
                    generatedCSVFile = generatedCSVFile + caseIdMap.get(lead.DHS_Case__c).Case_Number__c+','+''+','+lead.Item_number__c+','+''+','+''+','+''+','+''+','+''+','+''+','+''+','+''+','+'Fail'+','+errMsg+','+''+ '\n';
                    errorCount ++;
                } else {
                    generatedCSVFile = generatedCSVFile + caseIdMap.get(lead.DHS_Case__c).Case_Number__c+','+''+','+lead.Item_number__c+','+''+','+''+','+''+','+''+','+''+','+''+','+''+','+''+','+'Success'+','+''+','+dsr.getId() + '\n';
                    successCount ++;
                }
                index++;
                totalRecords ++;
                numberOfRecordsInFile++;
            }
            if(numberOfRecordsInFile >=15000 && attachmentNeedsToBeAttached){
                Attachment att = new Attachment();
                att.parentId = dLActivity.Id;
                att.Name = 'LeadFileUploadedPart'+leadFilePart+'.csv';
                att.Body = Blob.valueOf(generatedCSVFile);
                database.insert(att,false,AccessLevel.USER_MODE);
                generatedCSVFile = 'ISN Assigned Case Number,Case Name,Item_number__c,LeadType__c,Coverage_Type__c,Lead_Contact_Name__c,Lead_Contact_Address__c,Lead_Contact_City__c,Lead_Contact_State__c,Lead_Contact_Zip__c,Lead_Contact_Other_Information__c,Status,Error Message,Id\n';
                numberOfRecordsInFile = 0;
                attachmentNeedsToBeAttached = false;
                leadFilePart++;
            }  
        }catch(Exception ex){
            if(String.isBlank(exceptionMessage)){
                exceptionMessage = ex.getMessage()+'<br/>';    
            }else{
                exceptionMessage = exceptionMessage+ ex.getMessage()+'<br/>';    
            }
            
        }
    }
    
    /**
     * @description Provides this DHS API member.
     * @param bc Method parameter.
     */
    global void finish(Database.BatchableContext bc){
            if(attachmentNeedsToBeAttached){
                Attachment att = new Attachment();
                att.parentId = dLActivity.Id;
                att.Name = 'LeadFileUploadedPart'+leadFilePart+'.csv';
                att.Body = Blob.valueOf(generatedCSVFile);
                database.insert(att,false,AccessLevel.USER_MODE);
                generatedCSVFile = 'ISN Assigned Case Number,Case Name,Item_number__c,LeadType__c,Coverage_Type__c,Lead_Contact_Name__c,Lead_Contact_Address__c,Lead_Contact_City__c,Lead_Contact_State__c,Lead_Contact_Zip__c,Lead_Contact_Other_Information__c,Status,Error Message,Id\n';
                numberOfRecordsInFile = 0;
                attachmentNeedsToBeAttached = false;
            } 
           
            dLActivity.DHS_Activity_User__c  = userinfo.getUserId();
            dLActivity.Success_Count__c = successCount;
            dLActivity.Failure_Count__c = errorCount; 
            dLActivity.Total_Record_Count__c = totalRecords;
            dLActivity.Job_End_Time__c = system.now();
            database.update(dLActivity,false,AccessLevel.USER_MODE);
             sendEmailWithAttachments(dLActivity.id);
    }
    
    
    /**
     * @description Provides this DHS API member.
     * @param reportId Method parameter.
     */
    global static void sendEmailWithAttachments(String reportId) {
        User currentUser = [Select Id, Name,Email, ContactId from User where Id=:userinfo.getuserid()];
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setToAddresses(new String[] { currentUser.Email });
        
        List<Attachment> files = [SELECT Name, Body,ParentId, ContentType FROM Attachment WHERE parentId=:reportId];
        
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        for (Attachment file: files) {
          Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
          efa.setFileName(file.Name);
          efa.setBody(file.Body);
          efa.setContentType(file.ContentType);
          attachments.add(efa);
        }
        message.setFileAttachments(attachments);
        // Set the message template
        List<EmailTemplate> templates = [SELECT Id, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'DataLoadActivityTemplate'];
        message.setWhatId(reportId);
        message.setTemplateId(templates[0].id);
        
        String contactId;
        if(currentUser.contactId == Null){
            Contact con = [select Id from Contact Limit 1];
            contactId = con.id;
        }else{
            contactId = currentUser.contactId;
        }
        message.setTargetObjectId(contactID);
        message.setTreatTargetObjectAsRecipient(false);
        message.setSaveAsActivity(false);
        // Send the message
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
    }
    
    /**
     * @description Provides this DHS API member.
     * @param csvLine Method parameter.
     * @return The requested result.
     */
    public list<string> splitString(String csvLine){
         csvLine = csvLine.replace('\r\n', '');
            csvLine = csvLine.replace('\n', '');
            csvLine = csvLine.replace('\r', '');
        Integer startIndex;
        Integer endIndex;
        while(csvLine.indexOf('"') > -1){
            if(startIndex == null){
                startIndex = csvLine.indexOf('"');
                csvLine = csvLine.substring(0, startIndex) + ':quotes:' + csvLine.substring(startIndex+1, csvLine.length());
            }else{
                if(endIndex == null){
                    endIndex = csvLine.indexOf('"');
                    csvLine = csvLine.substring(0, endIndex) + ':quotes:' + csvLine.substring(endIndex+1, csvLine.length());
                }
            }
            if(startIndex != null && endIndex != null){
                String sub = csvLine.substring(startIndex, endIndex);
                sub = sub.replaceAll(',', ':comma:');
                csvLine = csvLine.substring(0, startIndex) + sub + csvLine.substring(endIndex, csvLine.length());
                startIndex = null;
                endIndex = null;
            }
        }
        List<String> columnValues = new List<String>();
        for(String column : csvLine.split(',')){
          column = column.replaceAll(':quotes:', '').replaceAll(':comma:', ',');
          columnValues.add(column);
        }
        return columnValues;
    }
    
    
}
