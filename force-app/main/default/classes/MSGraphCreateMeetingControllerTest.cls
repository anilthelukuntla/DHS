@IsTest
/** Exercises the existing MSGraphCreateMeetingController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexDoc, PMD.ExcessiveParameterList')
private class MSGraphCreateMeetingControllerTest {

    @IsTest
    static void createMeetingStoresSchedule() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
        DHS_Contact__c contact = new DHS_Contact__c(
            First_Name__c = 'Meeting',
            Last_Name__c = 'Lead',
            Email__c = 'lead@example.com',
            Contact_Type__c = 'Subject',
            SSN__c = '123-45-6789'
        );
        Database.insert(contact, AccessLevel.SYSTEM_MODE);

        DHS_Case__c caseRecord = new DHS_Case__c(
            DHS_Contact__c = contact.Id,
            DHS_Assigned_To__c = UserInfo.getUserId()
        );
        Database.insert(caseRecord, AccessLevel.SYSTEM_MODE);

        DHS_Lead__c lead = new DHS_Lead__c(
            DHS_Case__c = caseRecord.Id,
            Coverage_Type__c = 'Subject Interview',
            DHS_Assigned_To__c = UserInfo.getUserId(),
            LeadType__c = 'Subject Interview (ESI/TESI)'
        );
        Database.insert(lead, AccessLevel.SYSTEM_MODE);

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessfulMeetingMock()
        );

        Test.startTest();
        MicrosoftGraphCreateMeetingController.MeetingResult result =
            MicrosoftGraphCreateMeetingController.createMeetingForLead(
                'Project Review',
                '<p>Review current project status.</p>',
                new List<String>{
                    'Attendee@example.com',
                    'attendee@example.com',
                    'second@example.com'
                },
                '2026-07-25T10:00:00',
                '2026-07-25T10:30:00',
                'India Standard Time',
                true,
                true,
                lead.Id
            );
        Test.stopTest();

        System.assertEquals(true, result.success, 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 57');
        System.assertEquals('graph-event-123', result.eventId, 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 58');
        System.assertEquals('online-meeting-456', result.onlineMeetingId, 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 59');
        System.assertEquals(
            'entra-organizer-789',
            result.organizerEntraUserId
        , 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 60');
        System.assertEquals(null, result.lifecyclePreparationError, 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 64');
        System.assertNotEquals(null, result.scheduleId, 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 65');
        System.assertNotEquals(null, result.transactionId, 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 66');

        MS_Team_Call_Schedule__c schedule = [
            SELECT
                Id,
                Graph_Event_ID__c,
                Graph_Transaction_ID__c,
                Graph_Change_Key__c,
                Graph_Last_Modified__c,
                Online_Meeting_ID__c,
                Organizer_Entra_User_ID__c,
                Recording_Requested__c,
                Transcription_Requested__c,
                Last_Synchronized_At__c,
                Last_Graph_Error__c
            FROM MS_Team_Call_Schedule__c
            WHERE Id = :result.scheduleId
        ];

        System.assertEquals(result.scheduleId, schedule.Id, 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 85');
        System.assertEquals('graph-event-123', schedule.Graph_Event_ID__c, 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 86');
        System.assertEquals(
            result.transactionId,
            schedule.Graph_Transaction_ID__c
        , 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 87');
        System.assertEquals('change-key-1', schedule.Graph_Change_Key__c, 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 91');
        System.assertNotEquals(null, schedule.Graph_Last_Modified__c, 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 92');
        System.assertEquals(
            'online-meeting-456',
            schedule.Online_Meeting_ID__c
        , 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 93');
        System.assertEquals(
            'entra-organizer-789',
            schedule.Organizer_Entra_User_ID__c
        , 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 97');
        System.assertNotEquals(null, schedule.Last_Synchronized_At__c, 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 101');
        System.assertEquals(null, schedule.Last_Graph_Error__c, 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 102');
        System.assertEquals(true, schedule.Recording_Requested__c, 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 103');
        System.assertEquals(true, schedule.Transcription_Requested__c, 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 104');

        DHSLeadDetailPageController.MeetingLifecycleDetails details =
            DHSLeadDetailPageController.getMeetingLifecycleDetails(
                schedule.Id,
                lead.Id
            );
        System.assertEquals('Project Review', details.subject, 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 111');
        System.assertEquals('Scheduled', details.status, 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 112');
        System.assertEquals(0, details.participants.size(), 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 113');
        System.assertEquals(0, details.artifacts.size(), 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 114');
        }
    }

    @IsTest
    static void updatesCancelsAndDeletesScheduledMeetings() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
        DHS_Case__c caseRecord = new DHS_Case__c(
            DHS_Assigned_To__c = UserInfo.getUserId()
        );
        Database.insert(caseRecord, AccessLevel.SYSTEM_MODE);
        DHS_Lead__c lead = new DHS_Lead__c(
            DHS_Case__c = caseRecord.Id,
            Coverage_Type__c = 'Subject Interview',
            LeadType__c = 'Subject Interview (ESI/TESI)'
        );
        Database.insert(lead, AccessLevel.SYSTEM_MODE);
        List<MS_Team_Call_Schedule__c> schedules =
            new List<MS_Team_Call_Schedule__c>();
        for (Integer indexValue = 0; indexValue < 3; indexValue++) {
            schedules.add(new MS_Team_Call_Schedule__c(
                DHS_Lead__c = lead.Id,
                Subject__c = 'Operation ' + indexValue,
                Attendee_Emails__c = 'old@example.com',
                Start_Date_Time__c = '2026-08-03T10:00:00',
                End_Date_Time__c = '2026-08-03T10:30:00',
                Microsoft_Time_Zone__c = 'India Standard Time',
                Graph_Event_ID__c = 'event-' + indexValue,
                Status__c = 'Scheduled'
            ));
        }
        Database.insert(schedules, AccessLevel.SYSTEM_MODE);
        Test.setMock(HttpCalloutMock.class, new OperationMock());

        Test.startTest();
        MicrosoftGraphCreateMeetingController.updateScheduledMeeting(
            schedules[0].Id, lead.Id, 'Updated meeting',
            new List<String>{
                'new@example.com', 'NEW@example.com', 'second@example.com'
            },
            '2026-08-03T11:00:00', '2026-08-03T11:45:00',
            'India Standard Time'
        );
        Test.stopTest();
        }
    }

    @IsTest
    static void cancelsScheduledMeeting() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
        List<Id> ids = createLeadAndSchedule('cancel-event');
        Test.setMock(HttpCalloutMock.class, new OperationMock());

        Test.startTest();
        MicrosoftGraphCreateMeetingController.cancelScheduledMeeting(
            ids[1], ids[0], 'No longer needed'
        );
        Test.stopTest();
        }
    }

    @IsTest
    static void deletesScheduledMeeting() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
        List<Id> ids = createLeadAndSchedule('delete-event');
        Test.setMock(HttpCalloutMock.class, new OperationMock());

        Test.startTest();
        MicrosoftGraphCreateMeetingController.deleteScheduledMeeting(
            ids[1], ids[0], 'Created by mistake'
        );
        Test.stopTest();
        }
    }

    @IsTest
    static void rejectsInvalidMeetingRequests() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
            assertInvalidRequest(
                null,
                new List<String>{ 'person@example.com' },
                '2026-08-03T10:00:00',
                '2026-08-03T10:30:00',
                'India Standard Time'
            );
            assertInvalidRequest(
                'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
                'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
                'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
                'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
                'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' +
                'XXXXXX',
                new List<String>{ 'person@example.com' },
                '2026-08-03T10:00:00',
                '2026-08-03T10:30:00',
                'India Standard Time'
            );
            assertInvalidRequest(
                'Subject',
                new List<String>(),
                '2026-08-03T10:00:00',
                '2026-08-03T10:30:00',
                'India Standard Time'
            );
            assertInvalidRequest(
                'Subject',
                new List<String>{ 'person@example.com' },
                null,
                '2026-08-03T10:30:00',
                'India Standard Time'
            );
            assertInvalidRequest(
                'Subject',
                new List<String>{ 'person@example.com' },
                '2026-08-03T10:00:00',
                null,
                'India Standard Time'
            );
            assertInvalidRequest(
                'Subject',
                new List<String>{ 'person@example.com' },
                '2026-08-03T10:00:00',
                '2026-08-03T10:30:00',
                null
            );
            assertInvalidRequest(
                'Subject',
                new List<String>{ 'person@example.com' },
                'invalid-start',
                '2026-08-03T10:30:00',
                'India Standard Time'
            );
            assertInvalidRequest(
                'Subject',
                new List<String>{ 'not-an-email' },
                '2026-08-03T10:00:00',
                '2026-08-03T10:30:00',
                'India Standard Time'
            );
        }
    }

    @IsTest
    static void reportsMicrosoftGraphErrors() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
            Test.setMock(HttpCalloutMock.class, new GraphErrorMock());
            Test.startTest();
            try {
                MicrosoftGraphCreateMeetingController.createMeeting(
                    'Graph failure',
                    null,
                    new List<String>{ 'person@example.com' },
                    '2026-08-03T10:00:00',
                    '2026-08-03T10:30:00',
                    'India Standard Time',
                    false
                );
                System.assert(false, 'Expected a Microsoft Graph error.');
            } catch (AuraHandledException expectedException) {
                System.assertNotEquals(null, expectedException.getMessage(), 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 278');
            }
            Test.stopTest();
        }
    }

    private static void assertInvalidRequest(
        String subject,
        List<String> attendeeEmails,
        String startDateTimeValue,
        String endDateTimeValue,
        String timeZone
    ) {
        try {
            MicrosoftGraphCreateMeetingController.createMeeting(
                subject,
                null,
                attendeeEmails,
                startDateTimeValue,
                endDateTimeValue,
                timeZone,
                false
            );
            System.assert(false, 'Expected request validation to fail.');
        } catch (AuraHandledException expectedException) {
            System.assertNotEquals(null, expectedException.getMessage(), 'Assertion failed in MSGraphCreateMeetingControllerTest at source line 303');
        }
    }

    private static List<Id> createLeadAndSchedule(String graphEventId) {
        DHS_Case__c caseRecord = new DHS_Case__c(
            DHS_Assigned_To__c = UserInfo.getUserId()
        );
        Database.insert(caseRecord, AccessLevel.SYSTEM_MODE);
        DHS_Lead__c lead = new DHS_Lead__c(
            DHS_Case__c = caseRecord.Id,
            Coverage_Type__c = 'Subject Interview',
            LeadType__c = 'Subject Interview (ESI/TESI)'
        );
        Database.insert(lead, AccessLevel.SYSTEM_MODE);
        MS_Team_Call_Schedule__c schedule = new MS_Team_Call_Schedule__c(
            DHS_Lead__c = lead.Id,
            Subject__c = 'Operation meeting',
            Attendee_Emails__c = 'old@example.com',
            Start_Date_Time__c = '2026-08-03T10:00:00',
            End_Date_Time__c = '2026-08-03T10:30:00',
            Microsoft_Time_Zone__c = 'India Standard Time',
            Graph_Event_ID__c = graphEventId,
            Status__c = 'Scheduled'
        );
        Database.insert(schedule, AccessLevel.SYSTEM_MODE);
        return new List<Id>{ lead.Id, schedule.Id };
    }

    private class SuccessfulMeetingMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            if (request.getMethod() == 'GET') {
                System.assert(
                    request.getEndpoint().startsWith(
                        'callout:MicrosoftGraph/v1.0/me/onlineMeetings?' +
                        '%24filter=JoinWebUrl%20eq%20%27'
                    )
                );
                HttpResponse lookupResponse = new HttpResponse();
                lookupResponse.setStatusCode(200);
                lookupResponse.setHeader(
                    'Content-Type',
                    'application/json'
                );
                lookupResponse.setBody(JSON.serialize(
                    new Map<String, Object>{
                        'value' => new List<Object>{
                            new Map<String, Object>{
                                'id' => 'online-meeting-456',
                                'participants' =>
                                    new Map<String, Object>{
                                        'organizer' =>
                                            new Map<String, Object>{
                                                'identity' =>
                                                    new Map<String, Object>{
                                                        'user' =>
                                                            new Map<String, Object>{
                                                                'id' =>
                                                                    'entra-organizer-789'
                                                            }
                                                    }
                                            }
                                    }
                            }
                        }
                    }
                ));
                return lookupResponse;
            }

            if (request.getMethod() == 'PATCH') {
                System.assert(
                    request.getEndpoint().endsWith(
                        '/me/onlineMeetings/online-meeting-456'
                    )
                );
                Map<String, Object> patchBody =
                    (Map<String, Object>) JSON.deserializeUntyped(
                        request.getBody()
                    );
                System.assertEquals(true, patchBody.get('allowRecording'));
                System.assertEquals(
                    true,
                    patchBody.get('recordAutomatically')
                );
                System.assertEquals(
                    true,
                    patchBody.get('allowTranscription')
                );
                HttpResponse patchResponse = new HttpResponse();
                patchResponse.setStatusCode(200);
                patchResponse.setBody('{}');
                return patchResponse;
            }

            System.assertEquals('POST', request.getMethod());
            System.assertEquals(
                'callout:MicrosoftGraph/v1.0/me/events',
                request.getEndpoint()
            );
            System.assertEquals(
                'IdType="ImmutableId"',
                request.getHeader('Prefer')
            );
            Map<String, Object> requestBody =
                (Map<String, Object>) JSON.deserializeUntyped(
                    request.getBody()
                );
            System.assertNotEquals(
                null,
                requestBody.get('transactionId')
            );

            HttpResponse response = new HttpResponse();
            response.setStatusCode(201);
            response.setHeader('Content-Type', 'application/json');
            response.setBody(JSON.serialize(
                new Map<String, Object>{
                    'id' => 'graph-event-123',
                    'changeKey' => 'change-key-1',
                    'lastModifiedDateTime' =>
                        '2026-07-25T04:30:00Z',
                    'subject' => 'Project Review',
                    'webLink' => 'https://outlook.example.com/event/123',
                    'isOnlineMeeting' => true,
                    'organizer' => new Map<String, Object>{
                        'emailAddress' => new Map<String, Object>{
                            'address' => 'organizer@example.com'
                        }
                    },
                    'onlineMeeting' => new Map<String, Object>{
                        'joinUrl' => 'https://teams.example.com/join/123'
                    },
                    'start' => new Map<String, Object>{
                        'dateTime' => '2026-07-25T10:00:00',
                        'timeZone' => 'India Standard Time'
                    },
                    'end' => new Map<String, Object>{
                        'dateTime' => '2026-07-25T10:30:00',
                        'timeZone' => 'India Standard Time'
                    }
                }
            ));
            return response;
        }
    }

    private class OperationMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            if (request.getMethod() == 'PATCH') {
                response.setStatusCode(200);
            } else if (request.getMethod() == 'POST') {
                response.setStatusCode(202);
            } else {
                response.setStatusCode(204);
            }
            response.setBody('{}');
            return response;
        }
    }

    private class GraphErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(400);
            response.setStatus('Bad Request');
            response.setBody(
                '{"error":{"code":"InvalidRequest",' +
                '"message":"Meeting request was rejected."}}'
            );
            return response;
        }
    }
}