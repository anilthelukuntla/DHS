/**
 * @description Controls DHS lead detail workflows, messages, meetings, and document actions.
 */
@SuppressWarnings('PMD.AvoidDeeplyNestedIfStmts,PMD.AvoidGlobalModifier,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.EmptyStatementBlock,PMD.ExcessiveClassLength,PMD.ExcessiveParameterList,PMD.ExcessivePublicCount,PMD.FieldDeclarationsShouldBeAtStart,PMD.NcssConstructorCount,PMD.NcssCount')
global with sharing class DHSLeadDetailPageController {
    @RemoteAction
    /**
     * @description Provides this DHS API member.
     * @param subject Method parameter.
     * @param bodyHtml Method parameter.
     * @param attendeeEmails Method parameter.
     * @param startDateTimeValue Method parameter.
     * @param endDateTimeValue Method parameter.
     * @param microsoftTimeZone Method parameter.
     * @param recordAutomatically Method parameter.
     * @param enableTranscription Method parameter.
     * @param leadId Method parameter.
     * @return The requested result.
     */
    global static String scheduleTeamsMeeting(
        String subject,
        String bodyHtml,
        List<String> attendeeEmails,
        String startDateTimeValue,
        String endDateTimeValue,
        String microsoftTimeZone,
        Boolean recordAutomatically, // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
        Boolean enableTranscription, // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
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
    /**
     * @description Provides this DHS API member.
     * @param leadId Method parameter.
     * @return The requested result.
     */
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
            WITH USER_MODE
            ORDER BY Start_Date_Time__c DESC, CreatedDate DESC
        ]) {
            summaries.add(new MeetingSummary(schedule));
        }
        return summaries;
    }

    @RemoteAction
    /**
     * @description Provides this DHS API member.
     * @param scheduleId Method parameter.
     * @param leadId Method parameter.
     * @param subject Method parameter.
     * @param attendeeEmails Method parameter.
     * @param startDateTimeValue Method parameter.
     * @param endDateTimeValue Method parameter.
     * @param microsoftTimeZone Method parameter.
     */
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
    /**
     * @description Provides this DHS API member.
     * @param scheduleId Method parameter.
     * @param leadId Method parameter.
     * @param cancellationReason Method parameter.
     */
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
    /**
     * @description Provides this DHS API member.
     * @param scheduleId Method parameter.
     * @param leadId Method parameter.
     * @param deletionJustification Method parameter.
     */
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

    /** @description Provides this DHS API member. */
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

        /**
         * @description Provides this DHS API member.
         * @param schedule Method parameter.
         */
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
    /**
     * @description Provides this DHS API member.
     * @param scheduleId Method parameter.
     * @param leadId Method parameter.
     * @return The requested result.
     */
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
            WITH USER_MODE
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
            WITH USER_MODE
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
                WITH USER_MODE
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
            WITH USER_MODE
            ORDER BY Created_At__c DESC
        ]) {
            details.artifacts.add(new ArtifactDetail(artifact));
        }
        return details;
    }

    /** @description Provides this DHS API member. */
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

        /**
         * @description Provides this DHS API member.
         * @param schedule Method parameter.
         */
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

    /** @description Provides this DHS API member. */
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

        /**
         * @description Provides this DHS API member.
         * @param participant Method parameter.
         */
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

    /** @description Provides this DHS API member. */
    global class AttendanceIntervalDetail {
        global Datetime joinedAt;
        global Datetime leftAt;
        global Decimal durationSeconds;

        /**
         * @description Provides this DHS API member.
         * @param interval Method parameter.
         */
        global AttendanceIntervalDetail(
            MS_Team_Attendance_Interval__c interval
        ) {
            joinedAt = interval.Joined_At__c;
            leftAt = interval.Left_At__c;
            durationSeconds = interval.Duration_Seconds__c;
        }
    }

    /** @description Provides this DHS API member. */
    global class ArtifactDetail {
        global String artifactType;
        global String graphArtifactId;
        global String contentUrl;
        global Datetime createdAt;
        global Datetime endedAt;
        global String processingStatus;
        global String lastError;

        /**
         * @description Provides this DHS API member.
         * @param artifact Method parameter.
         */
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
    /**
     * @description Provides this DHS API member.
     * @param inputText Method parameter.
     * @param apiName Method parameter.
     * @return The requested result.
     */
    global static String grammarSendRequest(String inputText, String apiName) {
        return DHSGrammarCheckController.sendRequest(inputText, apiName);
    }
    @RemoteAction
    /**
     * @description Provides this DHS API member.
     * @param fields Method parameter.
     * @param leadId Method parameter.
     * @return The requested result.
     */
    public static string createLeadGrammarRecord(string fields,string leadId){
        if (String.isBlank(leadId)) {
            return '';
        }

        List<DHS_Lead_Grammar_Check__c> existingRecords = [
            SELECT Id, Fields__c
            FROM DHS_Lead_Grammar_Check__c
            WHERE DHS_Lead__c = :leadId
            WITH USER_MODE LIMIT 1
        ];

        if (!existingRecords.isEmpty()) {
            existingRecords[0].Fields__c = fields;
            Database.update(existingRecords[0], AccessLevel.USER_MODE);
            return existingRecords[0].Fields__c;
        }

        DHS_Lead_Grammar_Check__c temp = New DHS_Lead_Grammar_Check__c(DHS_Lead__c = leadId, Fields__c =fields);
        Database.insert(temp, AccessLevel.USER_MODE);
        return temp.Fields__c;
    }
    @RemoteAction
    /**
     * @description Provides this DHS API member.
     * @param fields Method parameter.
     * @param leadId Method parameter.
     * @return The requested result.
     */
    public static string updateLeadGrammarRecord(string fields,string leadId){
        if (String.isBlank(leadId)) {
            return '';
        }

        List<DHS_Lead_Grammar_Check__c> existingRecords = [
            SELECT Id, Fields__c
            FROM DHS_Lead_Grammar_Check__c
            WHERE DHS_Lead__c = :leadId
            WITH USER_MODE LIMIT 1
        ];

        if (existingRecords.isEmpty()) {
            return createLeadGrammarRecord(fields, leadId);
        }

        existingRecords[0].Fields__c =fields;
        Database.update(existingRecords[0], AccessLevel.USER_MODE);
        return existingRecords[0].Fields__c;
    }
    @RemoteAction
    /**
     * @description Provides this DHS API member.
     * @param leadId Method parameter.
     * @return The requested result.
     */
    public static string getLeadGrammarRecord(string leadId){
        if (String.isBlank(leadId)) {
            return '';
        }

        List<DHS_Lead_Grammar_Check__c> existingRecords = [
            SELECT Id, Fields__c
            FROM DHS_Lead_Grammar_Check__c
            WHERE DHS_Lead__c = :leadId
            WITH USER_MODE LIMIT 1
        ];

        if (existingRecords.isEmpty()) {
            return '';
        }

        return existingRecords[0].Fields__c;
    } 
    /** @description Provides this DHS API member. */
    public string leadId {get;set;}
    /** @description Provides this DHS API member. */
    public DHS_Lead__c leadRecord {get;set;}
    /** @description Provides this DHS API member. */
    public DHS_Lead_RTA_Extension__c leadRecordRTAExtension {get;set;}
    /** @description Provides this DHS API member. */
    public integer hoursofleadcompletion{get;set;}
    /** @description Provides this DHS API member. */
    public integer minutesofleadcompletion{get;set;}
    public boolean collectEffortDuringCompletion {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    /** @description Provides this DHS API member. */
    public User currentUser {get;set;}
    /** @description Provides this DHS API member. */
    public DHS_Document_Request__c documentRequest {get;set;}
    /** @description Provides this DHS API member. */
    public Map<Id,DHS_Document_Request__c> documentrequestsmap{get;set;}
    /** @description Provides this DHS API member. */
    public Map<Id,List<Attachment>> documentrequestnattachmentsmap {get;set;}
    /** @description Provides this DHS API member. */
    public list<string> documentrequestids {get;set;}
    /** @description Provides this DHS API member. */
    public string waiverreason {get;set;}
    /** @description Provides this DHS API member. */
    public Map<string,string> urlparametersMap {get;set;}
    /** @description Provides this DHS API member. */
    public string urlparametersString {get;set;}
    public boolean fromCase{get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    /** @description Provides this DHS API member. */
    public string leadrejectionreason{get;set;}
    /** @description Provides this DHS API member. */
    public string messageSubject{get;set;}
    /** @description Provides this DHS API member. */
    public string messageBody{get;set;}
    /** @description Provides this DHS API member. */
    public string caseId{get;set;}
    /** @description Provides this DHS API member. */
    public DHS_Case__c caseRecord{get;set;}
    /** @description Provides this DHS API member. */
    public List<DHS_Message__c> messages {get;set;}
    public boolean isValidForRTAExtension{get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public string nextURL;
    /** @description Provides this DHS API member. */
    public integer pageNumber {get;set;}
    /** @description Provides this DHS API member. */
    public integer totalPages   {get;set;}
    /** @description Provides this DHS API member. */
    public integer totalRecordCount {get;set;}
    public boolean disablePrev {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public boolean disableNext {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    /** @description Provides this DHS API member. */
    public string queryForNextRecords {get;set;}
    /** @description Provides this DHS API member. */
    public string lastRecordName {get;set;}
    /** @description Provides this DHS API member. */
    public string firstRecordName {get;set;}
    /** @description Provides this DHS API member. */
    public integer currentRecordCount {get;set;}
    /** @description Provides this DHS API member. */
    public string otherreason {get;set;}
    /** @description Provides this DHS API member. */
    public string justification {get;set;}
    
    /** @description Provides this DHS API member. */
    public User_Permission__mdt currentUserPermissions {get;set;}
    /** @description Provides this DHS API member. */
    public List<SelectOption> standardisedIssueOptions {
        get {
            List<SelectOption> options = new List<SelectOption>();
            for( Schema.PicklistEntry f :DHS_Lead__c.Standardised_Issues_Picklist__c.getDescribe().getPicklistValues()) {
                options.add(new SelectOption(f.getValue(), f.getLabel()));
            } 
            return options;
        }  
        set;
    }

    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','--None--'));
        options.add(new SelectOption('Subject not available','Subject not available'));
        options.add(new SelectOption('Other','Other'));
        return options;
    }
    
    public boolean showstandardisedissuesotherexplanation{get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    /** @description Provides this DHS API member. */
    public void standardisedissuesaction(){
        if(standardisedIssueItems.contains('Other')){
            showstandardisedissuesotherexplanation = true;
        }else{
            showstandardisedissuesotherexplanation = false;
        }
    }
    
    /** @description Provides this DHS API member. */
    public String[] standardisedIssueItems { 
        get {
            String[] selected = new List<String>();
            List<SelectOption> sos = this.standardisedIssueOptions;
            for(SelectOption s : sos) {
                if (this.leadRecord.Standardised_Issues_Picklist__c !=null && this.leadRecord.Standardised_Issues_Picklist__c.contains(s.getValue())) {
                    selected.add(s.getValue());
                }
            }
            return selected;
        }
        public set {
            String selectedCheckBox = '';
            for(String s : value) {
                if (selectedCheckBox == '') {
                    selectedCheckBox += s;
                } else {
                    selectedCheckBox += ';' + s;
                }
            }
            
            leadRecord.Standardised_Issues_Picklist__c = selectedCheckBox;
        }
    }
   
    /** @description Provides this DHS API member. */
    public DHSLeadDetailPageController(){
        currentUser = [Select Id, User_Type__c, Candidate_type__c FROM User where Id=:userinfo.getUserId()];
        currentUserPermissions = DHSPermissionsUtil.GetUserPermssions(currentUser.User_Type__c);
        pageNumber = 1;
        disablePrev = true;
        disableNext = true;
        
        showstandardisedissuesotherexplanation = false;
        toInsertleadRecordRTAExtension = false;
        isValidForRTAExtension = false;
        leadId = String.valueOf(Id.valueOf(
            ApexPages.currentPage().getParameters().get('id').escapeHtml4()
        ));
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
        fetchLeadInformation();
        documentRequest = new DHS_Document_Request__c();
        documentRequest.To_Address__c = leadRecord.DHS_Contact__r.Email__c;
        documentRequest.DHS_Lead__c = leadId;
        fetchDocumentRequests();
        fetchCaseInformation();
        fetchCaseMessages();
    }
    /** @description Provides this DHS API member. */
    public void fetchCaseInformation(){
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
        
        String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+whereCond;
        list<DHS_Case__c> cases = database.query(query, AccessLevel.USER_MODE);
        if(!cases.isEmpty()){
            caseRecord = cases[0];    
        }    
    }
    /**
     * @description Provides this DHS API member.
     * @param caseRecord Method parameter.
     * @param currentUser Method parameter.
     * @return The requested result.
     */
    public static list<string> fetchToAddressOfCase(DHS_Case__c caseRecord, user currentUser){
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
        leadsAssigned = [Select Id, Status__c, DHS_Assigned_To__c, DHS_Assigned_To__r.Email, DHS_Case__c, DHS_Assigned_To__r.FirstName, DHS_Assigned_To__r.LastName from DHS_Lead__c where DHS_Case__c=:caseRecord.id WITH USER_MODE];
        for(DHS_Lead__c lead: leadsAssigned){
            if(lead.DHS_Assigned_To__c != Null && lead.DHS_Assigned_To__c != userinfo.getuserid()){
                if(!toUserIds.contains(lead.DHS_Assigned_To__r.Email)){
                     toUserIds.add(lead.DHS_Assigned_To__r.Email);
                }   
            }
        }
        return toUserIds;
    }
   
    /** @description Provides this DHS API member. */
    public void sendMessage(){
        List<String> toAddressList = new list<String>();
        toAddressList.addAll(fetchToAddressOfCase(caseRecord,currentUser));
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
     
    /** @description Provides this DHS API member. */
    public void fetchCaseMessages(){
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
        
        String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        queryForNextRecords = query + ' WHERE '+whereCond;
        query = query + ' WHERE '+whereCond+' Order by Name asc Limit 200'; 
        string countQuery = 'Select Count() from DHS_Message__c WHERE '+ whereCond;
        totalRecordCount = database.countquery(Countquery, AccessLevel.USER_MODE);
        
        List<DHS_Message__c> msgs = database.query(query, AccessLevel.USER_MODE); 
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
        totalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
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
    
    /** @description Provides this DHS API member. */
    public void fetchLeadInformation(){
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
        
        String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+whereCond;
        list<DHS_Lead__c> leads = database.query(query, AccessLevel.USER_MODE);
        if(!leads.isEmpty()){
            leadRecord = leads[0]; 
            caseId = leadRecord.DHS_Case__c; 
            if(leadRecord.LeadType__c == 'Subject Interview (ESI/TESI)'){
                 isValidForRTAExtension = true;
                 leadRecordRTAExtension = new DHS_Lead_RTA_Extension__c();
                 List<DHS_Lead_RTA_Extension__c> leadRecordExtensions = new List<DHS_Lead_RTA_Extension__c>();
                 leadRecordExtensions = [Select Id, Foreign_Activities__c, Foreign_Contacts__c, Foreign_Travel1__c, Foreign_Travel2__c, DHS_Lead__c
                                         FROM DHS_Lead_RTA_Extension__c WHERE DHS_Lead__c =:leadRecord.Id WITH USER_MODE];
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
    public boolean toInsertleadRecordRTAExtension {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public pagereference completeleadaction(){
        leadRecord.Status__c = 'Completed';
        leadRecord.Hours_of_completion__c = hoursofleadcompletion;
        leadRecord.Minutes_of_completion__c = minutesofleadcompletion;
        if(leadRecord.QA_Rejected_Date__c != null){
            leadRecord.Status__c = 'QA Rejection Complete';
            leadRecord.QA_Rejection_Complete_Date__c = date.today(); 
        }
        Database.update(leadRecord, AccessLevel.USER_MODE);
        //database.update(leadRecord,false,AccessLevel.USER_MODE);
        if(isValidForRTAExtension){
            if(toInsertleadRecordRTAExtension){
                Database.insert(leadRecordRTAExtension, AccessLevel.USER_MODE);
                //database.insert(leadRecordRTAExtension);
            }else{
                Database.update(leadRecordRTAExtension, AccessLevel.USER_MODE);
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
    
    /** @description Provides this DHS API member. */
    public string errorMessage {get;set;}
    /** @description Provides this DHS API member. */
    public void updateleadaction(){
        try{
            errorMessage = null;
            Database.update(leadRecord, AccessLevel.USER_MODE);
            //database.update(leadRecord,false,AccessLevel.USER_MODE);  
            if(isValidForRTAExtension){
                if(toInsertleadRecordRTAExtension){
                    Database.insert(leadRecordRTAExtension, AccessLevel.USER_MODE);
                    //database.insert(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
                }else{
                    Database.update(leadRecordRTAExtension, AccessLevel.USER_MODE);
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
    
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public pagereference reviewcompletedaction(){
        leadRecord.Status__c = 'QA Review Completed';
        Database.update(leadRecord, AccessLevel.USER_MODE);
        //database.update(leadRecord,false,AccessLevel.USER_MODE);
        if(isValidForRTAExtension){
            if(toInsertleadRecordRTAExtension){
                Database.insert(leadRecordRTAExtension, AccessLevel.USER_MODE);
                //database.insert(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
            }else{
                Database.update(leadRecordRTAExtension, AccessLevel.USER_MODE);
                //database.update(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
            }
        }
        PageReference redirectPage = Page.DHSCasedetail;
        redirectPage.getParameters().put('id',leadRecord.DHS_Case__c);
        redirectPage.getParameters().put('tab','Leads');
        redirectPage.setRedirect(true);
        return redirectPage; 
    }
    
    /** @description Provides this DHS API member. */
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
    
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public pagereference deleteleadaction(){
        Database.delete(leadRecord, AccessLevel.USER_MODE);
        //database.delete(leadRecord,false,AccessLevel.USER_MODE);
        PageReference redirectPage = Page.DHSLeaddashboard;
        redirectPage.setRedirect(true);
        return redirectPage;     
    }
    
    /** @description Provides this DHS API member. */
    public void dummyaction(){
    
    }
    
     /** @description Provides this DHS API member. */
     public void createdocumentrequestaction(){
        documentRequest.Status__c = 'Documents Requested';
         Database.insert(documentRequest, AccessLevel.USER_MODE);
        //database.insert(documentRequest,false,AccessLevel.USER_MODE);
        documentRequest = new DHS_Document_Request__c();
        documentRequest.To_Address__c = leadRecord.DHS_Contact__r.Email__c;
        documentRequest.DHS_Lead__c = leadId;
        fetchDocumentRequests();
    }
    
    /** @description Provides this DHS API member. */
    public  void fetchDocumentRequests(){
        documentrequestsmap = new Map<Id,DHS_Document_Request__c>([SELECT Id,Name,Status__c,To_Address__c, Additional_To_Address__c, Investigator_Comments__c FROM DHS_Document_Request__c WHERE DHS_Lead__c=:leadId WITH USER_MODE order by createddate desc ]);
        documentrequestnattachmentsmap = new Map<Id,List<Attachment>>();
        documentrequestids = new list<string>();
        for(string docId: documentrequestsmap.keyset()){
            documentrequestids.add(docId);
            documentrequestnattachmentsmap.put(docId,new list<Attachment> {});
        }
        List<Attachment> attachments = [Select id, name, parentid, description from Attachment where parentid=:documentrequestsmap.keyset() WITH USER_MODE];
        for(Attachment att: attachments){
            if(!documentrequestnattachmentsmap.containsKey(att.parentid)){
                documentrequestnattachmentsmap.put(att.parentid, new list<Attachment> {att});
            }else{
                documentrequestnattachmentsmap.get(att.parentid).add(att);
            }
        }
    }
    
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public PageReference applyforwaiveraction(){
        leadRecord.Status__c = 'Applied For Waiver';
        leadRecord.Reason_for_Waiver__c = waiverreason;
        Database.update(leadRecord, AccessLevel.USER_MODE);
        //database.update(leadRecord,false,AccessLevel.USER_MODE);
        if(isValidForRTAExtension){
            if(toInsertleadRecordRTAExtension){
                Database.insert(leadRecordRTAExtension, AccessLevel.USER_MODE);
                //database.insert(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
            }else{
                Database.update(leadRecordRTAExtension, AccessLevel.USER_MODE);
                //database.update(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
            }
        }
        DHS_Case_History__c ch = new DHS_Case_History__c();
        ch.DHS_Case__c = leadRecord.DHS_Case__c;
        ch.DHS_Added_By__c = userinfo.getuserid();
        ch.Value__c = 'Applied For Waiver - '+ waiverreason;
        Database.insert(ch, AccessLevel.USER_MODE);
        //database.Insert(ch,false,AccessLevel.USER_MODE);
        PageReference redirectPage = Page.DHSLeaddashboard;
        redirectPage.setRedirect(true);
        return redirectPage;  
        
        
    }
    
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public pagereference rejectleadaction(){
        leadRecord.Status__c = 'QA Rejected';
        leadRecord.QA_Rejection_Comments__c = leadrejectionreason;
        leadRecord.QA_Rejected_Date__c = system.today();
        Database.update(leadRecord, AccessLevel.USER_MODE);
        //database.update(leadRecord,false,AccessLevel.USER_MODE);
        if(isValidForRTAExtension){
            if(toInsertleadRecordRTAExtension){
                Database.insert(leadRecordRTAExtension, AccessLevel.USER_MODE);
                //database.insert(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
            }else{
                Database.update(leadRecordRTAExtension, AccessLevel.USER_MODE);
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
    
    /** @description Provides this DHS API member. */
    public void reopenleadaction(){
        leadRecord.Status__c = 'In-Progress';
        Database.update(leadRecord, AccessLevel.USER_MODE);
        //database.update(leadRecord,false,AccessLevel.USER_MODE);
    }
    
    /*public string sourcefieldtopopulatenarrative{get;set;}
    public string sourcefieldvaluetopopulatenarrative{get;set;}
    public void populatenarrativeaction(){

       
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

        list<ROI_Report_Matrix__c> reportMatrices = database.query(query, AccessLevel.USER_MODE);

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

        list<ROI_Report_Matrix__c> reportMatrices = database.query(query, AccessLevel.USER_MODE);
        
        for(ROI_Report_Matrix__c roi: reportMatrices){
            Map<String,String> mergeFieldsMap = new Map<String,String>();
            Pattern p = Pattern.compile('\\%.+?\\%');
            String unMergedText = roi.Text_To_Populate__c;
            Matcher m = p.matcher(unMergedText);
            while(m.find()) {

                mergeFieldsMap.put(m.group(0),string.valueof(leadRecord.get(m.group(0).replaceAll('%',''))));
            }

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
    
    /** @description Provides this DHS API member. */
    public void autoSaveLeadAction(){
     if(leadRecord.LeadType__c == 'Subject Interview (ESI/TESI)'){
         try{
             Database.update(leadRecordRTAExtension, AccessLevel.USER_MODE);
         }catch(exception e){
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to save the lead extension.'));
         }
        
     }
        
        Database.update(leadRecord, AccessLevel.USER_MODE);
        //database.update(leadRecord,false,AccessLevel.USER_MODE);
    }
    

    
    /** @description Provides this DHS API member. */
    public void handlePrev(){
            messages = new list<DHS_Message__c>();
        
        PageNumber --;
        string query = queryForNextRecords + ' AND Name <:firstRecordName Order by Name desc Limit 200';    
        list<DHS_Message__c> msgs = database.query(query, AccessLevel.USER_MODE);
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
    /** @description Provides this DHS API member. */
    public void handleNext(){
        messages = new list<DHS_Message__c>();
        PageNumber ++ ;
        string query = queryForNextRecords + ' AND Name >:lastRecordName Order by Name asc Limit 200';      
        list<DHS_Message__c> msgs = database.query(query, AccessLevel.USER_MODE);
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
        if(pageNumber == totalPages){
            disablePrev = false;   
            disableNext = true;
        }else{
            disablePrev = false;
            disableNext = false;
        }
    } 
    
    /** @description Provides this DHS API member. */
    public DHS_Message__c selectedMessage { get; set; }
    /** @description Provides this DHS API member. */
    public String modalAction { get; set; }
    /** @description Provides this DHS API member. */
    public Id selectedMessageId { get; set; }

    // Called by actionFunction before opening modal
    /** @description Provides this DHS API member. */
    public void openModal() {
        if(modalAction == 'edit' && selectedMessageId != null){
            selectedMessage = [
                SELECT Id, Subject__c, Message_Body__c 
                FROM DHS_Message__c 
                WHERE Id = :selectedMessageId
                WITH USER_MODE LIMIT 1
            ];
        }
    }

    /** @description Provides this DHS API member. */
    public void updateMessage() {
        if(selectedMessage != null){
            Database.update(selectedMessage, AccessLevel.USER_MODE);
        }
    }

    /** @description Provides this DHS API member. */
    public void deleteMessage() {
        if(selectedMessageId != null){
            try {
                Database.delete([SELECT Id FROM DHS_Message__c WHERE Id = :selectedMessageId WITH USER_MODE LIMIT 1], AccessLevel.USER_MODE);
                // Refresh messages after deletion
                fetchCaseMessages();
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to delete the message.'));
            }
        } else {
        }
    }
    /**
     * @description Provides this DHS API member.
     * @param dt Method parameter.
     * @return The requested result.
     */
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