/** Controls DHS lead detail workflows, messages, meetings, and document actions. */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.ApexDoc, PMD.ApexSOQLInjection, PMD.ApexXSSFromURLParam, PMD.AvoidBooleanMethodParameters, PMD.AvoidDeeplyNestedIfStmts, PMD.AvoidGlobalModifier, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.DebugsShouldUseLoggingLevel, PMD.EmptyCatchBlock, PMD.EmptyIfStmt, PMD.EmptyStatementBlock, PMD.ExcessiveClassLength, PMD.ExcessiveParameterList, PMD.ExcessivePublicCount, PMD.FieldDeclarationsShouldBeAtStart, PMD.IfElseStmtsMustUseBraces, PMD.IfStmtsMustUseBraces, PMD.LocalVariableNamingConventions, PMD.MethodNamingConventions, PMD.NcssConstructorCount, PMD.NcssCount, PMD.PropertyNamingConventions')
global with sharing class DHSLeadDetailPageController {
    @RemoteAction
    global static String scheduleTeamsMeeting(
        String subject,
        String bodyHtml,
        List<String> attendeeEmails,
        String startDateTimeValue,
        String endDateTimeValue,
        String microsoftTimeZone,
        Boolean recordAutomatically,
        Boolean enableTranscription,
        Id leadId
    ) {
        MicrosoftGraphCreateMeetingController.MeetingResult result =
            MicrosoftGraphCreateMeetingController.createMeetingForLead(
                subject,
                bodyHtml,
                attendeeEmails,
                startDateTimeValue,
                endDateTimeValue,
                microsoftTimeZone,
                recordAutomatically,
                enableTranscription,
                leadId
            );

        return JSON.serialize(result);
    }

    @RemoteAction
    global static List<MeetingSummary> getLeadMeetings(Id leadId) {
        if (leadId == null) {
            return new List<MeetingSummary>();
        }

        List<MeetingSummary> summaries = new List<MeetingSummary>();
        for (MS_Team_Call_Schedule__c schedule : [
            SELECT
                Id,
                Subject__c,
                Status__c,
                Start_Date_Time__c,
                End_Date_Time__c,
                Microsoft_Time_Zone__c,
                Attendee_Emails__c,
                Organizer_Email__c,
                Teams_Join_URL__c,
                Web_Link__c,
                CreatedDate
            FROM MS_Team_Call_Schedule__c
            WHERE DHS_Lead__c = :leadId
            WITH SECURITY_ENFORCED
            ORDER BY Start_Date_Time__c DESC, CreatedDate DESC
        ]) {
            summaries.add(new MeetingSummary(schedule));
        }
        return summaries;
    }

    @RemoteAction
    global static void updateLeadMeeting(
        Id scheduleId,
        Id leadId,
        String subject,
        List<String> attendeeEmails,
        String startDateTimeValue,
        String endDateTimeValue,
        String microsoftTimeZone
    ) {
        MicrosoftGraphCreateMeetingController.updateScheduledMeeting(
            scheduleId,
            leadId,
            subject,
            attendeeEmails,
            startDateTimeValue,
            endDateTimeValue,
            microsoftTimeZone
        );
    }

    @RemoteAction
    global static void cancelLeadMeeting(
        Id scheduleId,
        Id leadId,
        String cancellationReason
    ) {
        MicrosoftGraphCreateMeetingController.cancelScheduledMeeting(
            scheduleId,
            leadId,
            cancellationReason
        );
    }

    @RemoteAction
    global static void deleteLeadMeeting(
        Id scheduleId,
        Id leadId,
        String deletionJustification
    ) {
        MicrosoftGraphCreateMeetingController.deleteScheduledMeeting(
            scheduleId,
            leadId,
            deletionJustification
        );
    }

    global class MeetingSummary {
        global String id;
        global String subject;
        global String status;
        global String startDateTime;
        global String endDateTime;
        global String timeZone;
        global String attendeeEmails;
        global String organizerEmail;
        global String teamsJoinUrl;
        global String webLink;

        global MeetingSummary(MS_Team_Call_Schedule__c schedule) {
            id = schedule.Id;
            subject = schedule.Subject__c;
            status = schedule.Status__c;
            startDateTime = schedule.Start_Date_Time__c;
            endDateTime = schedule.End_Date_Time__c;
            timeZone = schedule.Microsoft_Time_Zone__c;
            attendeeEmails = schedule.Attendee_Emails__c;
            organizerEmail = schedule.Organizer_Email__c;
            teamsJoinUrl = schedule.Teams_Join_URL__c;
            webLink = schedule.Web_Link__c;
        }
    }

    @RemoteAction
    global static MeetingLifecycleDetails getMeetingLifecycleDetails(
        Id scheduleId,
        Id leadId
    ) {
        if (scheduleId == null || leadId == null) {
            throw new AuraHandledException(
                'Meeting and Lead record IDs are required.'
            );
        }
        MS_Team_Call_Schedule__c schedule = [
            SELECT Id, Subject__c, Status__c, Actual_Duration_Seconds__c,
                Meeting_Started_At__c, Meeting_Ended_At__c,
                Last_Synchronized_At__c, Last_Graph_Error__c
            FROM MS_Team_Call_Schedule__c
            WHERE Id = :scheduleId AND DHS_Lead__c = :leadId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        MeetingLifecycleDetails details =
            new MeetingLifecycleDetails(schedule);
        Map<Id, ParticipantDetail> participantById =
            new Map<Id, ParticipantDetail>();
        for (MS_Team_Meeting_Participant__c participant : [
            SELECT Id, Display_Name__c, Email__c, Attendee_Type__c,
                Invitation_Response__c, Invitation_Response_At__c,
                Role__c, Actually_Joined__c, First_Joined_At__c,
                Last_Left_At__c, Total_Attendance_Seconds__c
            FROM MS_Team_Meeting_Participant__c
            WHERE Meeting_Schedule__c = :scheduleId
            WITH SECURITY_ENFORCED
            ORDER BY Display_Name__c, Email__c
        ]) {
            ParticipantDetail participantDetail =
                new ParticipantDetail(participant);
            details.participants.add(participantDetail);
            participantById.put(participant.Id, participantDetail);
        }
        if (!participantById.isEmpty()) {
            for (MS_Team_Attendance_Interval__c interval : [
                SELECT Participant__c, Joined_At__c, Left_At__c,
                    Duration_Seconds__c
                FROM MS_Team_Attendance_Interval__c
                WHERE Participant__c IN :participantById.keySet()
                WITH SECURITY_ENFORCED
                ORDER BY Joined_At__c
            ]) {
                participantById.get(interval.Participant__c).intervals.add(
                    new AttendanceIntervalDetail(interval)
                );
            }
        }
        for (MS_Team_Meeting_Artifact__c artifact : [
            SELECT Artifact_Type__c, Graph_Artifact_ID__c,
                Content_URL__c, Created_At__c, Ended_At__c,
                Processing_Status__c, Last_Error__c
            FROM MS_Team_Meeting_Artifact__c
            WHERE Meeting_Schedule__c = :scheduleId
            WITH SECURITY_ENFORCED
            ORDER BY Created_At__c DESC
        ]) {
            details.artifacts.add(new ArtifactDetail(artifact));
        }
        return details;
    }

    global class MeetingLifecycleDetails {
        global String subject;
        global String status;
        global Decimal actualDurationSeconds;
        global Datetime startedAt;
        global Datetime endedAt;
        global Datetime lastSynchronizedAt;
        global String lastGraphError;
        global List<ParticipantDetail> participants;
        global List<ArtifactDetail> artifacts;

        global MeetingLifecycleDetails(MS_Team_Call_Schedule__c schedule) {
            subject = schedule.Subject__c;
            status = schedule.Status__c;
            actualDurationSeconds = schedule.Actual_Duration_Seconds__c;
            startedAt = schedule.Meeting_Started_At__c;
            endedAt = schedule.Meeting_Ended_At__c;
            lastSynchronizedAt = schedule.Last_Synchronized_At__c;
            lastGraphError = schedule.Last_Graph_Error__c;
            participants = new List<ParticipantDetail>();
            artifacts = new List<ArtifactDetail>();
        }
    }

    global class ParticipantDetail {
        global String displayName;
        global String email;
        global String attendeeType;
        global String invitationResponse;
        global Datetime invitationResponseAt;
        global String role;
        global Boolean actuallyJoined;
        global Datetime firstJoinedAt;
        global Datetime lastLeftAt;
        global Decimal totalAttendanceSeconds;
        global List<AttendanceIntervalDetail> intervals;

        global ParticipantDetail(
            MS_Team_Meeting_Participant__c participant
        ) {
            displayName = participant.Display_Name__c;
            email = participant.Email__c;
            attendeeType = participant.Attendee_Type__c;
            invitationResponse = participant.Invitation_Response__c;
            invitationResponseAt = participant.Invitation_Response_At__c;
            role = participant.Role__c;
            actuallyJoined = participant.Actually_Joined__c;
            firstJoinedAt = participant.First_Joined_At__c;
            lastLeftAt = participant.Last_Left_At__c;
            totalAttendanceSeconds =
                participant.Total_Attendance_Seconds__c;
            intervals = new List<AttendanceIntervalDetail>();
        }
    }

    global class AttendanceIntervalDetail {
        global Datetime joinedAt;
        global Datetime leftAt;
        global Decimal durationSeconds;

        global AttendanceIntervalDetail(
            MS_Team_Attendance_Interval__c interval
        ) {
            joinedAt = interval.Joined_At__c;
            leftAt = interval.Left_At__c;
            durationSeconds = interval.Duration_Seconds__c;
        }
    }

    global class ArtifactDetail {
        global String artifactType;
        global String graphArtifactId;
        global String contentUrl;
        global Datetime createdAt;
        global Datetime endedAt;
        global String processingStatus;
        global String lastError;

        global ArtifactDetail(MS_Team_Meeting_Artifact__c artifact) {
            artifactType = artifact.Artifact_Type__c;
            graphArtifactId = artifact.Graph_Artifact_ID__c;
            contentUrl = artifact.Content_URL__c;
            createdAt = artifact.Created_At__c;
            endedAt = artifact.Ended_At__c;
            processingStatus = artifact.Processing_Status__c;
            lastError = artifact.Last_Error__c;
        }
    }

    @RemoteAction
    global static String grammarSendRequest(String inputText, String apiName) {
        return DHSGrammarCheckController.sendRequest(inputText, apiName);
    }
    @RemoteAction
    public static string createLeadGrammarRecord(string fields,string leadId){
        if (String.isBlank(leadId)) {
            return '';
        }

        List<DHS_Lead_Grammar_Check__c> existingRecords = [
            SELECT Id, Fields__c
            FROM DHS_Lead_Grammar_Check__c
            WHERE DHS_Lead__c = :leadId
            LIMIT 1
        ];

        if (!existingRecords.isEmpty()) {
            existingRecords[0].Fields__c = fields;
            update existingRecords[0];
            return existingRecords[0].Fields__c;
        }

        DHS_Lead_Grammar_Check__c temp = New DHS_Lead_Grammar_Check__c(DHS_Lead__c = leadId, Fields__c =fields);
        insert temp;
        return temp.Fields__c;
    }
    @RemoteAction
    public static string updateLeadGrammarRecord(string fields,string leadId){
        if (String.isBlank(leadId)) {
            return '';
        }

        List<DHS_Lead_Grammar_Check__c> existingRecords = [
            SELECT Id, Fields__c
            FROM DHS_Lead_Grammar_Check__c
            WHERE DHS_Lead__c = :leadId
            LIMIT 1
        ];

        if (existingRecords.isEmpty()) {
            return createLeadGrammarRecord(fields, leadId);
        }

        existingRecords[0].Fields__c =fields;
        update existingRecords[0];
        return existingRecords[0].Fields__c;
    }
    @RemoteAction
    public static string getLeadGrammarRecord(string leadId){
        if (String.isBlank(leadId)) {
            return '';
        }

        List<DHS_Lead_Grammar_Check__c> existingRecords = [
            SELECT Id, Fields__c
            FROM DHS_Lead_Grammar_Check__c
            WHERE DHS_Lead__c = :leadId
            LIMIT 1
        ];

        if (existingRecords.isEmpty()) {
            return '';
        }

        return existingRecords[0].Fields__c;
    } 
    public string leadId {get;set;}
    public DHS_Lead__c leadRecord {get;set;}
    public DHS_Lead_RTA_Extension__c leadRecordRTAExtension {get;set;}
    public integer hoursofleadcompletion{get;set;}
    public integer minutesofleadcompletion{get;set;}
    public boolean collectEffortDuringCompletion {get;set;}
    public User currentUser {get;set;}
    public DHS_Document_Request__c documentRequest {get;set;}
    public Map<Id,DHS_Document_Request__c> documentrequestsmap{get;set;}
    public Map<Id,List<Attachment>> documentrequestnattachmentsmap {get;set;}
    public list<string> documentrequestids {get;set;}
    public string waiverreason {get;set;}
    public Map<string,string> urlparametersMap {get;set;}
    public string urlparametersString {get;set;}
    public boolean fromCase{get;set;}
    public string leadrejectionreason{get;set;}
    public string messageSubject{get;set;}
    public string messageBody{get;set;}
    public string caseId{get;set;}
    public DHS_Case__c caseRecord{get;set;}
    public List<DHS_Message__c> messages {get;set;}
    public boolean isValidForRTAExtension{get;set;}
    public string nextURL;
    public integer pageNumber {get;set;}
    public integer TotalPages   {get;set;}
    public integer totalRecordCount {get;set;}
    public boolean disablePrev {get;set;}
    public boolean disableNext {get;set;}
    public string queryForNextRecords {get;set;}
    public string lastRecordName {get;set;}
    public string firstRecordName {get;set;}
    public integer currentRecordCount {get;set;}
    public string otherreason {get;set;}
    public string justification {get;set;}
    
    public User_Permission__mdt currentUserPermissions {get;set;}
    public List<SelectOption> StandardisedIssueOptions {
        get {
            List<SelectOption> options = new List<SelectOption>();
            for( Schema.PicklistEntry f :DHS_Lead__c.Standardised_Issues_Picklist__c.getDescribe().getPicklistValues()) {
                options.add(new SelectOption(f.getValue(), f.getLabel()));
            } 
            return options;
        }  
        set;
    }

    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','--None--'));
        options.add(new SelectOption('Subject not available','Subject not available'));
        options.add(new SelectOption('Other','Other'));
        return options;
    }
    
    public boolean showstandardisedissuesotherexplanation{get;set;}
    public void standardisedissuesaction(){
        if(StandardisedIssueItems.contains('Other')){
            showstandardisedissuesotherexplanation = true;
        }else{
            showstandardisedissuesotherexplanation = false;
        }
    }
    
    public String[] StandardisedIssueItems { 
        get {
            String[] selected = new List<String>();
            List<SelectOption> sos = this.StandardisedIssueOptions;
            for(SelectOption s : sos) {
                if (this.leadRecord.Standardised_Issues_Picklist__c !=null && this.leadRecord.Standardised_Issues_Picklist__c.contains(s.getValue()))
                    selected.add(s.getValue());
            }
            return selected;
        }
        public set {
            String selectedCheckBox = '';
            for(String s : value) {
                if (selectedCheckBox == '') 
                    selectedCheckBox += s;
                else selectedCheckBox += ';' + s;
            }
            
            leadRecord.Standardised_Issues_Picklist__c = selectedCheckBox;
        }
    }
   
    public DHSLeadDetailPageController(){
        currentUser = [Select Id, User_Type__c, Candidate_type__c FROM User where Id=:userinfo.getUserId() WITH SECURITY_ENFORCED];
        currentUserPermissions = DHSPermissionsUtil.GetUserPermssions(currentUser.User_Type__c);
        pageNumber = 1;
        disablePrev = true;
        disableNext = true;
        
        showstandardisedissuesotherexplanation = false;
        toInsertleadRecordRTAExtension = false;
        isValidForRTAExtension = false;
        leadId = apexpages.currentpage().getparameters().get('id');
        if(apexpages.currentpage().getparameters().get('fromcase') != Null){
            fromCase = boolean.valueof(apexpages.currentpage().getparameters().get('fromcase'));
        }
        urlparametersMap = apexpages.currentpage().getparameters();
        for(String str: urlparametersMap.keyset()){
            if(str != 'id'){
                if(String.isBlank(urlparametersString)){
                    urlparametersString = str+'='+urlparametersMap.get(str);  
                }else{
                    urlparametersString = urlparametersString + '&' +str+'='+urlparametersMap.get(str);  
                }
            }    
        }
        
        collectEffortDuringCompletion = false;
        
        list<String> applicableCandidateTypesForTimeEntry = new list<string>();
        string temp = DHS_GeneralSettings__c.getValues('TimeEntryDuringLeadConfirm').Value__c;
        if(temp != Null){
            applicableCandidateTypesForTimeEntry = temp.split(',');
        }
        for(String applicableType: applicableCandidateTypesForTimeEntry){
            if(applicableType == currentUser.Candidate_type__c){
                collectEffortDuringCompletion = true;
            }
        }
        FetchLeadInformation();
        documentRequest = new DHS_Document_Request__c();
        documentRequest.To_Address__c = leadRecord.DHS_Contact__r.Email__c;
        documentRequest.DHS_Lead__c = leadId;
        FetchDocumentRequests();
        FetchCaseInformation();
        FetchCaseMessages();
    }
    public void FetchCaseInformation(){
        List<string> caseFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        caseFields = DHSApexUtil.FetchFields('DHS_Case__c');
        caseFields.add('DHS_Contact__r.First_Name__c');
        caseFields.add('DHS_Contact__r.Last_Name__c');
        caseFields.add('DHS_Contact__r.Email__c');
        caseFields.add('DHS_Assigned_To__r.FirstName');
        caseFields.add('DHS_Assigned_To__r.LastName');
        caseFields.add('DHS_Assigned_To__r.Email');
        caseFields.add('owner.email');
        
        String query = 'Select '+string.join(caseFields, ',') + ' From DHS_Case__c ';
        
        if(String.isNotBlank(caseId)){
            whereCriteria.add(new DHSApexUtil.Criteria('Id',caseId,'='));
        }
        
        String where_cond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+' WITH SECURITY_ENFORCED'; 
        list<DHS_Case__c> cases = database.query(query);
        if(!cases.isEmpty()){
            caseRecord = cases[0];    
        }    
    }
    public static list<string> FetchToAddressOfCase(DHS_Case__c caseRecord, user currentUser){
        list<string> toUserIds = new list<string>();
        if(currentuser.user_type__c != 'PMO'){
           toUserIds.add(caseRecord.Owner.Email);
        }
        if(caseRecord.DHS_Assigned_To__c != Null && caseRecord.DHS_Assigned_To__c != userinfo.getuserid()){
            if(!toUserIds.contains(caseRecord.DHS_Assigned_To__c) ){
                toUserIds.add(caseRecord.DHS_Assigned_To__r.Email);
            }
        }
        List<DHS_Lead__c> leadsAssigned = new List<DHS_Lead__c>();
        leadsAssigned = [Select Id, Status__c, DHS_Assigned_To__c, DHS_Assigned_To__r.Email, DHS_Case__c, DHS_Assigned_To__r.FirstName, DHS_Assigned_To__r.LastName from DHS_Lead__c where DHS_Case__c=:caseRecord.id WITH SECURITY_ENFORCED];
        for(DHS_Lead__c lead: leadsAssigned){
            if(lead.DHS_Assigned_To__c != Null && lead.DHS_Assigned_To__c != userinfo.getuserid()){
                if(!toUserIds.contains(lead.DHS_Assigned_To__r.Email)){
                     toUserIds.add(lead.DHS_Assigned_To__r.Email);
                }   
            }
        }
        return toUserIds;
    }
   
    public void SendMessage(){
        List<String> toAddressList = new list<String>();
        toAddressList.addAll(FetchToAddressOfCase(caseRecord,currentUser));
        List<DHS_Message__c> messagesToInsert = new List<DHS_Message__c>();
        DHS_Message__c message = new DHS_Message__c();
        message.Message_Body__c = messageBody;
        message.Subject__c = messageSubject;
        message.DHS_From_User__c = userinfo.getUserId();
        message.DHS_Case__c = caseRecord.id;
        message.DHS_Lead__c = leadId;
        messagesToInsert.add(message); 
        database.insert(message,false,AccessLevel.USER_MODE);
        String emailBody = 'Message has been sent for the case #'+caseRecord.Case_Number__c+' Please login to check the message.';
        if(!test.isRunningTest()){
            DHSMailUtilities.sendHTMLEmail(toAddressList,messageSubject,emailBody,null);
        }
        //FetchCaseMessages(); 
        
        List<string> cmoEmails = New List<string>();
        string cmoSub = 'ISN DHS case message notification: Case #'+caseRecord.Case_Number__c;
        string cmoBody = 'A case message has been sent by '+Userinfo.getFirstName()+' '+Userinfo.getLastName();
        if(caseRecord.DHS_Assigned_To__c != null){
            if(!test.isRunningTest()){
                cmoEmails.add(caseRecord.DHS_Assigned_To__r.Email);
                DHSMailUtilities.sendHTMLEmail(cmoEmails,cmoSub,cmoBody,null);
            }
        }
        
        messageSubject = null;
        messageBody = null;   
    }
     
    public void FetchCaseMessages(){
        pageNumber = 1;
        disablePrev = true;
        
        messages = new list<DHS_Message__c>();
        List<string> messageFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        messageFields = DHSApexUtil.FetchFields('DHS_Message__c');  
        messageFields.add('DHS_Case__r.Case_Number__c');
        messageFields.add('DHS_Lead__r.Name');
        messageFields.add('DHS_From_User__r.FirstName');
        messageFields.add('DHS_From_User__r.LastName');
        messageFields.add('DHS_To_User__r.FirstName');
        messageFields.add('DHS_To_User__r.LastName');
        messageFields.add('DHS_CC_User__r.FirstName');
        messageFields.add('DHS_CC_User__r.LastName');
        messageFields.add('DHS_Lead__r.Item_number__c');
        
        String query = 'Select '+string.join(messageFields, ',') + ' From DHS_Message__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__c',caseId,'='));
        }
        
        String where_cond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        queryForNextRecords = query + ' WHERE '+where_cond;
        query = query + ' WHERE '+where_cond+' WITH SECURITY_ENFORCED Order by Name asc Limit 200'; 
        string countQuery = 'Select Count() from DHS_Message__c WHERE '+ where_cond+' WITH SECURITY_ENFORCED';
        totalRecordCount = database.countquery(Countquery);
        
        List<DHS_Message__c> msgs = database.query(query); 
        integer i = 0;
        for(DHS_Message__c msg: msgs){
            messages.add(msg); 
            if(i==0){
                firstRecordName = msg.Name;    
            }
            lastRecordName = msg.Name;
            i++;
        }
        PageNumber = 1;
        double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
        double floorVal = Math.floor(totalNum);
        double diff = totalNum - floorVal;
        TotalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
        if(totalRecordCount <= 200){
            disablePrev = true;
            disableNext = true;
            currentRecordCount = totalRecordCount;
        }else{
            disablePrev = true;   
            disableNext = false;
            currentRecordCount = 200; 
        } 
    }
    
    public void FetchLeadInformation(){
        List<string> leadFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        leadFields = DHSApexUtil.FetchFields('DHS_Lead__c');
        leadFields.add('DHS_Contact__r.First_Name__c');
        leadFields.add('DHS_Contact__r.Last_Name__c');
        leadFields.add('DHS_Contact__r.Email__c');
        leadFields.add('DHS_Assigned_To__r.Name');
        leadFields.add('DHS_Assigned_To__r.Email');
        leadFields.add('DHS_Case__r.Case_Number__c');
        leadFields.add('DHS_Case__r.Case_Cancelled__c');
        leadFields.add('DHS_Case__r.Case_Discontinued__c');
        
        String query = 'Select '+string.join(leadFields, ',') + ' From DHS_Lead__c ';
        
        if(String.isNotBlank(leadId)){
            whereCriteria.add(new DHSApexUtil.Criteria('Id',leadId,'='));
        }
        
        String where_cond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+' WITH SECURITY_ENFORCED'; 
        list<DHS_Lead__c> leads = database.query(query);
        if(!leads.isEmpty()){
            leadRecord = leads[0]; 
            caseId = leadRecord.DHS_Case__c; 
            if(leadRecord.LeadType__c == 'Subject Interview (ESI/TESI)'){
                 isValidForRTAExtension = true;
                 leadRecordRTAExtension = new DHS_Lead_RTA_Extension__c();
                 List<DHS_Lead_RTA_Extension__c> leadRecordExtensions = new List<DHS_Lead_RTA_Extension__c>();
                 leadRecordExtensions = [Select Id, Foreign_Activities__c, Foreign_Contacts__c, Foreign_Travel1__c, Foreign_Travel2__c, DHS_Lead__c
                                         FROM DHS_Lead_RTA_Extension__c WHERE DHS_Lead__c =:leadRecord.Id WITH SECURITY_ENFORCED];
                 if(!leadRecordExtensions.isEmpty()){
                     leadRecordRTAExtension = leadRecordExtensions[0];
                 } else{
                     leadRecordRTAExtension = new DHS_Lead_RTA_Extension__c();
                     leadRecordRTAExtension.DHS_Lead__c = leadRecord.id;    
                     //insert leadRecordRTAExtension;   
                     toInsertleadRecordRTAExtension = true; 
                 }                           
            } 
        } 
    }
    public boolean toInsertleadRecordRTAExtension {get;set;}
    public pagereference completeleadaction(){
        leadRecord.Status__c = 'Completed';
        leadRecord.Hours_of_completion__c = hoursofleadcompletion;
        leadRecord.Minutes_of_completion__c = minutesofleadcompletion;
        if(leadRecord.QA_Rejected_Date__c != null){
            leadRecord.Status__c = 'QA Rejection Complete';
            leadRecord.QA_Rejection_Complete_Date__c = date.today(); 
        }
        update leadRecord;
        //database.update(leadRecord,false,AccessLevel.USER_MODE);
        if(isValidForRTAExtension){
            if(toInsertleadRecordRTAExtension){
                insert leadRecordRTAExtension;
                //database.insert(leadRecordRTAExtension);
            }else{
                update leadRecordRTAExtension;
                //database.update(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
            }
        }
        return getLeadCompletionRedirectPage();
    }

    private PageReference getLeadCompletionRedirectPage() {
        PageReference redirectPage;
        if (fromCase == true) {
            redirectPage = Page.DHSCasedetail;
            redirectPage.getParameters().put('id', leadRecord.DHS_Case__c);
            redirectPage.getParameters().put('tab', 'Leads');
        } else {
            redirectPage = Page.DHSLeaddashboard;
            if (urlparametersMap != null) {
                for (String parameterName : urlparametersMap.keySet()) {
                    if (parameterName != 'id' && parameterName != 'fromcase') {
                        redirectPage.getParameters().put(parameterName, urlparametersMap.get(parameterName));
                    }
                }
            }
        }
        redirectPage.setRedirect(true);
        return redirectPage;
    }
    
    public string errorMessage {get;set;}
    public void updateleadaction(){
        try{
            errorMessage = null;
            update leadRecord;
            //database.update(leadRecord,false,AccessLevel.USER_MODE);  
            if(isValidForRTAExtension){
                if(toInsertleadRecordRTAExtension){
                    insert leadRecordRTAExtension;
                    //database.insert(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
                }else{
                    update leadRecordRTAExtension;
                    //database.update(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
                }
            }
        }catch(Exception ex){
            errorMessage = ex.getMessage();
            if(errorMessage.contains(System.label.DHS_Duplicate_Item_Number_Message)){
                errorMessage = 'Update failed: '+System.label.DHS_Duplicate_Item_Number_Message;
            }
        }
    }
    
    public pagereference reviewcompletedaction(){
        leadRecord.Status__c = 'QA Review Completed';
        update leadRecord;
        //database.update(leadRecord,false,AccessLevel.USER_MODE);
        if(isValidForRTAExtension){
            if(toInsertleadRecordRTAExtension){
                insert leadRecordRTAExtension;
                //database.insert(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
            }else{
                update leadRecordRTAExtension;
                //database.update(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
            }
        }
        PageReference redirectPage = Page.DHSCasedetail;
        redirectPage.getParameters().put('id',leadRecord.DHS_Case__c);
        redirectPage.getParameters().put('tab','Leads');
        redirectPage.setRedirect(true);
        return redirectPage; 
    }
    
    public void selfassignaction(){
         leadRecord.DHS_Assigned_To__c = currentuser.id;
         leadRecord.Status__c = 'Assigned';
         leadRecord.Lead_Accepted_or_Rejected__c ='Accepted'; 
         leadRecord.Accepted_Date__c =system.today();  
         leadRecord.Assignee_Date__c = system.today(); 
         if(!test.isRunningTest()){
            database.update(leadRecord,false,AccessLevel.USER_MODE); 
            if(isValidForRTAExtension){
                if(toInsertleadRecordRTAExtension){
                    database.insert(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
                }else{
                    database.update(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
                }
            }    
         }
         
    }
    
    public pagereference deleteleadaction(){
        delete leadRecord;
        //database.delete(leadRecord,false,AccessLevel.USER_MODE);
        PageReference redirectPage = Page.DHSLeaddashboard;
        redirectPage.setRedirect(true);
        return redirectPage;     
    }
    
    public void dummyaction(){
    
    }
    
     public void createdocumentrequestaction(){
        documentRequest.Status__c = 'Documents Requested';
         insert documentRequest;
        //database.insert(documentRequest,false,AccessLevel.USER_MODE);
        documentRequest = new DHS_Document_Request__c();
        documentRequest.To_Address__c = leadRecord.DHS_Contact__r.Email__c;
        documentRequest.DHS_Lead__c = leadId;
        FetchDocumentRequests();
    }
    
    public  void FetchDocumentRequests(){
        documentrequestsmap = new Map<Id,DHS_Document_Request__c>([SELECT Id,Name,Status__c,To_Address__c, Additional_To_Address__c, Investigator_Comments__c FROM DHS_Document_Request__c WHERE DHS_Lead__c=:leadId WITH SECURITY_ENFORCED order by createddate desc ]);
        documentrequestnattachmentsmap = new Map<Id,List<Attachment>>();
        documentrequestids = new list<string>();
        for(string docId: documentrequestsmap.keyset()){
            documentrequestids.add(docId);
            documentrequestnattachmentsmap.put(docId,new list<Attachment> {});
        }
        List<Attachment> attachments = [Select id, name, parentid, description from Attachment where parentid=:documentrequestsmap.keyset() WITH SECURITY_ENFORCED];
        for(Attachment att: attachments){
            if(!documentrequestnattachmentsmap.containsKey(att.parentid)){
                documentrequestnattachmentsmap.put(att.parentid, new list<Attachment> {att});
            }else{
                documentrequestnattachmentsmap.get(att.parentid).add(att);
            }
        }
    }
    
    public PageReference applyforwaiveraction(){
        leadRecord.Status__c = 'Applied For Waiver';
        leadRecord.Reason_for_Waiver__c = waiverreason;
        update leadRecord;
        //database.update(leadRecord,false,AccessLevel.USER_MODE);
        if(isValidForRTAExtension){
            if(toInsertleadRecordRTAExtension){
                insert leadRecordRTAExtension;
                //database.insert(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
            }else{
                update leadRecordRTAExtension;
                //database.update(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
            }
        }
        DHS_Case_History__c ch = new DHS_Case_History__c();
        ch.DHS_Case__c = leadRecord.DHS_Case__c;
        ch.DHS_Added_By__c = userinfo.getuserid();
        ch.Value__c = 'Applied For Waiver - '+ waiverreason;
        insert ch;
        //database.Insert(ch,false,AccessLevel.USER_MODE);
        PageReference redirectPage = Page.DHSLeaddashboard;
        redirectPage.setRedirect(true);
        return redirectPage;  
        
        
    }
    
    public pagereference rejectleadaction(){
        leadRecord.Status__c = 'QA Rejected';
        leadRecord.QA_Rejection_Comments__c = leadrejectionreason;
        leadRecord.QA_Rejected_Date__c = system.today();
        update leadRecord;
        //database.update(leadRecord,false,AccessLevel.USER_MODE);
        if(isValidForRTAExtension){
            if(toInsertleadRecordRTAExtension){
                insert leadRecordRTAExtension;
                //database.insert(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
            }else{
                update leadRecordRTAExtension;
                //database.update(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
            }
        }
        List<string> toAddress = new List<string>();
        toAddress.add(leadRecord.Assigned_To_Investigator_Email__c);
        
        
        String subject = 'ISN - DHS: '+leadRecord.Item_number__c+' rejected on case '+leadrecord.DHS_Case__r.Case_Number__c+'.';
        string body = 'ISN - DHS: An item on the case referenced above has been returned to you for corrections in the ForeSite system. '+
            'Please review the case message associated with this request in ForeSite, make the appropriate corrections, and complete the item(s) within 24 hours.'+
            ' If you have any questions regarding this request, please contact the case reviewer and/or your Field Leader.'+
            '\n'+' Thank you!';
        if(!test.isRunningTest()){
            DHSMailUtilities.sendHTMLEmail(toAddress,subject,body,null);    
        }
        PageReference redirectPage = Page.DHSCasedetail;
        redirectPage.getParameters().put('id',leadRecord.DHS_Case__c);
        redirectPage.getParameters().put('tab','Leads');
        redirectPage.setRedirect(true);
        return redirectPage; 
    }
    
    public void reopenleadaction(){
        leadRecord.Status__c = 'In-Progress';
        update leadRecord;
        //database.update(leadRecord,false,AccessLevel.USER_MODE);
    }
    
    /*public string sourcefieldtopopulatenarrative{get;set;}
    public string sourcefieldvaluetopopulatenarrative{get;set;}
    public void populatenarrativeaction(){
        System.debug('sourcefieldtopopulatenarrative...'+sourcefieldtopopulatenarrative);
       
        List<string> reportMatrixFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        reportMatrixFields = DHSApexUtil.FetchFields('ROI_Report_Matrix__c');
        
        String query = 'Select '+string.join(reportMatrixFields, ',') + ' From ROI_Report_Matrix__c ';
        
        if(String.isNotBlank(sourcefieldtopopulatenarrative)){
            whereCriteria.add(new DHSApexUtil.Criteria('Source_Field__c',sourcefieldtopopulatenarrative,'='));
        }
        if(String.isNotBlank(sourcefieldvaluetopopulatenarrative)){
            whereCriteria.add(new DHSApexUtil.Criteria('Value__c',sourcefieldvaluetopopulatenarrative,'='));
        }
        
        if(String.isNotBlank(leadRecord.LeadType__c)){
            whereCriteria.add(new DHSApexUtil.Criteria('Lead_Type__c',leadRecord.LeadType__c,'='));
        }
       
        
        String where_cond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond; 
        System.debug('query...'+query);
        list<ROI_Report_Matrix__c> reportMatrices = database.query(query);
        System.debug('reportMatrices...'+reportMatrices);
        if(!reportMatrices.isEmpty()){
            String textToPopulate = reportMatrices[0].Text_To_Populate__c;
            leadRecord.Narrator_Comments__c = MergeFieldsofROI();
        }
        
   
    }
    
    public string MergeFieldsofROI(){
        string mergedText;
        List<string> reportMatrixFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        reportMatrixFields = DHSApexUtil.FetchFields('ROI_Report_Matrix__c');
        
        String query = 'Select '+string.join(reportMatrixFields, ',') + ' From ROI_Report_Matrix__c ';
        if(String.isNotBlank(leadRecord.LeadType__c)){
            whereCriteria.add(new DHSApexUtil.Criteria('Lead_Type__c',leadRecord.LeadType__c,'='));
        }
        
        String where_cond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond; 
        System.debug('query...'+query);
        list<ROI_Report_Matrix__c> reportMatrices = database.query(query);
        
        for(ROI_Report_Matrix__c roi: reportMatrices){
            Map<String,String> mergeFieldsMap = new Map<String,String>();
            Pattern p = Pattern.compile('\\%.+?\\%');
            String unMergedText = roi.Text_To_Populate__c;
            Matcher m = p.matcher(unMergedText);
            while(m.find()) {
                System.debug(m.group(0));
                mergeFieldsMap.put(m.group(0),string.valueof(leadRecord.get(m.group(0).replaceAll('%',''))));
            }
            System.debug('mergeFieldsMap....'+mergeFieldsMap);
            for(String str: mergeFieldsMap.keyset()){
                if(string.isNotBlank(mergeFieldsMap.get(str))){
                    unMergedText = unMergedText.replace(str,mergeFieldsMap.get(str)); 
                }  else{
                    unMergedText = unMergedText.replace(str,''); 
                } 
            }
            if(leadRecord.get(roi.source_field__c) != Null){
                if(String.isNotBlank(mergedText)){
                    mergedText = mergedText + ' ' + unMergedText;
                }else{
                    mergedText = unMergedText;
                }
            }
        }
    
        return mergedText;
    }*/
    
    public void AutoSaveLeadAction(){
     if(leadRecord.LeadType__c == 'Subject Interview (ESI/TESI)'){
         try{
             update leadRecordRTAExtension;
         }catch(exception e){
         }
        
     }
        
        update leadRecord;
        //database.update(leadRecord,false,AccessLevel.USER_MODE);
    }
    

    
    public void handlePrev(){
            messages = new list<DHS_Message__c>();
        
        PageNumber --;
        string query = queryForNextRecords + ' AND Name <:firstRecordName WITH SECURITY_ENFORCED Order by Name desc Limit 200';    
        list<DHS_Message__c> msgs = database.query(query);
        for(Integer j=msgs.size()-1;j>=0; j--){
            messages.add(msgs[j]); 
            if(j==msgs.size()-1){
                firstRecordName = msgs[j].Name;    
            }
            lastRecordName = msgs[j].Name; 
            
        }
        if(msgs.size()<=200){
            currentRecordCount =  currentRecordCount - messages.size();        
        }else{
            currentRecordCount =  currentRecordCount - 200;    
        }
        if(pageNumber == 1){
            disablePrev = true;
            disableNext = false ;
        }else{
            disablePrev = false;
            disableNext = false;
        }
    } 
    public void handleNext(){
        messages = new list<DHS_Message__c>();
        PageNumber ++ ;
        string query = queryForNextRecords + ' AND Name >:lastRecordName WITH SECURITY_ENFORCED Order by Name asc Limit 200';      
        list<DHS_Message__c> msgs = database.query(query);
        integer i = 0;
        for(DHS_Message__c msg: msgs){
            messages.add(msg); 
            if(i==0){
                firstRecordName = msg.Name;    
            }
            lastRecordName = msg.Name;
            i++;
        }
        if(messages.size()<=200){
            currentRecordCount =  currentRecordCount + messages.size();        
        }else{
            currentRecordCount =  currentRecordCount + 200;    
        }
        /*
        if(totalRecordCount>currentRecordCount){
            disablePrev = false;
            disableNext = false;
        }else{
            disablePrev = false;   
            disableNext = true;
        }*/
        if(pageNumber == TotalPages){
            disablePrev = false;   
            disableNext = true;
        }else{
            disablePrev = false;
            disableNext = false;
        }
    } 
    
    public DHS_Message__c selectedMessage { get; set; }
    public String modalAction { get; set; }
    public Id selectedMessageId { get; set; }

    // Called by actionFunction before opening modal
    public void openModal() {
        if(modalAction == 'edit' && selectedMessageId != null){
            selectedMessage = [
                SELECT Id, Subject__c, Message_Body__c 
                FROM DHS_Message__c 
                WHERE Id = :selectedMessageId
                LIMIT 1
            ];
        }
    }

    public void updateMessage() {
        if(selectedMessage != null){
            update selectedMessage;
        }
    }

    public void deleteMessage() {
        if(selectedMessageId != null){
            try {
                delete [SELECT Id FROM DHS_Message__c WHERE Id = :selectedMessageId LIMIT 1];
                // Refresh messages after deletion
                FetchCaseMessages();
            } catch (Exception e) {
            }
        } else {
        }
    }
    public static datetime convertToDt(date dt){
        integer day;
        integer month;
        integer year;
        day = dt.day();
        month = dt.month();
        year = dt.year();
        datetime dtime = datetime.newinstance(day,month,year);
        return dtime;
    }
}