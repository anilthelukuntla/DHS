/** Retains the existing MicrosoftGraphLifecycleService integration and application behavior. */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.ApexDoc, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.NcssCount, PMD.NcssMethodCount, PMD.StdCyclomaticComplexity')
public without sharing class MicrosoftGraphLifecycleService {
    public static void processNotification(String notificationJson) {
        Map<String, Object> notification =
            (Map<String, Object>) JSON.deserializeUntyped(
                notificationJson
            );
        Id scheduleId = idValue(
            notification.get('_salesforceScheduleId')
        );
        String resource = stringValue(notification.get('resource'));
        String changeType = stringValue(
            notification.get('changeType')
        );
        String lifecycleEvent = stringValue(
            notification.get('lifecycleEvent')
        );

        try {
            if (String.isNotBlank(lifecycleEvent)) {
                processSubscriptionLifecycle(
                    stringValue(notification.get('subscriptionId')),
                    lifecycleEvent
                );
            } else if (
                containsIgnoreCase(resource, '/events/') ||
                containsIgnoreCase(resource, '/events')
            ) {
                syncCalendarEvent(
                    scheduleId,
                    resource,
                    changeType,
                    mapValue(notification, 'resourceData')
                );
            } else if (
                containsIgnoreCase(resource, '/transcripts') ||
                containsIgnoreCase(resource, '/recordings')
            ) {
                syncArtifacts(scheduleId);
            } else if (
                containsIgnoreCase(resource, 'meetingCallEvents')
            ) {
                syncMeetingCallEvent(
                    scheduleId,
                    mapValue(notification, 'resourceData'),
                    notificationJson
                );
            } else if (
                containsIgnoreCase(resource, 'callRecords')
            ) {
                if (scheduleId != null) {
                    System.enqueueJob(
                        new MicrosoftGraphMeetingSyncQueueable(
                            scheduleId
                        )
                    );
                }
            }
        } catch (Exception exceptionValue) {
            recordScheduleError(scheduleId, exceptionValue.getMessage());
            throw exceptionValue;
        }
    }

    public static void syncMeeting(Id scheduleId) {
        syncAttendance(scheduleId);
    }

    public static void syncArtifactsForMeeting(Id scheduleId) {
        syncArtifacts(scheduleId);
    }

    private static void syncCalendarEvent(
        Id scheduleId,
        String resource,
        String changeType,
        Map<String, Object> resourceData
    ) {
        String eventId = resourceData == null
            ? null
            : stringValue(resourceData.get('id'));
        if (String.isBlank(eventId)) {
            eventId = lastPathIdentifier(resource, 'events');
        }

        MS_Team_Call_Schedule__c schedule =
            findSchedule(scheduleId, eventId);
        if (schedule == null) {
            return;
        }
        if (changeType == 'deleted') {
            schedule.Status__c = 'Deleted';
            schedule.Meeting_Ended_At__c = System.now();
            schedule.Last_Synchronized_At__c = System.now();
            schedule.Last_Graph_Error__c = null;
            update schedule;
            return;
        }

        String path = '/me/events/' +
            MicrosoftGraphClient.encodePath(schedule.Graph_Event_ID__c) +
            '?%24select=id,subject,body,start,end,attendees,isCancelled,' +
            'changeKey,lastModifiedDateTime,webLink,isOnlineMeeting,' +
            'onlineMeeting,organizer';
        HttpResponse response = MicrosoftGraphClient.get(path);
        if (response.getStatusCode() == 404) {
            schedule.Status__c = 'Deleted';
            schedule.Meeting_Ended_At__c = System.now();
            schedule.Last_Synchronized_At__c = System.now();
            update schedule;
            return;
        }
        Map<String, Object> eventData =
            MicrosoftGraphClient.requireJson(
                response,
                new Set<Integer>{ 200 },
                'Calendar event synchronization'
            );

        schedule.Subject__c = stringValue(eventData.get('subject'));
        schedule.Graph_Change_Key__c =
            stringValue(eventData.get('changeKey'));
        schedule.Graph_Last_Modified__c =
            MicrosoftGraphClient.parseDateTime(
                eventData.get('lastModifiedDateTime')
            );
        schedule.Web_Link__c = stringValue(eventData.get('webLink'));
        schedule.Is_Online_Meeting__c =
            eventData.get('isOnlineMeeting') == true;
        Map<String, Object> startValue = mapValue(eventData, 'start');
        Map<String, Object> endValue = mapValue(eventData, 'end');
        if (startValue != null) {
            schedule.Start_Date_Time__c =
                stringValue(startValue.get('dateTime'));
            schedule.Microsoft_Time_Zone__c =
                stringValue(startValue.get('timeZone'));
        }
        if (endValue != null) {
            schedule.End_Date_Time__c =
                stringValue(endValue.get('dateTime'));
        }
        Map<String, Object> onlineMeeting =
            mapValue(eventData, 'onlineMeeting');
        if (onlineMeeting != null) {
            schedule.Teams_Join_URL__c =
                stringValue(onlineMeeting.get('joinUrl'));
        }
        if (eventData.get('isCancelled') == true) {
            schedule.Status__c = 'Cancelled';
            schedule.Cancelled_At__c = System.now();
        }
        schedule.Last_Synchronized_At__c = System.now();
        schedule.Last_Graph_Error__c = null;
        update schedule;
        syncInvitationResponses(
            schedule.Id,
            listValue(eventData, 'attendees')
        );
    }

    private static void syncInvitationResponses(
        Id scheduleId,
        List<Object> attendees
    ) {
        if (attendees == null) {
            return;
        }
        List<MS_Team_Meeting_Participant__c> participants =
            new List<MS_Team_Meeting_Participant__c>();
        for (Object attendeeValue : attendees) {
            Map<String, Object> attendee =
                (Map<String, Object>) attendeeValue;
            Map<String, Object> emailAddress =
                mapValue(attendee, 'emailAddress');
            String email = emailAddress == null
                ? null
                : stringValue(emailAddress.get('address'));
            if (String.isBlank(email)) {
                continue;
            }
            Map<String, Object> responseStatus =
                mapValue(attendee, 'status');
            participants.add(
                new MS_Team_Meeting_Participant__c(
                    External_Key__c = participantKey(
                        scheduleId,
                        email
                    ),
                    Meeting_Schedule__c = scheduleId,
                    Email__c = email.toLowerCase(),
                    Display_Name__c = emailAddress == null
                        ? null
                        : stringValue(emailAddress.get('name')),
                    Attendee_Type__c =
                        stringValue(attendee.get('type')),
                    Invitation_Response__c = responseStatus == null
                        ? null
                        : stringValue(responseStatus.get('response')),
                    Invitation_Response_At__c = responseStatus == null
                        ? null
                        : MicrosoftGraphClient.parseDateTime(
                            responseStatus.get('time')
                        )
                )
            );
        }
        if (!participants.isEmpty()) {
            upsert participants External_Key__c;
        }
    }

    private static void syncMeetingCallEvent(
        Id scheduleId,
        Map<String, Object> resourceData,
        String rawNotification
    ) {
        if (scheduleId == null) {
            return;
        }
        String eventText = (
            resourceData == null
                ? rawNotification
                : JSON.serialize(resourceData)
        ).toLowerCase();
        MS_Team_Call_Schedule__c schedule =
            findSchedule(scheduleId, null);
        if (schedule == null) {
            return;
        }
        if (eventText.contains('callstarted')) {
            schedule.Status__c = 'In Progress';
            schedule.Meeting_Started_At__c =
                firstDateTime(resourceData, System.now());
        } else if (eventText.contains('callended')) {
            schedule.Status__c = 'Completed';
            schedule.Meeting_Ended_At__c =
                firstDateTime(resourceData, System.now());
        }
        schedule.Last_Synchronized_At__c = System.now();
        schedule.Last_Graph_Error__c = null;
        update schedule;
        if (eventText.contains('callended')) {
            System.enqueueJob(
                new MicrosoftGraphMeetingSyncQueueable(schedule.Id)
            );
        }
    }

    private static void syncAttendance(Id scheduleId) {
        MS_Team_Call_Schedule__c schedule =
            findSchedule(scheduleId, null);
        if (
            schedule == null ||
            String.isBlank(schedule.Online_Meeting_ID__c)
        ) {
            return;
        }
        String meetingId = MicrosoftGraphClient.encodePath(
            schedule.Online_Meeting_ID__c
        );
        Map<String, Object> listResponse =
            MicrosoftGraphClient.requireJson(
                MicrosoftGraphClient.get(
                    '/me/onlineMeetings/' + meetingId +
                    '/attendanceReports'
                ),
                new Set<Integer>{ 200 },
                'Attendance report listing'
            );
        List<Object> reports = listValue(listResponse, 'value');
        if (reports == null || reports.isEmpty()) {
            return;
        }
        Map<String, Object> report =
            (Map<String, Object>) reports[reports.size() - 1];
        String reportId = stringValue(report.get('id'));
        Map<String, Object> reportData =
            MicrosoftGraphClient.requireJson(
                MicrosoftGraphClient.get(
                    '/me/onlineMeetings/' + meetingId +
                    '/attendanceReports/' +
                    MicrosoftGraphClient.encodePath(reportId) +
                    '?%24expand=attendanceRecords'
                ),
                new Set<Integer>{ 200 },
                'Attendance report retrieval'
            );
        applyAttendance(schedule, reportId, reportData);
    }

    private static void applyAttendance(
        MS_Team_Call_Schedule__c schedule,
        String reportId,
        Map<String, Object> reportData
    ) {
        Datetime meetingStart = MicrosoftGraphClient.parseDateTime(
            reportData.get('meetingStartDateTime')
        );
        Datetime meetingEnd = MicrosoftGraphClient.parseDateTime(
            reportData.get('meetingEndDateTime')
        );
        schedule.Attendance_Report_ID__c = reportId;
        schedule.Meeting_Started_At__c = meetingStart;
        schedule.Meeting_Ended_At__c = meetingEnd;
        if (meetingStart != null && meetingEnd != null) {
            schedule.Actual_Duration_Seconds__c =
                (meetingEnd.getTime() - meetingStart.getTime()) / 1000;
            schedule.Status__c = 'Completed';
        }
        schedule.Last_Synchronized_At__c = System.now();
        schedule.Last_Graph_Error__c = null;
        update schedule;

        List<Object> records =
            listValue(reportData, 'attendanceRecords');
        if (records == null) {
            return;
        }
        List<MS_Team_Meeting_Participant__c> participants =
            new List<MS_Team_Meeting_Participant__c>();
        Map<String, List<Object>> intervalsByKey =
            new Map<String, List<Object>>();
        for (Object recordValue : records) {
            Map<String, Object> attendance =
                (Map<String, Object>) recordValue;
            String email = stringValue(attendance.get('emailAddress'));
            Map<String, Object> identity =
                mapValue(attendance, 'identity');
            String identityId = identity == null
                ? null
                : stringValue(identity.get('id'));
            String identityName = identity == null
                ? null
                : stringValue(identity.get('displayName'));
            String participantIdentity = String.isNotBlank(email)
                ? email
                : String.isNotBlank(identityId)
                    ? identityId
                    : identityName;
            if (String.isBlank(participantIdentity)) {
                continue;
            }
            String externalKey = participantKey(
                schedule.Id,
                participantIdentity
            );
            List<Object> intervals =
                listValue(attendance, 'attendanceIntervals');
            Datetime firstJoined;
            Datetime lastLeft;
            if (intervals != null) {
                for (Object intervalValue : intervals) {
                    Map<String, Object> interval =
                        (Map<String, Object>) intervalValue;
                    Datetime joined =
                        MicrosoftGraphClient.parseDateTime(
                            interval.get('joinDateTime')
                        );
                    Datetime left =
                        MicrosoftGraphClient.parseDateTime(
                            interval.get('leaveDateTime')
                        );
                    if (
                        joined != null &&
                        (firstJoined == null || joined < firstJoined)
                    ) {
                        firstJoined = joined;
                    }
                    if (
                        left != null &&
                        (lastLeft == null || left > lastLeft)
                    ) {
                        lastLeft = left;
                    }
                }
            }
            participants.add(
                new MS_Team_Meeting_Participant__c(
                    External_Key__c = externalKey,
                    Meeting_Schedule__c = schedule.Id,
                    Email__c = email,
                    Display_Name__c = identityName,
                    Entra_User_ID__c = identityId,
                    Role__c = stringValue(attendance.get('role')),
                    Actually_Joined__c = true,
                    Total_Attendance_Seconds__c =
                        decimalValue(
                            attendance.get(
                                'totalAttendanceInSeconds'
                            )
                        ),
                    First_Joined_At__c = firstJoined,
                    Last_Left_At__c = lastLeft
                )
            );
            intervalsByKey.put(externalKey, intervals);
        }
        if (participants.isEmpty()) {
            return;
        }
        upsert participants External_Key__c;
        Map<String, Id> participantIdsByKey = new Map<String, Id>();
        for (MS_Team_Meeting_Participant__c participant : [
            SELECT Id, External_Key__c
            FROM MS_Team_Meeting_Participant__c
            WHERE External_Key__c IN :intervalsByKey.keySet()
        ]) {
            participantIdsByKey.put(
                participant.External_Key__c,
                participant.Id
            );
        }
        List<MS_Team_Attendance_Interval__c> intervalRecords =
            new List<MS_Team_Attendance_Interval__c>();
        for (String participantKeyValue : intervalsByKey.keySet()) {
            List<Object> intervals = intervalsByKey.get(
                participantKeyValue
            );
            if (intervals == null) {
                continue;
            }
            Integer position = 0;
            for (Object intervalValue : intervals) {
                position++;
                Map<String, Object> interval =
                    (Map<String, Object>) intervalValue;
                intervalRecords.add(
                    new MS_Team_Attendance_Interval__c(
                        External_Key__c = hashValue(
                            reportId + '|' +
                            participantKeyValue + '|' +
                            position
                        ),
                        Participant__c =
                            participantIdsByKey.get(
                                participantKeyValue
                            ),
                        Attendance_Report_ID__c = reportId,
                        Joined_At__c =
                            MicrosoftGraphClient.parseDateTime(
                                interval.get('joinDateTime')
                            ),
                        Left_At__c =
                            MicrosoftGraphClient.parseDateTime(
                                interval.get('leaveDateTime')
                            ),
                        Duration_Seconds__c =
                            decimalValue(
                                interval.get('durationInSeconds')
                            )
                    )
                );
            }
        }
        if (!intervalRecords.isEmpty()) {
            upsert intervalRecords External_Key__c;
        }
    }

    private static void syncArtifacts(Id scheduleId) {
        MS_Team_Call_Schedule__c schedule =
            findSchedule(scheduleId, null);
        if (
            schedule == null ||
            String.isBlank(schedule.Online_Meeting_ID__c)
        ) {
            return;
        }
        String meetingId = MicrosoftGraphClient.encodePath(
            schedule.Online_Meeting_ID__c
        );
        List<MS_Team_Meeting_Artifact__c> artifacts =
            new List<MS_Team_Meeting_Artifact__c>();
        artifacts.addAll(
            loadArtifactType(
                schedule,
                meetingId,
                'Transcript',
                'transcripts',
                'transcriptContentUrl'
            )
        );
        artifacts.addAll(
            loadArtifactType(
                schedule,
                meetingId,
                'Recording',
                'recordings',
                'recordingContentUrl'
            )
        );
        if (!artifacts.isEmpty()) {
            upsert artifacts External_Key__c;
        }
        schedule.Last_Synchronized_At__c = System.now();
        schedule.Last_Graph_Error__c = null;
        update schedule;
    }

    private static List<MS_Team_Meeting_Artifact__c> loadArtifactType(
        MS_Team_Call_Schedule__c schedule,
        String meetingId,
        String artifactType,
        String collectionName,
        String contentUrlProperty
    ) {
        Map<String, Object> responseData =
            MicrosoftGraphClient.requireJson(
                MicrosoftGraphClient.get(
                    '/me/onlineMeetings/' + meetingId +
                    '/' + collectionName
                ),
                new Set<Integer>{ 200 },
                artifactType + ' listing'
            );
        List<Object> values = listValue(responseData, 'value');
        if (values == null || values.isEmpty()) {
            return new List<MS_Team_Meeting_Artifact__c>();
        }
        List<MS_Team_Meeting_Artifact__c> artifacts =
            new List<MS_Team_Meeting_Artifact__c>();
        for (Object value : values) {
            Map<String, Object> artifact =
                (Map<String, Object>) value;
            String artifactId = stringValue(artifact.get('id'));
            if (String.isBlank(artifactId)) {
                continue;
            }
            artifacts.add(
                new MS_Team_Meeting_Artifact__c(
                    External_Key__c = hashValue(
                        schedule.Id + '|' +
                        artifactType + '|' + artifactId
                    ),
                    Meeting_Schedule__c = schedule.Id,
                    Artifact_Type__c = artifactType,
                    Graph_Artifact_ID__c = artifactId,
                    Content_URL__c =
                        stringValue(
                            artifact.get(contentUrlProperty)
                        ),
                    Content_Correlation_ID__c =
                        stringValue(
                            artifact.get('contentCorrelationId')
                        ),
                    Created_At__c =
                        MicrosoftGraphClient.parseDateTime(
                            artifact.get('createdDateTime')
                        ),
                    Ended_At__c =
                        MicrosoftGraphClient.parseDateTime(
                            artifact.get('endDateTime')
                        ),
                    Processing_Status__c = 'Available',
                    Last_Error__c = null
                )
            );
        }
        return artifacts;
    }

    private static void processSubscriptionLifecycle(
        String graphSubscriptionId,
        String lifecycleEvent
    ) {
        List<MS_Graph_Subscription__c> subscriptions = [
            SELECT Id, Status__c
            FROM MS_Graph_Subscription__c
            WHERE Graph_Subscription_ID__c = :graphSubscriptionId
            LIMIT 1
        ];
        if (subscriptions.isEmpty()) {
            return;
        }
        MS_Graph_Subscription__c subscription = subscriptions[0];
        if (lifecycleEvent == 'subscriptionRemoved') {
            subscription.Status__c = 'Removed';
        } else if (lifecycleEvent == 'reauthorizationRequired') {
            subscription.Status__c = 'Reauthorization Required';
        } else if (lifecycleEvent == 'missed') {
            subscription.Status__c = 'Missed Notifications';
        }
        update subscription;
    }

    private static MS_Team_Call_Schedule__c findSchedule(
        Id scheduleId,
        String eventId
    ) {
        List<MS_Team_Call_Schedule__c> schedules;
        if (scheduleId != null) {
            schedules = [
                SELECT
                    Id,
                    Graph_Event_ID__c,
                    Online_Meeting_ID__c,
                    Status__c,
                    Meeting_Started_At__c,
                    Meeting_Ended_At__c,
                    Actual_Duration_Seconds__c,
                    Attendance_Report_ID__c,
                    Subject__c,
                    Start_Date_Time__c,
                    End_Date_Time__c,
                    Microsoft_Time_Zone__c,
                    Graph_Change_Key__c,
                    Graph_Last_Modified__c,
                    Web_Link__c,
                    Teams_Join_URL__c,
                    Is_Online_Meeting__c,
                    Cancelled_At__c,
                    Last_Synchronized_At__c,
                    Last_Graph_Error__c
                FROM MS_Team_Call_Schedule__c
                WHERE Id = :scheduleId
                LIMIT 1
            ];
        } else if (String.isNotBlank(eventId)) {
            schedules = [
                SELECT
                    Id,
                    Graph_Event_ID__c,
                    Online_Meeting_ID__c,
                    Status__c,
                    Meeting_Started_At__c,
                    Meeting_Ended_At__c,
                    Actual_Duration_Seconds__c,
                    Attendance_Report_ID__c,
                    Subject__c,
                    Start_Date_Time__c,
                    End_Date_Time__c,
                    Microsoft_Time_Zone__c,
                    Graph_Change_Key__c,
                    Graph_Last_Modified__c,
                    Web_Link__c,
                    Teams_Join_URL__c,
                    Is_Online_Meeting__c,
                    Cancelled_At__c,
                    Last_Synchronized_At__c,
                    Last_Graph_Error__c
                FROM MS_Team_Call_Schedule__c
                WHERE Graph_Event_ID__c = :eventId
                LIMIT 1
            ];
        } else {
            return null;
        }
        return schedules.isEmpty() ? null : schedules[0];
    }

    private static void recordScheduleError(
        Id scheduleId,
        String message
    ) {
        if (scheduleId == null) {
            return;
        }
        update new MS_Team_Call_Schedule__c(
            Id = scheduleId,
            Status__c = 'Sync Failed',
            Last_Graph_Error__c = message,
            Last_Synchronized_At__c = System.now()
        );
    }

    private static String participantKey(
        Id scheduleId,
        String identityValue
    ) {
        return hashValue(
            String.valueOf(scheduleId) + '|' +
            identityValue.trim().toLowerCase()
        );
    }

    private static String hashValue(String value) {
        return EncodingUtil.convertToHex(
            Crypto.generateDigest('SHA-256', Blob.valueOf(value))
        ).toLowerCase();
    }

    private static String lastPathIdentifier(
        String resource,
        String segment
    ) {
        if (String.isBlank(resource)) {
            return null;
        }
        String marker = '/' + segment + '/';
        Integer startPosition =
            resource.toLowerCase().indexOf(marker.toLowerCase());
        if (startPosition < 0) {
            return null;
        }
        String remainder = resource.substring(
            startPosition + marker.length()
        );
        Integer slashPosition = remainder.indexOf('/');
        return slashPosition < 0
            ? remainder
            : remainder.substring(0, slashPosition);
    }

    private static Datetime firstDateTime(
        Map<String, Object> data,
        Datetime fallbackValue
    ) {
        if (data != null) {
            for (String key : new List<String>{
                'eventDateTime',
                'startDateTime',
                'endDateTime',
                'createdDateTime'
            }) {
                Datetime parsed =
                    MicrosoftGraphClient.parseDateTime(data.get(key));
                if (parsed != null) {
                    return parsed;
                }
            }
        }
        return fallbackValue;
    }

    private static Boolean containsIgnoreCase(
        String source,
        String value
    ) {
        return source != null &&
            source.toLowerCase().contains(value.toLowerCase());
    }

    private static Map<String, Object> mapValue(
        Map<String, Object> source,
        String key
    ) {
        return source == null || source.get(key) == null
            ? null
            : (Map<String, Object>) source.get(key);
    }

    private static List<Object> listValue(
        Map<String, Object> source,
        String key
    ) {
        return source == null || source.get(key) == null
            ? null
            : (List<Object>) source.get(key);
    }

    private static String stringValue(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    private static Id idValue(Object value) {
        if (value == null || String.isBlank(String.valueOf(value))) {
            return null;
        }
        try {
            return (Id) String.valueOf(value);
        } catch (Exception ignored) {
            return null;
        }
    }

    private static Decimal decimalValue(Object value) {
        return value == null
            ? null
            : Decimal.valueOf(String.valueOf(value));
    }
}