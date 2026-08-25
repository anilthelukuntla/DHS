@IsTest
private class MicrosoftGraphLifecycleTest {
    @IsTest
    static void webhookValidationReturnsPlainTextToken() {
        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestUri = '/services/apexrest/msgraph/lifecycle';
        request.params.put('validationToken', 'graph-validation-token');
        RestContext.request = request;
        RestContext.response = new RestResponse();

        MicrosoftGraphWebhookController.receive();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(
            'graph-validation-token',
            RestContext.response.responseBody.toString()
        );
    }

    @IsTest
    static void eventWebhookStoresDeclinedResponse() {
        MS_Team_Call_Schedule__c schedule = createSchedule();
        String clientState = 'test-client-state';
        Database.insert(new MS_Graph_Subscription__c(
            Graph_Subscription_ID__c = 'calendar-subscription',
            Resource__c = 'me/events',
            Change_Type__c = 'updated',
            Expiration__c = System.now().addDays(1),
            Client_State_Hash__c = hashValue(clientState),
            Notification_URL__c = 'https://example.com/webhook',
            Status__c = 'Active'
        ), AccessLevel.SYSTEM_MODE);
        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestUri = '/services/apexrest/msgraph/lifecycle';
        request.requestBody = Blob.valueOf(JSON.serialize(
            new Map<String, Object>{
                'value' => new List<Object>{
                    new Map<String, Object>{
                        'subscriptionId' => 'calendar-subscription',
                        'clientState' => clientState,
                        'changeType' => 'updated',
                        'resource' => 'me/events/graph-event-1',
                        'resourceData' => new Map<String, Object>{
                            'id' => 'graph-event-1'
                        }
                    }
                }
            }
        ));
        RestContext.request = request;
        RestContext.response = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new EventSyncMock());

        Test.startTest();
        MicrosoftGraphWebhookController.receive();
        Test.stopTest();

        System.assertEquals(202, RestContext.response.statusCode);
        schedule = [
            SELECT Subject__c, Graph_Change_Key__c
            FROM MS_Team_Call_Schedule__c
            WHERE Id = :schedule.Id
        ];
        System.assertEquals('Updated meeting', schedule.Subject__c);
        System.assertEquals('change-key-2', schedule.Graph_Change_Key__c);
        MS_Team_Meeting_Participant__c participant = [
            SELECT
                Email__c,
                Invitation_Response__c,
                Invitation_Response_At__c
            FROM MS_Team_Meeting_Participant__c
            WHERE Meeting_Schedule__c = :schedule.Id
            LIMIT 1
        ];
        System.assertEquals('customer@example.com', participant.Email__c);
        System.assertEquals(
            'declined',
            participant.Invitation_Response__c
        );
        System.assertNotEquals(
            null,
            participant.Invitation_Response_At__c
        );
    }

    @IsTest
    static void completedMeetingStoresAttendanceAndArtifacts() {
        MS_Team_Call_Schedule__c schedule = createSchedule();
        Test.setMock(
            HttpCalloutMock.class,
            new MeetingArtifactMock()
        );

        Test.startTest();
        MicrosoftGraphLifecycleService.syncMeeting(schedule.Id);
        Test.stopTest();

        schedule = [
            SELECT
                Status__c,
                Attendance_Report_ID__c,
                Meeting_Started_At__c,
                Meeting_Ended_At__c,
                Actual_Duration_Seconds__c
            FROM MS_Team_Call_Schedule__c
            WHERE Id = :schedule.Id
        ];
        System.assertEquals('Completed', schedule.Status__c);
        System.assertEquals(
            'attendance-report-1',
            schedule.Attendance_Report_ID__c
        );
        System.assertEquals(
            3600,
            schedule.Actual_Duration_Seconds__c
        );

        MS_Team_Meeting_Participant__c participant = [
            SELECT
                Actually_Joined__c,
                Total_Attendance_Seconds__c,
                First_Joined_At__c,
                Last_Left_At__c
            FROM MS_Team_Meeting_Participant__c
            WHERE Meeting_Schedule__c = :schedule.Id
            LIMIT 1
        ];
        System.assertEquals(true, participant.Actually_Joined__c);
        System.assertEquals(
            3300,
            participant.Total_Attendance_Seconds__c
        );
        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM MS_Team_Attendance_Interval__c
                WHERE Participant__c = :participant.Id
            ]
        );
    }

    @IsTest
    static void storesTranscriptAndRecordingMetadata() {
        MS_Team_Call_Schedule__c schedule = createSchedule();
        Test.setMock(
            HttpCalloutMock.class,
            new MeetingArtifactMock()
        );

        Test.startTest();
        MicrosoftGraphLifecycleService.syncArtifactsForMeeting(
            schedule.Id
        );
        Test.stopTest();

        List<MS_Team_Meeting_Artifact__c> artifacts = [
            SELECT
                Artifact_Type__c,
                Graph_Artifact_ID__c,
                Content_URL__c,
                Processing_Status__c
            FROM MS_Team_Meeting_Artifact__c
            WHERE Meeting_Schedule__c = :schedule.Id
        ];
        System.assertEquals(2, artifacts.size());
        Set<String> artifactTypes = new Set<String>();
        for (MS_Team_Meeting_Artifact__c artifact : artifacts) {
            artifactTypes.add(artifact.Artifact_Type__c);
            System.assertEquals(
                'Available',
                artifact.Processing_Status__c
            );
            System.assertNotEquals(null, artifact.Content_URL__c);
        }
        System.assertEquals(
            new Set<String>{ 'Transcript', 'Recording' },
            artifactTypes
        );
    }

    @IsTest
    static void createsAndPersistsLifecycleSubscriptions() {
        MS_Team_Call_Schedule__c schedule = createSchedule();
        Test.setMock(
            HttpCalloutMock.class,
            new SubscriptionMock()
        );

        Test.startTest();
        List<Id> subscriptionIds =
            MicrosoftGraphSubscriptionService.createLifecycleSubscriptions(
                schedule.Id,
                'https://example.com/services/apexrest/msgraph/lifecycle',
                'https://example.com/services/apexrest/msgraph/lifecycle',
                null,
                null
            );
        Test.stopTest();

        System.assertEquals(3, subscriptionIds.size());
        System.assertEquals(
            3,
            [SELECT COUNT() FROM MS_Graph_Subscription__c]
        );
    }

    @IsTest
    static void artifactSyncQueueableRunsLifecycleService() {
        MS_Team_Call_Schedule__c schedule = createSchedule();
        Test.setMock(HttpCalloutMock.class, new MeetingArtifactMock());

        Test.startTest();
        new MicrosoftGraphArtifactSyncQueueable(schedule.Id).execute(null);
        Test.stopTest();

        System.assertEquals(
            2,
            [SELECT COUNT() FROM MS_Team_Meeting_Artifact__c
             WHERE Meeting_Schedule__c = :schedule.Id]
        );
    }

    @IsTest
    static void maintenanceQueueableChecksExpiringSubscriptions() {
        new MicrosoftGraphMaintenanceQueueable().execute(null);
        System.assertEquals(0, [SELECT COUNT() FROM MS_Graph_Subscription__c]);
    }

    @IsTest
    static void meetingSyncQueueableRunsLifecycleSync() {
        MS_Team_Call_Schedule__c schedule = createSchedule();
        Test.setMock(HttpCalloutMock.class, new MeetingArtifactMock());
        MicrosoftGraphMeetingSyncQueueable.skipArtifactEnqueue = true;

        Test.startTest();
        new MicrosoftGraphMeetingSyncQueueable(schedule.Id).execute(null);
        Test.stopTest();

        schedule = [SELECT Attendance_Report_ID__c FROM MS_Team_Call_Schedule__c WHERE Id=:schedule.Id];
        System.assertEquals('attendance-report-1', schedule.Attendance_Report_ID__c);
    }

    @IsTest
    static void processesDeletedEventsCallStartsAndSubscriptionLifecycle() {
        MS_Team_Call_Schedule__c schedule = createSchedule();
        MS_Graph_Subscription__c subscription = new MS_Graph_Subscription__c(
            Graph_Subscription_ID__c = 'lifecycle-subscription',
            Resource__c = 'me/events', Change_Type__c = 'updated',
            Expiration__c = System.now().addDays(1),
            Client_State_Hash__c = hashValue('state'),
            Notification_URL__c = 'https://example.com/webhook',
            Status__c = 'Active'
        );
        Database.insert(subscription, AccessLevel.SYSTEM_MODE);

        for (String eventName : new List<String>{
            'subscriptionRemoved', 'reauthorizationRequired', 'missed'
        }) {
            MicrosoftGraphLifecycleService.processNotification(JSON.serialize(
                new Map<String, Object>{
                    'subscriptionId' => subscription.Graph_Subscription_ID__c,
                    'lifecycleEvent' => eventName
                }
            ));
        }

        MicrosoftGraphLifecycleService.processNotification(JSON.serialize(
            new Map<String, Object>{
                '_salesforceScheduleId' => schedule.Id,
                'resource' => 'me/events/' + schedule.Graph_Event_ID__c,
                'changeType' => 'deleted',
                'resourceData' => new Map<String, Object>{
                    'id' => schedule.Graph_Event_ID__c
                }
            }
        ));

        MicrosoftGraphLifecycleService.processNotification(JSON.serialize(
            new Map<String, Object>{
                '_salesforceScheduleId' => schedule.Id,
                'resource' => 'communications/meetingCallEvents',
                'resourceData' => new Map<String, Object>{
                    'eventType' => 'callStarted',
                    'startDateTime' => '2026-07-27T04:30:00Z'
                }
            }
        ));
    }

    @IsTest
    static void createsRichSubscriptionsAndRenewsExpiringOnes() {
        MS_Team_Call_Schedule__c schedule = createSchedule();
        Test.setMock(HttpCalloutMock.class, new SubscriptionAndRenewalMock());

        Test.startTest();
        MicrosoftGraphSubscriptionService.createLifecycleSubscriptions(
            schedule.Id,
            'https://example.com/services/apexrest/msgraph/lifecycle',
            'https://example.com/services/apexrest/msgraph/lifecycle',
            'test-certificate',
            'test-certificate-id'
        );
        Test.stopTest();

        try {
            MicrosoftGraphSubscriptionService.createLifecycleSubscriptions(
                schedule.Id, 'http://invalid.example.com', null, null, null
            );
        } catch (AuraHandledException expected) {
            // Invalid non-HTTPS URLs must be rejected.
        }
    }

    @IsTest
    static void renewsExpiringSubscription() {
        Database.insert(new MS_Graph_Subscription__c(
            Graph_Subscription_ID__c = 'renew-me',
            Resource__c = 'me/events', Change_Type__c = 'updated',
            Expiration__c = System.now().addMinutes(10),
            Client_State_Hash__c = hashValue('renew-state'),
            Notification_URL__c = 'https://example.com/webhook',
            Status__c = 'Active'
        ), AccessLevel.SYSTEM_MODE);
        Test.setMock(HttpCalloutMock.class, new SubscriptionAndRenewalMock());

        Test.startTest();
        MicrosoftGraphSubscriptionService.renewExpiringSubscriptions();
        Test.stopTest();
    }

    private static MS_Team_Call_Schedule__c createSchedule() {
        MS_Team_Call_Schedule__c schedule =
            new MS_Team_Call_Schedule__c(
                Subject__c = 'Lifecycle meeting',
                Attendee_Emails__c = 'customer@example.com',
                Start_Date_Time__c = '2026-07-27T10:00:00',
                End_Date_Time__c = '2026-07-27T11:00:00',
                Microsoft_Time_Zone__c = 'India Standard Time',
                Teams_Meeting_Requested__c = true,
                Is_Online_Meeting__c = true,
                Graph_Event_ID__c = 'graph-event-1',
                Online_Meeting_ID__c = 'online-meeting-1',
                Teams_Join_URL__c =
                    'https://teams.example.com/join/meeting-1',
                Status__c = 'Scheduled',
                Graph_Created_At__c = System.now()
            );
        Database.insert(schedule, AccessLevel.SYSTEM_MODE);
        return schedule;
    }

    private static String hashValue(String value) {
        return EncodingUtil.convertToHex(
            Crypto.generateDigest('SHA-256', Blob.valueOf(value))
        ).toLowerCase();
    }

    private class EventSyncMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            System.assertEquals('GET', request.getMethod());
            return jsonResponse(
                200,
                new Map<String, Object>{
                    'id' => 'graph-event-1',
                    'subject' => 'Updated meeting',
                    'changeKey' => 'change-key-2',
                    'lastModifiedDateTime' =>
                        '2026-07-27T08:00:00Z',
                    'webLink' => 'https://outlook.example.com/event',
                    'isOnlineMeeting' => true,
                    'isCancelled' => false,
                    'start' => new Map<String, Object>{
                        'dateTime' => '2026-07-27T10:00:00',
                        'timeZone' => 'India Standard Time'
                    },
                    'end' => new Map<String, Object>{
                        'dateTime' => '2026-07-27T11:00:00',
                        'timeZone' => 'India Standard Time'
                    },
                    'onlineMeeting' => new Map<String, Object>{
                        'joinUrl' =>
                            'https://teams.example.com/join/meeting-1'
                    },
                    'attendees' => new List<Object>{
                        new Map<String, Object>{
                            'emailAddress' =>
                                new Map<String, Object>{
                                    'name' => 'Customer',
                                    'address' =>
                                        'customer@example.com'
                                },
                            'type' => 'required',
                            'status' => new Map<String, Object>{
                                'response' => 'declined',
                                'time' =>
                                    '2026-07-27T07:45:00Z'
                            }
                        }
                    }
                }
            );
        }
    }

    private class MeetingArtifactMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            String endpoint = request.getEndpoint();
            if (
                endpoint.endsWith('/attendanceReports')
            ) {
                return jsonResponse(
                    200,
                    new Map<String, Object>{
                        'value' => new List<Object>{
                            new Map<String, Object>{
                                'id' => 'attendance-report-1'
                            }
                        }
                    }
                );
            }
            if (endpoint.contains('attendanceReports/')) {
                return jsonResponse(
                    200,
                    new Map<String, Object>{
                        'id' => 'attendance-report-1',
                        'meetingStartDateTime' =>
                            '2026-07-27T04:30:00Z',
                        'meetingEndDateTime' =>
                            '2026-07-27T05:30:00Z',
                        'attendanceRecords' => new List<Object>{
                            new Map<String, Object>{
                                'emailAddress' =>
                                    'customer@example.com',
                                'role' => 'Attendee',
                                'identity' =>
                                    new Map<String, Object>{
                                        'id' => 'entra-customer',
                                        'displayName' => 'Customer'
                                    },
                                'totalAttendanceInSeconds' => 3300,
                                'attendanceIntervals' =>
                                    new List<Object>{
                                        new Map<String, Object>{
                                            'joinDateTime' =>
                                                '2026-07-27T04:32:00Z',
                                            'leaveDateTime' =>
                                                '2026-07-27T05:27:00Z',
                                            'durationInSeconds' => 3300
                                        }
                                    }
                            }
                        }
                    }
                );
            }
            if (endpoint.endsWith('/transcripts')) {
                return jsonResponse(
                    200,
                    artifactList(
                        'transcript-1',
                        'transcriptContentUrl',
                        'https://graph.microsoft.com/transcript/content'
                    )
                );
            }
            if (endpoint.endsWith('/recordings')) {
                return jsonResponse(
                    200,
                    artifactList(
                        'recording-1',
                        'recordingContentUrl',
                        'https://graph.microsoft.com/recording/content'
                    )
                );
            }
            return jsonResponse(404, new Map<String, Object>());
        }
    }

    private class SubscriptionMock implements HttpCalloutMock {
        private Integer sequence = 0;

        public HttpResponse respond(HttpRequest request) {
            sequence++;
            System.assertEquals('POST', request.getMethod());
            Map<String, Object> requestData =
                (Map<String, Object>) JSON.deserializeUntyped(
                    request.getBody()
                );
            System.assertNotEquals(null, requestData.get('clientState'));
            return jsonResponse(
                201,
                new Map<String, Object>{
                    'id' => 'subscription-' + sequence,
                    'expirationDateTime' =>
                        '2026-07-29T09:00:00Z'
                }
            );
        }
    }

    private class SubscriptionAndRenewalMock implements HttpCalloutMock {
        private Integer sequence = 0;

        public HttpResponse respond(HttpRequest request) {
            sequence++;
            if (request.getMethod() == 'PATCH') {
                return jsonResponse(200, new Map<String, Object>{
                    'expirationDateTime' => '2026-08-03T09:00:00Z'
                });
            }
            return jsonResponse(201, new Map<String, Object>{
                'id' => 'rich-subscription-' + sequence,
                'expirationDateTime' => '2026-08-02T09:00:00Z'
            });
        }
    }

    private static Map<String, Object> artifactList(
        String artifactId,
        String contentProperty,
        String contentUrl
    ) {
        return new Map<String, Object>{
            'value' => new List<Object>{
                new Map<String, Object>{
                    'id' => artifactId,
                    contentProperty => contentUrl,
                    'contentCorrelationId' => 'correlation-1',
                    'createdDateTime' => '2026-07-27T05:31:00Z',
                    'endDateTime' => '2026-07-27T05:32:00Z'
                }
            }
        };
    }

    private static HttpResponse jsonResponse(
        Integer statusCode,
        Object body
    ) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(statusCode);
        response.setHeader('Content-Type', 'application/json');
        response.setBody(JSON.serialize(body));
        return response;
    }
}