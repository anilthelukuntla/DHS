public class BIManifest {
    public date fromDate	{get;set;}
    public date toDate		{get;set;}
    public list<ContentVersion> manifestFiles {get;set;}
    public BIManifest(){
        getManifestData();
    }
    public void regenerateManifest(){
        date weekStartDate = date.today().toStartOfWeek();
        date weekEndDate = weekStartDate.addDays(5);
        setPassword(weekStartDate,weekEndDate);
    }
    public void generateCustomDateRangeManifest(){
        system.debug('fromDate...'+fromDate);
        system.debug('fromDate...'+fromDate);
        setPassword(fromDate,toDate);
    }
    public void setPassword(date currentWeekStartDate,date currentWeekEndDate){
        date weekStartDate = currentWeekStartDate;
        date weekEndDate = currentWeekEndDate;
        List<DIA_Case__c> cases = new List<DIA_Case__c>();
        list<string> queryFields = New list<string>();
        Map<string,string> labelNAPINameMap = New Map<string,string>();
        Map<String, Manifest_Export__mdt> mapME = Manifest_Export__mdt.getAll();
        Map<integer,string> orderNLabel = New Map<integer,string>();
        for(string key : mapME.keyset()){
            string label = (string)mapME.get(key).get('Label');
            if(label != 'Subject’s Full Name'){
                if(!queryFields.contains((string)mapME.get(key).get('API_Name__c'))){
                    queryFields.add((string)mapME.get(key).get('API_Name__c'));
                }
            }
            labelNAPINameMap.put((string)mapME.get(key).get('Label'),(string)mapME.get(key).get('API_Name__c'));
            orderNLabel.put(integer.valueOf((decimal)mapME.get(key).get('Order__c')),(string)mapME.get(key).get('Label'));
            
        }
        string headers = '';
        for(integer i = 1; i <= mapME.keyset().size(); i++){
            system.debug(orderNLabel.get(i));
            headers += orderNLabel.get(i)+',';
        }
        string csv = headers.substringBeforeLast(',')+'\n';
        
        string status = 'Completed';
        system.debug('weekStartDate...'+weekStartDate);
        system.debug('weekEndDate...'+weekEndDate);
        string manifestStartRow = 'Manifest Start Date'+','+weekStartDate.tostring().substringbefore(' ')+','+'# of Completed T5s'+',';
        string manifestEndRow = 'Manifest End Date'+','+weekEndDate.tostring().substringbefore(' ')+','+'# of Cancelled T5s'+',';
        string additionalFields = 'contact__r.First_Name__c,contact__r.Last_Name__c,Case_Queue_Status__c,Status__c,Case_Completed_Date__c,Case_Cancellation_Date__c';
        for(string str : additionalFields.split(',')){
            if(!queryFields.contains(str)){
                queryFields.add(str);
            }
        }
        system.debug(queryFields);
        integer cancelledCases = 0;
        string query;
        
        if(Test.isrunningTest()){
            query = 'select '+string.join(queryFields,',')+' from DIA_Case__C';
        }else{
			query = 'select '+string.join(queryFields,',')+' from DIA_Case__C where ((Case_Completed_Date__c >= : weekStartDate and Case_Completed_Date__c <=: weekEndDate) or (Case_Cancellation_Date__c >= : weekStartDate and Case_Cancellation_Date__c <=: weekEndDate) or (Order_Received__c >=: weekStartDate and Order_Received__c <=:weekEndDate ))';
        }
        cases = database.query(query);
        system.debug('cases...'+cases);
        integer completedCount = 0;
        for(DIA_Case__C c : cases){
            if(c.Case_Completed_Date__c != null){
                completedCount++;
            }else if(c.Case_Cancellation_Date__c != null){
                cancelledCases++;
            }
            string row = '';
            Map<string,Object> caseMap = (Map<string,Object>)JSON.deserializeUntyped(JSON.serialize(c));
            for(integer i = 1; i <= mapME.keyset().size(); i++){
                string label = orderNLabel.get(i);
                system.debug(label);
                if(label == 'Subject’s Full Name'){
                    system.debug(label);
                    Map<string,Object> parentContact = (Map<string,Object>)JSON.deserializeUntyped(JSON.serialize(caseMap.get('Contact__r')));
                    row += (string)parentContact.get('Last_Name__c')+' '+(string)parentContact.get('First_Name__c')+',';
                }else{
                    string apiName = labelNAPINameMap.get(label);
                    if(apiName.contains('__r')){
                        string parentApiName = apiname.substringBefore('.');
                        Map<string,Object> parentObject = (Map<string,Object>)JSON.deserializeUntyped(JSON.serialize(caseMap.get(parentApiName)));
                        string parentFieldAPIName = apiName.substringAfter('.');
                        if(parentFieldAPIName == 'SSN__c'){
                            if((string)parentObject.get(parentFieldAPIName) == null){
                                row += ''+',';
                            }else{
                                row += string.valueOf(parentObject.get(parentFieldAPIName)).right(4)+',';
                            }
                        }else{
                            if((string)parentObject.get(parentFieldAPIName) == null){
                                row += ''+',';
                            }else{
                                row += string.valueOf(parentObject.get(parentFieldAPIName))+',';
                            }
                        }
                    }else{
                        if((string)caseMap.get(apiName) == null){
                            row += ''+',';
                        }else{
                            row += (string)caseMap.get(apiName)+',';
                        }
                    }
                }
            }
                csv += row.substringBeforeLast(',')+'\n';
        }
        manifestEndRow += cancelledCases+'\n';
        manifestStartRow += completedCount+'\n';
        manifestStartRow += manifestEndRow;
        manifestStartRow += csv;
            list<contentversion> cvd = FetchContentVersion();
            ContentVersion objCV = new ContentVersion();
            string fileName = 'Manifest from '+weekStartDate.tostring().substringBefore(' ')+' To '+weekEndDate.tostring().substringBefore(' ');
            system.debug(cvd.size());
            if(cvd.size() == 0){
                objCV.Title = fileName;
                objCV.PathOnClient = fileName+'.CSV';
                objCV.VersionData = blob.valueOf(manifestStartRow);
                insert objCV;
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: objCV.Id].ContentDocumentId;
                cdl.LinkedEntityId = [Select Id from Account Where Name='ISN'].id;
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                insert cdl;
            }else{
                objCV.Title = fileName;
                objCV.PathOnClient = fileName+'.CSV';
                objCV.VersionData = blob.valueOf(manifestStartRow);
                objCV.contentDocumentId = cvd[0].ContentDocumentId;
                insert objCV;
            }
    }
    public static list<ContentVersion> FetchContentVersion(){
        string title = 'Manifest'+'%';
        List<Account> acc = [Select ID from Account where Name='ISN'];
        list<ContentDocumentLink> cdls = [SELECT Id, Visibility, linkedentityId,contentdocument.Title, contentdocumentID from ContentDocumentLink WHERE linkedentityId=:acc[0].id and contentdocument.Title like :title];
        list<ContentVersion> cv = new list<ContentVersion>();
        if(cdls.size() > 0) {
            cv = [SELECT Title,Id,CreatedDate,ContentDocumentId,IsLatest,versiondata FROM ContentVersion WHERE Title like : title and IsLatest=true and ContentDocumentId=:cdls[0].contentdocumentID];
        }
        return cv;
    }
    public static void sendMail( String subject, String body, List<String> address, List<String> cc) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(address);
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        if(cc != null) {
            mail.setCcAddresses(cc);
        }
        Messaging.SendEmailResult[] results = Messaging.sendEmail(
                                 new Messaging.SingleEmailMessage[] { mail });
        inspectResults(results);
    }
    private static Boolean inspectResults(Messaging.SendEmailResult[] results) {
        Boolean sendResult = true;
        for (Messaging.SendEmailResult res : results) {
            if (res.isSuccess()) {
                System.debug('Email sent successfully');
            }
            else {
                sendResult = false;
                System.debug('The following errors occurred: ' + res.getErrors());                 
            }
        }
        return sendResult;
    }
    public static date convertdatetimetodate(datetime dt){
         integer day = dt.day();
         integer month = dt.month();
         integer year = dt.year();
         date convertedDate = Date.newInstance(year, month, day);
        return convertedDate;
    }
    public void getManifestData(){
        string title = 'Manifest'+'%';
        List<Account> acc = [Select ID from Account where Name='ISN'];
        list<ContentDocumentLink> cdls = [SELECT Id, Visibility, linkedentityId,contentdocument.Title, contentdocumentID from ContentDocumentLink WHERE linkedentityId=:acc[0].id and contentdocument.Title like :title];
        manifestFiles = new list<ContentVersion>();
        if(cdls.size() > 0) {
            manifestFiles = [SELECT Title,Id,CreatedDate,ContentDocumentId,IsLatest,versiondata FROM ContentVersion WHERE Title like : title and ContentDocumentId=:cdls[0].contentdocumentID order by createddate desc];
        }
    }
}