public class SetPasswordForCD {
    public list<manifestWrapper> mwList	{get;set;}
    public SetPasswordForCD(){
        getManifestData();
    }
    public static void setPassword(){
        List<DIA_Case__c> completedCases = new List<DIA_Case__c>();
        list<string> queryFields = New list<string>();
        Map<string,string> labelNAPINameMap = New Map<string,string>();
        Map<String, Manifest_Export__mdt> mapME = Manifest_Export__mdt.getAll();
        for(string key : mapME.keyset()){
            labelNAPINameMap.put((string)mapME.get(key).get('Label'),(string)mapME.get(key).get('API_Name__c'));
            queryFields.add((string)mapME.get(key).get('API_Name__c'));
        }
        string headers = '';
        for(string header : labelNAPINameMap.keyset()){
            headers += header+',';
        }
        labelNAPINameMap.put('Subject’s Full Name','');
        string csv = headers+'Subject’s Full Name,'.substringBeforeLast(',')+'\n';
        
        string status = 'Completed';
        date weekStartDate = date.today().toStartOfWeek();
        date weekEndDate = weekStartDate.addDays(5);
        string manifestStartRow = 'Manifest Start Date'+','+date.today().toStartOfWeek().tostring().substringbefore(' ')+','+'# of Completed T5s'+',';
        string manifestEndRow = 'Manifest End Date'+','+weekEndDate.tostring().substringbefore(' ')+','+'# of Cancelled T5s'+',';
        queryFields.add('contact__r.First_Name__c');
        queryFields.add('contact__r.Last_Name__c');
        string canceledStatus = 'Canceled';
        integer cancelledCases = database.countQuery('select count() from DIA_Case__C where status__c =: canceledStatus and Case_Cancellation_Date__c >= : weekStartDate and Case_Cancellation_Date__c <=: weekEndDate');
        manifestEndRow += cancelledCases+'\n';
        string query = 'select '+string.join(queryFields,',')+' from DIA_Case__C where Case_Queue_Status__c =: status and Case_Completed_Date__c >= : weekStartDate and Case_Completed_Date__c <=: weekEndDate';
        system.debug(query);
        completedCases = database.query(query);
        system.debug('completedCases...'+completedCases);
        integer completedCount = 0;
        for(DIA_Case__C completedCase : completedCases){
            completedCount++;
            string row = '';
            Map<string,Object> completedClaseMap = (Map<string,Object>)JSON.deserializeUntyped(JSON.serialize(completedCase));
            system.debug(completedClaseMap);
            for(string label : labelNAPINameMap.keyset()){
                string apiName = labelNAPINameMap.get(label);
                if(label == 'Subject’s Full Name'){
                    Map<string,Object> parentContact = (Map<string,Object>)JSON.deserializeUntyped(JSON.serialize(completedClaseMap.get('Contact__r')));
                    row += (string)parentContact.get('Last_Name__c')+' '+(string)parentContact.get('First_Name__c')+',';
                }else{
                    if(apiName.contains('__r')){
                        string parentApiName = apiname.substringBefore('.');
                        Map<string,Object> parentObject = (Map<string,Object>)JSON.deserializeUntyped(JSON.serialize(completedClaseMap.get(parentApiName)));
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
                        if((string)completedClaseMap.get(apiName) == null){
                            row += ''+',';
                        }else{
                            row += (string)completedClaseMap.get(apiName)+',';
                        }
                    }
                }
            }
                csv += row.substringBeforeLast(',')+'\n';
        }
        manifestStartRow += completedCount+'\n';
        manifestStartRow += manifestEndRow;
        manifestStartRow += csv;
        system.debug(manifestStartRow);
                system.debug(manifestStartRow);
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
            /*ContentDistribution cd = new ContentDistribution();
            cd.name = objCV.Title;
            cd.ContentVersionId = objCV.Id;
            cd.PreferencesAllowOriginalDownload = true;
            cd.PreferencesAllowPDFDownload = true;
            cd.PreferencesAllowViewInBrowser = true;
            cd.PreferencesNotifyOnVisit = false;
            cd.PreferencesPasswordRequired = true; // <- this is it
        try{
            insert cd;
            system.debug('Distribution Created');
            ContentDistribution cdis = [ SELECT Id, Name, ContentVersionId, DistributionPublicUrl, ContentDocumentId, ContentDownloadUrl, Password FROM ContentDistribution WHERE Id =: cd.Id];
            string publicURL = cdis.DistributionPublicUrl;
            string password = cdis.Password;
            system.debug('publicURL...'+publicURL);
            system.debug(basicurl+objCV.ContentDocumentId);
            system.debug('password...'+password);
            string body = 'Hi,'+'</br>';
            body += 'The below provided link will help you to download the Manifest.'+'</br>'+'</br>';
            body += 'Please click <b>'+'<a href="'+publicURL+'">Here</a>'+'</b>'+'</br>'+'</br>';
            body += 'ISN Management';
            system.debug(body);
            list<string> toAddress = string.valueOf(system.label.dashboardExportEmail).split(',');
            string subject = 'Weekly Manifest - '+fileName;
            sendMail(subject,body,toAddress,null);
            string manifestkeySubject = 'Manifest Key - '+fileName;
            string manifestkeyBody = 'Hi,'+'</br>';
            manifestkeyBody += 'The below provided manifest key is for '+fileName+'</br>'+'</br>';
            manifestkeyBody += 'Manifest Key: '+password+'</br>'+'</br>';
            manifestkeyBody += 'ISN Management';
            sendMail(manifestkeySubject,manifestkeyBody,toAddress,null);
        }catch(exception ex){
            system.debug(ex);
        }*/
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
        list<ContentVersion> manifestFiles = new list<ContentVersion>();
        if(cdls.size() > 0) {
            manifestFiles = [SELECT Title,Id,CreatedDate,ContentDocumentId,IsLatest,versiondata FROM ContentVersion WHERE Title like : title and ContentDocumentId=:cdls[0].contentdocumentID order by createddate desc];
        }
        
        if(manifestFiles.size() > 0){
            mwList = New List<manifestWrapper>();
            for(ContentVersion manifest : manifestFiles){
                manifestWrapper mw = New manifestWrapper();
                mw.Name = manifest.Title;
                mw.versionId = manifest.Id;
                mw.Createddate = manifest.CreatedDate;
                mwList.add(mw);
            }
        }
    }
    public class manifestWrapper{
        public string Name {get;set;}
        public datetime Createddate {get;set;}
        public string versionId {get;set;}
    }
}